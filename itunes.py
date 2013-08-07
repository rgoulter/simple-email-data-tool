'''
Created on Aug 7, 2013

@author: richard
'''

from lxml import etree
import html5lib  # @UnresolvedImport
import time
import email
import receipt_scraper



def get_receipt_emails(imap_server):
    return receipt_scraper.get_emails_from_withsubject(imap_server, "iTunes", "Your receipt")



def parse_email_html(html_data):
    etree_document = html5lib.parse(html_data, treebuilder="lxml", namespaceHTMLElements=False)
    root = etree_document.getroot()
    
    # Email HTML seems to be somewhat difficult to parse.
    # Find the date of purchase
    order_received_td_xpath = "/html/body/table[1]/tbody/tr/td/table[2]/tbody/tr[2]/td[2]/font/b[2]"
    received_td = root.xpath(order_received_td_xpath)
    date_rawstr = received_td[0].tail.strip() # 06/08/13
    date_val = time.strptime(" ".join(date_rawstr.split()[:3]), "%d/%m/%y") # DD/MM/YYYY
    date_str = time.strftime("%Y/%m/%d", date_val)
    
    # Now we need to get the songs purchased..
    
    # Each tr
    tr_xpath = "/html/body/table[1]/tbody/tr/td/table[3]/tbody/tr/td[1]/table[1]/tbody/tr"
    rows = root.xpath(tr_xpath)
    
    # Now we want the rows with 4 children (but not the first, which is the titles of the cols
    items = [row for row in rows if len(row) == 4][1:]
    
    result = []
    
    for item in items:
        title = item[0][0].text.strip()
        artist = item[1][0].text.strip()
        itype = item[2][0].text.strip() #type, e.g. song
        price = item[3][0].text.strip()
        
        result.append((date_str, title, artist, price, itype))
    
    return result


def scrape_all_data(imap_server):
    emails = get_receipt_emails(imap_server)
    res = []
    for m in emails:
        emsg = email.message_from_string(m)
        hdata = receipt_scraper.get_html_payload_of_email(emsg)
        
        data = parse_email_html(hdata)
        res = res + data
        
    return res