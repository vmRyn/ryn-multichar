CREATE TABLE IF NOT EXISTS `ryn_multichar_metadata` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `character_id` VARCHAR(50) NOT NULL,
    `last_played` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `playtime` INT NOT NULL DEFAULT 0,
    `scene_data` JSON DEFAULT NULL,
    UNIQUE KEY `character_id` (`character_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `ryn_multichar_slots` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `license` VARCHAR(255) NOT NULL,
    `slots` INT NOT NULL DEFAULT 3,
    `source` ENUM('config', 'tebex', 'admin') NOT NULL DEFAULT 'config',
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY `license` (`license`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `ryn_multichar_tebex_pending` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `license` VARCHAR(255) NOT NULL,
    `slots` INT NOT NULL DEFAULT 1,
    `package_id` VARCHAR(100) DEFAULT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    KEY `license` (`license`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
