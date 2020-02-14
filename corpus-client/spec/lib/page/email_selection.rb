require 'capybara/dsl'

module Page
  module EmailSelection
    EMAILS_SELECTOR = '#emails'

    class << self
      include Capybara::DSL

      def emails
        trs = all("#{EMAILS_SELECTOR} tr")

        trs.map do |tr|
          datetime = tr.find(".datetime").text
          sender = tr.find(".from").text
          subject = tr.find(".subject").text
          { datetime: datetime, sender: sender, subject: subject }
        end
      end

      def select(datetime, sender, subject)
        tr = find("#{EMAILS_SELECTOR} tr") do |tr|
          datetime == tr.find(".datetime").text &&
          sender == tr.find(".from").text &&
          subject == tr.find(".subject").text
        end
        tr.first('td').click
      end
    end
  end
end
