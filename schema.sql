CREATE TABLE IF NOT EXISTS emails
(
  id INTEGER PRIMARY KEY,
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
  id INTEGER PRIMARY KEY,
  email_id INTEGER NOT NULL,
  total DECIMAL(10,2) NOT NULL,
  currency TEXT NOT NULL,
  verified BOOLEAN DEFAULT 0
);

CREATE TABLE IF NOT EXISTS items
(
  id INTEGER PRIMARY KEY,
  description TEXT,
  amount DECIMAL(10,2) NOT NULL,
  currency TEXT NOT NULL,
  receipt_id INTEGER,
  FOREIGN KEY (receipt_id) REFERENCES receipts(id)
);

CREATE TABLE IF NOT EXISTS notes
(
  email_id INTEGER PRIMARY_KEY UNIQUE,
  note TEXT NOT NULL,
  FOREIGN KEY (email_id) REFERENCES emails(id)
);
