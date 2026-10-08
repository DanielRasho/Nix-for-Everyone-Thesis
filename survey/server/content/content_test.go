package content

import (
	"encoding/json"
	"strings"
	"testing"
	"testing/fstest"
)

// The real content files must always load.
func TestLoadEmbeddedContent(t *testing.T) {
	c, err := Load()
	if err != nil {
		t.Fatalf("content files are invalid: %v", err)
	}

	if got := c.SurveyIDs(); strings.Join(got, ",") != "nix,nixty" {
		t.Errorf("surveys = %v, want [nix nixty]", got)
	}

	q, ok := c.Question("nix.PA1-1")
	if !ok || q.Survey != "nix" || q.Section != SectionTasks {
		t.Errorf("nix.PA1-1 = %+v, want a nix task", q)
	}

	fb, ok := c.Question("nixty.feedback.experience")
	if !ok || fb.Section != SectionFeedback {
		t.Fatalf("nixty.feedback.experience missing or not feedback: %+v", fb)
	}
	if !strings.Contains(fb.Prompt, "Nixty") || strings.Contains(fb.Prompt, toolPlaceholder) {
		t.Errorf("{tool} not replaced in feedback prompt: %q", fb.Prompt)
	}

	if _, ok := c.Question("background.experience"); !ok {
		t.Error("background.experience missing")
	}

	// The free-answers screen links each survey to its own codespace.
	for _, id := range c.SurveyIDs() {
		s := c.Surveys[id]
		q, ok := c.Question(id + ".free-answers")
		if !ok {
			t.Fatalf("%s.free-answers missing", id)
		}
		if s.Codespace == "" || !strings.Contains(q.Prompt, "("+s.Codespace+")") {
			t.Errorf("%s.free-answers does not link to codespace %q: %q", id, s.Codespace, q.Prompt)
		}
	}
}

func TestCodespacePlaceholder(t *testing.T) {
	const url = "https://codespaces.new/owner/repo?quickstart=1&devcontainer_path=.devcontainer/nix/devcontainer.json"
	fsys := fstest.MapFS{
		backgroundFile: {Data: []byte("questions:\n  - { id: hi, kind: info, prompt: Hola }\n")},
		feedbackFile:   {Data: []byte("questions:\n  - { id: bye, kind: info, prompt: Adiós }\n")},
		"nix.yaml": {Data: []byte("title: Nix\ntool: NixLang\nlanguage: nix\ncodespace: " + url + "\n" +
			"questions:\n  - { id: q1, kind: info, prompt: \"[Abrir Codespace]({codespace})\" }\n")},
	}

	c, err := load(fsys)
	if err != nil {
		t.Fatal(err)
	}
	q, _ := c.Question("nix.q1")
	if want := "[Abrir Codespace](" + url + ")"; q.Prompt != want {
		t.Errorf("prompt = %q, want %q", q.Prompt, want)
	}
}

// Correct answers must never reach the client.
func TestCorrectIsNotSerialized(t *testing.T) {
	c, err := Load()
	if err != nil {
		t.Fatal(err)
	}
	q, _ := c.Question("nix.PA1-1")
	b, _ := json.Marshal(q)
	if strings.Contains(strings.ToLower(string(b)), `"correct":`) {
		t.Errorf("serialized question leaks the answer: %s", b)
	}
}

func TestLoadRejectsInvalidContent(t *testing.T) {
	const background = `
questions:
  - id: experience
    kind: likert
    scale: 5
    prompt: Experiencia
    items:
      - { id: nix, left: Poca, right: Mucha }
`
	const feedback = `
questions:
  - id: comments
    kind: free_text
    prompt: Comentarios sobre {tool}
`
	survey := func(questions string) string {
		return "title: Nix\ntool: NixLang\nlanguage: nix\nquestions:\n" + questions
	}

	tests := []struct {
		name    string
		survey  string
		wantErr string
	}{
		{
			name: "no correct option",
			survey: survey(`
  - id: q1
    kind: choice_text
    prompt: P
    options:
      - { id: a, text: A }
      - { id: b, text: B }
`),
			wantErr: "exactly 1 correct option, found 0",
		},
		{
			name: "two correct options",
			survey: survey(`
  - id: q1
    kind: choice_text
    prompt: P
    options:
      - { id: a, text: A, correct: true }
      - { id: b, text: B, correct: true }
`),
			wantErr: "exactly 1 correct option, found 2",
		},
		{
			name: "code option in a choice_text question",
			survey: survey(`
  - id: q1
    kind: choice_text
    prompt: P
    options:
      - { id: a, code: A, correct: true }
      - { id: b, text: B }
`),
			wantErr: "choice_text options need `text`",
		},
		{
			name: "typo in a field name",
			survey: survey(`
  - id: q1
    kind: choice_text
    prompt: P
    options:
      - { id: a, text: A, corect: true }
      - { id: b, text: B }
`),
			wantErr: "corect",
		},
		{
			name: "duplicated question id",
			survey: survey(`
  - { id: q1, kind: info, prompt: P }
  - { id: q1, kind: info, prompt: P }
`),
			wantErr: "id is used twice",
		},
		{
			name: "dot in question id",
			survey: survey(`
  - { id: q.1, kind: info, prompt: P }
`),
			wantErr: "excludesall",
		},
		{
			name: "likert without scale",
			survey: survey(`
  - id: q1
    kind: likert
    prompt: P
    items:
      - { id: a, left: L, right: R }
`),
			wantErr: "scale must be 5 or 7",
		},
		{
			name: "{codespace} without a codespace",
			survey: survey(`
  - { id: q1, kind: info, prompt: "[Abrir]({codespace})" }
`),
			wantErr: "{codespace} is used but `codespace` is empty",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			fsys := fstest.MapFS{
				backgroundFile: {Data: []byte(background)},
				feedbackFile:   {Data: []byte(feedback)},
				"nix.yaml":     {Data: []byte(tt.survey)},
			}
			_, err := load(fsys)
			if err == nil || !strings.Contains(err.Error(), tt.wantErr) {
				t.Errorf("err = %v, want it to contain %q", err, tt.wantErr)
			}
		})
	}
}
