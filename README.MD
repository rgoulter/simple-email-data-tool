# Simple Email Notes Tool [![Build Status](https://travis-ci.com/rgoulter/simple-email-data-tool.svg?branch=master)](https://travis-ci.com/rgoulter/simple-email-data-tool)

This is a yak-shaving side-project to help me record
data from (structured) emails.

e.g. to extract billing info from emails in my inbox.

- `fetch_gmail_to_mbox.py` is a simple script which
  fetches certain emails from an IMAP inbox to an mbox.

- "corpus viewer" (SQLite schema `schema.sql`, server `corpus_viewer.py`,
  client `corpus-client/src/Main.elm`)
  is a tool for viewing and writing notes for the emails in an inbox.

## Installing Dependencies

On Windows with [Chocolatey](https://chocolatey.org/install)

### Prerequisites:

- Ruby < 2.7

    ```
    choco install ruby --version 2.6.5.1
    ```

- Python 3

    ```
    choco install python
    ```

- Elm Platform 0.19

    ```
    choco install elm-platform
    ```

### Project Dependencies

To ensure the project dependencies for Elm, Python, and Ruby,
run:

```
pip install -r requirements.txt
cd corpus-viewer
bundle install
elm make src/Main.elm
cd ..
```

## Running the Automated Checks

- Corpus Viewer
  - Server Tests:  
    To run the automated unit checks for the corpus viewer server:
      ```
      python -m unittest
      ```

    To run the automated components checks for the corpus server:
      ```
      mamba
      ```

  - Client  
    To run the automated component checks for the corpus viewer client,
    run:
      ```
      cd corpus-viewer
      bundle exec rspec
      ```

## Running the Program

- Corpus Viewer  
  Ensure the Elm client is build:
  ```
  cd corpus-viewer
  elm make src/Main.elm
  cd ..
  ```
  then run the flask app with (e.g. in Powershell):
  ```
  $Env:FLASK_APP="corpus_viewer.py"
  flask run
  ```
