# Email Receipt Scraper

## What does it do? / Motivation
I wrote this because I spend too damn much on Steam, Kobo, iTunes and wanted
to know how much.  
I'd not kept track, but hadn't deleted the emails from my GMail account.

This script searches through a GMail account, scrapes the HTML contents of these
emails, and outputs relevant CSV file.  
A bit of tinkering here/there may adjust it to your use.

## Assumptions

* For this to be of any use, you'd have to have not deleted these emails from
  your inbox. (Assumes emails can be found in Gmail from IMAP, in the IMAP
  folder 'INBOX').

* "Receipt" emails from some particular store can be found from an IMAP search
  for the some subject, and from some user. e.g. "Your Kobo Receipt" from
  "noreply@kobo.com" will return if and only if an email is a receipt for a
  Kobo order.

## Implementation Details
* Algorithmically there's nothing exciting/magic going on here,
  the functions scrape the emails based on hard-coded assumptions of structure
  (inferred by looking at sample emails).

* Since this is meant as a quick/dirty script, there's zero defensive/error
  handling. No testing. (I'm ok with that).

* The Python script makes use of lxml and html5lib libraries, which do most of
  the work. (You'll need to install these, e.g. `# pip2 install html5lib`).

* The "Handlers" for stores (iTunes, etc.) are each their own Python filec
  which are called from the main file.

## Usage / Instructions

* Assumes file `gmail.password`, first line is username, second line is an
  app-specific password.

* Run and see what errors you get? Currently nothing outputs to `STDOUT`.
