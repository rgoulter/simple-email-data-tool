import imaplib
import mailbox

if __name__ == '__main__':
  f = open("gmail.password", "r")
  lines = f.readlines()
  username, pwd = (lines[0].strip(), lines[1].strip())
  mail = imaplib.IMAP4_SSL("imap.gmail.com")
  mail.login(username, pwd)

  # i.e. label:receipt
  mail.select('Receipt')

  mbox = mailbox.mbox('receipts.mbox')

  typ, data = mail.search(None, 'ALL')

  for num in data[0].split():
      print('fetching %s\n' % (num))
      typ, data = mail.fetch(num, '(RFC822)')
      mbox.lock()
      mbox.add(data[0][1])
      mbox.flush()
      mbox.unlock()

  mail.close()
  mail.logout()
