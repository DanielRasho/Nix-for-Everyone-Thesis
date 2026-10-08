import { beforeAll, describe, expect, test } from "vitest";
import {
  UNKNOWN_ID,
  api,
  as,
  completeStep,
  createParticipant,
  getCurrent,
  login,
  loginAdmin,
  uniqueUsername,
} from "./helpers.js";

// 12 characters without the ambiguous 0/O/1/l/I.
const PASSWORD = /^[a-km-zA-HJ-NP-Z2-9]{12}$/;

let admin; // admin session cookie
let adminId;
let participant; // only used for the 403 cases
beforeAll(async () => {
  admin = await loginAdmin();
  adminId = (await api.get("/auth/me", as(admin))).data.user.id;
  participant = await createParticipant(admin);
});

describe("GET /admin/surveys", () => {
  test("answers 200 with every survey a participant can be assigned", async () => {
    const res = await api.get("/admin/surveys", as(admin));

    expect(res.status).toBe(200);
    expect(res.data).toEqual({
      surveys: [
        { id: "nix", title: expect.any(String) },
        { id: "nixty", title: expect.any(String) },
      ],
    });
  });

  test("fails with 401 without a session", async () => {
    const res = await api.get("/admin/surveys");

    expect(res.status).toBe(401);
    expect(res.data).toEqual({ message: expect.any(String) });
  });

  test("fails with 403 when called by a participant", async () => {
    const res = await api.get("/admin/surveys", as(participant.cookie));

    expect(res.status).toBe(403);
    expect(res.data).toEqual({ message: expect.any(String) });
  });
});

describe("GET /admin/participants", () => {
  test("answers 200 with every participant and their progress", async () => {
    const p = await createParticipant(admin, { surveyOrder: ["nixty", "nix"] });
    await completeStep(p.cookie, "background");
    await getCurrent(p.cookie, "nixty"); // starts it

    const res = await api.get("/admin/participants", as(admin));

    expect(res.status).toBe(200);
    expect(res.data.participants).toContainEqual({
      id: p.id,
      username: p.username,
      createdAt: expect.any(String),
      steps: [
        { id: "background", title: expect.any(String), status: "completed", answered: 1, total: 1 },
        {
          id: "nixty",
          title: expect.any(String),
          position: 1,
          status: "in_progress",
          answered: 0,
          total: expect.any(Number),
          startedAt: expect.any(String),
        },
        { id: "nix", title: expect.any(String), position: 2, status: "locked", answered: 0, total: expect.any(Number) },
      ],
    });
    // Only participants, never the admin.
    expect(res.data.participants.map((x) => x.id)).not.toContain(adminId);
  });

  test("fails with 401 without a session", async () => {
    const res = await api.get("/admin/participants");

    expect(res.status).toBe(401);
  });

  test("fails with 403 when called by a participant", async () => {
    const res = await api.get("/admin/participants", as(participant.cookie));

    expect(res.status).toBe(403);
  });
});

describe("POST /admin/participants", () => {
  test("answers 201 with the participant and their password, shown only this time", async () => {
    const username = uniqueUsername("P");

    const res = await api.post("/admin/participants", { username, surveyOrder: ["nix", "nixty"] }, as(admin));

    expect(res.status).toBe(201);
    expect(res.data).toEqual({
      participant: {
        id: expect.any(String),
        username,
        createdAt: expect.any(String),
        steps: [
          { id: "background", title: expect.any(String), status: "available", answered: 0, total: expect.any(Number) },
          { id: "nix", title: expect.any(String), position: 1, status: "locked", answered: 0, total: expect.any(Number) },
          { id: "nixty", title: expect.any(String), position: 2, status: "locked", answered: 0, total: expect.any(Number) },
        ],
      },
      password: expect.stringMatching(PASSWORD),
    });

    // The participant can log in with it.
    const cookie = await login(username, res.data.password);
    expect((await api.get("/auth/me", as(cookie))).data.user.role).toBe("participant");
  });

  test("fails with 400 when username is not provided", async () => {
    const res = await api.post("/admin/participants", { surveyOrder: ["nix", "nixty"] }, as(admin));

    expect(res.status).toBe(400);
    expect(res.data).toEqual({ message: expect.any(String), errors: { username: "is required" } });
  });

  test("fails with 400 when username has characters other than letters, digits, _ or -", async () => {
    const res = await api.post("/admin/participants", { username: "P 01!", surveyOrder: ["nix", "nixty"] }, as(admin));

    expect(res.status).toBe(400);
    expect(res.data.errors).toEqual({ username: "must be 2 to 32 letters, digits, '_' or '-'" });
  });

  test("fails with 400 when username is shorter than 2 characters", async () => {
    const res = await api.post("/admin/participants", { username: "P", surveyOrder: ["nix", "nixty"] }, as(admin));

    expect(res.status).toBe(400);
    expect(res.data.errors).toHaveProperty("username");
  });

  test("fails with 400 when username is longer than 32 characters", async () => {
    const res = await api.post(
      "/admin/participants",
      { username: "P".repeat(33), surveyOrder: ["nix", "nixty"] },
      as(admin),
    );

    expect(res.status).toBe(400);
    expect(res.data.errors).toHaveProperty("username");
  });

  test("fails with 400 when surveyOrder is not provided", async () => {
    const res = await api.post("/admin/participants", { username: uniqueUsername("P") }, as(admin));

    expect(res.status).toBe(400);
    expect(res.data.errors).toEqual({ surveyOrder: "is required" });
  });

  test("fails with 400 when surveyOrder misses a survey", async () => {
    const res = await api.post("/admin/participants", { username: uniqueUsername("P"), surveyOrder: ["nix"] }, as(admin));

    expect(res.status).toBe(400);
    expect(res.data.errors).toEqual({ surveyOrder: "must contain each survey exactly once: nix, nixty" });
  });

  test("fails with 400 when surveyOrder repeats a survey", async () => {
    const res = await api.post(
      "/admin/participants",
      { username: uniqueUsername("P"), surveyOrder: ["nix", "nix"] },
      as(admin),
    );

    expect(res.status).toBe(400);
    expect(res.data.errors).toHaveProperty("surveyOrder");
  });

  test("fails with 400 when surveyOrder has an unknown survey", async () => {
    const res = await api.post(
      "/admin/participants",
      { username: uniqueUsername("P"), surveyOrder: ["nix", "nixty", "other"] },
      as(admin),
    );

    expect(res.status).toBe(400);
    expect(res.data.errors).toHaveProperty("surveyOrder");
  });

  test("fails with 401 without a session", async () => {
    const res = await api.post("/admin/participants", { username: uniqueUsername("P"), surveyOrder: ["nix", "nixty"] });

    expect(res.status).toBe(401);
  });

  test("fails with 403 when called by a participant", async () => {
    const res = await api.post(
      "/admin/participants",
      { username: uniqueUsername("P"), surveyOrder: ["nix", "nixty"] },
      as(participant.cookie),
    );

    expect(res.status).toBe(403);
  });

  test("fails with 409 when the username exists", async () => {
    const res = await api.post(
      "/admin/participants",
      { username: participant.username, surveyOrder: ["nix", "nixty"] },
      as(admin),
    );

    expect(res.status).toBe(409);
    expect(res.data).toEqual({ message: "Username already exists" });
  });
});

