package survey_s

import (
	"fmt"
	"slices"
	"strings"
	"unicode/utf8"

	"github.com/DanielRasho/Thesis/content"
	"github.com/jackc/pgx/v5/pgtype"
)

// Longest free_code / free_text answer accepted, in characters.
const maxValueLength = 100_000

// Answer is what a participant submits for a question. Which fields are set
// depends on the question kind:
//
//	info                      { questionId }
//	choice_code, choice_text  { questionId, optionId }
//	free_code, free_text      { questionId, value }      (empty ok if optional)
//	likert                    { questionId, likert: { itemId: 1..scale } }
//	any optional question     { questionId, skipped: true }
type Answer struct {
	QuestionID string         `json:"questionId" validate:"required"`
	OptionID   *string        `json:"optionId"`
	Value      *string        `json:"value"`
	Likert     map[string]int `json:"likert"`
	Skipped    bool           `json:"skipped"`
}

// answerRow is what gets stored for a valid answer.
type answerRow struct {
	optionID  pgtype.Text
	value     pgtype.Text
	isCorrect pgtype.Bool // only choices are graded automatically
	likert    []likertValue
}

type likertValue struct {
	itemID string
	value  int16
}

// checkAnswer validates an answer against its question. On failure it returns
// the errors by field, ready to be answered as a 400.
func checkAnswer(q *content.Question, a Answer) (answerRow, map[string]string) {
	var row answerRow
	fields := map[string]string{}

	isChoice := q.Kind == content.KindChoiceCode || q.Kind == content.KindChoiceText
	isFree := q.Kind == content.KindFreeCode || q.Kind == content.KindFreeText
	notAllowed := fmt.Sprintf("is not allowed for %s questions", q.Kind)

	// Skipped optional question: stored with every field NULL (and no likert
	// rows), it only marks the question as done.
	if a.Skipped {
		if !q.Optional {
			fields["skipped"] = "is only allowed for optional questions"
		}
		if a.OptionID != nil {
			fields["optionId"] = "is not allowed when skipped"
		}
		if a.Value != nil {
			fields["value"] = "is not allowed when skipped"
		}
		if a.Likert != nil {
			fields["likert"] = "is not allowed when skipped"
		}
		if len(fields) > 0 {
			return answerRow{}, fields
		}
		return answerRow{}, nil
	}

	// Fields that don't belong to the kind.
	if a.OptionID != nil && !isChoice {
		fields["optionId"] = notAllowed
	}
	if a.Value != nil && !isFree {
		fields["value"] = notAllowed
	}
	if a.Likert != nil && q.Kind != content.KindLikert {
		fields["likert"] = notAllowed
	}

	switch {
	case isChoice:
		if a.OptionID == nil || *a.OptionID == "" {
			fields["optionId"] = "is required"
			break
		}
		i := slices.IndexFunc(q.Options, func(o content.Option) bool { return o.ID == *a.OptionID })
		if i < 0 {
			fields["optionId"] = "is not an option of this question"
			break
		}
		row.optionID = pgtype.Text{String: q.Options[i].ID, Valid: true}
		row.isCorrect = pgtype.Bool{Bool: q.Options[i].Correct, Valid: true}

	case isFree:
		value := ""
		if a.Value != nil {
			value = *a.Value
		}
		switch {
		case strings.TrimSpace(value) == "":
			if !q.Optional {
				fields["value"] = "is required"
			}
			// Skipped optional question: stored as NULL.
		case utf8.RuneCountInString(value) > maxValueLength:
			fields["value"] = fmt.Sprintf("must be at most %d characters", maxValueLength)
		default:
			row.value = pgtype.Text{String: value, Valid: true}
		}

	case q.Kind == content.KindLikert:
		if a.Likert == nil {
			fields["likert"] = "is required"
			break
		}
		for _, item := range q.Items {
			value, ok := a.Likert[item.ID]
			switch {
			case !ok:
				fields["likert."+item.ID] = "is required"
			case value < 1 || value > q.Scale:
				fields["likert."+item.ID] = fmt.Sprintf("must be between 1 and %d", q.Scale)
			default:
				row.likert = append(row.likert, likertValue{itemID: item.ID, value: int16(value)})
			}
		}
		for itemID := range a.Likert {
			if !slices.ContainsFunc(q.Items, func(item content.Item) bool { return item.ID == itemID }) {
				fields["likert."+itemID] = "is not an item of this question"
			}
		}
	}

	if len(fields) > 0 {
		return answerRow{}, fields
	}
	return row, nil
}
