CREATE TABLE IF NOT EXISTS emails
(
  id INT PRIMARY KEY,
  date DATETIME,
  from_host TEXT,
  from_email TEXT,
  subject TEXT,
  receipt_id INT,
  FOREIGN KEY (receipt_id) REFERENCES receipts(id),
  UNIQUE (date, from_email, subject)
);

CREATE TABLE IF NOT EXISTS receipts
(
  id INT PRIMARY KEY,
  email_id INT NOT NULL,
  total DECIMAL(10,2) NOT NULL,
  currency TEXT NOT NULL,
  verified BOOLEAN DEFAULT 0
);

CREATE TABLE IF NOT EXISTS items
(
  id INT PRIMARY KEY,
  description TEXT,
  amount DECIMAL(10,2) NOT NULL,
  currency TEXT NOT NULL,
  receipt_id INT,
  FOREIGN KEY (receipt_id) REFERENCES receipts(id)
);
