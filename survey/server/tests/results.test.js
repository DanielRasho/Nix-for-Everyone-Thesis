import { beforeAll, describe, expect, test } from "vitest";
import {
  UNKNOWN_ID,
  advanceTo,
  api,
  as,
  completeStep,
  createParticipant,
  getCurrent,
  isChoice,
  loginAdmin,
  parseCSVObjects,
  sleep,
  validAnswer,
} from "./helpers.js";

let admin; // admin session cookie
// A participant with a choice and a free_code answer in their first survey.
let participant;
let choiceQuestion;
let freeCodeQuestion;
beforeAll(async () => {
  admin = await loginAdmin();
  participant = await createParticipant(admin);
  const [first] = participant.surveyOrder;
  await completeStep(participant.cookie, "background");

  ({ question: choiceQuestion } = await advanceTo(participant.cookie, first, isChoice));
  await api.post("/me/answers", validAnswer(choiceQuestion), as(participant.cookie));

  ({ question: freeCodeQuestion } = await advanceTo(participant.cookie, first, (q) => q.kind === "free_code"));
  await api.post(
    "/me/answers",
    { questionId: freeCodeQuestion.id, value: "{ answer = 42; }" },
    as(participant.cookie),
  );
});

describe("GET /admin/grading", () => {
  test("answers 200 with every free_code answer", async () => {
    const res = await api.get("/admin/grading", as(admin));

    expect(res.status).toBe(200);
    const mine = res.data.answers.filter((a) => a.userId === participant.id);
    expect(mine).toEqual([
      {
        userId: participant.id,
        username: participant.username,
        questionId: freeCodeQuestion.id,
        prompt: freeCodeQuestion.prompt,
        value: "{ answer = 42; }",
        isCorrect: null, // not graded yet
        answeredAt: expect.any(String),
      },
    ]);
  });

  test("fails with 401 without a session", async () => {
    const res = await api.get("/admin/grading");

    expect(res.status).toBe(401);
  });

  test("fails with 403 when called by a participant", async () => {
    const res = await api.get("/admin/grading", as(participant.cookie));

    expect(res.status).toBe(403);
  });
});

describe("PUT /admin/grading", () => {
  const graded = async () => {
    const { data } = await api.get("/admin/grading", as(admin));
    return data.answers.find((a) => a.userId === participant.id && a.questionId === freeCodeQuestion.id);
  };

  test("answers 204 and stores the grade of a free_code answer", async () => {
    const res = await api.put(
      "/admin/grading",
      { userId: participant.id, questionId: freeCodeQuestion.id, isCorrect: true },
      as(admin),
    );

    expect(res.status).toBe(204);
    expect((await graded()).isCorrect).toBe(true);
  });

  test("answers 204 and clears the grade when isCorrect is null", async () => {
    const res = await api.put(
      "/admin/grading",
      { userId: participant.id, questionId: freeCodeQuestion.id, isCorrect: null },
      as(admin),
    );

    expect(res.status).toBe(204);
    expect((await graded()).isCorrect).toBeNull();
  });

  test("fails with 400 when userId is not provided", async () => {
    const res = await api.put("/admin/grading", { questionId: freeCodeQuestion.id, isCorrect: true }, as(admin));

    expect(res.status).toBe(400);
    expect(res.data).toEqual({ message: expect.any(String), errors: { userId: "is required" } });
  });

  test("fails with 400 when userId is not a UUID", async () => {
    const res = await api.put(
      "/admin/grading",
      { userId: "not-a-uuid", questionId: freeCodeQuestion.id, isCorrect: true },
      as(admin),
    );

    expect(res.status).toBe(400);
    expect(res.data.errors).toEqual({ userId: "must be a valid UUID" });
  });

  test("fails with 400 when questionId is not provided", async () => {
    const res = await api.put("/admin/grading", { userId: participant.id, isCorrect: true }, as(admin));

    expect(res.status).toBe(400);
    expect(res.data.errors).toEqual({ questionId: "is required" });
  });

  test("fails with 400 when isCorrect is not provided", async () => {
    const res = await api.put("/admin/grading", { userId: participant.id, questionId: freeCodeQuestion.id }, as(admin));

    expect(res.status).toBe(400);
    expect(res.data.errors).toEqual({ isCorrect: "is required (true, false or null)" });
  });

  test("fails with 400 when isCorrect is not a boolean", async () => {
    const res = await api.put(
      "/admin/grading",
      { userId: participant.id, questionId: freeCodeQuestion.id, isCorrect: "yes" },
      as(admin),
    );

    expect(res.status).toBe(400);
    expect(res.data.errors).toEqual({ isCorrect: "must be of type boolean" });
  });

  test("fails with 400 when the question is not free_code", async () => {
    const res = await api.put(
      "/admin/grading",
      { userId: participant.id, questionId: choiceQuestion.id, isCorrect: true },
      as(admin),
    );

    expect(res.status).toBe(400);
    expect(res.data).toEqual({ message: "Only free_code answers can be graded" });
  });

  test("fails with 401 without a session", async () => {
    const res = await api.put("/admin/grading", {
      userId: participant.id,
      questionId: freeCodeQuestion.id,
      isCorrect: true,
    });

    expect(res.status).toBe(401);
  });

  test("fails with 403 when called by a participant", async () => {
    const res = await api.put(
      "/admin/grading",
      { userId: participant.id, questionId: freeCodeQuestion.id, isCorrect: true },
      as(participant.cookie),
    );

    expect(res.status).toBe(403);
  });

  test("fails with 404 when the question does not exist", async () => {
    const res = await api.put(
      "/admin/grading",
      { userId: participant.id, questionId: "nix.not-a-question", isCorrect: true },
      as(admin),
    );

    expect(res.status).toBe(404);
  });

  test("fails with 404 when the participant has no answer to the question", async () => {
    const res = await api.put(
      "/admin/grading",
      { userId: UNKNOWN_ID, questionId: freeCodeQuestion.id, isCorrect: true },
      as(admin),
    );

    expect(res.status).toBe(404);
    expect(res.data).toEqual({ message: "Answer not found" });
  });
});

