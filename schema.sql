CREATE TABLE IF NOT EXISTS emails
(
  id int PRIMARY KEY,
  date DATETIME,
  from_host TEXT,
  from_email TEXT,
  subject TEXT
);

CREATE TABLE IF NOT EXISTS receipts
(
  id int PRIMARY KEY,
  email_id int NOT NULL,
  total DECIMAL(10,2) NOT NULL,
  currency TEXT NOT NULL,
  verified BOOLEAN DEFAULT 0,
  FOREIGN KEY (email_id) REFERENCES emails(id)
);
