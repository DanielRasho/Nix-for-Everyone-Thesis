-- ============================================
-- USERS
-- ============================================

-- name: CreateUser :one
INSERT INTO users (username, password_hash, role)
VALUES (@username, @password_hash, @role)
RETURNING *;

-- name: UpsertAdmin :exec
INSERT INTO users (username, password_hash, role)
VALUES (@username, @password_hash, 'admin')
ON CONFLICT (username) DO UPDATE
SET password_hash = EXCLUDED.password_hash, role = 'admin';

-- name: GetUserByUsername :one
SELECT * FROM users
WHERE username = @username;

-- name: ListParticipants :many
SELECT * FROM users
WHERE role = 'participant'
ORDER BY username;

-- name: UpdateParticipantPassword :execrows
-- The admin's password comes from env vars, only participants can be updated.
UPDATE users SET password_hash = @password_hash
WHERE id = @id AND role = 'participant';

-- name: DeleteParticipant :execrows
DELETE FROM users
WHERE id = @id AND role = 'participant';

-- ============================================
-- SESSIONS
-- ============================================

-- name: CreateSession :exec
INSERT INTO sessions (token_hash, user_id, expires_at)
VALUES (@token_hash, @user_id, @expires_at);

-- name: GetSessionUser :one
SELECT u.id, u.username, u.role
FROM sessions s
JOIN users u ON u.id = s.user_id
WHERE s.token_hash = @token_hash AND s.expires_at > now();

-- name: DeleteSession :exec
DELETE FROM sessions
WHERE token_hash = @token_hash;

-- name: DeleteUserSessions :exec
DELETE FROM sessions
WHERE user_id = @user_id;

-- ============================================
-- ASSIGNMENTS
-- ============================================

-- name: CreateAssignment :exec
INSERT INTO assignments (user_id, survey, position)
VALUES (@user_id, @survey, @position);

-- name: ListUserAssignments :many
SELECT * FROM assignments
WHERE user_id = @user_id
ORDER BY position;

-- name: ListAssignments :many
SELECT * FROM assignments
ORDER BY user_id, position;

-- name: StartAssignment :exec
UPDATE assignments SET started_at = now()
WHERE user_id = @user_id AND survey = @survey AND started_at IS NULL;

-- name: CompleteAssignment :execrows
UPDATE assignments SET completed_at = now()
WHERE user_id = @user_id AND survey = @survey AND completed_at IS NULL;

-- ============================================
-- ANSWERS
-- ============================================

-- name: InsertAnswer :execrows
-- Forward-only: an answer is never overwritten, 0 rows means it already existed.
INSERT INTO answers (user_id, question_id, option_id, value, is_correct)
VALUES (@user_id, @question_id, sqlc.narg(option_id), sqlc.narg(value), sqlc.narg(is_correct))
ON CONFLICT (user_id, question_id) DO NOTHING;

-- name: InsertLikertAnswer :exec
INSERT INTO likert_answers (user_id, question_id, item_id, value)
VALUES (@user_id, @question_id, @item_id, @value);

-- name: ListUserAnsweredQuestions :many
SELECT question_id FROM answers
WHERE user_id = @user_id;

-- name: CountAnswersBySurvey :many
-- Question ids are prefixed with their survey: 'nix.PA1-1' -> 'nix'.
SELECT user_id, split_part(question_id, '.', 1)::text AS survey, count(*)::int AS answered
FROM answers
GROUP BY user_id, survey;

-- name: GradeAnswer :execrows
UPDATE answers SET is_correct = sqlc.narg(is_correct)
WHERE user_id = @user_id AND question_id = @question_id;

-- name: ListAnswers :many
SELECT a.user_id, u.username, a.question_id, a.option_id, a.value, a.is_correct, a.answered_at
FROM answers a
JOIN users u ON u.id = a.user_id
ORDER BY u.username, a.answered_at;

-- name: ListLikertAnswers :many
SELECT user_id, question_id, item_id, value
FROM likert_answers
ORDER BY user_id, question_id, item_id;

-- ============================================
-- TIME TRACKING
-- ============================================

-- name: ExtendTimeSegment :execrows
-- Extends the latest segment if it was seen recently, 0 rows means a new one is needed.
UPDATE time_segments SET last_seen_at = now()
WHERE id = (
    SELECT latest.id FROM time_segments latest
    WHERE latest.user_id = @user_id
      AND latest.question_id = @question_id
      AND latest.last_seen_at > now() - make_interval(secs => @max_gap_seconds::float8)
    ORDER BY latest.last_seen_at DESC
    LIMIT 1
);

-- name: StartTimeSegment :exec
INSERT INTO time_segments (user_id, question_id)
VALUES (@user_id, @question_id);

-- name: ListQuestionTimes :many
SELECT user_id,
       question_id,
       (EXTRACT(EPOCH FROM sum(last_seen_at - started_at)) * 1000)::bigint AS time_ms,
       count(*)::int AS segments
FROM time_segments
GROUP BY user_id, question_id
ORDER BY user_id, question_id;
