package survey_s

import (
	"context"
	"fmt"
	"time"

	"github.com/DanielRasho/Thesis/content"
	"github.com/DanielRasho/Thesis/internal/storage/survey_db"
	"github.com/DanielRasho/Thesis/utils"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/jackc/pgx/v5/pgxpool"
)

// Heartbeats closer than this extend the same time segment, otherwise a new
// one starts. Browsers throttle timers of background tabs to ~1/min, so it
// must stay above 60 s.
const maxHeartbeatGap = 90 * time.Second

// SurveyService handles the progress of participants through their roadmap:
// which question comes next, answers and time tracking.
type SurveyService struct {
	DBClient  *pgxpool.Pool
	DBQueries *survey_db.Queries
	Content   *content.Content
}

// StepInfo describes the step a question belongs to.
type StepInfo struct {
	ID        string `json:"id"`
	Title     string `json:"title"`
	Tool      string `json:"tool,omitempty"`
	Language  string `json:"language,omitempty"`
	Codespace string `json:"codespace,omitempty"`
}

type Progress struct {
	Answered int `json:"answered"`
	Total    int `json:"total"`
}

// Current is the screen a participant must see for a step. Question is nil
// once the step is finished.
type Current struct {
	Step     StepInfo          `json:"step"`
	Progress Progress          `json:"progress"`
	Question *content.Question `json:"question"`
}

type SurveySummary struct {
	ID    string `json:"id"`
	Title string `json:"title"`
}

// Surveys returns every survey of the content, sorted by id.
func (s *SurveyService) Surveys() []SurveySummary {
	surveys := []SurveySummary{}
	for _, id := range s.Content.SurveyIDs() {
		surveys = append(surveys, SurveySummary{ID: id, Title: s.Content.Surveys[id].Title})
	}
	return surveys
}

// Roadmap returns the steps of a participant, without dates.
func (s *SurveyService) Roadmap(ctx context.Context, userID pgtype.UUID) ([]Step, error) {
	p, err := s.loadProgress(ctx, s.DBQueries, userID)
	if err != nil {
		return nil, err
	}
	return buildSteps(p.defs, p.counts(), false), nil
}

// Current returns the current question of a step and marks the survey as
// started.
func (s *SurveyService) Current(ctx context.Context, userID pgtype.UUID, stepID string) (Current, error) {
	p, err := s.loadProgress(ctx, s.DBQueries, userID)
	if err != nil {
		return Current{}, err
	}

	i, ok := p.step(stepID)
	if !ok {
		return Current{}, utils.Reject(utils.StepNotFound, "step %q does not exist or is not assigned to the participant", stepID)
	}
	if statuses(p.defs, p.counts())[i] == StatusLocked {
		return Current{}, utils.Reject(utils.StepLocked, "step %q is locked", stepID)
	}

	if def := p.defs[i]; def.assignment != nil && !def.assignment.StartedAt.Valid {
		err := s.DBQueries.StartAssignment(ctx, survey_db.StartAssignmentParams{UserID: userID, Survey: def.id})
		if err != nil {
			return Current{}, fmt.Errorf("starting survey %q: %w", def.id, err)
		}
	}

	return p.currentOf(i), nil
}

// Answer stores the answer to the current question of a step and returns the
// next screen of that step. In one transaction it counts as a heartbeat,
// inserts the answer and, after the last question of a survey, completes it.
func (s *SurveyService) Answer(ctx context.Context, userID pgtype.UUID, answer Answer) (Current, error) {
	q, ok := s.Content.Question(answer.QuestionID)
	if !ok {
		return Current{}, utils.Reject(utils.QuestionNotFound, "question %q does not exist", answer.QuestionID)
	}

	row, fields := checkAnswer(q, answer)
	if fields != nil {
		return Current{}, utils.RejectFields(utils.InvalidFields, fields)
	}

	var current Current
	err := pgx.BeginFunc(ctx, s.DBClient, func(tx pgx.Tx) error {
		queries := s.DBQueries.WithTx(tx)

		p, err := s.loadProgress(ctx, queries, userID)
		if err != nil {
			return err
		}
		i, err := p.checkCurrent(q)
		if err != nil {
			return err
		}

		if err := heartbeat(ctx, queries, userID, q.ID); err != nil {
			return err
		}

		inserted, err := queries.InsertAnswer(ctx, survey_db.InsertAnswerParams{
			UserID:     userID,
			QuestionID: q.ID,
			OptionID:   row.optionID,
			Value:      row.value,
			IsCorrect:  row.isCorrect,
		})
		if err != nil {
			return fmt.Errorf("inserting answer to %s: %w", q.ID, err)
		}
		if inserted == 0 {
			// Answered by a concurrent request since the progress was read.
			return utils.Reject(utils.NotCurrentQuestion, "question %s is already answered", q.ID)
		}

		for _, item := range row.likert {
			err := queries.InsertLikertAnswer(ctx, survey_db.InsertLikertAnswerParams{
				UserID:     userID,
				QuestionID: q.ID,
				ItemID:     item.itemID,
				Value:      item.value,
			})
			if err != nil {
				return fmt.Errorf("inserting likert item %s of %s: %w", item.itemID, q.ID, err)
			}
		}

		p.answered[q.ID] = true
		if def := p.defs[i]; def.assignment != nil && p.current(i) == nil {
			_, err := queries.CompleteAssignment(ctx, survey_db.CompleteAssignmentParams{UserID: userID, Survey: def.id})
			if err != nil {
				return fmt.Errorf("completing survey %q: %w", def.id, err)
			}
		}

		current = p.currentOf(i)
		return nil
	})
	if err != nil {
		return Current{}, err
	}
	return current, nil
}

