// Package content loads the survey questions defined in the YAML files of this
// folder. They are embedded in the binary and validated at startup, so a
// broken file stops the server instead of reaching a participant.
//
//   - background.yaml: asked once per participant, before any survey.
//   - feedback.yaml:   appended to the end of every survey.
//   - any other file:  a survey, its file name is its id (nix.yaml -> "nix").
//
// Every "{tool}" in a survey file and in feedback.yaml is replaced by the
// survey's `tool` field. Every "{codespace}" in a survey file (not in
// feedback.yaml) is replaced by the survey's `codespace` field; using it while
// `codespace` is empty is an error.
package content

import (
	"bytes"
	"embed"
	"fmt"
	"io/fs"
	"path"
	"sort"
	"strings"

	"github.com/go-playground/validator/v10"
	"github.com/goccy/go-yaml"
)

//go:embed *.yaml
var files embed.FS

const (
	backgroundFile       = "background.yaml"
	feedbackFile         = "feedback.yaml"
	toolPlaceholder      = "{tool}"
	codespacePlaceholder = "{codespace}"
)

type Kind string

const (
	KindInfo       Kind = "info"        // text only, acknowledged with "Continuar"
	KindChoiceCode Kind = "choice_code" // options are code: prompt + options left, selected one right
	KindChoiceText Kind = "choice_text" // code left, text options right
	KindFreeCode   Kind = "free_code"   // code written in Codespaces and pasted back
	KindFreeText   Kind = "free_text"
	KindLikert     Kind = "likert"
)

type Section string

const (
	SectionBackground Section = "background"
	SectionTasks      Section = "tasks"
	SectionFeedback   Section = "feedback"
)

type Option struct {
	ID      string `yaml:"id" json:"id" validate:"required"`
	Text    string `yaml:"text" json:"text,omitempty"`
	Code    string `yaml:"code" json:"code,omitempty"`
	Correct bool   `yaml:"correct" json:"-"` // never sent to the client
}

// Item is one row of a likert question.
type Item struct {
	ID    string `yaml:"id" json:"id" validate:"required"`
	Label string `yaml:"label" json:"label,omitempty"`
	Left  string `yaml:"left" json:"left" validate:"required"`
	Right string `yaml:"right" json:"right" validate:"required"`
}

type Question struct {
	// Full id once loaded: "<survey>.<id>", "<survey>.feedback.<id>" or "background.<id>".
	ID       string   `yaml:"id" json:"id" validate:"required,excludesall=."`
	Kind     Kind     `yaml:"kind" json:"kind" validate:"required,oneof=info choice_code choice_text free_code free_text likert"`
	Prompt   string   `yaml:"prompt" json:"prompt" validate:"required"` // markdown
	Code     string   `yaml:"code" json:"code,omitempty"`               // reference snippet, or starter code for free_code
	Options  []Option `yaml:"options" json:"options,omitempty" validate:"dive"`
	Scale    int      `yaml:"scale" json:"scale,omitempty"`
	Items    []Item   `yaml:"items" json:"items,omitempty" validate:"dive"`
	Optional bool     `yaml:"optional" json:"optional,omitempty"`

	// Set by the loader.
	Survey  string  `yaml:"-" json:"-"`
	Section Section `yaml:"-" json:"section"`
}

type Survey struct {
	ID        string     `yaml:"-" json:"id"`
	Title     string     `yaml:"title" json:"title" validate:"required"`
	Tool      string     `yaml:"tool" json:"tool" validate:"required"`
	Language  string     `yaml:"language" json:"language" validate:"required,oneof=nix typescript"`
	Codespace string     `yaml:"codespace" json:"codespace,omitempty" validate:"omitempty,url"`
	Questions []Question `yaml:"questions" json:"questions" validate:"min=1,dive"`
}

type questionFile struct {
	Questions []Question `yaml:"questions" validate:"min=1,dive"`
}

type Content struct {
	Background []Question
	Surveys    map[string]*Survey
	byID       map[string]*Question
}

// Question finds a question by its full id.
func (c *Content) Question(id string) (*Question, bool) {
	q, ok := c.byID[id]
	return q, ok
}

// SurveyIDs returns the ids of all surveys, sorted.
func (c *Content) SurveyIDs() []string {
	ids := make([]string, 0, len(c.Surveys))
	for id := range c.Surveys {
		ids = append(ids, id)
	}
	sort.Strings(ids)
	return ids
}

// Load parses and validates the embedded content files.
func Load() (*Content, error) {
	return load(files)
}

func load(fsys fs.FS) (*Content, error) {
	validate := validator.New(validator.WithRequiredStructEnabled())
	c := &Content{Surveys: map[string]*Survey{}, byID: map[string]*Question{}}

	// Background
	var background questionFile
	if err := decode(fsys, backgroundFile, nil, &background, validate); err != nil {
		return nil, err
	}
	c.Background = background.Questions
	if err := prepare(c.Background, "background", "background.", SectionBackground); err != nil {
		return nil, fmt.Errorf("%s: %w", backgroundFile, err)
	}

	// Surveys
	entries, err := fs.ReadDir(fsys, ".")
	if err != nil {
		return nil, err
	}
	for _, entry := range entries {
		name := entry.Name()
		if name == backgroundFile || name == feedbackFile || path.Ext(name) != ".yaml" {
			continue
		}

		survey, err := loadSurvey(fsys, name, validate)
		if err != nil {
			return nil, err
		}
		c.Surveys[survey.ID] = survey
	}
	if len(c.Surveys) == 0 {
		return nil, fmt.Errorf("no survey files found")
	}

	// Index every question by its full id.
	all := [][]Question{c.Background}
	for _, s := range c.Surveys {
		all = append(all, s.Questions)
	}
	for _, questions := range all {
		for i := range questions {
			q := &questions[i]
			if _, dup := c.byID[q.ID]; dup {
				return nil, fmt.Errorf("question id %q is used twice", q.ID)
			}
			c.byID[q.ID] = q
		}
	}

	return c, nil
}

