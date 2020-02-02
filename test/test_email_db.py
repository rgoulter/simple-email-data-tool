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




if __name__ == '__main__':
    unittest.main()
