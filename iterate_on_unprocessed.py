import jinja2
import mailbox
import os
import re
import sqlite3

from dateutil.parser import parse

def leaf_payloads_of_mail(m):
  if m.is_multipart():
    ms = [leaf_payloads_of_mail(p) for p in m.get_payload()]
    flattened = [item for sublist in ms for item in sublist]
    return flattened
  else:
    return [(m.get_content_type(), m)]

# returns dict with keys 'text/plain' or 'text/html'
def plaintext_payloads_of_mail(m):
  leaves = leaf_payloads_of_mail(m)
  return dict((ct, m.get_payload(decode=True)) for (ct, m) in leaves if ct.startswith('text'))

# A <B> => B
# <B>   => B
# B     => B
def email_of_from(from_str):
  match = re.search('(.*)<(.*)>', from_str)
  if match:
    return match.group(2)
  else:
    return from_str

def email_of_mail(m):
  return email_of_from(m['From'])

def filename_for_mail(m):
  dt = parse(m['Date'])
  datetime_str = dt.isoformat(timespec='seconds')
  subj = m['Subject']
  name = datetime_str + subj
  return "".join(x if x.isalnum() else "_" for x in name)

def dump_email_payloads(m):
  # output structure
  # dump/<domain>/<friendly>.{txt,html}
  email = email_of_mail(m)
  domain = email.split('@')[1]
  dirname = "dump/%s/" % (domain)
  os.makedirs(dirname, exist_ok = True)

  filename = filename_for_mail(m)
  payloads = plaintext_payloads_of_mail(m)
  filenames = {}

  if 'text/html' in payloads:
    payload = payloads['text/html']
    filenames['text/html'] = dirname + filename + ".html"
    f = open(filenames['text/html'], "wb")
    f.write(payload)
    f.close()

  if 'text/plain' in payloads:
    payload = payloads['text/plain']
    filenames['text/plain'] = dirname + filename + ".txt"
    f = open(filenames['text/plain'], "wb")
    f.write(payload)
    f.close()

  return filenames

def sql_for_manual_input(from_email, date, subject, plaintext = None, html = None):
  templateLoader = jinja2.FileSystemLoader(searchpath=".")
  templateEnv = jinja2.Environment(loader=templateLoader)
  template = templateEnv.get_template("manual_template.sql")

  templateVars = {
    "from_email": from_email,
    "date": date.isoformat(),
    "subject": subject,
    "plaintext": plaintext,
    "html": html,
  }

  return template.render(templateVars)


if __name__ == '__main__':
  print('opening mbox')
  mbox = mailbox.mbox('receipts.mbox')

  print('building list of tuples of emails')
  tuple_of_mail = lambda m: (email_of_from(m['From']), parse(m['Date']), m['Subject'])
  mbox_email_tuples = sorted(tuple_of_mail(m) for m in mbox.itervalues())

  # dict from (email, date, subj) -> Message
  mbox_email_dict = dict((tuple_of_mail(m), m) for m in mbox.itervalues())

  # for (e, d, s) in mbox_email_tuples:
  #   print("email: %s %s %s" % (e, d, s))

  print("%d emails in mbox" % (len(mbox_email_tuples)))

  # load mbox, summarise processed / not.

  print('connecting to DB')
  conn = sqlite3.connect('receipts.db')

  # 'SYNC' EMAILS BETWEEN MBOX AND DB:
  # 1. fetch emails from DB
  c = conn.cursor()
  c.execute('SELECT from_email, date, subject, receipt_id FROM emails')
  rows = c.fetchall()

  print("%d rows loaded from DB" % (len(rows)))

  # dict from (email, date, subj) -> Message
  db_email_dict = dict(((email, parse(date), subject), fk) for (email, date, subject, fk) in rows)

  # Count/WARN about emails in DB that are in DB but not in mbox
  if mbox_email_dict.keys() - db_email_dict.keys() == set():
    print("INFO: all mbox emails are in DB already")
  # XXX: other set comparisons/info

  # Insert all email tuples into DB
  # (DB has UNIQUE constraint on (date, from_email, subject))
  for (email, dt, subj) in mbox_email_tuples:
    domain = email.split('@')[1]
  c.executemany('''
    INSERT OR IGNORE INTO emails (date, from_host, from_email, subject)
    VALUES (?, ?, ?, ?)
  ''', [(dt.isoformat(), email.split('@')[1], email, subj) for (email, dt, subj) in mbox_email_tuples if True])
  conn.commit()

  # TO-PROCESS:
  # - emails which weren't in DB
  # - emails in DB which don't have receipt FK

  domains = set(e.split('@')[1] for (e, d, s) in mbox_email_dict.keys())

  # "Processed" = has `receipt` + `items` in the DB.
  # :: domain -> [(email, date, subject)]
  tuples_per_domain = dict((d, [(e, dt, s) for (e, dt, s) in mbox_email_tuples if e.split('@')[1] == d])
                           for d
                           in domains)

  sorted_tuples_per_domain = sorted(tuples_per_domain.items(),
                                    key=lambda t: len(t[1]))

  for (domain, tuples) in sorted_tuples_per_domain:
    # "Processed" = has "receipt"; so its `fk` isn't `None`.
    processed_tuples = [(e, dt, s) for (e, dt, s) in tuples if db_email_dict.get((e, dt, s), None) != None]
    unprocessed_tuples = [(e, dt, s) for (e, dt, s) in tuples if db_email_dict.get((e, dt, s), None) == None]

    print("%s has %d/%d emails processed" % (domain, len(processed_tuples), len(tuples)))

    # TODO: try scrapers on the unprocessed; use successful results

    if len(unprocessed_tuples) > 0:
      # For the unprocessed which fail scraping:
      if len(unprocessed_tuples) <= 12:
        # If only a handful of emails (12 or less), manually output an SQL file
        # to input receipt/items into the DB (and extract all plaintext/html
        sql = []
        for (e, dt, s) in unprocessed_tuples:
          m = mbox_email_dict[(e, dt, s)]

          filenames = dump_email_payloads(m)
          sql.append(sql_for_manual_input(e,
                                          dt,
                                          s,
                                          plaintext = filenames.get('text/plain', None),
                                          html = filenames.get('text/html', None)))

        f = open(domain + ".sql", "w")
        payload = "\n\n\n".join(sql)
        f.write(payload)
        f.close()
      else:
        # Otherwise, output the plaintext/html of the first email
        pass

  conn.close()
