import datetime
import mailbox
import re
import sqlite3

from dateutil.parser import parse

from typing import NamedTuple


class Email(NamedTuple):
  sender: str
  datetimetz: datetime.datetime
  subject: str


# A <B> => B
# <B>   => B
# B     => B
def email_of_from(from_str):
  match = re.search('(.*)<(.*)>', from_str)
  if match:
    return match.group(2)
  else:
    return from_str


def namedtuple_from_mbox_mail(m):
  sender = email_of_from(m['From'])
  datetimetz = parse(m['Date'])
  subject = str(m['Subject'])

  return Email(sender = sender, datetimetz = datetimetz, subject = subject)


def insert_mbox_into_connection(mbox, conn):
  tuples = [namedtuple_from_mbox_mail(m) for m in mbox.itervalues()]

  c = conn.cursor()
  c.executemany('''
    INSERT OR IGNORE INTO emails (date, from_host, from_email, subject)
    VALUES (?, ?, ?, ?)
  ''', [(email.datetimetz.isoformat(), email.sender.split('@')[1], email.sender, email.subject) for email in tuples])
  conn.commit()