func loadSurvey(fsys fs.FS, name string, validate *validator.Validate) (*Survey, error) {
	survey := &Survey{ID: strings.TrimSuffix(name, ".yaml")}

	// First pass reads `tool` and `codespace`, so they can be substituted before the real parse.
	var header struct {
		Tool      string `yaml:"tool"`
		Codespace string `yaml:"codespace"`
	}
	raw, err := fs.ReadFile(fsys, name)
	if err != nil {
		return nil, err
	}
	if err := yaml.Unmarshal(raw, &header); err != nil {
		return nil, fmt.Errorf("%s: %w", name, err)
	}
	// Checked on the raw file, so a "{codespace}" in a comment counts too.
	if header.Codespace == "" && bytes.Contains(raw, []byte(codespacePlaceholder)) {
		return nil, fmt.Errorf("%s: %s is used but `codespace` is empty", name, codespacePlaceholder)
	}
	replaceTool := func(b []byte) []byte {
		return bytes.ReplaceAll(b, []byte(toolPlaceholder), []byte(header.Tool))
	}
	replaceSurvey := func(b []byte) []byte {
		return bytes.ReplaceAll(replaceTool(b), []byte(codespacePlaceholder), []byte(header.Codespace))
	}

	if err := decode(fsys, name, replaceSurvey, survey, validate); err != nil {
		return nil, err
	}
	if err := prepare(survey.Questions, survey.ID, survey.ID+".", SectionTasks); err != nil {
		return nil, fmt.Errorf("%s: %w", name, err)
	}

	var feedback questionFile
	if err := decode(fsys, feedbackFile, replaceTool, &feedback, validate); err != nil {
		return nil, err
	}
	if err := prepare(feedback.Questions, survey.ID, survey.ID+".feedback.", SectionFeedback); err != nil {
		return nil, fmt.Errorf("%s (for %s): %w", feedbackFile, name, err)
	}
	survey.Questions = append(survey.Questions, feedback.Questions...)

	return survey, nil
}

// decode reads a YAML file strictly (unknown fields are errors, so typos like
// `corect: true` are caught) and validates its struct tags.
func decode(fsys fs.FS, name string, transform func([]byte) []byte, target any, validate *validator.Validate) error {
	raw, err := fs.ReadFile(fsys, name)
	if err != nil {
		return err
	}
	if transform != nil {
		raw = transform(raw)
	}
	if err := yaml.UnmarshalWithOptions(raw, target, yaml.Strict()); err != nil {
		return fmt.Errorf("%s: %w", name, err)
	}
	if err := validate.Struct(target); err != nil {
		return fmt.Errorf("%s: %w", name, err)
	}
	return nil
}

// prepare checks the rules that depend on the question kind, then prefixes the
// ids and fills in the loader-set fields.
func prepare(questions []Question, survey, idPrefix string, section Section) error {
	seen := map[string]bool{}
	for i := range questions {
		q := &questions[i]
		if seen[q.ID] {
			return fmt.Errorf("question %s: id is used twice", q.ID)
		}
		seen[q.ID] = true

		if err := checkKind(q); err != nil {
			return fmt.Errorf("question %s: %w", q.ID, err)
		}

		q.ID = idPrefix + q.ID
		q.Survey = survey
		q.Section = section
	}
	return nil
}

func checkKind(q *Question) error {
	isChoice := q.Kind == KindChoiceCode || q.Kind == KindChoiceText

	if !isChoice && len(q.Options) > 0 {
		return fmt.Errorf("only choice questions can have options")
	}
	if q.Kind != KindLikert && (len(q.Items) > 0 || q.Scale != 0) {
		return fmt.Errorf("only likert questions can have items or scale")
	}
	if q.Kind == KindInfo && q.Optional {
		return fmt.Errorf("info screens cannot be optional")
	}

	switch {
	case isChoice:
		if len(q.Options) < 2 {
			return fmt.Errorf("needs at least 2 options")
		}
		ids := map[string]bool{}
		correct := 0
		for _, o := range q.Options {
			if ids[o.ID] {
				return fmt.Errorf("option %s: id is used twice", o.ID)
			}
			ids[o.ID] = true
			if o.Correct {
				correct++
			}
			if q.Kind == KindChoiceCode && (o.Code == "" || o.Text != "") {
				return fmt.Errorf("option %s: choice_code options need `code` and no `text`", o.ID)
			}
			if q.Kind == KindChoiceText && (o.Text == "" || o.Code != "") {
				return fmt.Errorf("option %s: choice_text options need `text` and no `code`", o.ID)
			}
		}
		if correct != 1 {
			return fmt.Errorf("needs exactly 1 correct option, found %d", correct)
		}

	case q.Kind == KindLikert:
		if q.Scale != 5 && q.Scale != 7 {
			return fmt.Errorf("likert scale must be 5 or 7, got %d", q.Scale)
		}
		if len(q.Items) == 0 {
			return fmt.Errorf("likert needs at least 1 item")
		}
		ids := map[string]bool{}
		for _, item := range q.Items {
			if ids[item.ID] {
				return fmt.Errorf("item %s: id is used twice", item.ID)
			}
			ids[item.ID] = true
		}
	}
	return nil
}