describe("POST /admin/participants/{id}/password", () => {
  test("answers 200 with a new password and logs the participant out", async () => {
    const p = await createParticipant(admin);

    const res = await api.post(`/admin/participants/${p.id}/password`, null, as(admin));

    expect(res.status).toBe(200);
    expect(res.data).toEqual({ password: expect.stringMatching(PASSWORD) });
    // Their sessions ended, the old password is gone, the new one works.
    expect((await api.get("/auth/me", as(p.cookie))).status).toBe(401);
    expect((await api.post("/auth/login", { username: p.username, password: p.password })).status).toBe(401);
    expect(await login(p.username, res.data.password)).toBeDefined();
  });

  test("fails with 400 when the id is not a UUID", async () => {
    const res = await api.post("/admin/participants/not-a-uuid/password", null, as(admin));

    expect(res.status).toBe(400);
    expect(res.data).toEqual({ message: expect.any(String) });
  });

  test("fails with 401 without a session", async () => {
    const res = await api.post(`/admin/participants/${participant.id}/password`);

    expect(res.status).toBe(401);
  });

  test("fails with 403 when called by a participant", async () => {
    const res = await api.post(`/admin/participants/${participant.id}/password`, null, as(participant.cookie));

    expect(res.status).toBe(403);
  });

  test("fails with 404 when the participant does not exist", async () => {
    const res = await api.post(`/admin/participants/${UNKNOWN_ID}/password`, null, as(admin));

    expect(res.status).toBe(404);
    expect(res.data).toEqual({ message: "Participant not found" });
  });

  test("fails with 404 when the id is the admin's", async () => {
    const res = await api.post(`/admin/participants/${adminId}/password`, null, as(admin));

    expect(res.status).toBe(404);
  });
});

describe("DELETE /admin/participants/{id}", () => {
  test("answers 204 and deletes the participant with all their data", async () => {
    const p = await createParticipant(admin);
    await completeStep(p.cookie, "background");

    const res = await api.delete(`/admin/participants/${p.id}`, as(admin));

    expect(res.status).toBe(204);
    expect(res.data).toBe("");
    // Gone: no longer listed, logged out and can't log in.
    const list = await api.get("/admin/participants", as(admin));
    expect(list.data.participants.map((x) => x.id)).not.toContain(p.id);
    expect((await api.get("/auth/me", as(p.cookie))).status).toBe(401);
    expect((await api.post("/auth/login", { username: p.username, password: p.password })).status).toBe(401);
  });

  test("fails with 400 when the id is not a UUID", async () => {
    const res = await api.delete("/admin/participants/not-a-uuid", as(admin));

    expect(res.status).toBe(400);
  });

  test("fails with 401 without a session", async () => {
    const res = await api.delete(`/admin/participants/${participant.id}`);

    expect(res.status).toBe(401);
  });

  test("fails with 403 when called by a participant", async () => {
    const res = await api.delete(`/admin/participants/${participant.id}`, as(participant.cookie));

    expect(res.status).toBe(403);
  });

  test("fails with 404 when the participant does not exist", async () => {
    const res = await api.delete(`/admin/participants/${UNKNOWN_ID}`, as(admin));

    expect(res.status).toBe(404);
    expect(res.data).toEqual({ message: "Participant not found" });
  });

  test("fails with 404 when the id is the admin's", async () => {
    const res = await api.delete(`/admin/participants/${adminId}`, as(admin));

    expect(res.status).toBe(404);
    // The admin is still there.
    expect((await api.get("/auth/me", as(admin))).status).toBe(200);
  });
});
