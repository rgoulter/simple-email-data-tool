# Zoo of Examples

I put the 'mock' APIs used for testing the Elm client here.

## Mock API Requests:

- `/emails`
  - `emails.rb` :: Returns simply and happily for `/emails`.
    This allows tests with the client running against this server
    to check the emails are populated with this request.
  - `emails_happy_slow.rb` :: After 5 seconds, returns simply and happily for `/emails`.
    This allows tests with the client running against this server to check
    the loading screen shows before the emails are populated by this request.

# Running from Windows Powershell

e.g. from the corpus-client dir:

```
ruby .\spec\zoo\emails_happy.rb -p 8555 -q 2> $null
```
