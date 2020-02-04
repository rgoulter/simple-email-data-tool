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


def leaf_payloads_of_mail(m):
  if m.is_multipart():
    ms = [leaf_payloads_of_mail(p) for p in m.get_payload()]
    flattened = [item for sublist in ms for item in sublist]
    return flattened
  else:
    return [(m.get_content_subtype(), m)]


# returns dict with keys 'plain' or 'html'
def plaintext_payloads_of_mail(m):
  leaves = leaf_payloads_of_mail(m)
  return dict((ct, m.get_payload(decode=True)) for (ct, m) in leaves if m.get_content_maintype() == 'text')


def get_message_from_mbox(mbox, sender, timestamp):
  for message in mbox:
    fr = email_of_from(message['From'])
    dt = int(parse(message['Date']).timestamp())

    if (fr == sender and dt == int(timestamp)):
      return message

  return None


def has_plain(mbox, sender, timestamp):
  msg = get_message_from_mbox(mbox, sender, timestamp)

  if msg:
    payloads = plaintext_payloads_of_mail(msg)
    return "plain" in payloads

  return False


def has_html(mbox, sender, timestamp):
  msg = get_message_from_mbox(mbox, sender, timestamp)

  if msg:
    payloads = plaintext_payloads_of_mail(msg)
    return "html" in payloads

  return False


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


def fetch_email_info(conn, mbox, sender, timestamp):
  c = conn.cursor()
  c.execute('''
     SELECT from_email, date, strftime('%s', date) AS timestamp, subject, note
     FROM emails
     LEFT OUTER JOIN notes ON notes.email_id = emails.id
     WHERE from_email = ? AND timestamp = ?
  ''', (sender, str(timestamp)))
  (res_from_email, res_date, res_timestamp, res_subject, res_note) = c.fetchone()

  plaintext = has_plain(mbox, sender, timestamp)
  html = has_html(mbox, sender, timestamp)

  return {
    'from': res_from_email,
    'timestamp': int(res_timestamp),
    'datetime': res_date,
    'subject': res_subject,
    'plain': plaintext,
    'html': html,
    'note': res_note
  }


def fetch_emails_info(conn, mbox):
  c = conn.cursor()
  c.execute('''
     SELECT from_email, date, strftime('%s', date) AS timestamp, subject, note
     FROM emails
     LEFT OUTER JOIN notes ON notes.email_id = emails.id
  ''')

  rows = c.fetchall()
  result = []

  for row in rows:
    (res_from_email, res_date, res_timestamp, res_subject, res_note) = row

    plaintext = has_plain(mbox, sender, timestamp, subject)
    html = has_html(mbox, sender, timestamp, subject)

    result << {
       'from': res_from_email,
       'timestamp': int(res_timestamp),
       'datetime': res_date,
       'subject': res_subject,
       'plain': plaintext,
       'html': html,
       'note': res_note
      }

  return result




def update_note(conn, mbox, sender, timestamp, note):
  c = conn.cursor()
  c.execute('''
    INSERT INTO notes (email_id, note)
    VALUES ((SELECT id
             FROM emails
             WHERE from_email = ?
               AND strftime('%s', date) = ?),
            ?)
    ON CONFLICT(email_id) DO
      UPDATE
      SET note = ?
      WHERE email_id = (SELECT id
                        FROM emails
                        WHERE from_email = ?
                          AND strftime('%s', date) = ?)
  ''', (sender, str(timestamp), note, note, sender, str(timestamp)))
  conn.commit()

  return fetch_email_info(conn, mbox, sender, timestamp)
