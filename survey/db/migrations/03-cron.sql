-- Scheduled maintenance with pg_cron (preloaded in db/Dockerfile).
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- Remove expired login sessions every hour.
SELECT cron.schedule(
    'purge-expired-sessions',
    '0 * * * *',
    $$DELETE FROM sessions WHERE expires_at < now()$$
);
