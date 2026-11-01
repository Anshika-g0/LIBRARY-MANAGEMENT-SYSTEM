-- =====================================================
-- LIBRARY MANAGEMENT SYSTEM - DBMS MINI PROJECT
-- Name    : Anshika
-- UID     : 25BCD10154
-- Section : BCD-3(A)
-- College : Chandigarh University
-- Database: MySQL 8.0
-- Run this whole file in MySQL Workbench (Ctrl+Shift+Enter)
-- =====================================================

DROP DATABASE IF EXISTS library_db;
CREATE DATABASE library_db;
USE library_db;

-- =====================================================
-- 1. TABLE CREATION (DDL)
-- =====================================================

CREATE TABLE Category (
    category_id   INT PRIMARY KEY AUTO_INCREMENT,
    category_name VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE Author (
    author_id   INT PRIMARY KEY AUTO_INCREMENT,
    author_name VARCHAR(80) NOT NULL,
    country     VARCHAR(50)
);

CREATE TABLE Book (
    book_id          INT PRIMARY KEY AUTO_INCREMENT,
    title            VARCHAR(150) NOT NULL,
    isbn             VARCHAR(20) UNIQUE,
    category_id      INT,
    author_id        INT,
    publisher        VARCHAR(80),
    year_published   YEAR,
    total_copies     INT NOT NULL CHECK (total_copies >= 0),
    available_copies INT NOT NULL CHECK (available_copies >= 0),
    FOREIGN KEY (category_id) REFERENCES Category(category_id),
    FOREIGN KEY (author_id)   REFERENCES Author(author_id)
);

CREATE TABLE Member (
    member_id         INT PRIMARY KEY AUTO_INCREMENT,
    name              VARCHAR(80) NOT NULL,
    email             VARCHAR(100) UNIQUE,
    phone             VARCHAR(15),
    address           VARCHAR(150),
    join_date         DATE DEFAULT (CURRENT_DATE),
    membership_status ENUM('Active','Inactive') DEFAULT 'Active'
);

CREATE TABLE Staff (
    staff_id INT PRIMARY KEY AUTO_INCREMENT,
    name     VARCHAR(80) NOT NULL,
    role     VARCHAR(40),
    email    VARCHAR(100) UNIQUE,
    phone    VARCHAR(15)
);

CREATE TABLE Issue (
    issue_id    INT PRIMARY KEY AUTO_INCREMENT,
    book_id     INT NOT NULL,
    member_id   INT NOT NULL,
    staff_id    INT,
    issue_date  DATE NOT NULL,
    due_date    DATE NOT NULL,
    return_date DATE,
    fine_amount DECIMAL(8,2) DEFAULT 0,
    FOREIGN KEY (book_id)   REFERENCES Book(book_id),
    FOREIGN KEY (member_id) REFERENCES Member(member_id),
    FOREIGN KEY (staff_id)  REFERENCES Staff(staff_id)
);

-- =====================================================
-- 2. SAMPLE DATA (DML)
-- =====================================================

INSERT INTO Category (category_name) VALUES
('Computer Science'), ('Fiction'), ('Mathematics'), ('Physics');

INSERT INTO Author (author_name, country) VALUES
('Abraham Silberschatz', 'USA'),
('Ramez Elmasri', 'USA'),
('R. K. Narayan', 'India'),
('R. S. Aggarwal', 'India'),
('H. C. Verma', 'India');

INSERT INTO Book (title, isbn, category_id, author_id, publisher, year_published, total_copies, available_copies) VALUES
('Database System Concepts',         '9780078022159', 1, 1, 'McGraw Hill',    2019, 5, 5),
('Fundamentals of Database Systems', '9780133970777', 1, 2, 'Pearson',        2016, 4, 4),
('Malgudi Days',                     '9780143039655', 2, 3, 'Penguin',        2006, 3, 2),
('Quantitative Aptitude',            '9788121924986', 3, 4, 'S. Chand',       2020, 6, 5),
('Concepts of Physics',              '9788177091878', 4, 5, 'Bharati Bhawan', 2018, 4, 4);

INSERT INTO Member (name, email, phone, address) VALUES
('Anshika',     'anshika@example.com', '9876500001', 'Mohali, Punjab'),
('Riya Sharma', 'riya@example.com',    '9876500002', 'Chandigarh'),
('Aman Verma',  'aman@example.com',    '9876500003', 'Kharar, Punjab'),
('Simran Kaur', 'simran@example.com',  '9876500004', 'Ludhiana, Punjab'),
('Karan Singh', 'karan@example.com',   '9876500005', 'Zirakpur, Punjab');

INSERT INTO Staff (name, role, email, phone) VALUES
('Mr. Gupta', 'Librarian',           'gupta@library.com', '9811100001'),
('Ms. Mehta', 'Assistant Librarian', 'mehta@library.com', '9811100002');

-- Issue rows are inserted BEFORE the triggers are created, so available_copies
-- above already reflects the two books that are currently issued.
INSERT INTO Issue (book_id, member_id, staff_id, issue_date, due_date, return_date, fine_amount) VALUES
(1, 1, 1, '2026-10-01', '2026-10-15', '2026-10-14', 0),
(2, 2, 1, '2026-10-05', '2026-10-19', '2026-10-25', 12),
(3, 3, 2, '2026-10-20', '2026-11-03', NULL,         0),
(4, 4, 2, '2026-10-22', '2026-11-05', NULL,         0);

-- =====================================================
-- 3. VIEWS
-- =====================================================

CREATE VIEW available_books AS
SELECT book_id, title, available_copies
FROM Book
WHERE available_copies > 0;

CREATE VIEW current_issues AS
SELECT i.issue_id, m.name AS member_name, b.title, i.issue_date, i.due_date
FROM Issue i
JOIN Member m ON i.member_id = m.member_id
JOIN Book b   ON i.book_id = b.book_id
WHERE i.return_date IS NULL;

-- =====================================================
-- 4. TRIGGERS
-- =====================================================

DELIMITER //

-- Reduce available copies when a book is issued
CREATE TRIGGER after_issue_insert
AFTER INSERT ON Issue
FOR EACH ROW
BEGIN
    UPDATE Book
    SET available_copies = available_copies - 1
    WHERE book_id = NEW.book_id;
END //

-- On return: increase stock and calculate fine (Rs. 2 per late day)
CREATE TRIGGER before_issue_return
BEFORE UPDATE ON Issue
FOR EACH ROW
BEGIN
    IF OLD.return_date IS NULL AND NEW.return_date IS NOT NULL THEN
        IF NEW.return_date > OLD.due_date THEN
            SET NEW.fine_amount = DATEDIFF(NEW.return_date, OLD.due_date) * 2;
        END IF;
        UPDATE Book
        SET available_copies = available_copies + 1
        WHERE book_id = OLD.book_id;
    END IF;
END //

-- =====================================================
-- 5. STORED PROCEDURE
-- =====================================================

CREATE PROCEDURE issue_book(IN p_book INT, IN p_member INT, IN p_staff INT)
BEGIN
    DECLARE copies INT;
    SELECT available_copies INTO copies FROM Book WHERE book_id = p_book;

    IF copies > 0 THEN
        INSERT INTO Issue (book_id, member_id, staff_id, issue_date, due_date)
        VALUES (p_book, p_member, p_staff, CURRENT_DATE,
                DATE_ADD(CURRENT_DATE, INTERVAL 14 DAY));
        SELECT 'Book issued successfully' AS message;
    ELSE
        SELECT 'Book not available' AS message;
    END IF;
END //

DELIMITER ;

-- =====================================================
-- 6. SQL QUERIES
-- =====================================================

-- Q1. All books with author, category and available copies
SELECT b.book_id, b.title, a.author_name, c.category_name, b.available_copies
FROM Book b
JOIN Author a   ON b.author_id = a.author_id
JOIN Category c ON b.category_id = c.category_id;

-- Q2. Books currently issued (not yet returned)
SELECT i.issue_id, b.title, m.name AS member, i.issue_date, i.due_date
FROM Issue i
JOIN Book b   ON i.book_id = b.book_id
JOIN Member m ON i.member_id = m.member_id
WHERE i.return_date IS NULL;

-- Q3. Overdue books as on 10 November 2026
SELECT m.name, b.title, i.due_date,
       DATEDIFF('2026-11-10', i.due_date) AS days_overdue
FROM Issue i
JOIN Member m ON i.member_id = m.member_id
JOIN Book b   ON i.book_id = b.book_id
WHERE i.return_date IS NULL AND i.due_date < '2026-11-10';

-- Q4. Number of titles and copies in each category
SELECT c.category_name, COUNT(b.book_id) AS total_titles,
       SUM(b.total_copies) AS total_copies
FROM Category c
LEFT JOIN Book b ON c.category_id = b.category_id
GROUP BY c.category_name;

-- Q5. Most frequently issued books
SELECT b.title, COUNT(i.issue_id) AS times_issued
FROM Book b
JOIN Issue i ON b.book_id = i.book_id
GROUP BY b.title
ORDER BY times_issued DESC;

-- Q6. Borrowing history of member Anshika
SELECT m.name, b.title, i.issue_date, i.return_date
FROM Member m
JOIN Issue i ON m.member_id = i.member_id
JOIN Book b  ON i.book_id = b.book_id
WHERE m.name = 'Anshika';

-- Q7. Members who have never borrowed a book (subquery)
SELECT name FROM Member
WHERE member_id NOT IN (SELECT member_id FROM Issue);

-- Q8. Search books by keyword
SELECT title, publisher FROM Book WHERE title LIKE '%Database%';

-- Q9. Update phone number of a member
UPDATE Member SET phone = '9999900001' WHERE member_id = 1;

-- Q10. Delete inactive members who have no issue records
DELETE FROM Member
WHERE membership_status = 'Inactive'
  AND member_id NOT IN (SELECT member_id FROM Issue);

-- Q11. Total fine collected
SELECT SUM(fine_amount) AS total_fine FROM Issue;

-- Views
SELECT * FROM available_books;
SELECT * FROM current_issues;

-- =====================================================
-- 7. TESTING TRIGGERS AND PROCEDURE
-- =====================================================

-- Test 1: issue book 5 (Concepts of Physics) to Anshika -> copies 4 becomes 3
SELECT book_id, title, available_copies FROM Book WHERE book_id = 5;
CALL issue_book(5, 1, 2);
SELECT book_id, title, available_copies FROM Book WHERE book_id = 5;

-- Test 2: return that book 20 days after issue (6 days late) -> fine = 12.00, copies back to 4
UPDATE Issue
SET return_date = DATE_ADD(issue_date, INTERVAL 20 DAY)
WHERE issue_id = 5;
SELECT issue_id, due_date, return_date, fine_amount FROM Issue WHERE issue_id = 5;
SELECT book_id, title, available_copies FROM Book WHERE book_id = 5;

-- Test 3: constraint violations (each of these should show an ERROR - that is expected)
-- INSERT INTO Book (title, isbn, category_id, author_id, total_copies, available_copies)
--     VALUES ('Test Book', '123', 1, 1, -1, 0);                       -- CHECK fails
-- INSERT INTO Issue (book_id, member_id, issue_date, due_date)
--     VALUES (99, 1, '2026-11-01', '2026-11-15');                     -- FOREIGN KEY fails
-- DELETE FROM Book WHERE book_id = 1;                                 -- referenced by Issue

-- =====================================================
-- END OF FILE
-- =====================================================
