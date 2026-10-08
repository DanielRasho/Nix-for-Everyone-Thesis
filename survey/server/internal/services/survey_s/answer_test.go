package survey_s

import (
	"maps"
	"slices"
	"strings"
	"testing"

	"github.com/DanielRasho/Thesis/content"
)

func ptr(s string) *string { return &s }

var (
	infoQ   = &content.Question{ID: "s.info", Kind: content.KindInfo}
	choiceQ = &content.Question{ID: "s.choice", Kind: content.KindChoiceText, Options: []content.Option{
		{ID: "a", Text: "A"}, {ID: "b", Text: "B", Correct: true},
	}}
	freeQ     = &content.Question{ID: "s.free", Kind: content.KindFreeCode}
	optionalQ = &content.Question{ID: "s.comments", Kind: content.KindFreeText, Optional: true}
	likertQ   = &content.Question{ID: "s.likert", Kind: content.KindLikert, Scale: 5, Items: []content.Item{
		{ID: "x", Left: "L", Right: "R"}, {ID: "y", Left: "L", Right: "R"},
	}}
)

func TestCheckAnswerAccepts(t *testing.T) {
	t.Run("info", func(t *testing.T) {
		row, fields := checkAnswer(infoQ, Answer{QuestionID: infoQ.ID})
		if fields != nil || row.optionID.Valid || row.value.Valid || row.isCorrect.Valid {
			t.Errorf("got %+v, %v", row, fields)
		}
	})

	t.Run("choice is graded", func(t *testing.T) {
		row, fields := checkAnswer(choiceQ, Answer{QuestionID: choiceQ.ID, OptionID: ptr("b")})
		if fields != nil || row.optionID.String != "b" || !row.isCorrect.Valid || !row.isCorrect.Bool {
			t.Errorf("correct option: got %+v, %v", row, fields)
		}
		row, _ = checkAnswer(choiceQ, Answer{QuestionID: choiceQ.ID, OptionID: ptr("a")})
		if !row.isCorrect.Valid || row.isCorrect.Bool {
			t.Errorf("wrong option: got %+v", row)
		}
	})

	t.Run("free_code is not graded", func(t *testing.T) {
		row, fields := checkAnswer(freeQ, Answer{QuestionID: freeQ.ID, Value: ptr("{ }")})
		if fields != nil || row.value.String != "{ }" || row.isCorrect.Valid {
			t.Errorf("got %+v, %v", row, fields)
		}
	})

	t.Run("optional free_text can be empty or missing", func(t *testing.T) {
		for _, value := range []*string{nil, ptr(""), ptr("  ")} {
			row, fields := checkAnswer(optionalQ, Answer{QuestionID: optionalQ.ID, Value: value})
			if fields != nil || row.value.Valid {
				t.Errorf("value %v: got %+v, %v", value, row, fields)
			}
		}
	})

	t.Run("likert", func(t *testing.T) {
		row, fields := checkAnswer(likertQ, Answer{QuestionID: likertQ.ID, Likert: map[string]int{"x": 1, "y": 5}})
		if fields != nil || len(row.likert) != 2 {
			t.Errorf("got %+v, %v", row, fields)
		}
	})
}

func TestCheckAnswerRejects(t *testing.T) {
	cases := []struct {
		name   string
		q      *content.Question
		answer Answer
		fields map[string]string // field -> part of the reason
	}{
		{"info with option", infoQ, Answer{OptionID: ptr("a")}, map[string]string{"optionId": "not allowed"}},
		{"info with likert", infoQ, Answer{Likert: map[string]int{}}, map[string]string{"likert": "not allowed"}},
		{"choice without option", choiceQ, Answer{}, map[string]string{"optionId": "required"}},
		{"choice with unknown option", choiceQ, Answer{OptionID: ptr("z")}, map[string]string{"optionId": "not an option"}},
		{"choice with value", choiceQ, Answer{OptionID: ptr("a"), Value: ptr("x")}, map[string]string{"value": "not allowed"}},
		{"free_code empty", freeQ, Answer{Value: ptr(" \n")}, map[string]string{"value": "required"}},
		{"free_code missing", freeQ, Answer{}, map[string]string{"value": "required"}},
		{"free_code too long", freeQ, Answer{Value: ptr(strings.Repeat("a", maxValueLength+1))}, map[string]string{"value": "at most"}},
		{"free_code with option", freeQ, Answer{Value: ptr("x"), OptionID: ptr("a")}, map[string]string{"optionId": "not allowed"}},
		{"likert missing", likertQ, Answer{}, map[string]string{"likert": "required"}},
		{"likert missing item", likertQ, Answer{Likert: map[string]int{"x": 3}}, map[string]string{"likert.y": "required"}},
		{"likert out of range", likertQ, Answer{Likert: map[string]int{"x": 0, "y": 6}}, map[string]string{"likert.x": "between 1 and 5", "likert.y": "between 1 and 5"}},
		{"likert unknown item", likertQ, Answer{Likert: map[string]int{"x": 1, "y": 1, "z": 1}}, map[string]string{"likert.z": "not an item"}},
	}

	for _, c := range cases {
		t.Run(c.name, func(t *testing.T) {
			_, fields := checkAnswer(c.q, c.answer)
			if !slices.Equal(slices.Sorted(maps.Keys(fields)), slices.Sorted(maps.Keys(c.fields))) {
				t.Fatalf("fields = %v, want %v", fields, c.fields)
			}
			for field, want := range c.fields {
				if !strings.Contains(fields[field], want) {
					t.Errorf("%s = %q, want it to contain %q", field, fields[field], want)
				}
			}
		})
	}
}
