import kobo
import itunes
import steam
import playstation

import codecs
import unicodecsv

from receipt_scraper import login_to_email, scrape_all_data
from receipt_scraper import parse_price



# What I wanna do is this:
# - perform some search using the (FROM, SUBJ) params..
# - with these emails, ... get the 'skeleton'.
#   - of course!, skeleton will be different for different
#     number of orders. Hrm.


if __name__ == '__main__':
    mail = login_to_email()

    # This is where we assume all in GMail IMAP "INBOX" folder,
    # not in some other folder.
    # wfm.
    mail.select('INBOX')


    # title, author, price
    kobo_purchased_items   = scrape_all_data(mail,
                                             kobo.SEARCH_FROM,
                                             kobo.SEARCH_SUBJECT,
                                             kobo.parse_email_html,
                                             "kobo")
    for item in kobo_purchased_items:
        (amount, cur) = parse_price(item["price"], default_currency = "USD")
        item["amount"]   = amount
        item["currency"] = cur
        item["kind"]     = "book"
        item["store"]    = "kobo"
    # title, author, price, date, kind, amount, currency


    # item, price
    steam_purchased_items  = scrape_all_data(mail,
                                             steam.SEARCH_FROM,
                                             steam.SEARCH_SUBJECT,
                                             steam.parse_email_html,
                                             "steam")
    for item in steam_purchased_items:
        (amount, cur) = parse_price(item["price"])
        item["amount"]   = amount
        item["currency"] = cur
        item["kind"]     = "game"
        item["store"]    = "steam"
    # item, price, date, kind, amount, currency


    # item, price
    psn_purchased_items    = scrape_all_data(mail,
                                             playstation.SEARCH_FROM,
                                             playstation.SEARCH_SUBJECT,
                                             playstation.parse_email_html,
                                             "playstation")
    for item in psn_purchased_items:
        (amount, cur) = parse_price(item["price"])
        item["amount"]   = amount
        item["currency"] = cur
        item["kind"]     = "game"
        item["store"]    = "playstation"
    # item, price, date, kind, amount, currency


    # date, title, author, price, kind
    # title, author, kind, price
    itunes_purchased_items = []

    for (f, s, default_cur) in itunes.FROM_SUBJECT_PAIRS:
        res = scrape_all_data(mail, f, s, itunes.parse_email_html, "itunes")
        for item in res:
            (amount, cur) = parse_price(item["price"], default_currency = default_cur)
            item["amount"]   = amount
            item["currency"] = cur
            item["store"]    = "itunes"

        itunes_purchased_items = itunes_purchased_items + res
    # title, author, kind, price, date, amount, currency


    all_items = kobo_purchased_items + steam_purchased_items + psn_purchased_items + itunes_purchased_items

    stores = set(item["store"] for item in all_items)

    print "DEBUG stores: ", stores

    # Segregate by Store, Currency, into indiv. CSV files.

    for store in stores:
        items_for_store = [item for item in all_items if item["store"] == store]

        # segregate by Currency
        currencies = set(item["currency"] for item in items_for_store)

        print "DEBUG currencies for Store '%s': " % store, currencies

        for currency in currencies:
            items_for_currency = [item for item in items_for_store if item["currency"] == currency]

            with open("purchased_%s.%s.csv" % (store, currency), "w") as out:
              csv_out = unicodecsv.writer(out, encoding="utf-8")
              csv_out.writerow(['date','title','author','amount','currency', 'type'])

              for item in items_for_currency:
                row = [item["date"], item["title"], item.get("author", ""), item["amount"], item["currency"], item["kind"]]
                csv_out.writerow(row)


    # Write all items
    with open("purchased_all.csv", "w") as out:
      csv_out = unicodecsv.writer(out, encoding="utf-8")
      csv_out.writerow(['date','title','author','amount','currency', 'type', 'store'])

      for item in items_for_currency:
        row = [item["date"], item["title"], item.get("author", ""), item["amount"], item["currency"], item["kind"], item["store"]]
        csv_out.writerow(row)
