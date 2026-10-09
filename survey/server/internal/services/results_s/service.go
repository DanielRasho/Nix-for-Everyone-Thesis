package results_s

import (
	"archive/zip"
	"bytes"
	"context"
	"encoding/csv"
	"fmt"
	"io"
	"slices"
	"strconv"
	"strings"
	"time"

	"github.com/DanielRasho/Thesis/content"
	"github.com/DanielRasho/Thesis/internal/storage/survey_db"
	"github.com/DanielRasho/Thesis/utils"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/jackc/pgx/v5/pgxpool"
)

// ResultsService exposes the answers to the admin: manual grading of
// free_code answers, the CSV export and the zip of free_code answers.
type ResultsService struct {
	DBClient  *pgxpool.Pool
	DBQueries *survey_db.Queries
	Content   *content.Content
}

// GradingAnswer is a free_code answer waiting for (or with) a manual grade.
type GradingAnswer struct {
	UserID     pgtype.UUID `json:"userId"`
	Username   string      `json:"username"`
	QuestionID string      `json:"questionId"`
	Prompt     string      `json:"prompt"`
	Value      string      `json:"value"`
	IsCorrect  *bool       `json:"isCorrect"`
	AnsweredAt time.Time   `json:"answeredAt"`
}

// GradingAnswers returns every free_code answer, by username and answer time.
func (s *ResultsService) GradingAnswers(ctx context.Context) ([]GradingAnswer, error) {
	rows, err := s.DBQueries.ListAnswers(ctx)
	if err != nil {
		return nil, fmt.Errorf("listing answers: %w", err)
	}

	answers := []GradingAnswer{}
	for _, row := range rows {
		q, ok := s.Content.Question(row.QuestionID)
		if !ok || q.Kind != content.KindFreeCode {
			continue
		}
		answer := GradingAnswer{
			UserID:     row.UserID,
			Username:   row.Username,
			QuestionID: row.QuestionID,
			Prompt:     q.Prompt,
			Value:      row.Value.String,
			AnsweredAt: row.AnsweredAt.Time,
		}
		if row.IsCorrect.Valid {
			answer.IsCorrect = &row.IsCorrect.Bool
		}
		answers = append(answers, answer)
	}
	return answers, nil
}

// Grade sets (or clears, with nil) the grade of a free_code answer.
func (s *ResultsService) Grade(ctx context.Context, userID pgtype.UUID, questionID string, isCorrect *bool) error {
	q, ok := s.Content.Question(questionID)
	if !ok {
		return utils.Reject(utils.QuestionNotFound, "question %q does not exist", questionID)
	}
	if q.Kind != content.KindFreeCode {
		return utils.Reject(utils.NotGradable, "question %s is %s, only free_code answers are graded manually", questionID, q.Kind)
	}

	grade := pgtype.Bool{}
	if isCorrect != nil {
		grade = pgtype.Bool{Bool: *isCorrect, Valid: true}
	}
	updated, err := s.DBQueries.GradeAnswer(ctx, survey_db.GradeAnswerParams{
		IsCorrect:  grade,
		UserID:     userID,
		QuestionID: questionID,
	})
	if err != nil {
		return fmt.Errorf("grading %s of %s: %w", questionID, userID, err)
	}
	if updated == 0 {
		return utils.Reject(utils.AnswerNotFound, "user %s has no answer to %s", userID, questionID)
	}
	return nil
}

// CSV columns, one row per answer (likert: one row per item).
var csvHeader = []string{
	"username",      // participant
	"survey_order",  // their assigned surveys in order, e.g. "nixty,nix" (the group)
	"step",          // "background" or the survey id
	"step_position", // 1, 2... (empty for background)
	"section",       // background | tasks | feedback
	"question_id",
	"kind",
	"item_id",    // likert only
	"option_id",  // choice only
	"value",      // free_code / free_text text, or the likert value
	"is_correct", // true | false | empty (not graded or not gradable)
	"answered_at",
	"time_ms", // time spent on the question (repeated on each likert item row)
}

