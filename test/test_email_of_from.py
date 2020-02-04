import re
import unittest

from .context import email_db
from email_db import email_of_from




class TestEmailOfFrom(unittest.TestCase):
  def test_standard_case(self):
    s = 'foo@bar.com'
    self.assertEqual(email_of_from(s), 'foo@bar.com')


  def test_nameless_case(self):
    s = '<foo@baz.com>'
    self.assertEqual(email_of_from(s), 'foo@baz.com')


  def test_fancy_case(self):
    s = 'Foo Bar <foo2@bar.com>'
    self.assertEqual(email_of_from(s), 'foo2@bar.com')




if __name__ == '__main__':
  unittest.main()
