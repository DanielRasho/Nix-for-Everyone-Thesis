// Shared helpers of the integration tests. They run against the live API
// (`moon run server:dev`), configured by server/.env like the server itself.
import axios from "axios";
import { readFileSync } from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { inflateRawSync } from "node:zlib";

// ============================================
// CONFIG
// ============================================

// Reads server/.env. Real env vars win, as in the server (godotenv).
function readEnvFile() {
  const file = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../.env");
  const env = {};
  for (const line of readFileSync(file, "utf8").split("\n")) {
    const match = line.match(/^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*?)\s*$/);
    if (match) env[match[1]] = match[2].replace(/^(['"])(.*)\1$/, "$2");
  }
  return env;
}

const env = { ...readEnvFile(), ...process.env };

export const BASE_URL = env.API_URL ?? `http://localhost:${env.API_PORT}`;
export const ADMIN = { username: env.ADMIN_USERNAME, password: env.ADMIN_PASSWORD };

// Axios never throws on non-2xx, so tests can assert error statuses.
export const api = axios.create({ baseURL: BASE_URL, validateStatus: () => true });

// ============================================
// SESSIONS
// ============================================

/** Request options that send a session cookie: `api.get(url, as(cookie))`. */
export const as = (cookie) => ({ headers: { Cookie: cookie } });

/** The raw Set-Cookie header of the session cookie, if the response sets it. */
export function setSessionCookie(res) {
  return (res.headers["set-cookie"] ?? []).find((c) => c.startsWith("survey_session="));
}

/** The `survey_session=<token>` pair of a response, ready for a Cookie header. */
export function sessionCookie(res) {
  return setSessionCookie(res)?.split(";")[0];
}

/** Logs in and returns the session cookie. */
export async function login(username, password) {
  const res = await api.post("/auth/login", { username, password });
  if (res.status !== 200) {
    throw new Error(`login of ${username} failed: ${res.status} ${JSON.stringify(res.data)}`);
  }
  return sessionCookie(res);
}

export const loginAdmin = () => login(ADMIN.username, ADMIN.password);

// ============================================
// PARTICIPANTS
// ============================================

// The DB is shared by every test of the run (and previous runs), so usernames
// carry a random run id.
const runId = `${Date.now().toString(36).slice(-5)}${Math.random().toString(36).slice(2, 5)}`;
let created = 0;

/** A username no other test (or run) uses. */
export function uniqueUsername(prefix = "t") {
  created++;
  return `${prefix}_${runId}_${created}`;
}

/** Ids of every survey, as GET /admin/surveys answers them. */
export async function surveyIds(adminCookie) {
  const res = await api.get("/admin/surveys", as(adminCookie));
  return res.data.surveys.map((s) => s.id);
}

/**
 * Creates a participant (as admin) and logs them in.
 * Returns the participant of the response plus { password, cookie, surveyOrder }.
 */
export async function createParticipant(adminCookie, { username = uniqueUsername("p"), surveyOrder } = {}) {
  surveyOrder ??= await surveyIds(adminCookie);
  const res = await api.post("/admin/participants", { username, surveyOrder }, as(adminCookie));
  if (res.status !== 201) {
    throw new Error(`creating ${username} failed: ${res.status} ${JSON.stringify(res.data)}`);
  }
  const cookie = await login(username, res.data.password);
  return { ...res.data.participant, password: res.data.password, cookie, surveyOrder };
}

// ============================================
// ANSWERING
// ============================================

/** A valid answer for a question of any kind. */
export function validAnswer(question) {
  const questionId = question.id;
  switch (question.kind) {
    case "info":
      return { questionId };
    case "choice_code":
    case "choice_text":
      return { questionId, optionId: question.options[0].id };
    case "free_code":
    case "free_text":
      return { questionId, value: question.optional ? "" : "my answer" };
    case "likert":
      return { questionId, likert: Object.fromEntries(question.items.map((item) => [item.id, 1])) };
    default:
      throw new Error(`unknown question kind ${question.kind}`);
  }
}

/** GET /me/steps/{stepId}/current, failing the test if it doesn't answer 200. */
export async function getCurrent(cookie, stepId) {
  const res = await api.get(`/me/steps/${stepId}/current`, as(cookie));
  if (res.status !== 200) {
    throw new Error(`current of ${stepId} failed: ${res.status} ${JSON.stringify(res.data)}`);
  }
  return res.data;
}

/** Answers the current question of a step with a valid answer, returns the response. */
export async function answerCurrent(cookie, stepId) {
  const { question } = await getCurrent(cookie, stepId);
  if (!question) throw new Error(`step ${stepId} is already completed`);
  return api.post("/me/answers", validAnswer(question), as(cookie));
}

/**
 * Answers questions of a step until `predicate(question, current)` is true for
 * the current one, returns that Current.
 */
export async function advanceTo(cookie, stepId, predicate) {
  for (;;) {
    const current = await getCurrent(cookie, stepId);
    if (!current.question) throw new Error(`step ${stepId} finished before reaching the question`);
    if (predicate(current.question, current)) return current;

    const res = await api.post("/me/answers", validAnswer(current.question), as(cookie));
    if (res.status !== 200) {
      throw new Error(`answering ${current.question.id} failed: ${res.status} ${JSON.stringify(res.data)}`);
    }
  }
}

/** Answers every remaining question of a step. */
export async function completeStep(cookie, stepId) {
  for (;;) {
    const { question } = await getCurrent(cookie, stepId);
    if (!question) return;
    const res = await api.post("/me/answers", validAnswer(question), as(cookie));
    if (res.status !== 200) {
      throw new Error(`answering ${question.id} failed: ${res.status} ${JSON.stringify(res.data)}`);
    }
  }
}

export const isChoice = (q) => q.kind === "choice_code" || q.kind === "choice_text";

// ============================================
// MISC
// ============================================

/** A valid UUID that no row has. */
export const UNKNOWN_ID = "00000000-0000-4000-8000-000000000000";

export const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

/** Parses CSV (RFC 4180: quoted fields may have commas, quotes and newlines). */
export function parseCSV(text) {
  const rows = [];
  let row = [];
  let field = "";
  let quoted = false;
  for (let i = 0; i < text.length; i++) {
    const c = text[i];
    if (quoted) {
      if (c === '"' && text[i + 1] === '"') {
        field += '"';
        i++;
      } else if (c === '"') {
        quoted = false;
      } else {
        field += c;
      }
    } else if (c === '"') {
      quoted = true;
    } else if (c === ",") {
      row.push(field);
      field = "";
    } else if (c === "\n" || c === "\r") {
      if (c === "\r" && text[i + 1] === "\n") i++;
      row.push(field);
      rows.push(row);
      row = [];
      field = "";
    } else {
      field += c;
    }
  }
  if (field !== "" || row.length > 0) {
    row.push(field);
    rows.push(row);
  }
  return rows;
}

/** CSV text as objects keyed by the header row. */
export function parseCSVObjects(text) {
  const [header, ...rows] = parseCSV(text);
  return rows.map((row) => Object.fromEntries(header.map((name, i) => [name, row[i]])));
}

/**
 * Zip archive (Buffer) as `{ [path]: text }`, read from its central directory.
 * Only what the server writes: stored or deflated entries, no zip64.
 */
export function unzip(buffer) {
  const end = buffer.lastIndexOf(Buffer.from("PK\x05\x06", "latin1"));
  const count = buffer.readUInt16LE(end + 10);
  let entry = buffer.readUInt32LE(end + 16);
  const files = {};
  for (let i = 0; i < count; i++) {
    const method = buffer.readUInt16LE(entry + 10);
    const size = buffer.readUInt32LE(entry + 20);
    const nameLength = buffer.readUInt16LE(entry + 28);
    const extraLength = buffer.readUInt16LE(entry + 30);
    const commentLength = buffer.readUInt16LE(entry + 32);
    const local = buffer.readUInt32LE(entry + 42);
    const name = buffer.toString("utf8", entry + 46, entry + 46 + nameLength);

    const start = local + 30 + buffer.readUInt16LE(local + 26) + buffer.readUInt16LE(local + 28);
    const data = buffer.subarray(start, start + size);
    files[name] = (method === 8 ? inflateRawSync(data) : data).toString("utf8");
    entry += 46 + nameLength + extraLength + commentLength;
  }
  return files;
}
