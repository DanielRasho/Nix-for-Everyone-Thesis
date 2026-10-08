import { beforeAll, describe, expect, test } from "vitest";
import {
  ADMIN,
  api,
  as,
  createParticipant,
  loginAdmin,
  sessionCookie,
  setSessionCookie,
} from "./helpers.js";

let admin; // admin session cookie
beforeAll(async () => {
  admin = await loginAdmin();
});

describe("POST /auth/login", () => {
  test("answers 200 with the user and sets the session cookie when the credentials are right", async () => {
    const participant = await createParticipant(admin);

    const res = await api.post("/auth/login", {
      username: participant.username,
      password: participant.password,
    });

    expect(res.status).toBe(200);
    expect(res.data).toEqual({
      user: { id: participant.id, username: participant.username, role: "participant" },
    });
    const cookie = setSessionCookie(res);
    expect(cookie).toMatch(/^survey_session=[A-Za-z0-9_-]{43};/);
    expect(cookie).toContain("Path=/");
    expect(cookie).toContain("HttpOnly");
    expect(cookie).toContain("SameSite=Lax");

    // The cookie is the session.
    const me = await api.get("/auth/me", as(sessionCookie(res)));
    expect(me.data.user.username).toBe(participant.username);
  });

  test("answers 200 with role admin when the admin logs in", async () => {
    const res = await api.post("/auth/login", ADMIN);

    expect(res.status).toBe(200);
    expect(res.data.user).toMatchObject({ username: ADMIN.username, role: "admin" });
    expect(sessionCookie(res)).toBeDefined();
  });

  test("fails with 400 when username is not provided", async () => {
    const res = await api.post("/auth/login", { password: "whatever" });

    expect(res.status).toBe(400);
    expect(res.data).toEqual({
      message: expect.any(String),
      errors: { username: "is required" },
    });
  });

  test("fails with 400 when password is not provided", async () => {
    const res = await api.post("/auth/login", { username: ADMIN.username });

    expect(res.status).toBe(400);
    expect(res.data.errors).toEqual({ password: "is required" });
  });

  test("fails with 400 when the body is not JSON", async () => {
    const res = await api.post("/auth/login", "username=admin", {
      headers: { "Content-Type": "text/plain" },
    });

    expect(res.status).toBe(400);
    expect(res.data.message).toEqual(expect.any(String));
  });

  test("fails with 400 when a field has the wrong type", async () => {
    const res = await api.post("/auth/login", { username: 42, password: "x" });

    expect(res.status).toBe(400);
    expect(res.data.errors).toEqual({ username: "must be of type string" });
  });

  test("fails with 401 when the password is wrong", async () => {
    const res = await api.post("/auth/login", { username: ADMIN.username, password: "wrong" });

    expect(res.status).toBe(401);
    expect(res.data).toEqual({ message: "Wrong username or password" });
    expect(setSessionCookie(res)).toBeUndefined();
  });

  test("fails with 401 when the username does not exist", async () => {
    const res = await api.post("/auth/login", { username: "nobody_here", password: "wrong" });

    expect(res.status).toBe(401);
    expect(res.data).toEqual({ message: "Wrong username or password" });
  });
});

describe("POST /auth/logout", () => {
  test("answers 204, ends the session and clears the cookie", async () => {
    const cookie = await loginAdmin();

    const res = await api.post("/auth/logout", null, as(cookie));

    expect(res.status).toBe(204);
    expect(setSessionCookie(res)).toMatch(/^survey_session=;.*Max-Age=0/);
    // The old cookie is no longer a session.
    expect((await api.get("/auth/me", as(cookie))).status).toBe(401);
  });

  test("answers 204 without a session (idempotent)", async () => {
    const res = await api.post("/auth/logout");

    expect(res.status).toBe(204);
  });

  test("answers 204 with a session that already ended", async () => {
    const cookie = await loginAdmin();
    await api.post("/auth/logout", null, as(cookie));

    const res = await api.post("/auth/logout", null, as(cookie));

    expect(res.status).toBe(204);
  });
});

describe("GET /auth/me", () => {
  test("answers 200 with the logged in user", async () => {
    const participant = await createParticipant(admin);

    const res = await api.get("/auth/me", as(participant.cookie));

    expect(res.status).toBe(200);
    expect(res.data).toEqual({
      user: { id: participant.id, username: participant.username, role: "participant" },
    });
  });

  test("fails with 401 without a session", async () => {
    const res = await api.get("/auth/me");

    expect(res.status).toBe(401);
    expect(res.data).toEqual({ message: expect.any(String) });
  });

  test("fails with 401 with an invalid session cookie", async () => {
    const res = await api.get("/auth/me", as("survey_session=not-a-real-token"));

    expect(res.status).toBe(401);
  });
});
