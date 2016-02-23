import kobo
import itunes
import steam
import playstation

from receipt_scraper import login_to_email, scrape_all_data



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

    # Get purchases from iTunes, Steam and Kobo
    kobo_purchased_items   = scrape_all_data(mail,
                                             kobo.SEARCH_FROM,
                                             kobo.SEARCH_SUBJECT,
                                             kobo.parse_email_html,
                                             "kobo")
    steam_purchased_items  = scrape_all_data(mail,
                                             steam.SEARCH_FROM,
                                             steam.SEARCH_SUBJECT,
                                             steam.parse_email_html,
                                             "steam")
    psn_purchased_items    = scrape_all_data(mail,
                                             playstation.SEARCH_FROM,
                                             playstation.SEARCH_SUBJECT,
                                             playstation.parse_email_html,
                                             "playstation")

    itunes_purchased_items = []

    for (f, s) in itunes.FROM_SUBJECT_PAIRS:
      res = scrape_all_data(mail, f, s, itunes.parse_email_html, "itunes")
      itunes_purchased_items.append(res)

    # all_items = itunes_purchased_items + steam_purchased_items + kobo_purchased_items
    # all_items.sort()
    #
    # with open('purchased_digital_media.csv','w') as out:
    #     csv_out = csv.writer(out)
    #     csv_out.writerow(['date','title','creator','price','type'])
    #
    #     for d in all_items:
    #         print d
    #         csv_out.writerow(d)
