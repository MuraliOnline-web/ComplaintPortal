USE complaint_portal;

-- Users table enhancements for account-based user login
ALTER TABLE users ADD COLUMN city_village VARCHAR(120);
ALTER TABLE users ADD COLUMN password_hash VARCHAR(255) NULL;
ALTER TABLE users ADD COLUMN password_salt VARCHAR(255) NULL;
ALTER TABLE users ADD COLUMN is_verified TINYINT(1) DEFAULT 0;
ALTER TABLE users ADD COLUMN created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;

-- OTP verification table (email-only, zero-cost)
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

-- Officer reporting table (no complaint CRUD by officer)
CREATE TABLE IF NOT EXISTS officer_reports (
	report_id INT AUTO_INCREMENT PRIMARY KEY,
	complaint_id INT NOT NULL,
	officer_name VARCHAR(100) NOT NULL,
	report_notes TEXT NOT NULL,
	report_photo_path VARCHAR(255),
	reported_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	CONSTRAINT fk_officer_report_complaint FOREIGN KEY (complaint_id) REFERENCES complaints(complaint_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Mark existing admin/officer records as verified
UPDATE users SET is_verified = 1 WHERE role IN ('admin', 'officer');
