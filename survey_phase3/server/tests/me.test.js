import { beforeAll, describe, expect, test } from "vitest";
import {
  advanceTo,
  api,
  as,
  completeStep,
  createParticipant,
  getCurrent,
  isChoice,
  loginAdmin,
  validAnswer,
} from "./helpers.js";

let admin; // admin session cookie
beforeAll(async () => {
  admin = await loginAdmin();
});

describe("GET /me/roadmap", () => {
  test("answers 200 with background first, then the surveys in the assigned order", async () => {
    const participant = await createParticipant(admin, { surveyOrder: ["nixty", "nix"] });

    const res = await api.get("/me/roadmap", as(participant.cookie));

    expect(res.status).toBe(200);
    expect(res.data).toEqual({
      steps: [
        { id: "background", title: "Preguntas iniciales", status: "available", answered: 0, total: expect.any(Number) },
        { id: "nixty", title: expect.any(String), position: 1, status: "locked", answered: 0, total: expect.any(Number) },
        { id: "nix", title: expect.any(String), position: 2, status: "locked", answered: 0, total: expect.any(Number) },
      ],
    });
  });

  test("answers 200 with the first survey available once background is completed", async () => {
    const participant = await createParticipant(admin);
    await completeStep(participant.cookie, "background");

    const { data } = await api.get("/me/roadmap", as(participant.cookie));

    expect(data.steps.map((s) => s.status)).toEqual(["completed", "available", "locked"]);
    expect(data.steps[0].answered).toBe(data.steps[0].total);
  });

  test("answers 200 with in_progress once a survey is opened", async () => {
    const participant = await createParticipant(admin);
    const [first] = participant.surveyOrder;
    await completeStep(participant.cookie, "background");
    await getCurrent(participant.cookie, first); // opening it marks it started

    const { data } = await api.get("/me/roadmap", as(participant.cookie));

    expect(data.steps.map((s) => s.status)).toEqual(["completed", "in_progress", "locked"]);
  });

  test("answers 200 with the second survey available once the first is completed", async () => {
    const participant = await createParticipant(admin);
    const [first] = participant.surveyOrder;
    await completeStep(participant.cookie, "background");
    await completeStep(participant.cookie, first);

    const { data } = await api.get("/me/roadmap", as(participant.cookie));

    expect(data.steps.map((s) => s.status)).toEqual(["completed", "completed", "available"]);
    expect(data.steps[1].answered).toBe(data.steps[1].total);
    // Dates are only in admin views.
    expect(data.steps[1].startedAt).toBeUndefined();
    expect(data.steps[1].completedAt).toBeUndefined();
  });

  test("fails with 401 without a session", async () => {
    const res = await api.get("/me/roadmap");

    expect(res.status).toBe(401);
    expect(res.data).toEqual({ message: expect.any(String) });
  });

  test("fails with 403 when called by an admin", async () => {
    const res = await api.get("/me/roadmap", as(admin));

    expect(res.status).toBe(403);
    expect(res.data).toEqual({ message: expect.any(String) });
  });
});

