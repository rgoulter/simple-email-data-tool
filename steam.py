'''
Created on Aug 7, 2013

@author: richard
'''
from lxml import etree
import html5lib
import time
import email

import receipt_scraper



SEARCH_FROM    = "Steam"
SEARCH_SUBJECT = "Thank you" # for your purchase" # Steam is inconsistent w/ subject!



def parse_email_html(html_data):
    etree_document = html5lib.parse(html_data, treebuilder="lxml", namespaceHTMLElements=False)
    root = etree_document.getroot()

    # Email HTML seems to be somewhat difficult to parse.
    # Find the date of purchase
    order_received_td_xpath = "/html/body/div/table[1]/tbody/tr[last()]/td[2]"
    received_td = root.xpath(order_received_td_xpath)
    date_rawstr = received_td[0].text #e.g. Tue Jul 16 21:51:26 2013
    date_val = time.strptime(date_rawstr, "%a %b %d %H:%M:%S %Y")
    date_str = time.strftime("%Y/%m/%d", date_val)

    # Get the name & author
    # Kindof gonna be annoying to process this..
    # We process the table-rows, until the one which has a hr in it.
    tr_xpath = "/html/body/div/table[1]/tbody/tr"
    rows = root.xpath(tr_xpath)

    result = []

    for row in rows:
        if len(row[1]) > 0 and row[1][0].tag == "hr":
            break

        title = row[0][0][0].text.strip()
        author = ""
        price = row[1].text.strip()
        gtype = "Game"

        print "STEAM found '%s' @ '%s'" % (title, price)

        result.append((date_str, title, author, price, gtype))


    return result