// Heartbeat records that the participant is still looking at a question. Only
// the current question of an unlocked step counts.
func (s *SurveyService) Heartbeat(ctx context.Context, userID pgtype.UUID, questionID string) error {
	q, ok := s.Content.Question(questionID)
	if !ok {
		return utils.Reject(utils.QuestionNotFound, "question %q does not exist", questionID)
	}

	p, err := s.loadProgress(ctx, s.DBQueries, userID)
	if err != nil {
		return err
	}
	if _, err := p.checkCurrent(q); err != nil {
		return err
	}

	return heartbeat(ctx, s.DBQueries, userID, q.ID)
}

// ParticipantSteps returns the roadmap of one participant, with dates.
func (s *SurveyService) ParticipantSteps(ctx context.Context, userID pgtype.UUID) ([]Step, error) {
	p, err := s.loadProgress(ctx, s.DBQueries, userID)
	if err != nil {
		return nil, err
	}
	return buildSteps(p.defs, p.counts(), true), nil
}

// AllParticipantSteps returns the roadmap (with dates) of every user that has
// assignments, by user id.
func (s *SurveyService) AllParticipantSteps(ctx context.Context) (map[pgtype.UUID][]Step, error) {
	assignments, err := s.DBQueries.ListAssignments(ctx)
	if err != nil {
		return nil, fmt.Errorf("listing assignments: %w", err)
	}
	counts, err := s.DBQueries.CountAnswersBySurvey(ctx)
	if err != nil {
		return nil, fmt.Errorf("counting answers: %w", err)
	}

	// Answers by user and step ('background' or the survey id).
	type key struct {
		user pgtype.UUID
		step string
	}
	answered := map[key]int{}
	for _, c := range counts {
		answered[key{c.UserID, c.Survey}] = int(c.Answered)
	}

	// Assignments come sorted by user and position.
	byUser := map[pgtype.UUID][]survey_db.Assignment{}
	for _, a := range assignments {
		byUser[a.UserID] = append(byUser[a.UserID], a)
	}

	steps := map[pgtype.UUID][]Step{}
	for userID, userAssignments := range byUser {
		defs := stepDefs(s.Content, userAssignments)
		stepCounts := make([]int, len(defs))
		for i, def := range defs {
			stepCounts[i] = answered[key{userID, def.id}]
		}
		steps[userID] = buildSteps(defs, stepCounts, true)
	}
	return steps, nil
}

// StepsWithoutProgress returns the roadmap of a user with no assignments nor
// answers (only background).
func (s *SurveyService) StepsWithoutProgress() []Step {
	defs := stepDefs(s.Content, nil)
	return buildSteps(defs, make([]int, len(defs)), true)
}

func (s *SurveyService) loadProgress(ctx context.Context, queries *survey_db.Queries, userID pgtype.UUID) (*progress, error) {
	assignments, err := queries.ListUserAssignments(ctx, userID)
	if err != nil {
		return nil, fmt.Errorf("listing assignments: %w", err)
	}
	answeredIDs, err := queries.ListUserAnsweredQuestions(ctx, userID)
	if err != nil {
		return nil, fmt.Errorf("listing answered questions: %w", err)
	}

	answered := make(map[string]bool, len(answeredIDs))
	for _, id := range answeredIDs {
		answered[id] = true
	}
	return &progress{defs: stepDefs(s.Content, assignments), answered: answered}, nil
}

// checkCurrent checks that q is the current question of an unlocked step of
// the participant, and returns that step.
func (p *progress) checkCurrent(q *content.Question) (int, error) {
	// Background questions belong to the "background" step, the rest to their survey.
	i, ok := p.step(q.Survey)
	if !ok {
		return 0, utils.Reject(utils.QuestionNotFound, "question %s belongs to survey %q, not assigned to the participant", q.ID, q.Survey)
	}
	if statuses(p.defs, p.counts())[i] == StatusLocked {
		return 0, utils.Reject(utils.StepLocked, "question %s belongs to the locked step %q", q.ID, q.Survey)
	}

	current := p.current(i)
	switch {
	case p.answered[q.ID]:
		return 0, utils.Reject(utils.NotCurrentQuestion, "question %s is already answered", q.ID)
	case current == nil:
		return 0, utils.Reject(utils.NotCurrentQuestion, "step %q is already completed", q.Survey)
	case current.ID != q.ID:
		return 0, utils.Reject(utils.NotCurrentQuestion, "question %s is not the current one, %s is", q.ID, current.ID)
	}
	return i, nil
}

// currentOf builds the Current screen of a step.
func (p *progress) currentOf(i int) Current {
	def := p.defs[i]
	info := StepInfo{ID: def.id, Title: def.title}
	if def.survey != nil {
		info.Tool = def.survey.Tool
		info.Language = def.survey.Language
		info.Codespace = def.survey.Codespace
	}
	return Current{
		Step:     info,
		Progress: Progress{Answered: p.counts()[i], Total: len(def.questions)},
		Question: p.current(i),
	}
}

// heartbeat extends the latest time segment of the question if it was seen
// recently, otherwise starts a new one.
func heartbeat(ctx context.Context, queries *survey_db.Queries, userID pgtype.UUID, questionID string) error {
	extended, err := queries.ExtendTimeSegment(ctx, survey_db.ExtendTimeSegmentParams{
		UserID:        userID,
		QuestionID:    questionID,
		MaxGapSeconds: maxHeartbeatGap.Seconds(),
	})
	if err != nil {
		return fmt.Errorf("extending time segment of %s: %w", questionID, err)
	}
	if extended > 0 {
		return nil
	}

	if err := queries.StartTimeSegment(ctx, survey_db.StartTimeSegmentParams{UserID: userID, QuestionID: questionID}); err != nil {
		return fmt.Errorf("starting time segment of %s: %w", questionID, err)
	}
	return nil
}
