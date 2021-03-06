import imaplib
import email
import email.utils
import csv
import os
import os.path
import re
from lxml import etree
import html5lib



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

    print "Retrieving %d emails..." % (len(email_ids))
    return [get_email_data_using_id(imap_server, e_id) for e_id in email_ids]



def login_to_email():
    username, pwd = get_gmail_login()
    mail = imaplib.IMAP4_SSL("imap.gmail.com")
    mail.login(username, pwd)

    return mail



# m : email.message.Message
def get_html_payload_of_email(m):
    # The emails of the receipts we're scraping happen to have multiple MIME parts.
    # Also, some are base-64 encoded, so we need to decode them before trying to read them.
    if m.is_multipart():
        for part in m.get_payload():
            if(part.get_content_type() == "text/html"):
                return part.get_payload(decode=True)
    elif m.get_content_type() == "text/html":
      return m.get_payload(decode=True)
    else:
      return None



# String to output in the CSV
def datetime_str_of_email(msg):
    (year, month, day, h, m, s, wd, yd, dst) = email.utils.parsedate(msg.get("Date"))

    # This ignores timezone.
    # But... I don't care *that* much about that precision.
    #   YYYY-MM-DD HH:MM:SS
    return "%04d-%02d-%02d %02d:%02d:%02d" % (year, month, day, h, m, s)



# String to output in the CSV
def date_str_of_email(msg):
    (year, month, day, h, m, s, wd, yd, dst) = email.utils.parsedate(msg.get("Date"))

    # This ignores timezone.
    # But... I don't care *that* much about that precision.
    #   YYYY-MM-DD
    return "%04d-%02d-%02d" % (year, month, day)




# Human-Readable name/description of an email message.
# msg : email.message.Message
# name : string
def friendlyname_of_email(msg, name = "mail"):
    # Date is of the form:
    #   '11 Jul 2011 18:57:58 -0500'
    (year, month, day, h, m, s, wd, yd, dst) = email.utils.parsedate(msg.get("Date"))

    # Need to sanitize time.
    t = "%02d%02d%02d" % (h, m, s)
    ymd = "%4d%02d%02d" % (year, month, day)

    # "friendly" as $name.$year$month$day.$time
    return name + "." + ymd + "." + t



# msg : email.message.Message
# Store the text/html and text/plain payloads
# of an email message to file.
def dump_email(msg, name = "mail"):
    cachename = "cache"
    if not os.path.isdir(cachename):
        os.mkdir(cachename)

    html_content = get_html_payload_of_email(msg)

    if (html_content != None):
        fn = friendlyname_of_email(msg, name) + ".html"
        with open(os.path.join(cachename, fn), 'w') as out:
            out.write(html_content)

    # Dump text/plain also?



# Create a skeleton-structure of the html, using html5lib.
# (just the tags, no attrib/text).
# html_data : string
#
# e.g. running on my emails, I got back:
# Counts for skeletons: [1, 1, 1, 3, 93, 3, 1, 1, 3, 1, 5, 9, 27, 1, 31]
# unique 'skeletons' of emails.
def skeleton_of_html(html_data):
    etree_document = html5lib.parse(html_data, treebuilder="lxml", namespaceHTMLElements=False)
    root = etree_document.getroot()

    def skeleton_of_element(el):
        children = [skeleton_of_element(ch) for ch in el]

        return (el.tag, children)

    return skeleton_of_element(root)



# Create a skeleton-structure of the html, using html5lib.
# (just the tags, no attrib/text).
# html_data : string
def bare_skeleton_of_html(html_data):
    etree_document = html5lib.parse(html_data, treebuilder="lxml", namespaceHTMLElements=False)
    root = etree_document.getroot()

    def skeleton_of_element(el):
        children = [skeleton_of_element(ch) for ch in el]

        # This may not be enough; may want the set instead
        children = list(set(children))

        return (el.tag, children)

    return skeleton_of_element(root)



# Kobo        "$1.23"
# Steam       "1.23 USD"
# Steam       "1.23 SGD"
# Steam       "S$1.23"
# PlayStation "SGD1.23"
# PlayStation "$1.23"
# iTunes      "$1.23" (implied NZD)
#             "S$.98
# iTunes      "Free"
# iTunes      "S$ 1.23"
# iTunes      "$1.23" (implied USD)
def parse_price(s, default_currency = "USD"):
    # Remove all spaces
    s = s.replace(" ", "")

    if s.strip() == "Free":
        amount = "0.00"
    else:
        match = re.search("\d*\.\d+", s)
        if match == None:
          print "What? Unexpected None for: %s" % s
        amount = match.group(0)

    # Look for "NZD", "SGD", "USD" etc.
    cur_match = re.search("[A-Z]{3}", s)
    if cur_match != None and s.strip() != "Free":
      currency = cur_match.group(0)
    elif s.startswith("S$"):
      # From my emails, only alternate to "implied" is if begins with
      # "S$"
      currency = "SGD"
    else:
      currency = default_currency


    return (amount, currency)



def scrape_all_data(imap_server, searchFrom, searchSubject, parse_email_html, name = "mail"):
    # XXX time how long this takes, right?
    emails = get_emails_from_withsubject(imap_server, searchFrom, searchSubject)

    print "%d emails retrieved.\n" % len(emails)

    def tally(d, k):
      d[k] = d.get(k, 0) + 1

    # Tallies
    multipart_ct = {}
    content_ct = {}
    skel_ct = {}
    bare_skel_ct = {}

    res = []
    for m in emails:
        emsg = email.message_from_string(m)

        # Is the message multipart? (We assume it is).
        is_mp = emsg.is_multipart()
        tally(multipart_ct, is_mp)

        # Has the message got text/html? text/plain?
        if any([part.get_content_type() == "text/html" for part in emsg.get_payload() if emsg.is_multipart()]):
          tally(content_ct, "html")
        if any([part.get_content_type() == "text/plain" for part in emsg.get_payload() if emsg.is_multipart()]):
          tally(content_ct, "plain")

        if not emsg.is_multipart() and emsg.get_content_type() == "text/plain":
          tally(content_ct, "plain")
        if not emsg.is_multipart() and emsg.get_content_type() == "text/html":
          tally(content_ct, "html")

        # Date can be had from:
        #   > m.get("Date")
        #   '11 Jul 2011 18:57:58 -0500'
        # as specified by RFC-2822
        # https://tools.ietf.org/html/rfc2822

        # (Later emails from Kobo don't display Date in-email, so).

        friendlyname = friendlyname_of_email(emsg, name)

        dump_email(emsg, name)

        hdata = get_html_payload_of_email(emsg)

        if (parse_email_html != None):
            # TODO Should try-catch here?
            data = parse_email_html(hdata)
        else:
            data = []

        # Add date, datetime to the results
        for item in data:
          item["date"] = date_str_of_email(emsg)
          item["datetime"] = datetime_str_of_email(emsg)

        res = res + data

    # Output tallies
    # if multipart_ct.get(True, 0) < len(emails):
    #   print "Not all emails multipart. (%d/%d)" % (multipart_ct.get(True, 0), len(emails))
    # else:
    #   print "All emails multipart."

    # print "# html: %d" % content_ct.get("html", 0)
    # print "# plain: %d" % content_ct.get("plain", 0)

    # print "Counts for skeletons: " + str(skel_ct.values())

    return res
