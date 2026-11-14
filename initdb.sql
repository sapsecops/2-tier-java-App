CREATE DATABASE employeedb;
CREATE USER appuser WITH PASSWORD 'P@55Word';
GRANT ALL PRIVILEGES ON DATABASE employeedb TO appuser;
\c employeedb;
CREATE TABLE employee (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL,
    designation VARCHAR(100) NOT NULL,
    salary NUMERIC(10,2) NOT NULL
);
GRANT SELECT, INSERT, UPDATE, DELETE ON employee TO appuser;
GRANT USAGE ON SCHEMA public TO appuser;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO appuser;
-- Inserting Dummy DATA in Table
INSERT INTO employee (name, email, designation, salary) VALUES
('Venkatesh', 'venkatesh@example.com', 'DevSecOps Engineer', 75000.00),
('Chaitanya', 'chaitanya@example.com', 'Jr DevOps Engineer', 68000.00),
('Padol', 'padol@example.com', 'SAP Developer', 72000.00),
('Pandu', 'pandu@example.com', 'System Analyst', 90000.00),
('Ganesh', 'ganesh@example.com', 'Manager', 65000.00);

SELECT * FROM employee;