describe("GET /me/steps/{stepId}/current", () => {
  test("answers 200 with the first unanswered question of the step", async () => {
    const participant = await createParticipant(admin);

    const res = await api.get("/me/steps/background/current", as(participant.cookie));

    expect(res.status).toBe(200);
    expect(res.data).toEqual({
      step: { id: "background", title: "Preguntas iniciales" },
      progress: { answered: 0, total: expect.any(Number) },
      question: expect.objectContaining({
        id: expect.stringMatching(/^background\./),
        kind: expect.any(String),
        section: "background",
        prompt: expect.any(String),
      }),
    });
  });

  test("answers 200 with the survey's tool and language, and marks the survey as started", async () => {
    const participant = await createParticipant(admin, { surveyOrder: ["nix", "nixty"] });
    await completeStep(participant.cookie, "background");

    const res = await api.get("/me/steps/nix/current", as(participant.cookie));

    expect(res.status).toBe(200);
    expect(res.data.step).toMatchObject({
      id: "nix",
      title: expect.any(String),
      tool: expect.any(String), // what {tool} was replaced with in the prompts
      language: expect.stringMatching(/^(nix|typescript)$/), // for code highlighting
      // codespace?: string, the GitHub Codespaces URL when the survey has one
    });
    expect(res.data.progress.answered).toBe(0);
    expect(res.data.question).toMatchObject({ id: expect.stringMatching(/^nix\./), section: "tasks" });

    const participants = await api.get("/admin/participants", as(admin));
    const { steps } = participants.data.participants.find((p) => p.id === participant.id);
    expect(steps[1]).toMatchObject({ id: "nix", status: "in_progress", startedAt: expect.any(String) });
  });

  test("answers 200 without the correct option of choice questions", async () => {
    const participant = await createParticipant(admin);
    const [first] = participant.surveyOrder;
    await completeStep(participant.cookie, "background");

    const current = await advanceTo(participant.cookie, first, isChoice);

    expect(current.question.options.length).toBeGreaterThan(1);
    for (const option of current.question.options) {
      expect(option).toHaveProperty("id");
      expect(option).not.toHaveProperty("correct");
    }
  });

  test("answers 200 with question null when the step is completed", async () => {
    const participant = await createParticipant(admin);
    await completeStep(participant.cookie, "background");

    const res = await api.get("/me/steps/background/current", as(participant.cookie));

    expect(res.status).toBe(200);
    expect(res.data.question).toBeNull();
    expect(res.data.progress.answered).toBe(res.data.progress.total);
  });

  test("fails with 401 without a session", async () => {
    const res = await api.get("/me/steps/background/current");

    expect(res.status).toBe(401);
  });

  test("fails with 403 when called by an admin", async () => {
    const res = await api.get("/me/steps/background/current", as(admin));

    expect(res.status).toBe(403);
  });

  test("fails with 403 when the first survey is locked (background not completed)", async () => {
    const participant = await createParticipant(admin);
    const [first] = participant.surveyOrder;

    const res = await api.get(`/me/steps/${first}/current`, as(participant.cookie));

    expect(res.status).toBe(403);
    expect(res.data).toEqual({ message: expect.stringContaining("locked") });
  });

  test("fails with 403 when the second survey is locked (first survey not completed)", async () => {
    const participant = await createParticipant(admin);
    const [, second] = participant.surveyOrder;
    await completeStep(participant.cookie, "background");

    const res = await api.get(`/me/steps/${second}/current`, as(participant.cookie));

    expect(res.status).toBe(403);
  });

  test("fails with 404 when the step does not exist", async () => {
    const participant = await createParticipant(admin);

    const res = await api.get("/me/steps/not-a-survey/current", as(participant.cookie));

    expect(res.status).toBe(404);
    expect(res.data).toEqual({ message: expect.any(String) });
  });
});

