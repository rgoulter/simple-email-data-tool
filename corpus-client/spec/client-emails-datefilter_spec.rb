# n.b. see spec_helper for imports and constants

require 'date'

require 'pry'

require_relative 'lib/page/edrp.rb'
require_relative 'lib/page/email_selection.rb'

feature "client can filter by dates" do
  include_context "logger"
  include_context "runs elm reactor"
  include_context "able to run sinatra examples"

  def eventually_pass()
    attempt = 0
    loop do
      yield

      break
    rescue RSpec::Expectations::ExpectationNotMetError
      attempt += 1
      sleep 1
      raise if attempt >= 10
    end
  end

  # SEE: /spec/zoo/<example>.rb
  context "happy emails" do
    around(:example) do |example|
      run_sinatra_example("emails_happy", &example)
    end

    before(:example) do
      visit CLIENT_PATH
    end

    it "can filter to the 1 email in 2019-01-02 -- 2019-01-04" do
      Page::EDRP.select_date_range(Date.new(2019, 1, 2), Date.new(2019, 1, 4))

      eventually_pass {
        emails = Page::EmailSelection.emails
        expect(emails.length).to eq(1)
      }
    end
  end
end
