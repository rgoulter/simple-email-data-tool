# n.b. see spec_helper for imports and constants

require_relative 'lib/page/email_selection.rb'

feature "fetching emails on page load" do
  include_context "logger"
  include_context "runs elm reactor"
  include_context "able to run sinatra examples"

  xcontext "the server is not running" do
    # XXX: with the change from calling the (mock) sinatra server directly,
    # to calling the sinatra server via the same server as serves the Elm client,
    # the error isn't ConnRefused so much as (atm) HTTP 500.
    it "shows that a network error occurred" do
      # ASSEMBLE
      visit CLIENT_PATH

      # ASSERT
      error = find('div.error', wait: 15)

      expect(error.text.downcase).to include("network error")
    end
  end

  # SEE: /spec/zoo/<example>.rb
  context "/emails returns successfully" do
    around(:example) do |example|
      run_sinatra_example("emails_happy", &example)
    end

    it "shows the list of emails" do
      # ASSEMBLE
      visit CLIENT_PATH

      # ASSERT
      emails = Page::EmailSelection.emails

      expected_emails =
        [{ datetime: "2019-01-01T12:00:00+0000", sender: "foo1@bar.com", subject: "Foo Bar" },
         { datetime: "2019-01-01T12:01:00+0000", sender: "foo2@bar.com", subject: "Foo2 Bar" },
         { datetime: "2019-01-03T12:02:00+0000", sender: "foo3@baz.com", subject: "Foo3 Bar" }]
      expect(emails).to eql(expected_emails)
    end
  end

  context "/emails SLOWLY returns successfully" do
    around(:example) do |example|
      run_sinatra_example("emails_happy_slow", &example)
    end

    it "shows 'loading'" do
      # ASSEMBLE
      visit CLIENT_PATH

      # ASSERT
      error = find('div.loading')

      expect(error.text.downcase).to include("loading")
    end
  end
end
