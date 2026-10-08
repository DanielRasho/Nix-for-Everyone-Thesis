package survey_s

import (
	"slices"
	"testing"
	"time"

	"github.com/DanielRasho/Thesis/content"
	"github.com/DanielRasho/Thesis/internal/storage/survey_db"
	"github.com/jackc/pgx/v5/pgtype"
)

// Background (1 question) and two surveys (2 questions each).
func testDefs(firstStarted bool) []stepDef {
	two := []content.Question{{ID: "q1"}, {ID: "q2"}}
	first := &survey_db.Assignment{Survey: "nixty", Position: 1}
	if firstStarted {
		first.StartedAt = pgtype.Timestamptz{Time: time.Now(), Valid: true}
	}
	return []stepDef{
		{id: BackgroundStepID, questions: []content.Question{{ID: "b1"}}},
		{id: "nixty", questions: two, assignment: first},
		{id: "nix", questions: two, assignment: &survey_db.Assignment{Survey: "nix", Position: 2}},
	}
}

func TestStatuses(t *testing.T) {
	cases := []struct {
		name     string
		started  bool
		answered []int
		want     []Status
	}{
		{"fresh participant", false, []int{0, 0, 0}, []Status{StatusAvailable, StatusLocked, StatusLocked}},
		{"background done", false, []int{1, 0, 0}, []Status{StatusCompleted, StatusAvailable, StatusLocked}},
		{"first survey opened", true, []int{1, 0, 0}, []Status{StatusCompleted, StatusInProgress, StatusLocked}},
		{"first survey half done", true, []int{1, 1, 0}, []Status{StatusCompleted, StatusInProgress, StatusLocked}},
		{"first survey done", true, []int{1, 2, 0}, []Status{StatusCompleted, StatusCompleted, StatusAvailable}},
		{"all done", true, []int{1, 2, 2}, []Status{StatusCompleted, StatusCompleted, StatusCompleted}},
	}
	for _, c := range cases {
		t.Run(c.name, func(t *testing.T) {
			if got := statuses(testDefs(c.started), c.answered); !slices.Equal(got, c.want) {
				t.Errorf("statuses = %v, want %v", got, c.want)
			}
		})
	}
}

func TestBuildStepsDatesOnlyForAdmin(t *testing.T) {
	defs := testDefs(true)
	answered := []int{1, 1, 0}

	participant := buildSteps(defs, answered, false)
	if participant[1].StartedAt != nil || participant[1].Position != 1 {
		t.Errorf("participant step = %+v, want position and no dates", participant[1])
	}
	admin := buildSteps(defs, answered, true)
	if admin[1].StartedAt == nil || admin[0].Position != 0 {
		t.Errorf("admin steps = %+v, want startedAt on the survey and no position on background", admin)
	}
}

func TestCurrentIsFirstUnanswered(t *testing.T) {
	p := &progress{defs: testDefs(true), answered: map[string]bool{"b1": true, "q1": true}}

	if q := p.current(0); q != nil {
		t.Errorf("background current = %v, want nil (finished)", q.ID)
	}
	if q := p.current(1); q == nil || q.ID != "q2" {
		t.Errorf("survey current = %v, want q2", q)
	}
}
