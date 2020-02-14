# n.b. see spec_helper for imports and constants

require_relative 'lib/page/email_selection.rb'

feature "client allows a keyboard-based workflow" do
  include_context "logger"
  include_context "runs elm reactor"
  include_context "able to run sinatra examples"

  # Page::EmailSelection.select("2019-01-01T12:00:00+0000", "foo1@bar.com", "Foo Bar")
  # Page::EmailSelection.select("2019-01-01T12:01:00+0000", "foo2@bar.com", "Foo2 Bar")
  # Page::EmailSelection.select("2019-01-03T12:02:00+0000", "foo3@baz.com", "Foo3 Bar")

  # SEE: /spec/zoo/<example>.rb
  context "happy API example" do
    around(:example) do |example|
      run_sinatra_example("emails_happy", &example)
    end

    before(:example) do
      visit CLIENT_PATH
    end

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

    context "initial load" do
      before(:example) do
        # Page::EmailSelection.select("2019-01-01T12:00:00+0000", "foo1@bar.com", "Foo Bar")
      end

      context "can select the next email" do
        it "with Alt+J" do
          find('#note').send_keys [:alt, 'j']

          eventually_pass do
            selected_email = Page::EmailSelection.selected_email
            expect(selected_email).to eq({ datetime: "2019-01-01T12:01:00+0000", sender: "foo2@bar.com", subject: "Foo2 Bar" })
          end
        end
      end
    end
  end
end
