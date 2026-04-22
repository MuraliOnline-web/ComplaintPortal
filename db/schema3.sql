-- Complaint Portal - Fresh Install Schema (MySQL)
-- Run this whole file to provision a fresh database with all changes included.

CREATE DATABASE IF NOT EXISTS complaint_portal;
USE complaint_portal;

-- Users table (citizens + officers + admin)
-- Password is NULLABLE so citizens don't need one
CREATE TABLE IF NOT EXISTS users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    mobile VARCHAR(15) NOT NULL,
    city_village VARCHAR(120),
    password VARCHAR(255) NULL,
    password_hash VARCHAR(255) NULL,
    password_salt VARCHAR(255) NULL,
    is_verified TINYINT(1) DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    role ENUM('user','officer','admin') DEFAULT 'user'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Complaints table (includes complaint_code for unique search)
CREATE TABLE IF NOT EXISTS complaints (
    complaint_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    category ENUM('WaterTap','Electricity','Road','Sanitation','Other') NOT NULL,
    description TEXT NOT NULL,
    address VARCHAR(255) NOT NULL,
    photo_path VARCHAR(255),
    status ENUM('Pending','Solving','Solved') DEFAULT 'Pending',
    officer_notes TEXT,
    solved_photo_path VARCHAR(255),
    officer_name VARCHAR(100),
    complaint_code VARCHAR(30) UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_complaints_user FOREIGN KEY (user_id) REFERENCES users(user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Notifications table
CREATE TABLE IF NOT EXISTS notifications (
    notify_id INT AUTO_INCREMENT PRIMARY KEY,
    complaint_id INT,
    user_id INT,
    message VARCHAR(255),
    sent_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_notif_complaint FOREIGN KEY (complaint_id) REFERENCES complaints(complaint_id),
    CONSTRAINT fk_notif_user FOREIGN KEY (user_id) REFERENCES users(user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- OTP table for email-based login verification
CREATE TABLE IF NOT EXISTS otp_codes (
    otp_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    channel ENUM('email') DEFAULT 'email',
    otp_hash VARCHAR(255) NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    attempts INT DEFAULT 0,
    consumed TINYINT(1) DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_otp_user FOREIGN KEY (user_id) REFERENCES users(user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Officer reports table (officer reports only; admin performs final complaint updates)
CREATE TABLE IF NOT EXISTS officer_reports (
    report_id INT AUTO_INCREMENT PRIMARY KEY,
    complaint_id INT NOT NULL,
    officer_name VARCHAR(100) NOT NULL,
    report_notes TEXT NOT NULL,
    report_photo_path VARCHAR(255),
    reported_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_officer_report_complaint FOREIGN KEY (complaint_id) REFERENCES complaints(complaint_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Do NOT seed default admin/officer credentials in source control.
-- Create privileged users manually per environment using strong unique passwords.
-- Example bootstrap SQL (replace placeholders before running):
-- INSERT INTO users (name, email, mobile, password, role)
-- VALUES ('Admin', 'REPLACE_ADMIN_EMAIL', 'REPLACE_ADMIN_MOBILE', 'REPLACE_STRONG_ADMIN_PASSWORD', 'admin')
-- ON DUPLICATE KEY UPDATE
--   name=VALUES(name),
--   mobile=VALUES(mobile),
--   password=VALUES(password),
--   role=VALUES(role);
--
-- INSERT INTO users (name, email, mobile, password, role)
-- VALUES ('Officer', 'REPLACE_OFFICER_EMAIL', 'REPLACE_OFFICER_MOBILE', 'REPLACE_STRONG_OFFICER_PASSWORD', 'officer')
-- ON DUPLICATE KEY UPDATE
--   name=VALUES(name),
--   mobile=VALUES(mobile),
--   password=VALUES(password),
--   role=VALUES(role);

USE complaint_portal;
UPDATE users SET password_hash='CrzCi8xMFl4NUOBbXjya8ynEUyycVM3gbDJhZIzDLMc=', password_salt='tE+ROrSahv2LeVWMsMB0Uw==', password=NULL WHERE user_id=1;
UPDATE users SET password_hash='mFmAs6Riy+XyaZXsxQ4cc5aK8OGVtwaZaSP6F0D7QtQ=', password_salt='HJ3NfmYCvyNapNcFNBFEsQ==', password=NULL WHERE user_id=10;
  
USE complaint_portal;
SELECT user_id, name, email, role, is_verified
FROM users
WHERE role IN ('admin','officer')
ORDER BY user_id;


USE complaint_portal;
UPDATE users SET password_hash='CrzCi8xMFl4NUOBbXjya8ynEUyycVM3gbDJhZIzDLMc=', password_salt='tE+ROrSahv2LeVWMsMB0Uw==', password=NULL WHERE user_id=1;
SELECT ROW_COUNT();

USE complaint_portal;
UPDATE users SET password_hash='mFmAs6Riy+XyaZXsxQ4cc5aK8OGVtwaZaSP6F0D7QtQ=', password_salt='HJ3NfmYCvyNapNcFNBFEsQ==', password=NULL WHERE user_id=10;
SELECT ROW_COUNT();

SELECT user_id, name, email, password, password_hash, password_salt FROM users WHERE user_id IN (1, 10);

USE complaint_portal;
START TRANSACTION;

SET SQL_SAFE_UPDATES = 0;

DELETE FROM notifications;
DELETE FROM officer_reports;
DELETE FROM otp_codes;
DELETE FROM complaints;

DELETE FROM users
WHERE role NOT IN ('admin','officer');

UPDATE users
SET email = LOWER(TRIM(email));

COMMIT;

SELECT user_id, name, email, role
FROM users
ORDER BY user_id;

USE complaint_portal;
SELECT email, COUNT(*) AS cnt
FROM users
GROUP BY email
HAVING COUNT(*) > 1;

UPDATE users
SET email = LOWER(TRIM(email));

ALTER TABLE users
DROP INDEX email;

ALTER TABLE users
ADD CONSTRAINT uq_users_email UNIQUE (email);

SHOW INDEX FROM users;

--Replaced Deomo mails with Original Mails.
SELECT * FROM complaint_portal.users;

-- Verify the changes
USE complaint_portal;
SELECT user_id, name, email, role FROM users WHERE role IN ('admin', 'officer');

-- Update Admin email
UPDATE users 
SET email = 'XXXXXXXXX.XXXXXX@gmail.com' 
WHERE role = 'admin' AND email = 'admin@portal.com'
LIMIT 1;

-- Update Officer email
UPDATE users 
SET email = 'XXXXXXXXX@gmail.com' 
WHERE role = 'officer' AND email = 'officer@portal.com'
LIMIT 1;