describe("POST /me/answers", () => {
  // Shared by the error cases: a participant on their first survey, moved
  // forward by the tests as they need other question kinds.
  let participant;
  let first;
  beforeAll(async () => {
    participant = await createParticipant(admin);
    [first] = participant.surveyOrder;
    await completeStep(participant.cookie, "background");
  });

  test("answers 200 with the next question of the same step", async () => {
    const p = await createParticipant(admin);
    const [survey] = p.surveyOrder;
    await completeStep(p.cookie, "background");
    const before = await getCurrent(p.cookie, survey);

    const res = await api.post("/me/answers", validAnswer(before.question), as(p.cookie));

    expect(res.status).toBe(200);
    expect(res.data).toEqual({
      step: expect.objectContaining({ id: survey }),
      progress: { answered: 1, total: before.progress.total },
      question: expect.objectContaining({ id: expect.any(String), kind: expect.any(String) }),
    });
    expect(res.data.question.id).not.toBe(before.question.id);
  });

  test("answers 200 when answering a likert question with every item", async () => {
    const p = await createParticipant(admin);
    const { question } = await advanceTo(p.cookie, "background", (q) => q.kind === "likert");
    const likert = Object.fromEntries(question.items.map((item) => [item.id, question.scale]));

    const res = await api.post("/me/answers", { questionId: question.id, likert }, as(p.cookie));

    expect(res.status).toBe(200);
    expect(res.data.progress.answered).toBe(1);
  });

  test("answers 200 when answering a choice question with one of its options", async () => {
    const p = await createParticipant(admin);
    const [survey] = p.surveyOrder;
    await completeStep(p.cookie, "background");
    const { question } = await advanceTo(p.cookie, survey, isChoice);

    const res = await api.post("/me/answers", { questionId: question.id, optionId: question.options[1].id }, as(p.cookie));

    expect(res.status).toBe(200);
  });

  test("answers 200 when answering a free_code question", async () => {
    const p = await createParticipant(admin);
    const [survey] = p.surveyOrder;
    await completeStep(p.cookie, "background");
    const { question } = await advanceTo(p.cookie, survey, (q) => q.kind === "free_code");

    const res = await api.post(
      "/me/answers",
      { questionId: question.id, value: "{ outputs = { ... }: { }; }" },
      as(p.cookie),
    );

    expect(res.status).toBe(200);
  });

  test("answers 200 when an optional question is left empty", async () => {
    const p = await createParticipant(admin);
    const [survey] = p.surveyOrder;
    await completeStep(p.cookie, "background");
    const { question } = await advanceTo(p.cookie, survey, (q) => q.optional === true);

    const res = await api.post("/me/answers", { questionId: question.id, value: "" }, as(p.cookie));

    expect(res.status).toBe(200);
  });

  test("answers 200 when an optional question is skipped (nothing is stored but it counts as answered)", async () => {
    const p = await createParticipant(admin);
    const [survey] = p.surveyOrder;
    await completeStep(p.cookie, "background");
    const before = await advanceTo(p.cookie, survey, (q) => q.optional === true);

    const res = await api.post("/me/answers", { questionId: before.question.id, skipped: true }, as(p.cookie));

    expect(res.status).toBe(200);
    expect(res.data.progress.answered).toBe(before.progress.answered + 1);
  });

  test("answers 200 with question null and completes the survey after its last question", async () => {
    const p = await createParticipant(admin);
    const [survey] = p.surveyOrder;
    await completeStep(p.cookie, "background");
    const last = await advanceTo(p.cookie, survey, (q, c) => c.progress.answered === c.progress.total - 1);

    const res = await api.post("/me/answers", validAnswer(last.question), as(p.cookie));

    expect(res.status).toBe(200);
    expect(res.data.question).toBeNull();
    expect(res.data.progress).toEqual({ answered: last.progress.total, total: last.progress.total });

    const participants = await api.get("/admin/participants", as(admin));
    const { steps } = participants.data.participants.find((x) => x.id === p.id);
    expect(steps[1]).toMatchObject({ id: survey, status: "completed", completedAt: expect.any(String) });
  });

  test("fails with 400 when questionId is not provided", async () => {
    const res = await api.post("/me/answers", {}, as(participant.cookie));

    expect(res.status).toBe(400);
    expect(res.data).toEqual({ message: expect.any(String), errors: { questionId: "is required" } });
  });

  test("fails with 400 when a field does not belong to the question kind", async () => {
    const { question } = await advanceTo(participant.cookie, first, (q) => q.kind === "info");

    const res = await api.post("/me/answers", { questionId: question.id, value: "hello" }, as(participant.cookie));

    expect(res.status).toBe(400);
    expect(res.data.errors).toEqual({ value: "is not allowed for info questions" });
  });

  test("fails with 400 when a choice answer has no optionId", async () => {
    const { question } = await advanceTo(participant.cookie, first, isChoice);

    const res = await api.post("/me/answers", { questionId: question.id }, as(participant.cookie));

    expect(res.status).toBe(400);
    expect(res.data.errors).toEqual({ optionId: "is required" });
  });

  test("fails with 400 when optionId is not an option of the question", async () => {
    const { question } = await advanceTo(participant.cookie, first, isChoice);

    const res = await api.post(
      "/me/answers",
      { questionId: question.id, optionId: "not-an-option" },
      as(participant.cookie),
    );

    expect(res.status).toBe(400);
    expect(res.data.errors).toEqual({ optionId: "is not an option of this question" });
  });

  test("fails with 400 when a free_code answer is empty", async () => {
    const { question } = await advanceTo(participant.cookie, first, (q) => q.kind === "free_code");

    const res = await api.post("/me/answers", { questionId: question.id, value: "  " }, as(participant.cookie));

    expect(res.status).toBe(400);
    expect(res.data.errors).toEqual({ value: "is required" });
  });

  test("fails with 400 when skipping a question that is not optional", async () => {
    const { question } = await getCurrent(participant.cookie, first);
    expect(question.optional).toBeUndefined();

    const res = await api.post("/me/answers", { questionId: question.id, skipped: true }, as(participant.cookie));

    expect(res.status).toBe(400);
    expect(res.data.errors).toEqual({ skipped: "is only allowed for optional questions" });
  });

  test("fails with 400 when a skipped answer also has a value", async () => {
    const p = await createParticipant(admin);
    const [survey] = p.surveyOrder;
    await completeStep(p.cookie, "background");
    const { question } = await advanceTo(p.cookie, survey, (q) => q.optional === true);

    const res = await api.post("/me/answers", { questionId: question.id, skipped: true, value: "x" }, as(p.cookie));

    expect(res.status).toBe(400);
    expect(res.data.errors).toEqual({ value: "is not allowed when skipped" });
  });

  test("fails with 400 when a likert item is missing", async () => {
    const { question } = await advanceTo(
      participant.cookie,
      first,
      (q) => q.kind === "likert" && q.items.length > 1,
    );
    const [missing, ...rest] = question.items;

    const res = await api.post(
      "/me/answers",
      { questionId: question.id, likert: Object.fromEntries(rest.map((item) => [item.id, 1])) },
      as(participant.cookie),
    );

    expect(res.status).toBe(400);
    expect(res.data.errors).toEqual({ [`likert.${missing.id}`]: "is required" });
  });

  test("fails with 400 when a likert value is out of the scale", async () => {
    const { question } = await advanceTo(participant.cookie, first, (q) => q.kind === "likert");
    const likert = Object.fromEntries(question.items.map((item) => [item.id, 1]));
    likert[question.items[0].id] = question.scale + 1;

    const res = await api.post("/me/answers", { questionId: question.id, likert }, as(participant.cookie));

    expect(res.status).toBe(400);
    expect(res.data.errors).toEqual({
      [`likert.${question.items[0].id}`]: `must be between 1 and ${question.scale}`,
    });
  });

  test("fails with 400 when a likert item does not exist", async () => {
    const { question } = await advanceTo(participant.cookie, first, (q) => q.kind === "likert");
    const likert = Object.fromEntries(question.items.map((item) => [item.id, 1]));
    likert["not-an-item"] = 1;

    const res = await api.post("/me/answers", { questionId: question.id, likert }, as(participant.cookie));

    expect(res.status).toBe(400);
    expect(res.data.errors).toEqual({ "likert.not-an-item": "is not an item of this question" });
  });

  test("fails with 401 without a session", async () => {
    const res = await api.post("/me/answers", { questionId: "background.experience" });

    expect(res.status).toBe(401);
  });

  test("fails with 403 when called by an admin", async () => {
    const res = await api.post("/me/answers", { questionId: "background.experience" }, as(admin));

    expect(res.status).toBe(403);
  });

  test("fails with 403 when the step is locked", async () => {
    const p = await createParticipant(admin);
    const [survey] = p.surveyOrder;

    // Background is not completed yet: the first question of the survey is locked.
    const res = await api.post("/me/answers", { questionId: `${survey}.instructions` }, as(p.cookie));

    expect(res.status).toBe(403);
    expect(res.data).toEqual({ message: expect.stringContaining("locked") });
  });

  test("fails with 404 when the question does not exist", async () => {
    const res = await api.post("/me/answers", { questionId: "nix.not-a-question" }, as(participant.cookie));

    expect(res.status).toBe(404);
    expect(res.data).toEqual({ message: expect.any(String) });
  });

  test("fails with 409 when the question is not the current one", async () => {
    const current = await getCurrent(participant.cookie, first);
    const later = `${first}.feedback.comments`; // the last question of every survey
    expect(current.question.id).not.toBe(later);

    const res = await api.post("/me/answers", { questionId: later, value: "too early" }, as(participant.cookie));

    expect(res.status).toBe(409);
    expect(res.data).toEqual({ message: "The question is not the current one" });
  });

  test("fails with 409 when the question is already answered", async () => {
    const { question } = await getCurrent(participant.cookie, first);
    await api.post("/me/answers", validAnswer(question), as(participant.cookie));

    const res = await api.post("/me/answers", validAnswer(question), as(participant.cookie));

    expect(res.status).toBe(409);
  });
});

