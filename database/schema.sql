CREATE DATABASE IF NOT EXISTS investicash CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE investicash;
CREATE TABLE users (
 id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY, name VARCHAR(120) NOT NULL,
 email VARCHAR(190) NOT NULL UNIQUE, phone VARCHAR(30) NULL, password_hash VARCHAR(255) NOT NULL,
 referral_code VARCHAR(32) NOT NULL UNIQUE, sponsor_id BIGINT UNSIGNED NULL,
 role ENUM('member','admin') NOT NULL DEFAULT 'member',
 status ENUM('pending_payment','active','suspended') NOT NULL DEFAULT 'pending_payment',
 payment_verified_at DATETIME NULL, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
 CONSTRAINT fk_sponsor FOREIGN KEY(sponsor_id) REFERENCES users(id) ON DELETE SET NULL,
 INDEX(sponsor_id), INDEX(status)
) ENGINE=InnoDB;
CREATE TABLE activation_payments (
 id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY, user_id BIGINT UNSIGNED NOT NULL UNIQUE,
 amount BIGINT UNSIGNED NOT NULL DEFAULT 1500, currency CHAR(3) NOT NULL DEFAULT 'XAF',
 provider VARCHAR(60) NOT NULL DEFAULT 'Maketou', checkout_url VARCHAR(500) NOT NULL,
 provider_reference VARCHAR(190) NULL UNIQUE,
 status ENUM('pending','verified','rejected') NOT NULL DEFAULT 'pending',
 verified_by BIGINT UNSIGNED NULL, verified_at DATETIME NULL, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
 FOREIGN KEY(user_id) REFERENCES users(id), FOREIGN KEY(verified_by) REFERENCES users(id),
 INDEX(status,created_at)
) ENGINE=InnoDB;
CREATE TABLE products (
 id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY, name VARCHAR(180) NOT NULL, description TEXT NULL,
 price BIGINT UNSIGNED NOT NULL, currency CHAR(3) NOT NULL DEFAULT 'XAF',
 status ENUM('draft','active','archived') NOT NULL DEFAULT 'draft', created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;
CREATE TABLE orders (
 id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY, order_number VARCHAR(40) NOT NULL UNIQUE,
 buyer_id BIGINT UNSIGNED NOT NULL, product_id BIGINT UNSIGNED NOT NULL,
 product_name_snapshot VARCHAR(180) NOT NULL, amount BIGINT UNSIGNED NOT NULL, currency CHAR(3) NOT NULL,
 status ENUM('pending','paid','fulfilled','refunded','cancelled') NOT NULL DEFAULT 'pending',
 paid_at DATETIME NULL, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
 FOREIGN KEY(buyer_id) REFERENCES users(id), FOREIGN KEY(product_id) REFERENCES products(id),
 INDEX(status,created_at)
) ENGINE=InnoDB;
CREATE TABLE payment_events (
 id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY, provider VARCHAR(60) NOT NULL,
 provider_event_id VARCHAR(190) NOT NULL, order_id BIGINT UNSIGNED NULL, event_type VARCHAR(60) NOT NULL,
 verification_status ENUM('received','verified','rejected') NOT NULL DEFAULT 'received',
 payload_hash CHAR(64) NULL, received_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, processed_at DATETIME NULL,
 UNIQUE(provider,provider_event_id), FOREIGN KEY(order_id) REFERENCES orders(id)
) ENGINE=InnoDB;
CREATE TABLE commissions (
 id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY, order_id BIGINT UNSIGNED NOT NULL,
 beneficiary_id BIGINT UNSIGNED NOT NULL, level TINYINT UNSIGNED NOT NULL,
 rate_basis_points SMALLINT UNSIGNED NOT NULL, base_amount BIGINT UNSIGNED NOT NULL,
 amount BIGINT UNSIGNED NOT NULL, currency CHAR(3) NOT NULL,
 status ENUM('pending','available','paid','reversed') NOT NULL DEFAULT 'pending',
 created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
 UNIQUE(order_id,beneficiary_id,level), FOREIGN KEY(order_id) REFERENCES orders(id),
 FOREIGN KEY(beneficiary_id) REFERENCES users(id), CHECK(level BETWEEN 1 AND 3),
 INDEX(beneficiary_id,status)
) ENGINE=InnoDB;
CREATE TABLE withdrawals (
 id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY, user_id BIGINT UNSIGNED NOT NULL,
 amount BIGINT UNSIGNED NOT NULL, currency CHAR(3) NOT NULL, method VARCHAR(40) NOT NULL,
 destination_encrypted TEXT NOT NULL,
 status ENUM('pending','approved','processing','paid','rejected','failed') NOT NULL DEFAULT 'pending',
 provider_reference VARCHAR(190) NULL UNIQUE, reviewed_by BIGINT UNSIGNED NULL, reviewed_at DATETIME NULL,
 created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, FOREIGN KEY(user_id) REFERENCES users(id),
 FOREIGN KEY(reviewed_by) REFERENCES users(id), INDEX(status,created_at)
) ENGINE=InnoDB;
CREATE TABLE wallet_transactions (
 id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY, user_id BIGINT UNSIGNED NOT NULL,
 commission_id BIGINT UNSIGNED NULL, withdrawal_id BIGINT UNSIGNED NULL,
 transaction_type ENUM('commission_credit','withdrawal_debit','refund_reversal','admin_adjustment') NOT NULL,
 amount BIGINT NOT NULL, currency CHAR(3) NOT NULL, idempotency_key VARCHAR(190) NOT NULL UNIQUE,
 description VARCHAR(255) NOT NULL, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
 FOREIGN KEY(user_id) REFERENCES users(id), FOREIGN KEY(commission_id) REFERENCES commissions(id),
 FOREIGN KEY(withdrawal_id) REFERENCES withdrawals(id), INDEX(user_id,created_at)
) ENGINE=InnoDB;
CREATE TABLE admin_logs (
 id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY, admin_id BIGINT UNSIGNED NOT NULL,
 action VARCHAR(100) NOT NULL, target_id BIGINT UNSIGNED NULL, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
 FOREIGN KEY(admin_id) REFERENCES users(id), INDEX(created_at)
) ENGINE=InnoDB;