// ExportCSV writes every answer in long format, sorted by participant, then
// step in their order, then question in content order.
func (s *ResultsService) ExportCSV(ctx context.Context) ([]byte, error) {
	answers, err := s.DBQueries.ListAnswers(ctx)
	if err != nil {
		return nil, fmt.Errorf("listing answers: %w", err)
	}
	likertRows, err := s.DBQueries.ListLikertAnswers(ctx)
	if err != nil {
		return nil, fmt.Errorf("listing likert answers: %w", err)
	}
	timeRows, err := s.DBQueries.ListQuestionTimes(ctx)
	if err != nil {
		return nil, fmt.Errorf("listing question times: %w", err)
	}
	assignments, err := s.DBQueries.ListAssignments(ctx)
	if err != nil {
		return nil, fmt.Errorf("listing assignments: %w", err)
	}

	type questionKey struct {
		user     pgtype.UUID
		question string
	}

	// Survey order and position of every survey, by user.
	order := map[pgtype.UUID][]string{}
	position := map[questionKey]int{} // (user, survey) -> position
	for _, a := range assignments {
		order[a.UserID] = append(order[a.UserID], a.Survey)
		position[questionKey{a.UserID, a.Survey}] = int(a.Position)
	}

	likert := map[questionKey][]survey_db.LikertAnswer{}
	for _, l := range likertRows {
		key := questionKey{l.UserID, l.QuestionID}
		likert[key] = append(likert[key], l)
	}

	times := map[questionKey]int64{}
	for _, t := range timeRows {
		times[questionKey{t.UserID, t.QuestionID}] = t.TimeMs
	}

	// Sort by username (as listed), step position, then content order.
	// Unknown questions (removed from the content) go last.
	stepOf := func(row survey_db.ListAnswersRow) string {
		step, _, _ := strings.Cut(row.QuestionID, ".")
		return step
	}
	slices.SortStableFunc(answers, func(a, b survey_db.ListAnswersRow) int {
		if c := strings.Compare(a.Username, b.Username); c != 0 {
			return c
		}
		if c := position[questionKey{a.UserID, stepOf(a)}] - position[questionKey{b.UserID, stepOf(b)}]; c != 0 {
			return c
		}
		return s.questionIndex(a.QuestionID) - s.questionIndex(b.QuestionID)
	})

	var buf bytes.Buffer
	w := csv.NewWriter(&buf)
	w.Write(csvHeader)

	for _, a := range answers {
		key := questionKey{a.UserID, a.QuestionID}
		step := stepOf(a)

		var section, kind string
		q, known := s.Content.Question(a.QuestionID)
		if known {
			section, kind = string(q.Section), string(q.Kind)
		}

		stepPosition := ""
		if p, ok := position[questionKey{a.UserID, step}]; ok {
			stepPosition = strconv.Itoa(p)
		}

		timeMs := ""
		if t, ok := times[key]; ok {
			timeMs = strconv.FormatInt(t, 10)
		}

		base := []string{
			a.Username,
			strings.Join(order[a.UserID], ","),
			step,
			stepPosition,
			section,
			a.QuestionID,
			kind,
		}
		tail := []string{
			formatBool(a.IsCorrect),
			a.AnsweredAt.Time.UTC().Format(time.RFC3339),
			timeMs,
		}

		items := likert[key]
		if len(items) == 0 {
			w.Write(slices.Concat(base, []string{"", a.OptionID.String, a.Value.String}, tail))
			continue
		}
		if known {
			// Items in content order instead of alphabetical.
			slices.SortStableFunc(items, func(x, y survey_db.LikertAnswer) int {
				return itemIndex(q, x.ItemID) - itemIndex(q, y.ItemID)
			})
		}
		for _, item := range items {
			w.Write(slices.Concat(base, []string{item.ItemID, "", strconv.Itoa(int(item.Value))}, tail))
		}
	}

	w.Flush()
	if err := w.Error(); err != nil {
		return nil, fmt.Errorf("writing CSV: %w", err)
	}
	return buf.Bytes(), nil
}

// ExportCode zips every free_code answer as a file, one folder per participant:
// <username>/<questionId>.<nix|ts> (extension from the survey language), dated
// when it was answered. Usernames and ids are safe path segments (validated).
func (s *ResultsService) ExportCode(ctx context.Context) ([]byte, error) {
	answers, err := s.GradingAnswers(ctx)
	if err != nil {
		return nil, err
	}

	var buf bytes.Buffer
	zw := zip.NewWriter(&buf)
	for _, a := range answers {
		name := fmt.Sprintf("%s/%s.%s", a.Username, a.QuestionID, s.codeExtension(a.QuestionID))
		f, err := zw.CreateHeader(&zip.FileHeader{Name: name, Method: zip.Deflate, Modified: a.AnsweredAt})
		if err != nil {
			return nil, fmt.Errorf("adding %s to the zip: %w", name, err)
		}
		if _, err := io.WriteString(f, a.Value); err != nil {
			return nil, fmt.Errorf("writing %s to the zip: %w", name, err)
		}
	}
	if err := zw.Close(); err != nil {
		return nil, fmt.Errorf("writing zip: %w", err)
	}
	return buf.Bytes(), nil
}

// codeExtension is the file extension of the code answered to a question.
func (s *ResultsService) codeExtension(questionID string) string {
	q, ok := s.Content.Question(questionID)
	if !ok {
		return "txt"
	}
	survey, ok := s.Content.Surveys[q.Survey]
	if !ok {
		return "txt"
	}
	switch survey.Language {
	case "nix":
		return "nix"
	case "typescript":
		return "ts"
	default:
		return "txt"
	}
}

// questionIndex is the position of a question inside its step, in content order.
func (s *ResultsService) questionIndex(id string) int {
	q, ok := s.Content.Question(id)
	if !ok {
		return 1 << 30
	}
	questions := s.Content.Background
	if survey, ok := s.Content.Surveys[q.Survey]; ok {
		questions = survey.Questions
	}
	return slices.IndexFunc(questions, func(other content.Question) bool { return other.ID == id })
}

func itemIndex(q *content.Question, itemID string) int {
	i := slices.IndexFunc(q.Items, func(item content.Item) bool { return item.ID == itemID })
	if i < 0 {
		return len(q.Items)
	}
	return i
}

func formatBool(b pgtype.Bool) string {
	if !b.Valid {
		return ""
	}
	return strconv.FormatBool(b.Bool)
}
