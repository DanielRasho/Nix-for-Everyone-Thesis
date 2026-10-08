-- Initial schema.

-- ============================================
-- USERS & SESSIONS
-- ============================================

CREATE TYPE user_role AS ENUM ('admin', 'participant');

CREATE TABLE users (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username      TEXT NOT NULL UNIQUE,             -- P01, P02... never a real name
    password_hash TEXT NOT NULL,                    -- bcrypt
    role          user_role NOT NULL DEFAULT 'participant',
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE sessions (
    token_hash BYTEA PRIMARY KEY,                   -- sha256 of the cookie token
    user_id    UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    expires_at TIMESTAMPTZ NOT NULL
);

-- ============================================
-- SURVEY PROGRESS
-- ============================================

-- The surveys a participant must solve, in order. The order is the group.
CREATE TABLE assignments (
    user_id      UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    survey       TEXT NOT NULL,                     -- content file id: 'nix' | 'nixty'
    position     SMALLINT NOT NULL CHECK (position > 0),
    started_at   TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    PRIMARY KEY (user_id, survey),
    UNIQUE (user_id, position)
);

-- One row per answered screen. Insert-only: the survey is forward-only.
CREATE TABLE answers (
    user_id     UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    question_id TEXT NOT NULL,
    option_id   TEXT,                               -- choice_code / choice_text
    value       TEXT,                               -- free_code / free_text
    is_correct  BOOLEAN,                            -- auto for choices, manual for free_code
    answered_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (user_id, question_id)
);

-- One row per item of a likert question.
CREATE TABLE likert_answers (
    user_id     UUID NOT NULL,
    question_id TEXT NOT NULL,
    item_id     TEXT NOT NULL,
    value       SMALLINT NOT NULL CHECK (value BETWEEN 1 AND 7),
    PRIMARY KEY (user_id, question_id, item_id),
    FOREIGN KEY (user_id, question_id) REFERENCES answers (user_id, question_id) ON DELETE CASCADE
);

-- Uninterrupted stretches of time spent on a question, extended by heartbeats.
-- Time on a question = SUM(last_seen_at - started_at).
CREATE TABLE time_segments (
    id           BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id      UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    question_id  TEXT NOT NULL,
    started_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    last_seen_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX time_segments_lookup_idx ON time_segments (user_id, question_id, last_seen_at DESC);
