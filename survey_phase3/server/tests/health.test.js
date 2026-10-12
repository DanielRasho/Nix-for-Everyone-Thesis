import { describe, expect, test } from "vitest";
import { api } from "./helpers.js";

describe("GET /health", () => {
  test("answers 200 with ok when the server is up", async () => {
    const res = await api.get("/health");

    expect(res.status).toBe(200);
    expect(res.data).toBe("ok");
  });
});
