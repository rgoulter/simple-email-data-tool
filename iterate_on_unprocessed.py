import mailbox
import re
import sqlite3

from dateutil.parser import parse

# A <B> => B
# <B>   => B
# B     => B
def email_of_from(from_str):
  match = re.search('(.*)<(.*)>', from_str)
  if match:
    return match.group(2)
  else:
    return from_str

if __name__ == '__main__':
  print('opening mbox')
  mbox = mailbox.mbox('receipts.mbox')

  print('building list of tuples of emails')
  email_tuples = sorted((email_of_from(m['From']), parse(m['Date']), m['Subject']) for m in mbox.itervalues())

  for (e, d, s) in email_tuples:
    print("email: %s %s %s" % (e, d, s))

  print("%d emails in mbox" % (len(email_tuples)))

  # load mbox, summarise processed / not.

  # conn = sqlite3.connect('receipts.db')

  # EMAILS: 
  # XXX: Fetch all 'emails' (and count of those emails with receipts) from DB
  # XXX: Count/WARN about emails in DB that are in DB but not in mbox
  # XXX: insert all email tuples into DB


  # XXX: emails which aren't recorded (with items) in the DB:

  # XXX:
  # extract text/html, text/plain from the messages
  #   N.B., some emails have mimetype text/plain, text/html or maybe multipart/mixed
  #     some multipart/mixed have payloads with multipart/alternative,
  #     and so the text/html (or text/plain) is nested (somewhere?) in this.

  # XXX:
  # - dump the payload in a friendly format.
  #   - dump `text/html` part HTML in some dir structure
  #   - dump the text same way;

  # TODO:
  # - try parsing it for each case; input with 'by=parser' or whatever
  #   for successful cases

  # "For the stuff which didn't succeed":

  # - generate SQL INSERT for what it would take to input receipts/items
  #   for a handful of emails (good for "3 emails" or whatever)

  # - go from: smallest (with manual), to largest (which benefit from parser)
