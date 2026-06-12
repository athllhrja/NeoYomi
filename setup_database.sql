-- ============================================================
-- NeoYomi Database Setup
-- Database target: neuyomi
-- Jalankan script ini di HeidiSQL / phpMyAdmin / MySQL CLI
-- ============================================================

CREATE DATABASE IF NOT EXISTS `neuyomi`
    CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE `neuyomi`;

-- ============================================================
-- 1. TABEL EKSTENSI KOMIK
-- Dipakai oleh: LibraryDAO.getDaftarKomik() -> KomikServlet (/api/komik)
-- ============================================================
CREATE TABLE IF NOT EXISTS `komik` (
    `id`      INT NOT NULL AUTO_INCREMENT,
    `name`    VARCHAR(255) NOT NULL,
    `lang`    VARCHAR(10)  NOT NULL DEFAULT 'en',
    `version` VARCHAR(50)  DEFAULT NULL,
    `url`     VARCHAR(500) DEFAULT NULL,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- 2. TABEL EKSTENSI NOVEL
-- Dipakai oleh: LibraryDAO.getDaftarNovel() -> NovelServlet (/api/novel)
-- NB: id bertipe String/VARCHAR sesuai model Novel.java
-- ============================================================
CREATE TABLE IF NOT EXISTS `novel` (
    `id`   VARCHAR(50)  NOT NULL,
    `name` VARCHAR(255) NOT NULL,
    `site` VARCHAR(255) DEFAULT NULL,
    `lang` VARCHAR(10)  NOT NULL DEFAULT 'en',
    `url`  VARCHAR(500) DEFAULT NULL,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- 3. TABEL GENRES (dipakai bersama oleh komik & novel)
-- ============================================================
CREATE TABLE IF NOT EXISTS `genres` (
    `id`        INT NOT NULL AUTO_INCREMENT,
    `nama_genre` VARCHAR(100) NOT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `nama_genre` (`nama_genre`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- 4. RELASI KOMIK <-> GENRES (many-to-many)
-- ============================================================
CREATE TABLE IF NOT EXISTS `komik_genres` (
    `komik_id` INT NOT NULL,
    `genre_id` INT NOT NULL,
    PRIMARY KEY (`komik_id`, `genre_id`),
    FOREIGN KEY (`komik_id`) REFERENCES `komik`(`id`)  ON DELETE CASCADE,
    FOREIGN KEY (`genre_id`) REFERENCES `genres`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- 5. RELASI NOVEL <-> GENRES (many-to-many)
-- ============================================================
CREATE TABLE IF NOT EXISTS `novel_genres` (
    `novel_id` VARCHAR(50) NOT NULL,
    `genre_id` INT NOT NULL,
    PRIMARY KEY (`novel_id`, `genre_id`),
    FOREIGN KEY (`novel_id`) REFERENCES `novel`(`id`)   ON DELETE CASCADE,
    FOREIGN KEY (`genre_id`) REFERENCES `genres`(`id`)  ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- 6. TABEL CONTENTS (My Library - hasil tombol "Simpan")
-- Dipakai oleh: LibraryDAO.saveToLibrary() -> SaveServlet (/api/save)
-- ============================================================
CREATE TABLE IF NOT EXISTS `contents` (
    `id`           VARCHAR(500) NOT NULL,
    `judul`        VARCHAR(255) NOT NULL,
    `content_type` VARCHAR(20)  NOT NULL,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- 7. TABEL TAGS (genre dari hasil "Simpan")
-- ============================================================
CREATE TABLE IF NOT EXISTS `tags` (
    `content_id` VARCHAR(500) NOT NULL,
    `tag`        VARCHAR(100) NOT NULL,
    PRIMARY KEY (`content_id`, `tag`),
    FOREIGN KEY (`content_id`) REFERENCES `contents`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- 8. TABEL READING_HISTORY
-- (Sebenarnya sudah auto-create di HistoryServlet.init(),
--  tapi disertakan di sini agar setup lengkap dalam satu file)
-- ============================================================
CREATE TABLE IF NOT EXISTS `reading_history` (
    `id`            INT NOT NULL AUTO_INCREMENT,
    `manga_id`      VARCHAR(500) NOT NULL,
    `judul`         VARCHAR(255) NOT NULL,
    `gambar_sampul` TEXT,
    `tags`          VARCHAR(500),
    `waktu_baca`    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `manga_id` (`manga_id`(255))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- DATA CONTOH — agar tampilan "Ekstensi Komik" / "Ekstensi Novel"
-- tidak kosong saat pertama kali dibuka.
-- Silakan sesuaikan / hapus sesuai kebutuhan.
-- ============================================================

INSERT INTO `genres` (`nama_genre`) VALUES
    ('Action'), ('Adventure'), ('Comedy'), ('Drama'),
    ('Fantasy'), ('Romance'), ('Slice of Life')
ON DUPLICATE KEY UPDATE nama_genre = nama_genre;

-- Ekstensi komik contoh (mengarah ke MangaDex/Jikan via app sendiri,
-- jadi "url" di sini hanya informatif)
INSERT INTO `komik` (`name`, `lang`, `version`, `url`) VALUES
    ('MangaDex', 'en', '1.0.0', 'https://mangadex.org'),
    ('Komiku',   'id', '1.0.0', 'https://komiku.id');

-- Hubungkan genre contoh ke ekstensi komik pertama
INSERT INTO `komik_genres` (`komik_id`, `genre_id`)
SELECT k.id, g.id FROM `komik` k, `genres` g
WHERE k.name = 'MangaDex' AND g.nama_genre IN ('Action', 'Fantasy')
ON DUPLICATE KEY UPDATE komik_id = komik_id;

-- Ekstensi novel contoh
INSERT INTO `novel` (`id`, `name`, `site`, `lang`, `url`) VALUES
    ('novel-001', 'NovelUpdates', 'NovelUpdates', 'en', 'https://www.novelupdates.com');

INSERT INTO `novel_genres` (`novel_id`, `genre_id`)
SELECT n.id, g.id FROM `novel` n, `genres` g
WHERE n.id = 'novel-001' AND g.nama_genre IN ('Romance', 'Drama')
ON DUPLICATE KEY UPDATE novel_id = novel_id;
