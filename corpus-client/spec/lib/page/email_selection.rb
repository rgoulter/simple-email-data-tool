require 'capybara/dsl'

module Page
  module EmailSelection
    EMAILS_SELECTOR = '#emails'

    class << self
      include Capybara::DSL

      def emails
        options = all("#{EMAILS_SELECTOR} option")
        options_text = options.map(&:text)

        options_text.map do |email_text|
          datetime, sender, subject = email_text.split(" ", 3)
          { datetime: datetime, sender: sender[0..-2], subject: subject }
        end
      end
    end
  end
end
