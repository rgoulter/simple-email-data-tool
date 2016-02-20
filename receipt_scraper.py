import imaplib
import email
import csv



def get_gmail_login():
    # Return (username, password) tuple to login to gmail via IMAP

    f = open("gmail.password", "r")
    lines = f.readlines()

    return (lines[0].strip(), lines[1].strip())



def get_email_ids_from_withsubject(imap_server, fromWho, withSubject):
    status, response = imap_server.search(None,
                                          '(FROM "%s")' % fromWho,
                                          '(SUBJECT "%s")' % withSubject)

    # I'm not entirely sure why this works.
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
                # XXX should save this ... somewhere?
                return part.get_payload(decode=True)
            # XXX elif text/plain, dump also
    # and what if it's not multipart? at least an
    # "oh, that was unexpected".



def scrape_all_data(imap_server, searchFrom, searchSubject, parse_email_html):
    emails = get_emails_from_withsubject(imap_server, searchFrom, searchSubject)

    res = []
    for m in emails:
        emsg = email.message_from_string(m)
        hdata = get_html_payload_of_email(emsg)

        data = parse_email_html(hdata)
        res.append(data)

    return res