describe("GET /admin/export.csv", () => {
  test("answers 200 with a CSV attachment of every answer, one row per likert item", async () => {
    const res = await api.get("/admin/export.csv", { ...as(admin), responseType: "text" });

    expect(res.status).toBe(200);
    expect(res.headers["content-type"]).toBe("text/csv; charset=utf-8");
    expect(res.headers["content-disposition"]).toMatch(/^attachment; filename=".+\.csv"$/);

    const [header] = res.data.split("\n");
    expect(header).toBe(
      "username,survey_order,step,step_position,section,question_id,kind,item_id,option_id,value,is_correct,answered_at,time_ms",
    );

    const rows = parseCSVObjects(res.data).filter((row) => row.username === participant.username);
    const [first] = participant.surveyOrder;
    const order = participant.surveyOrder.join(",");

    // Background likert: one row per item, in order, before the surveys.
    const background = rows.filter((row) => row.step === "background");
    expect(background.length).toBeGreaterThan(1);
    expect(background[0]).toMatchObject({
      survey_order: order,
      step_position: "",
      section: "background",
      kind: "likert",
      item_id: expect.any(String),
      value: "1",
      is_correct: "",
      time_ms: expect.stringMatching(/^\d+$/),
    });
    expect(rows.indexOf(background[0])).toBe(0);

    // Choices are graded automatically, free_code is not (until the admin does it).
    expect(rows.find((row) => row.question_id === choiceQuestion.id)).toMatchObject({
      step: first,
      step_position: "1",
      section: "tasks",
      kind: choiceQuestion.kind,
      option_id: choiceQuestion.options[0].id,
      is_correct: expect.stringMatching(/^(true|false)$/),
    });
    expect(rows.find((row) => row.question_id === freeCodeQuestion.id)).toMatchObject({
      kind: "free_code",
      value: "{ answer = 42; }",
      answered_at: expect.stringMatching(/^\d{4}-\d{2}-\d{2}T/),
    });
  });

  test("answers 200 with the time spent on a question, counted by heartbeats", async () => {
    const p = await createParticipant(admin);
    const { question } = await getCurrent(p.cookie, "background");
    await api.post("/me/heartbeat", { questionId: question.id }, as(p.cookie));
    await sleep(1200);
    await api.post("/me/answers", validAnswer(question), as(p.cookie)); // also a heartbeat

    const res = await api.get("/admin/export.csv", { ...as(admin), responseType: "text" });

    const row = parseCSVObjects(res.data).find((r) => r.username === p.username && r.question_id === question.id);
    expect(Number(row.time_ms)).toBeGreaterThanOrEqual(1100);
    expect(Number(row.time_ms)).toBeLessThan(10_000);
  });

  test("fails with 401 without a session", async () => {
    const res = await api.get("/admin/export.csv");

    expect(res.status).toBe(401);
  });

  test("fails with 403 when called by a participant", async () => {
    const res = await api.get("/admin/export.csv", as(participant.cookie));

    expect(res.status).toBe(403);
  });
});
