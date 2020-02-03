import mailbox
import sqlite3
import unittest

from .context import email_db




class TestFlaskApiMethods(unittest.TestCase):
  def setUp(self):
    self.mbox = mailbox.mbox('test/simple.mbox')

    self.conn = sqlite3.connect(':memory:')

    # create a DB file, load schema into it
    f = open('schema.sql', 'r')
    schema_sql = f.read()
    f.close()

    self.conn.executescript(schema_sql)
    self.conn.commit


  def tearDown(self):
    self.mbox.close()


  def test_mbox_has_one_email(self):
    self.assertEqual(len(self.mbox.values()), 1)


  def test_mbox_to_db(self):
    # ACT
    email_db.insert_mbox_into_connection(self.mbox, self.conn)

    # ASSERT
    c = self.conn.cursor()
    c.execute('SELECT from_email, date, subject FROM emails')
    rows = c.fetchall()

    self.assertEqual(len(rows), 1)
    (from_email, date, subject) = rows[0]
    self.assertEqual(from_email, "foo@bar.com")
    self.assertEqual(date, "2020-01-14T10:30:00+00:00")
    self.assertEqual(subject, "Test Email Message")


  def test_fetch_email_info(self):
    # ASSEMBLE
    email_db.insert_mbox_into_connection(self.mbox, self.conn)

    # ACT
    sender = 'foo@bar.com'
    timestamp = 1578997800
    subject = 'Test Email Message'
    note = 'new note'
    info = email_db.fetch_email_info(self.conn, self.mbox, sender, timestamp, subject)

    # ASSERT
    self.assertEqual(info['timestamp'], timestamp)


  def test_update_notes(self):
    # ASSEMBLE
    email_db.insert_mbox_into_connection(self.mbox, self.conn)

    # ACT
    sender = 'foo@bar.com'
    timestamp = 1578997800
    subject = 'Test Email Message'
    note = 'new note'
    email_db.update_note(self.conn, self.mbox, sender, timestamp, subject, note)

    # ASSERT
    info = email_db.fetch_email_info(self.conn, self.mbox, sender, timestamp, subject)
    self.assertEqual(info['note'], 'new note')


  # The first time note updates is probably an INSERT.
  # This test checks the note can be updated after an INSERT is made.
  def test_update_notes_twice(self):
    # ASSEMBLE
    email_db.insert_mbox_into_connection(self.mbox, self.conn)

    # ACT
    sender = 'foo@bar.com'
    timestamp = 1578997800
    subject = 'Test Email Message'
    note = 'new note'
    email_db.update_note(self.conn, self.mbox, sender, timestamp, subject, 'x')
    email_db.update_note(self.conn, self.mbox, sender, timestamp, subject, note)

    # ASSERT
    info = email_db.fetch_email_info(self.conn, self.mbox, sender, timestamp, subject)
    self.assertEqual(info['note'], 'new note')




if __name__ == '__main__':
    unittest.main()
