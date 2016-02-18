import imaplib
import email
import csv

import kobo
import itunes
import steam

def get_gmail_login():
    # Return (username, password) tuple to login to gmail via IMAP

    f = open("gmail.password", "r")
    lines = f.readlines()

    return (lines[0].strip(), lines[1].strip())



def get_email_ids_from_withsubject(imap_server, fromWho, withSubject):
    status, response = imap_server.search(None, '(FROM "%s")' % fromWho, '(SUBJECT "%s")' % withSubject)
    return response[0].split()



def get_email_data_using_id(imap_server, email_id):
    status, response = imap_server.fetch(email_id, '(RFC822)')
    return response[0][1]




def get_emails_from_withsubject(imap_server, fromWho, withSubject):
    # Now fetch the emails. A composition of the previous two functions
    email_ids = get_email_ids_from_withsubject(imap_server, fromWho, withSubject)
    return [get_email_data_using_id(imap_server, e_id) for e_id in email_ids]



def login_to_email():
    username, pwd = get_gmail_login()
    mail = imaplib.IMAP4_SSL("imap.gmail.com")
    mail.login(username, pwd)

    return mail



def get_html_payload_of_email(m):
    # The emails of the receipts we're scraping happen to have multiple MIME parts.
    # Also, some are base-64 encoded, so we need to decode them before trying to read them.
    if m.is_multipart():
        for part in m.get_payload():
            if(part.get_content_type() == "text/html"):
                return part.get_payload(decode=True)



if __name__ == '__main__':
    mail = login_to_email()
    mail.select('INBOX')

    # Get purchases from iTunes, Steam and Kobo
    itunes_purchased_items = itunes.scrape_all_data(mail)
    steam_purchased_items = steam.scrape_all_data(mail)
    kobo_purchased_items = kobo.scrape_all_data(mail)

    all_items = itunes_purchased_items + steam_purchased_items + kobo_purchased_items
    all_items.sort()

    with open('purchased_digital_media.csv','w') as out:
        csv_out = csv.writer(out)
        csv_out.writerow(['date','title','creator','price','type'])

        for d in all_items:
            print d
            csv_out.writerow(d)
