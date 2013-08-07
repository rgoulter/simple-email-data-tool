'''
Created on Aug 7, 2013

@author: richard
'''

from lxml import etree
import html5lib
import time
import email
import receipt_scraper



def get_receipt_emails(imap_server):
    # Kobo receipts are
    # from Kobo
    # with subject "Your Kobo Order Receipt"
    return receipt_scraper.get_emails_from_withsubject(imap_server, "Kobo", "Your Kobo Order Receipt")

def parse_email_html(html_data):
    etree_document = html5lib.parse(html_data, treebuilder="lxml", namespaceHTMLElements=False)
    root = etree_document.getroot()
    
    # Email HTML seems to be somewhat difficult to parse.
    # Find the date of purchase
    order_received_td_xpath = "/html/body/table/tbody/tr/td/table/tbody/tr/td/table/tbody/tr/td[2]/table[3]/tbody/tr/td[2]/table[3]/tbody/tr/td/table[4]/tbody/tr/td/table/tbody/tr/td/table/tbody/tr/td[3]"
    received_td = root.xpath(order_received_td_xpath)
    date_rawstr = received_td[0].text #DD/MM/YYYY or YYYY-MM-DD, dang
    date_val = None
    if "-" in date_rawstr:
        date_val = time.strptime(" ".join(date_rawstr.split()[:3]), "%Y-%m-%d") # YYYY-MM-DD
    else:
        date_val = time.strptime(" ".join(date_rawstr.split()[:3]), "%d/%m/%Y") # DD/MM/YYYY
    date_str = time.strftime("%Y/%m/%d", date_val)
    
    # Get the name & author
    # (This assumes only one item per email, which seems to hold for Kobo). 
    order_title_xpath = "/html/body/table/tbody/tr/td/table/tbody/tr/td/table/tbody/tr/td[2]/table[3]/tbody/tr/td[2]/table[3]/tbody/tr/td/table[4]/tbody/tr/td/table/tbody/tr/td/table/tbody/tr/td[2]"
    title_td = root.xpath(order_title_xpath)
    title_str = title_td[0].text
    
    order_author_xpath = "/html/body/table/tbody/tr/td/table/tbody/tr/td/table/tbody/tr/td[2]/table[3]/tbody/tr/td[2]/table[3]/tbody/tr/td/table[4]/tbody/tr/td/table/tbody/tr/td/table/tbody/tr/td[2]/span"
    author_td = root.xpath(order_author_xpath)
    author_str = " ".join(author_td[0].text.split()[1:])
    
    # Get the price
    order_price_xpath = "/html/body/table/tbody/tr/td/table/tbody/tr/td/table/tbody/tr/td[2]/table[3]/tbody/tr/td[2]/table[3]/tbody/tr/td/table[4]/tbody/tr/td/table/tbody/tr/td/table/tbody/tr/td[4]"
    price_td = root.xpath(order_price_xpath)
    price_str = price_td[0].text
    
    return (date_str, title_str, author_str, price_str, "Book") 


def scrape_all_data(imap_server):
    emails = get_receipt_emails(imap_server)
    res = []
    for m in emails:
        emsg = email.message_from_string(m)
        hdata = receipt_scraper.get_html_payload_of_email(emsg)
        
        data = parse_email_html(hdata)
        res.append(data)
        
    return res