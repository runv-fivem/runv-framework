-- RUN V (RNV) core schema. Runs automatically on resource start (idempotent).

-- Account: the person. Survives logout and wipes.
CREATE TABLE IF NOT EXISTS `users` (
  `userId` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `username` VARCHAR(255) DEFAULT NULL,
  `identifier` VARCHAR(80) NOT NULL,
  `license` VARCHAR(60) DEFAULT NULL,
  `license2` VARCHAR(60) DEFAULT NULL,
  `fivem` VARCHAR(30) DEFAULT NULL,
  `discord` VARCHAR(40) DEFAULT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`userId`),
  UNIQUE KEY `identifier` (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Profile: the single game profile of a user. Owns assets and progression.
CREATE TABLE IF NOT EXISTS `players` (
  `citizenid` VARCHAR(16) NOT NULL,
  `userId` INT UNSIGNED NOT NULL,
  `name` VARCHAR(255) NOT NULL,
  `metadata` LONGTEXT NOT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `last_updated` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `last_logged_out` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`citizenid`),
  UNIQUE KEY `userId` (`userId`),
  CONSTRAINT `fk_players_user` FOREIGN KEY (`userId`) REFERENCES `users` (`userId`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Wipe cycles. The open cycle (ended_at IS NULL) is the current one.
CREATE TABLE IF NOT EXISTS `cycles` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `started_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `ended_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Bank accounts. Belong to one cycle. UNSIGNED balance: the DB itself refuses negatives.
CREATE TABLE IF NOT EXISTS `accounts` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `cycle_id` INT UNSIGNED NOT NULL,
  `owner_type` VARCHAR(20) NOT NULL,
  `owner_id` VARCHAR(50) NOT NULL,
  `type` VARCHAR(20) NOT NULL DEFAULT 'bank',
  `balance` BIGINT UNSIGNED NOT NULL DEFAULT 0,
  `status` ENUM('open','frozen','closed') NOT NULL DEFAULT 'open',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `owner` (`cycle_id`, `owner_type`, `owner_id`, `type`),
  CONSTRAINT `fk_accounts_cycle` FOREIGN KEY (`cycle_id`) REFERENCES `cycles` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Ledger. Every balance change is one row. `ref` makes a payment idempotent.
CREATE TABLE IF NOT EXISTS `transactions` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `account_id` INT UNSIGNED NOT NULL,
  `cycle_id` INT UNSIGNED NOT NULL,
  `amount` BIGINT NOT NULL,
  `balance_after` BIGINT UNSIGNED NOT NULL,
  `reason` VARCHAR(100) NOT NULL,
  `ref` VARCHAR(64) DEFAULT NULL,
  `actor` VARCHAR(64) NOT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `ref` (`ref`),
  KEY `account` (`account_id`, `created_at`),
  CONSTRAINT `fk_transactions_account` FOREIGN KEY (`account_id`) REFERENCES `accounts` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Admin / sensitive actions that are not money movements.
CREATE TABLE IF NOT EXISTS `audit_log` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `actor` VARCHAR(64) NOT NULL,
  `action` VARCHAR(64) NOT NULL,
  `target` VARCHAR(64) DEFAULT NULL,
  `data` LONGTEXT DEFAULT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `action` (`action`, `created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
