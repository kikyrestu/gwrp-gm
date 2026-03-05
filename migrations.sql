CREATE TABLE IF NOT EXISTS twitter_accounts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    player_id INT NOT NULL,
    username VARCHAR(24) NOT NULL UNIQUE,
    password VARCHAR(64) NOT NULL,
    ts INT DEFAULT 0
);

CREATE TABLE IF NOT EXISTS twitter_comments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    tweet_id INT NOT NULL,
    author_id INT NOT NULL,
    content VARCHAR(255) NOT NULL,
    ts INT DEFAULT 0
);

CREATE TABLE IF NOT EXISTS phone_notes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    player_id INT NOT NULL,
    title VARCHAR(48) NOT NULL,
    body VARCHAR(255) DEFAULT '',
    ts INT DEFAULT 0
);

-- Update phone_tweets table to use author_id instead of player_id/player_name
-- Check and add author_id column (ignore error if exists)
SET @col_exists = (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema='astawnew' AND table_name='phone_tweets' AND column_name='author_id');
SET @sql = IF(@col_exists = 0, 'ALTER TABLE phone_tweets ADD COLUMN author_id INT DEFAULT 0', 'SELECT 1');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SELECT 'All migrations completed OK' AS result;
