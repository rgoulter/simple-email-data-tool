# Running on Workstation

`src/Main.elm` is the main application. Since this makes requests
to endpoint `/api/*`, it should be served by e.g. `../corpus_server.py`,
`src/server.py` (which is used the component tests), or otherwise.

`src/Showcase.elm` is intended as a quick way of visualising individual
components, to work on invidual modules with just `elm reactor`.

# Running the Automated Component Checks

To run the component tests:

```
bundle exec rspec
```

The environment variable `SELENIUM_BROWSER` is used to determine
which Capybara driver to run the selenium tests with.
(Values: `selenium_chrome`, `selenium_chrome_headless`, `selenium`,
`selenium_headless` (__default__)).

# Reference

- https://guide.elm-lang.org/install/elm.html
- https://package.elm-lang.org/
- https://faq.elm-community.org/

- https://github.com/jcollard/elm-mode
