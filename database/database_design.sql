CREATE DATABASE mowise;
USE mowise;

-- Users table
CREATE TABLE users (
    user_id INT PRIMARY KEY AUTO_INCREMENT,
    user_name VARCHAR(100) NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL,
    balance INT DEFAULT 0,
    phone_number VARCHAR(20) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
);

-- Transaction_categories
CREATE TABLE transaction_categories (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
);

CREATE TABLE people (
    person_id INT PRIMARY KEY AUTO_INCREMENT,
    names VARCHAR(50) NOT NULL,
    phone_number VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    user_id INT NOT NULL,
);

-- Transactions table
CREATE TABLE transactions (
    transaction_id INT PRIMARY KEY AUTO_INCREMENT,
    currency VARCHAR(10) DEFAULT 'RWF',
    rawMessage TEXT,
    status ENUM('pending', 'completed', 'failed', 'cancelled') DEFAULT 'pending',
    amount DECIMAL(15,2) NOT NULL,
    new_balance INT,
    category_id INT NOT NULL,
    person_id INT,
    user_id INT NOT NULL,
    sent BOOLEAN NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (category_id) REFERENCES transaction_categories(id) ON DELETE RESTRICT,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE RESTRICT,
    FOREIGN KEY (person_id) REFERENCES people(person_id) ON DELETE RESTRICT,
    
    INDEX user_id (user_id),
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

-- User_category_junction table
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
);

-- Create triggers to update user_category_junction when transactions are inserted
DELIMITER //

CREATE TRIGGER update_user_category_stats
AFTER INSERT ON transactions
FOR EACH ROW
BEGIN
    INSERT INTO user_category_junction (user_id, category_id, frequency_count, total_amount, last_used_date)
    VALUES (NEW.user_id, NEW.category_id, 1, NEW.amount, NEW.created_at)
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
    -- Add balance from this transaction's new_balance to user with matching user_id regardless of having sent or received
        UPDATE users
        SET balance = NEW.new_balance
        WHERE user_id = NEW.user_id;
        
        -- Log the balance update action
        INSERT INTO system_logs (type, status, transaction_id, user_id)
        VALUES ('update_balance', 'success', NEW.transaction_id, NEW.user_id);
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
('Jean Philippe Niyitegeka', 'niyitegeka@gmail.com', '+250790987654', 'hashed_password_2', 100000),
('Aime Cyuzuzo', 'cyuzuzo@gmail.com', '+250783650846', 'hashed_password_3', 150000),
('Lionel Karekezi', 'karekezi@gmail.com', '+250780987654', 'hashed_password_4', 146700),
('Wakuma', 'wakuma@gmail.com', '+250790987656', 'hashed_password_5', 0);

-- Insert sample people. Note that people in this table are linked to users that added them, so user_id is required. We are adding 2 people per user for demonstration.
INSERT INTO people (names, phone_number, user_id) VALUES
('Mordecai Nayituriki', '+250720123456', 2),
('Alice Uwase', '+250788123456', 2),
('Jean Philippe Niyitegeka', '+250790987654', 1),
('Alice Mukamana', '+250789654321', 1),
('Aime Cyuzuzo', '+250783650846', 3),
('Ngoga Ndoli', '+250782345678', 3),
('Lionel Karekezi', '+250780987654', 4),
('Diane Uwera', '+250781234567', 4),
('Wakuma', '+250790987656', 5),
('Eve Sogokuru', '+250785678901', 5);


-- Insert sample transactions. Note that person_id and user_id must correspond to existing entries in people and users tables; and each user can only transact with people they have added.
INSERT INTO transactions (currency, rawMessage, status, amount, new_balance, category_id, person_id, user_id, sent) VALUES
('RWF', 'Sent 1000 RWF to +250720123456', 'completed', 1000, 49000, 1, 1, 2, TRUE),
('RWF', 'Received 2000 RWF from +250790987654', 'completed', 2000, 102000, 1, 3, 1, FALSE),
('RWF', 'Paid 5000 RWF for Electricity Bill to +250788123456', 'completed', 5000, 95000, 2, 2, 2, TRUE),
('RWF', 'Bought Airtime of 3000 RWF for +250789654321', 'completed', 3000, 97000, 3, 4, 1, TRUE),
('RWF', 'Sent 1500 RWF to +250783650846', 'completed', 1500, 148500, 1, 5, 3, TRUE),
('RWF', 'Received 2500 RWF from +250781234567', 'completed', 2500, 149000, 1, 8, 4, FALSE),
('RWF', 'Withdrew 2000 RWF', 'completed', 2000, 146000, 8, NULL, 4, TRUE),
('RWF', 'Deposited 5000 RWF', 'completed', 5000, 5000, 7, NULL, 5, FALSE);



INSERT INTO system_logs (type, status, transaction_id, user_id) VALUES
('transaction_record', 'success', 1, 2),
('transaction_record', 'success', 2, 2),
('transaction_record', 'success', 3, 2),
('transaction_record', 'success', 4, 2),
('transaction_record', 'success', 5, 2);