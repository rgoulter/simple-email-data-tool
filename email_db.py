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


def fetch_email_info(conn, mbox, sender, timestamp, subject):
  c = conn.cursor()
  c.execute('''
     SELECT from_email, date, strftime('%s', date) AS timestamp, subject, note
     FROM emails
     LEFT OUTER JOIN notes ON notes.email_id = emails.id
     WHERE from_email = ? AND timestamp = ? AND subject = ?
  ''', (sender, str(timestamp), subject))
  (res_from_email, res_date, res_timestamp, res_subject, res_note) = c.fetchone()

  has_plaintext = True # WIP
  has_html = False # WIP

  return {
    'from': res_from_email,
    'timestamp': int(res_timestamp),
    'datetime': res_date,
    'subject': res_subject,
    'plain': has_plaintext,
    'html': has_html,
    'note': res_note
  }




def update_note(conn, mbox, sender, timestamp, subject, note):
  c = conn.cursor()
  c.execute('''
    INSERT INTO notes (email_id, note)
    VALUES ((SELECT id
             FROM emails
             WHERE from_email = ?
               AND strftime('%s', date) = ?
               AND subject = ?),
            ?)
    ON CONFLICT(email_id) DO
      UPDATE
      SET note = ?
      WHERE email_id = (SELECT id
                        FROM emails
                        WHERE from_email = ?
                          AND strftime('%s', date) = ?
                          AND subject = ?)
  ''', (sender, str(timestamp), subject, note, note, sender, str(timestamp), subject))
  conn.commit()

  return fetch_email_info(conn, mbox, sender, timestamp, subject)
