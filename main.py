import kobo
import itunes
import steam

from receipt_scraper import login_to_email, scrape_all_data



if __name__ == '__main__':
    mail = login_to_email()

    # This is where we assume all in GMail IMAP "INBOX" folder,
    # not in some other folder.
    # wfm.
    mail.select('INBOX')

    # Get purchases from iTunes, Steam and Kobo
    itunes_purchased_items = scrape_all_data(mail,
                                             itunes.SEARCH_FROM,
                                             itunes.SEARCH_SUBJECT,
                                             itunes.parse_email_html)
    steam_purchased_items  = scrape_all_data(mail,
                                             steam.SEARCH_FROM,
                                             steam.SEARCH_SUBJECT,
                                             steam.parse_email_html)
    kobo_purchased_items   = scrape_all_data(mail,
                                             kobo.SEARCH_FROM,
                                             kobo.SEARCH_SUBJECT,
                                             kobo.parse_email_html)

    all_items = itunes_purchased_items + steam_purchased_items + kobo_purchased_items
    all_items.sort()

    with open('purchased_digital_media.csv','w') as out:
        csv_out = csv.writer(out)
        csv_out.writerow(['date','title','creator','price','type'])

        for d in all_items:
            print d
            csv_out.writerow(d)
