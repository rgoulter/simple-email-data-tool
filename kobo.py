'''
Created on Aug 7, 2013

@author: richard
'''

from lxml import etree
import html5lib
import time
import email

import receipt_scraper



# e.g. for calling with get_emails_from_withsubject
SEARCH_FROM    = "Kobo"
SEARCH_SUBJECT = "Your Kobo Order Receipt"



# n.b. Kobo has "Purchase History",
#   https://secure.kobobooks.com/profile/purchasehistory
# if all you need is a glance/refresher of what you
# purchased. Can't download-as-CSV, nor will it show
# more than 100 orders per page.

def parse_email_html(html_data):
    etree_document = html5lib.parse(html_data, treebuilder="lxml", namespaceHTMLElements=False)
    root = etree_document.getroot()

    # By inspecting HTML payloads (saved/dumped elsewhere),
    # (samples taken at points which the scraping threw an exception!),
    #
    # It's clear that the format in the emails is close-enough that it's easier
    # to write a flexible scraper, than to scrape scrictly for slight variations.
    #
    # Emails after 2014-Aug (ish) change from:
    #  <td>BookTitle <span>By AuthorName</span></td>
    # to:
    #  <td><a>$BookTitle</a> <span>By $AuthorName</span></td>
    # Additionally, emails after 2014-Aug (ish) no longer include
    # a <td>$DateOfPurchase</td>, so, this changes xpath of $Price <td/>
    #
    # Emails after 2015-Aug (ish) change the specific xpath to the items table.
    #
    # Edge case in my emails is an email (before 2014-Aug) with no <span/>,
    #  & so no author. Okay.

    # General formula was
    #   some_xpath = "/path/to/el"
    #   some_el = root.xpath(some_xpath) # n.b. this is a list.
    #   some_str = f(some_el) # some_el[0].text, etc.

    # TBH, most of the rest is "magic"/hard-coded enough (by nature)
    # that it's not particularly maintainable.
    # Scrapers should be fragile.

    # items_table contains all the <tr/> with order items.
    # items_table_xpath = "/html/body/table/tbody/tr/td/table/tbody/tr/td/table/tbody/tr/td[2]/table[3]/tbody/tr/td[2]/table[3]/tbody/tr/td/table[4]"
    items_table_xpath = "/html/body/table/tbody/tr/td/table/tbody/tr/td/table/tbody/tr/td[2]/table/tbody/tr/td[2]/table[3]/tbody/tr/td/table[4]"
    items_table = root.xpath(items_table_xpath)[0]

    # "/tbody..." vs "tbody..."?
    item_rows = items_table.xpath("tbody/tr")

    # print "DEBUG Num item rows: ", len(item_rows)

    # For individual <tr/>, return { title, author, price }
    def item_from_row(tr):
      # Because it's email, the <tr/> has a table or two inside it. Cool.
      title_author_td = tr.xpath("td/table/tbody/tr/td/table/tbody/tr/td[2]")

      # print "DEBUG Title Author TD len", len(title_author_td)

      # How to do things like ".getElementsByTag"? :S
      # Prefer BeautifulSoup for some things?

      a = title_author_td[0].xpath("a")

      if len(a) == 0:
        title = title_author_td[0].text
      else:
        title = a[0].text


      # print "DEBUG Title", title

      span = title_author_td[0].xpath("span")

      if len(span) > 0:
        # Get rid of the "By.."
        author = " ".join(span[0].text.split()[1:])
      else:
        author = None

      # print "DEBUG author ", author

      # Price <td/> is the last one.
      price_td = tr.xpath("td/table/tbody/tr/td/table/tbody/tr/td")[-1]
      price = price_td.text

      print "DEBUG Kobo found '%s' by '%s' @ '%s'" % (title, author, price)

      return {
          "title": title,
          "author": author,
          "price": price
      }

    return [item_from_row(r) for r in item_rows]
