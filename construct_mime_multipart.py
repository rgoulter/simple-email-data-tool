from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText

import email.message

import mailbox




def message_with_plain():
  simple = email.message.EmailMessage()
  simple["Subject"] = "Foo Bar"
  simple["From"] = "Foo Bar <foo@bar.com>"
  simple["Date"] = "Tue, 01 Jan 2019 12:00:00 +0000"

  simple.set_content("Hi,\n\nFirst message.\n\nRegards,\nSender")

  return simple



def message_with_html_and_plain():
  html = """
  <!DOCTYPE HTML>
<html>
  <body>
    <p>Hi,</p>
    <p>Second message.</p>
    <p>Regards,<br/>Sender</p>
  </body>
</html>
  """
  msgText = MIMEText("Hi\n\nSecond message.\n\nRegards,\nSender")

  msgHtml = MIMEText(html, 'html')

  msgRelated = MIMEMultipart('related')
  msgRelated.attach(msgHtml)

  # Encapsulate the plain and HTML versions of the message body in an
  # 'alternative' part, so message agents can decide which they want to display.
  msgAlternative = MIMEMultipart('alternative')
  msgAlternative.attach(msgText)
  msgAlternative.attach(msgRelated)

  # mixed
  #   alternative
  #     text/plain
  #     related/
  #        text/html
  msgMixed = MIMEMultipart('mixed')
  msgMixed['Subject'] = 'Foo2 Bar'
  msgMixed['From'] = "foo2@bar.com"
  msgMixed['Date'] = "Tue, 01 Jan 2019 12:01:00 +0000"
  msgMixed.attach(msgAlternative)

  return msgMixed



def message_with_html():
  html = """
<!DOCTYPE HTML>
<html>
  <body>
    <p>Hi,</p>
    <p>HTML only message.</p>
    <p>Regards,<br/>Sender</p>
  </body>
</html>
  """

  msgHtml = MIMEText(html, 'html')

  msgRelated = MIMEMultipart('related')
  msgRelated.attach(msgHtml)

  # mixed
  #   alternative
  #     text/plain
  #     related/
  #        text/html
  msgMixed = MIMEMultipart('mixed')
  msgMixed['Subject'] = 'Foo3 Bar'
  msgMixed['From'] = "foo3@baz.com"
  msgMixed['Date'] = "Thu, 03 Jan 2019 12:02:00 +0000"
  msgMixed.attach(msgRelated)

  return msgMixed



if __name__ == '__main__':
  mb = mailbox.mbox("happy.mbox")
  mb.add(message_with_plain())
  mb.add(message_with_html_and_plain())
  mb.add(message_with_html())
  mb.flush()
  mb.close()
