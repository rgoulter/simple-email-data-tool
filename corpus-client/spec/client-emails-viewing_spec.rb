# n.b. see spec_helper for imports and constants

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
        # n.b. coupled to view
        email = "2019-01-01T12:00:00+0000 foo1@bar.com: Foo Bar"
        find('#emails').select(email)
      end

      it "shows the contents for the email" do
        within_frame('email_content') do
          expect(page).to have_text("First message.")
        end
      end
    end

    context "the second email is selected" do
      before(:example) do
        # n.b. coupled to view
        email = "2019-01-01T12:01:00+0000 foo2@bar.com: Foo2 Bar"
        find('#emails').select(email)
      end

      it "shows the contents for the email" do
        within_frame('email_content') do
          expect(page).to have_text("Second message.")
        end
      end
    end
  end
end
