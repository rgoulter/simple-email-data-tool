# Email Receipt Scraper

I wrote this script for scraping (some) of the receipt info from my emails,
since I've not been diligent at keeping track of this information myself.
For this to be of any use, you'd have to have not cleaned out your emails of these. The script seems to work for the emails I happened to have in my Inbox for the given stores.
This is limited, of course, by what information the email actually contains.

Algorithmically there's nothing too exciting here, the functions scrape the emails based on magically-encoded structures inferred from sample data.

The Python script makes use of lxml and html5lib libraries, which do most of the work.
