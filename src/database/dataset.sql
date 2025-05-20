-- M-BOT Project SQL Schema for Supabase/Postgres
-- All tables use a unique six-digit integer auth_id for user identification

-- 1. user_auth: Stores authentication credentials and unique auth_id
CREATE TABLE IF NOT EXISTS user_auth (
    auth_id INTEGER PRIMARY KEY CHECK (auth_id BETWEEN 100000 AND 999999),
    username VARCHAR(64) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. users: Stores user profile and bot registration info, linked to user_auth
CREATE TABLE IF NOT EXISTS users (
    auth_id INTEGER PRIMARY KEY,
    email VARCHAR(255) UNIQUE,
    display_name VARCHAR(64),
    is_admin BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (auth_id) REFERENCES user_auth(auth_id) ON DELETE CASCADE
);

-- 3. subscription_tokens: Stores tokens for user access, linked to user_auth
CREATE TABLE IF NOT EXISTS subscription_tokens (
    token VARCHAR(64) PRIMARY KEY,
    auth_id INTEGER NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    issued_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (auth_id) REFERENCES user_auth(auth_id) ON DELETE CASCADE
);

-- 4. notifications: Stores notifications for users
CREATE TABLE IF NOT EXISTS notifications (
    id SERIAL PRIMARY KEY,
    auth_id INTEGER NOT NULL,
    message TEXT NOT NULL,
    type VARCHAR(32) DEFAULT 'info',
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (auth_id) REFERENCES user_auth(auth_id) ON DELETE CASCADE
);

-- 5. bots: Stores bot registration info, linked to user_auth
CREATE TABLE IF NOT EXISTS bots (
    bot_id SERIAL PRIMARY KEY,
    auth_id INTEGER NOT NULL,
    bot_name VARCHAR(64) NOT NULL,
    registered_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (auth_id) REFERENCES user_auth(auth_id) ON DELETE CASCADE
);

-- 6. user_sessions: Stores bot/user sessions, protected by token-based access
CREATE TABLE IF NOT EXISTS user_sessions (
    session_id SERIAL PRIMARY KEY,
    auth_id INTEGER NOT NULL,
    bot_id INTEGER NOT NULL,
    started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ended_at TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (auth_id) REFERENCES user_auth(auth_id) ON DELETE CASCADE,
    FOREIGN KEY (bot_id) REFERENCES bots(bot_id) ON DELETE CASCADE
);

-- 7. metrics: Stores metrics for bot usage
CREATE TABLE IF NOT EXISTS metrics (
    id SERIAL PRIMARY KEY,
    bot_id INTEGER NOT NULL,
    metric_type VARCHAR(64) NOT NULL,
    value NUMERIC,
    recorded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (bot_id) REFERENCES bots(bot_id) ON DELETE CASCADE
);

-- 8. memory: Stores bot memory/context per user (if used)
CREATE TABLE IF NOT EXISTS memory (
    id SERIAL PRIMARY KEY,
    bot_id INTEGER NOT NULL,
    key VARCHAR(128) NOT NULL,
    value TEXT,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (bot_id) REFERENCES bots(bot_id) ON DELETE CASCADE
);

-- 9. supabase_auth_state: Stores Supabase auth state for integration
CREATE TABLE IF NOT EXISTS supabase_auth_state (
    id SERIAL PRIMARY KEY,
    auth_id INTEGER NOT NULL,
    supabase_uid VARCHAR(64) NOT NULL,
    last_synced TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (auth_id) REFERENCES user_auth(auth_id) ON DELETE CASCADE
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_user_auth_username ON user_auth(username);
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_subscription_tokens_auth_id ON subscription_tokens(auth_id);
CREATE INDEX IF NOT EXISTS idx_notifications_auth_id ON notifications(auth_id);
CREATE INDEX IF NOT EXISTS idx_bots_auth_id ON bots(auth_id);
CREATE INDEX IF NOT EXISTS idx_user_sessions_auth_id ON user_sessions(auth_id);
CREATE INDEX IF NOT EXISTS idx_user_sessions_bot_id ON user_sessions(bot_id);

-- Triggers to update updated_at columns
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
   NEW.updated_at = NOW();
   RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_user_auth_updated_at BEFORE UPDATE ON user_auth
FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();
