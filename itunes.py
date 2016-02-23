'''
Created on Aug 7, 2013

@author: richard
'''

from lxml import etree
import html5lib  # @UnresolvedImport
import time
import email

import receipt_scraper



SEARCH_FROM    = "iTunes"

SEARCH_SUBJECT = "No."

# From:iTunes works before June 2015.
# "Your receipt No.123456" is the subject before 2015.
# "Your invoice No.123456" is the subject 2015 afterwards. (Not sure about 2016?).
#
# June 2015 onwards,
# it's from Apple,
# subject "Your invoice from Apple",
#
# Purchases from the US store (for me, Dec 2015 / Jan 2016),
# have subject "Your receipt from Apple"

FROM_SUBJECT_PAIRS = [
    ("iTunes", "Your receipt"), # before 2015
    ("iTunes", "Your invoice"), # Jan 2015 - Jun 2015
    ("Apple",  "Your invoice"), # June 2015 onwards
    ("Apple",  "Your invoice") # Dec 2015 / Jan 2016 (US Store)
]

def parse_email_html(html_data):
    etree_document = html5lib.parse(html_data, treebuilder="lxml", namespaceHTMLElements=False)
    root = etree_document.getroot()

    # How to distinguish between before-June-2015 and after-June-2015?

    # Old
    # xpath to "Order Total"
    # /html/body/table[1]/tbody/tr/td/table[3]/tbody/tr/td[1]/table[1]/tbody/tr[9]/td[1]/font
    # /html/body/table[1]/tbody/tr/td/table[3]/tbody/tr/td[1]/table[1]/tbody/tr[12]/td[1]/font
    old_ordertotal_xpath = "/html/body/table[1]/tbody/tr/td/table[3]/tbody/tr/td[1]/table[1]/tbody/tr/td[1]/font"
    old_ot_font = root.xpath(old_ordertotal_xpath)
    is_old = len(old_ot_font) > 0

    # new:
    # /html/body/table/tbody/tr/td/div[1]/table/tbody/tr[4]/td/table/tbody/tr[1]/td/table/tbody/tr[1]/td[3]/span[1]
    new_total_xpath = "/html/body/table/tbody/tr/td/div[1]/table/tbody/tr[4]/td/table/tbody/tr[1]/td/table/tbody/tr[1]/td[3]/span[1]"
    new_tot_span = root.xpath(new_total_xpath)
    is_new = len(new_tot_span) > 0

    # Works, apparently.
    # print "DEBUG iTunes isOld? isNew? %s %s" % (is_old, is_new)

    if is_old:
        return parse_email_html_classic(html_data)
    elif is_new:
        return parse_email_html_fancy(html_data)



# Worked @ 2013.
# Amazingly, works up until (before) 2015-June.
def parse_email_html_classic(html_data):
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
    # In older emails, the text at the xpath will read "Unit Price",
    #    on newer (2011-08 onwards) will read "Type"
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

        print "DEBUG iTunes found '%s' by '%s' [%s] @ '%s'" % (title, artist, itype, price)

        result.append({
            "date": date_str,
            "title": title,
            "author": artist,
            "price": price,
            "kind": itype
        })

    return result



def parse_email_html_fancy(html_data):
    etree_document = html5lib.parse(html_data, treebuilder="lxml", namespaceHTMLElements=False)
    root = etree_document.getroot()

    # It'd be possible to distinguish which 'store' bought from,
    # e.g. "iTunes Store" vs "App Store".. but since we wanna grab 'kind',
    # this may be fairly obvious?

    # Row xpath ... can't.

    # Title

    # Purchased From

    # Price
    # /html/body/table/tbody/tr/td/div[1]/table/tbody/tr[4]/td/table/tbody/tr[3]/td/table/tbody/tr[2]/td[5]/span
    price_xpath = "/html/body/table/tbody/tr/td/div[1]/table/tbody/tr[4]/td/table/tbody/tr/td/table/tbody/tr/td[5]/span"

    prices  = root.xpath(price_xpath)

    rows = [span.getparent().getparent() for span in prices]

    def item_from_row(row):
        # print "DEBUG tag %s" % row.tag

        title = row.xpath("td[2]/span[1]")[0].text

        # Author / Genre? are the same thing?
        author = row.xpath("td[2]/span[2]")[0].text

        # Kind
        # /html/body/table/tbody/tr/td/div[1]/table/tbody/tr[4]/td/table/tbody/tr[3]/td/table/tbody/tr[2]/td[3]/span
        kind = row.xpath("td[3]/span")[0].text

        # Purchased From

        # Price
        # /html/body/table/tbody/tr/td/div[1]/table/tbody/tr[4]/td/table/tbody/tr[3]/td/table/tbody/tr[2]/td[5]/span
        price = row.xpath("td[5]/span")[0].text

        print "DEBUG iTunes (new) found '%s' '%s' [%s] @ '%s'" % (title, author, kind, price)

        return {
            "title": title,
            "author": author,
            "kind": kind,
            "price": price
        }

    return [item_from_row(row) for row in rows]
