-- Create Database
CREATE DATABASE mowise;
USE mowise;

-- Create Users table
CREATE TABLE users (
    user_id INT PRIMARY KEY AUTO_INCREMENT,
    user_name VARCHAR(100) NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL,
    balance INT DEFAULT 0,
    phone_number VARCHAR(20) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX index_email (email),
    INDEX index_phone (phone_number)
);

-- Create Transaction_categories table
CREATE TABLE transaction_categories (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    
    INDEX index_name (name)
);

-- Create Transactions table (acts as junction between users and categories)
CREATE TABLE transactions (
    transaction_id INT PRIMARY KEY AUTO_INCREMENT,
    currency VARCHAR(10) DEFAULT 'RWF',
    rawMessage TEXT,
    status ENUM('pending', 'completed', 'failed', 'cancelled') DEFAULT 'pending',
    category_id INT NOT NULL,
    receiver_id INT NOT NULL,
    sender_id INT NOT NULL,
    amount DECIMAL(15,2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (category_id) REFERENCES transaction_categories(id) ON DELETE RESTRICT,
    FOREIGN KEY (receiver_id) REFERENCES users(user_id) ON DELETE RESTRICT,
    FOREIGN KEY (sender_id) REFERENCES users(user_id) ON DELETE RESTRICT,
    
    INDEX index_sender (sender_id),
    INDEX index_receiver (receiver_id),
    INDEX index_category (category_id)
);

-- Create System_Logs table
CREATE TABLE system_logs (
    log_id INT PRIMARY KEY AUTO_INCREMENT,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    type ENUM('update_balance', 'transaction_record', 'transaction_update', 'unknown') DEFAULT 'unknown',
    status ENUM('success', 'failed', 'unknown') DEFAULT 'success',
    transaction_id INT,
    user_id INT,
    
    FOREIGN KEY (transaction_id) REFERENCES transactions(transaction_id) ON DELETE SET NULL,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE SET NULL,
    
    INDEX index_user (user_id)
);

-- Create User_category_junction table (for tracking user preferences/history with categories)
CREATE TABLE user_category_junction (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    category_id INT NOT NULL,
    frequency_count INT DEFAULT 1,
    total_amount INT DEFAULT 0,
    last_used_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (category_id) REFERENCES transaction_categories(id) ON DELETE CASCADE,
    
    UNIQUE KEY unique_user_category (user_id, category_id),
    INDEX idx_user_id (user_id),
    INDEX idx_category_id (category_id),
    INDEX idx_last_used (last_used_date)
);

-- Create triggers to update user_category_junction when transactions are inserted
DELIMITER //

CREATE TRIGGER update_user_category_stats
AFTER INSERT ON transactions
FOR EACH ROW
BEGIN
    INSERT INTO user_category_junction (user_id, category_id, frequency_count, total_amount, last_used_date)
    VALUES (NEW.sender_id, NEW.category_id, 1, NEW.amount, NEW.created_at)
    ON DUPLICATE KEY UPDATE
        frequency_count = frequency_count + 1,
        total_amount = total_amount + NEW.amount,
        last_used_date = NEW.created_at;
END//
DELIMITER ;
-- Trigger to update new balance after a transaction is completed; deduct if the user is the sender, add if receiver
DELIMITER //

CREATE TRIGGER update_user_balance
AFTER INSERT ON transactions
FOR EACH ROW
BEGIN
    IF NEW.status = 'completed' THEN
        UPDATE users SET balance = balance - (NEW.amount + 100) WHERE user_id = NEW.sender_id;
        UPDATE users SET balance = balance + NEW.amount WHERE user_id = NEW.receiver_id;
    END IF;
END//

DELIMITER ;

-- Insert sample transaction categories
INSERT INTO transaction_categories (name, description) VALUES
('Send Money', 'Transfer money to another user'),
('Electricity Bill', 'Utility and service bill payments'),
('Airtime Purchase', 'Mobile airtime top-up'),
('Data Bundle', 'Internet data bundle purchase'),
('Merchant Payment', 'Payment to registered merchants'),
('Bank Transfer', 'Transfer to bank account'),
('Deposit', 'Deposit cash to wallet'),
('Withdrawal', 'Withdraw cash from wallet');

-- Insert sample users
INSERT INTO users (user_name, email, phone_number, password, balance) VALUES
('Mordecai Nayituriki', 'mordecai@gmail.com', '+250720123456', 'hashed_password_1', 50000),
('Aime Cyuzuzo', 'aimecyuzuzo5@gmail.com', '+250783650846', 'hashed_password_2', 75000),
('Jean Philippe Niyitegeka', 'jeanphilippeperfect@gmail.com', '+250790987654', 'hashed_password_3', 25000),
('Lionel Karekezi', 'likarekezi@gmail.com', '+250780987654', 'hashed_password_3', 25000),
('Wakuma', 'wakuma@alu.com', '+250790987656', 'hashed_password_3', 25000);

INSERT INTO transactions (currency, rawMessage, status, category_id, receiver_id, sender_id, amount) VALUES
    (
    'RWF',
    '*165*S*1200 RWF transferred to Jean Philippe Niyitegeka (250790987654) from 22846752 at 2025-09-16 15:07:47 .Fee was: 100 RWF. New balance: 150000 RWF. To Buy Airtime or Bundles using MoMo, Dial *182*2*1# .*EN#',
    'completed', 1, 3, 2, 1200
    ),
    (
        'RWF',
        '*165*S*1200 RWF transferred to Lionel Karekezi (250780987654) from 22846752 at 2025-09-16 15:07:47 .Fee was: 100 RWF. New balance: 146700 RWF. To Buy Airtime or Bundles using MoMo, Dial *182*2*1# .*EN#',
        'completed', 1, 4, 2, 1200
    ),
    -- More examples with the same amount of money, to all users, with appropriate new balance
    (
        'RWF',
        '*165*S*5000 RWF transferred to Mordecai Nayituriki (250720123456) from 22846752 at 2025-09-16 15:07:47 .Fee was: 100 RWF. New balance: 141600 RWF. To Buy Airtime or Bundles using MoMo, Dial *182*2*1# .*EN#',
        'completed', 1, 1, 2, 5000
    ),
    (
        'RWF',
        '*165*S*3000 RWF transferred to Mordecai Nayituriki (250720123456) from 22846752 at 2025-09-16 15:07:47 .Fee was: 100 RWF. New balance: 138500 RWF. To Buy Airtime or Bundles using MoMo, Dial *182*2*1# .*EN#',
        'completed', 1, 1, 2, 3000
    ),
    (
        'RWF',
        '*165*S*2000 RWF transferred to Wakuma (250790987654) from 22846752 at 2025-09-16 15:07:47 .Fee was: 100 RWF. New balance: 136400 RWF. To Buy Airtime or Bundles using MoMo, Dial *182*2*1# .*EN#',
        'completed', 1, 5, 2, 2000
    );


INSERT INTO system_logs (type, status, transaction_id, user_id) VALUES
('transaction_record', 'success', 1, 2),
('transaction_record', 'success', 2, 2),
('transaction_record', 'success', 3, 2),
('transaction_record', 'success', 4, 2),
('transaction_record', 'success', 5, 2);

