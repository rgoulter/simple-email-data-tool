# Zoo of Examples

I put the 'mock' APIs used for testing the Elm client here.

## Mock API Requests:

- `/email-addresses`
  - `email-addresses_happy.rb` :: Returns simply and happily for `/email-addreses`.
    This allows tests with the client running against this server
    to check the email addresses are populated with this request.
  - `email-addresses_happy_slow.rb` :: After 5 seconds, returns simply and happily for `/email-addreses`.
    This allows tests with the client running against this server to check
    the loading screen shows before the email addresses are populated by this request.

# Running from Windows Powershell

e.g. from the corpus-client dir:

```
ruby .\spec\zoo\email-addresses_happy.rb -p 8555 -q 2> $null
```
