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

    # Format changes significantly before/after 2016.
    # Without super-magic-wizard algorithm, can't do with single approach.

    # New one has <title/> in <head/>, so.
    has_title = len(root.xpath("/html/head/title")) > 0

    if not has_title:
      return parse_email_html_classic(html_data)
    else:
      return parse_email_html_fancy(html_data)



# For before 2016
def parse_email_html_classic(html_data):
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

    # Classic-format is a bit stateful.. in that
    # we stop when the 2nd <td/> in a row has an <hr/> as its first tag.
    # (Because this indicates "end of orders", mkay?).
    for row in rows:
        if len(row[1]) > 0 and row[1][0].tag == "hr":
            break

        title = row[0][0][0].text.strip()
        price = row[1].text.strip()

        print "STEAM found '%s' @ '%s'" % (title, price)

        result.append({
            "date": date_str,
            "title": title,
            "price": price
        })


    return result



def parse_email_html_fancy(html_data):
    etree_document = html5lib.parse(html_data, treebuilder="lxml", namespaceHTMLElements=False)
    root = etree_document.getroot()

    # I've not yet made an order of multiple items with the new Steam format.
    # Will have to fix/adjust for when I do.

    # *Unfortunately*,
    # the <tr/>s with order items aren't in their own table!
    # (The <tr/> before, after are for blank spacing. Ok. Cool).
    ## tr_xpath =    "/html/body/table/tbody/tr[2]/td/table/tbody/tr/td/table/tbody/tr[2]"
    ## rows = root.xpath(tr_xpath)
    ## print "DEBUG # rows", len(rows)

    # Let's try this instead
    title_xpath = "/html/body/table/tbody/tr[2]/td/table/tbody/tr/td/table/tbody/tr/td[2]"
    titles = root.xpath(title_xpath)
    price_xpath = "/html/body/table/tbody/tr[2]/td/table/tbody/tr/td/table/tbody/tr/td[3]"
    prices = root.xpath(price_xpath)

    print "DEBUG # titles, prices", len(titles), len(prices)

    titleprices = zip(titles, prices)

    for (title_td, price_td) in titleprices:
      title = title_td.text.strip()
      price = price_td.text.strip()

      print "DEBUG Steam found '%s' @ '%s'" % (title, price)

    result = []

    return result
