# n.b. see spec_helper for imports and constants

require_relative 'lib/page/email_selection.rb'

feature "viewing the contents of a selected email" do
  include_context "logger"
  include_context "runs elm reactor"
  include_context "able to run sinatra examples"

  # SEE: /spec/zoo/<example>.rb
  context "/email/<from>/<timestamp>/ returns successfully" do
    around(:example) do |example|
      run_sinatra_example("emails_happy", &example)
    end

    before(:example) do
      visit CLIENT_PATH
    end

    context "the first email is selected" do
      before(:example) do
        Page::EmailSelection.select("2019-01-01T12:00:00+0000", "foo1@bar.com", "Foo Bar")
      end

      it "shows the contents for the email" do
        within_frame('email_content') do
          expect(page).to have_text("First message.")
        end
      end
    end

    context "the second email is selected" do
      before(:example) do
        Page::EmailSelection.select("2019-01-01T12:01:00+0000", "foo2@bar.com", "Foo2 Bar")
      end

      it "shows the contents for the email" do
        within_frame('email_content') do
          expect(page).to have_text("Second message.")
        end
      end
    end
  end

  context "/email/<from>/<timestamp>/ returns emails with a mix of plaintext, html content" do
    around(:example) do |example|
      run_sinatra_example("emails_happy", &example)
    end

    before(:example) do
      visit CLIENT_PATH
    end

    context "an email with a text payload is selected" do
      context "plaintext" do
        before(:example) do
          Page::EmailSelection.select("2019-01-01T12:00:00+0000", "foo1@bar.com", "Foo Bar")
        end

        it "only has plaintext tab enabled" do
          tabs = all('.content .tabs li:not(.disabled)', minimum: 1)

          expect(tabs.count).to eq 1
          expect(tabs[0].text.downcase).to include("plain")
        end
      end

      context "html" do
        before(:example) do
          Page::EmailSelection.select("2019-01-03T12:02:00+0000", "foo3@baz.com", "Foo3 Bar")
        end

        it "only has html tab enabled" do
          tabs = all('.content .tabs li:not(.disabled)', minimum: 1)

          expect(tabs.count).to eq 1
          expect(tabs[0].text.downcase).to include("html")
        end

        it "shows the html contents for the email" do
          within_frame('email_content') do
            expect(page).to have_selector("p")
            expect(page).to have_text("HTML only message.")
          end
        end
      end
    end

    context "an email with a multipart payload is selected" do
      before(:example) do
        Page::EmailSelection.select("2019-01-01T12:01:00+0000", "foo2@bar.com", "Foo2 Bar")
      end

      it "has both html and plaintext enabled" do
        tabs = all('.content .tabs li:not(.disabled)', minimum: 1)

        expect(tabs.count).to eq 2

        content_types = tabs.map(&:text).map(&:downcase)
        expect(content_types).to include("html")
        expect(content_types).to include("plain")
      end

      it "can select the plaintext content" do
        tab = find('.tabs li', text: "plain")
        tab.click

        within_frame('email_content') do
          expect(page).not_to have_selector("p")
          expect(page).to have_text("Second message")
        end
      end

      it "can select the html content" do
        tab = find('.tabs li', text: "html")
        tab.click

        within_frame('email_content') do
          expect(page).to have_selector("p")
          expect(page).to have_text("Second message")
        end
      end
    end
  end
end
