import mailbox

from datetime import *

from dateutil.parser import parse

from dateutil.relativedelta import *

if __name__ == '__main__':
  in_mbox = mailbox.mbox('receipts.mbox')

  # e.g. 2020-W3 from 13th - 19th of January 2020
  iso_year = 2020
  iso_week = 3

  def mail_in_iso_week(iso_year, iso_week, mail):
    date = parse(mail['Date'])

    # Adapted from https://dateutil.readthedocs.io/en/stable/examples.html
    iso_week = datetime(iso_year, 1, 1, tzinfo=date.tzinfo) + relativedelta(weekday = MO(-1), weeks = +iso_week - 1)

    next_iso_week = iso_week + relativedelta(weeks = 1)

    return (date >= iso_week and date < next_iso_week)

  out_mbox = mailbox.mbox('filtered.mbox')
  out_mbox.lock()


  mails_in_week = [m for m in in_mbox.itervalues() if mail_in_iso_week(iso_year, iso_week, m)]
  for mail in mails_in_week:
    try:
      out_mbox.add(mail)
      out_mbox.flush()

      print("Adding %s %s %s" % (mail['Date'], mail['From'], mail['Subject']))

    except:
      pass

  out_mbox.unlock()
  out_mbox.close()
