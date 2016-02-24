from lxml import etree
import html5lib
import time
import email

import receipt_scraper



# e.g. for calling with get_emails_from_withsubject
SEARCH_FROM    = "PlayStation"
# "Purchase Confirmation" is for Asia/Pacific,
# "Thank You For Your Purchase" for the purchase I made from US store.
SEARCH_SUBJECT = "Purchase Confirmation"


# Adapted from `parse_playstation_fancy`. (different xpaths, duh)
def parse_email_html(html_data):
    etree_document = html5lib.parse(html_data, treebuilder="lxml", namespaceHTMLElements=False)
    root = etree_document.getroot()


    # Before:
    # (indexed from 1?)
    # /html/body/table/tbody/tr/td[2]/table[9]
    # After:
    # /html/body/table/tbody/tr/td[2]/table[20]
    # Last:
    # /html/body/table/tbody/tr/td[2]/table[29]
    #
    # => exclude first 9(?), last 10.

    tables_xpath = "/html/body/table/tbody/tr/td[2]/table"
    tables = root.xpath(tables_xpath)[9:-10] # Magic. Works..

    # print "DEBUG Playstation # rows: %d" % len(tables)

    # Assumes it's a table w/ stuff. table
    def item_from_table(table):
        title_xpath = "tbody/tr/td[3]/a"
        title_els = table.xpath(title_xpath)
        price_xpath = "tbody/tr/td[5]"
        price_els = table.xpath(price_xpath)

        # print "DEBUG Playstation row, # title, price %d, %d" % (len(title_els), len(price_els))

        title = title_els[0].text

        # Inside the <td/>, it's <div></div>$Price<div></div>
        # So.. this works.
        price = price_els[0][0].tail

        print "DEBUG Playstation found '%s' @ '%s'" % (title, price)

        return {
            "title": title,
            "price": price
        }

    return [item_from_table(table) for table in tables]
