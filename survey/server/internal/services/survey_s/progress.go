package survey_s

import (
	"time"

	"github.com/DanielRasho/Thesis/content"
	"github.com/DanielRasho/Thesis/internal/storage/survey_db"
)

const (
	// BackgroundStepID is the step of the background questions, always first.
	BackgroundStepID = "background"
	backgroundTitle  = "Preguntas iniciales"
)

type Status string

const (
	StatusLocked     Status = "locked"
	StatusAvailable  Status = "available"
	StatusInProgress Status = "in_progress"
	StatusCompleted  Status = "completed"
)

// Step is one entry of a roadmap. Dates are only filled in admin views.
type Step struct {
	ID          string     `json:"id"`
	Title       string     `json:"title"`
	Position    int        `json:"position,omitempty"` // surveys only: 1, 2...
	Status      Status     `json:"status"`
	Answered    int        `json:"answered"`
	Total       int        `json:"total"`
	StartedAt   *time.Time `json:"startedAt,omitempty"`
	CompletedAt *time.Time `json:"completedAt,omitempty"`
}

// stepDef is a step of a participant's roadmap: the background questions or
// one of their assigned surveys.
type stepDef struct {
	id         string
	title      string
	survey     *content.Survey // nil for background
	questions  []content.Question
	assignment *survey_db.Assignment // nil for background
}

// stepDefs returns the roadmap of a participant: background, then their
// assignments (already sorted by position).
func stepDefs(c *content.Content, assignments []survey_db.Assignment) []stepDef {
	defs := []stepDef{{id: BackgroundStepID, title: backgroundTitle, questions: c.Background}}
	for i := range assignments {
		a := &assignments[i]
		survey, ok := c.Surveys[a.Survey]
		if !ok {
			continue // the survey was removed from the content
		}
		defs = append(defs, stepDef{
			id:         survey.ID,
			title:      survey.Title,
			survey:     survey,
			questions:  survey.Questions,
			assignment: a,
		})
	}
	return defs
}

// statuses computes the status of every step from how many of its questions
// are answered. Background is never locked, survey N is locked until
// background and survey N-1 are completed.
func statuses(defs []stepDef, answered []int) []Status {
	out := make([]Status, len(defs))
	for i, def := range defs {
		started := answered[i] > 0 || (def.assignment != nil && def.assignment.StartedAt.Valid)
		switch {
		case answered[i] >= len(def.questions):
			out[i] = StatusCompleted
		case i > 0 && (out[0] != StatusCompleted || out[i-1] != StatusCompleted):
			out[i] = StatusLocked
		case started:
			out[i] = StatusInProgress
		default:
			out[i] = StatusAvailable
		}
	}
	return out
}

// buildSteps turns step definitions into the roadmap answered by the API.
func buildSteps(defs []stepDef, answered []int, withDates bool) []Step {
	status := statuses(defs, answered)
	steps := make([]Step, len(defs))
	for i, def := range defs {
		steps[i] = Step{
			ID:       def.id,
			Title:    def.title,
			Status:   status[i],
			Answered: min(answered[i], len(def.questions)),
			Total:    len(def.questions),
		}
		if def.assignment != nil {
			steps[i].Position = int(def.assignment.Position)
			if withDates {
				if def.assignment.StartedAt.Valid {
					steps[i].StartedAt = &def.assignment.StartedAt.Time
				}
				if def.assignment.CompletedAt.Valid {
					steps[i].CompletedAt = &def.assignment.CompletedAt.Time
				}
			}
		}
	}
	return steps
}

// progress is everything known about one participant: their steps and the ids
// of the questions they answered.
type progress struct {
	defs     []stepDef
	answered map[string]bool
}

// counts returns how many questions of each step are answered.
func (p *progress) counts() []int {
	counts := make([]int, len(p.defs))
	for i, def := range p.defs {
		for _, q := range def.questions {
			if p.answered[q.ID] {
				counts[i]++
			}
		}
	}
	return counts
}

// step finds a step of the roadmap by id.
func (p *progress) step(id string) (int, bool) {
	for i, def := range p.defs {
		if def.id == id {
			return i, true
		}
	}
	return 0, false
}

// current returns the first unanswered question of a step, in content order,
// or nil when the step is finished.
func (p *progress) current(i int) *content.Question {
	questions := p.defs[i].questions
	for j := range questions {
		if !p.answered[questions[j].ID] {
			return &questions[j]
		}
	}
	return nil
}
