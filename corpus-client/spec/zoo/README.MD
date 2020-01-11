# Zoo of Examples

I put the 'mock' APIs used for testing the Elm client here.

## Mock API Requests:

- `/email-addresses`
  - `email-addresses_happy.rb`

# Running from Windows Powershell

e.g. from the corpus-client dir:

```
ruby .\spec\zoo\email-addresses_happy.rb -p 8555 -q 2> $null
```