describe("POST /me/heartbeat", () => {
  test("answers 204 when the question is the current one", async () => {
    const participant = await createParticipant(admin);
    const { question } = await getCurrent(participant.cookie, "background");

    const res = await api.post("/me/heartbeat", { questionId: question.id }, as(participant.cookie));

    expect(res.status).toBe(204);
    expect(res.data).toBe("");
  });

  test("fails with 400 when questionId is not provided", async () => {
    const participant = await createParticipant(admin);

    const res = await api.post("/me/heartbeat", {}, as(participant.cookie));

    expect(res.status).toBe(400);
    expect(res.data).toEqual({ message: expect.any(String), errors: { questionId: "is required" } });
  });

  test("fails with 401 without a session", async () => {
    const res = await api.post("/me/heartbeat", { questionId: "background.experience" });

    expect(res.status).toBe(401);
  });

  test("fails with 403 when called by an admin", async () => {
    const res = await api.post("/me/heartbeat", { questionId: "background.experience" }, as(admin));

    expect(res.status).toBe(403);
  });

  test("fails with 403 when the step is locked", async () => {
    const participant = await createParticipant(admin);
    const [first] = participant.surveyOrder;

    const res = await api.post("/me/heartbeat", { questionId: `${first}.instructions` }, as(participant.cookie));

    expect(res.status).toBe(403);
  });

  test("fails with 404 when the question does not exist", async () => {
    const participant = await createParticipant(admin);

    const res = await api.post("/me/heartbeat", { questionId: "nix.not-a-question" }, as(participant.cookie));

    expect(res.status).toBe(404);
  });

  test("fails with 409 when the question is not the current one", async () => {
    const participant = await createParticipant(admin);
    const { question } = await getCurrent(participant.cookie, "background");
    await api.post("/me/answers", validAnswer(question), as(participant.cookie));

    // Already answered: no longer the current question.
    const res = await api.post("/me/heartbeat", { questionId: question.id }, as(participant.cookie));

    expect(res.status).toBe(409);
    expect(res.data).toEqual({ message: expect.any(String) });
  });
});
