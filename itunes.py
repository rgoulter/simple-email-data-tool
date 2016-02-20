'''
Created on Aug 7, 2013

@author: richard
'''

from lxml import etree
import html5lib  # @UnresolvedImport
import time
import email

import receipt_scraper



SEARCH_FROM    = "Kobo"
SEARCH_SUBJECT = "Your Kobo Order Receipt"



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

    # Due to older emails having a different format, we need
    # to check whether this is new or old.
    # In older emails, the text at the xpath will read "Unit Price", on newer will read "Type"
    type_col_header_xpath = "/html/body/table[1]/tbody/tr/td/table[3]/tbody/tr/td[1]/table[1]/tbody/tr[2]/td[3]/font/b"
    type_col_b = root.xpath(type_col_header_xpath)[0]
    has_type_column = type_col_b.text == "Type"

    # Each tr
    #          "/html/body/table[1]/tbody/tr/td/table[3]/tbody/tr/td[1]/table[1]/tbody/tr"
    tr_xpath = "/html/body/table[1]/tbody/tr/td/table[3]/tbody/tr/td[1]/table[1]/tbody/tr"
    rows = root.xpath(tr_xpath)

    # Now we want the rows with 4 children (but not the first, which is the titles of the cols

    items = [row for row in rows if len(row) == (4 if has_type_column else 3)][1:]

    result = []

    for item in items:
        if has_type_column:
            # Newer Formatting
            title = item[0][0].text.strip()
            artist = item[1][0].text.strip()
            itype = item[2][0].text.strip() #type, e.g. song
            price = item[3][0].text.strip()
        else:
            # Older Formatting.
            # Significantly lacks information.
            title = item[1][0].text.strip()
            artist = ""
            itype = "iTunes Media"
            price = item[2][0].text.strip()

        result.append((date_str, title, artist, price, itype))

    return result
