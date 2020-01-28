# n.b. see spec_helper for imports and constants

feature "client make notes about the selected email" do
  include_context "logger"
  include_context "runs elm reactor"
  include_context "able to run sinatra examples"

  # SEE: /spec/zoo/<example>.rb
  context "PATCH /email/<from>/<timestamp>/ returns successfully" do
    around(:example) do |example|
      run_sinatra_example("emails_happy", &example)
    end

    before(:example) do
      visit CLIENT_PATH
    end

    context "a note is made for the first email" do
      before(:example) do
        # n.b. coupled to view
        email = "2019-01-01T12:00:00+0000 foo1@bar.com: Foo Bar"
        find('#emails').select(email)

        find('#note').fill_in(with: 'updated note for email 1')
        find('#note').send_keys :enter
        # wait for the request to finish
        expect(find('#summary')).to have_text('updated note for email 1')
      end

      it "persists the note after a refresh" do
        refresh

        email = "2019-01-01T12:00:00+0000 foo1@bar.com: Foo Bar"
        find('#emails').select(email)

        expect(page).to have_field('note', with:'updated note for email 1', wait: 10)
      end

      it "shows the note in the summary" do
        expect(find('#summary')).to have_text(<<~TEXT.strip)
          2019-01-01
          updated note for email 1
          # foo1@bar.com: Foo Bar
        TEXT
      end

      it "can update the note" do
        find('#note').fill_in(with: 'different arbitrary note')
        find('#note').send_keys :enter
        # wait for the request to finish
        expect(find('#summary')).to have_text('different arbitrary note')

        refresh

        email = "2019-01-01T12:00:00+0000 foo1@bar.com: Foo Bar"
        find('#emails').select(email)

        expect(page).to have_field('note', with: 'different arbitrary note')
      end

      context "a note is made for the second email" do
        before(:example) do
          # n.b. coupled to view
          email = "2019-01-01T12:01:00+0000 foo2@bar.com: Foo2 Bar"
          find('#emails').select(email)

          find('#note').fill_in(with: 'updated note for email 2')
          find('#note').send_keys :enter
          # wait for the request to finish
          expect(find('#summary')).to have_text('updated note for email 2')
        end

        it "shows both notes in the summary" do
          expect(find('#summary')).to have_text(<<~TEXT.strip)
            2019-01-01
            updated note for email 1
            # foo1@bar.com: Foo Bar
            updated note for email 2
            # foo2@bar.com: Foo2 Bar
          TEXT
        end
      end

      context "a note is made for an email on a different date" do
        before(:example) do
          # n.b. coupled to view
          email = "2019-01-03T12:02:00+0000 foo3@baz.com: Foo3 Bar"
          find('#emails').select(email)

          find('#note').fill_in(with: 'updated note for email 3')
          find('#note').send_keys :enter
          # wait for the request to finish
          expect(find('#summary')).to have_text('updated note for email 3')
        end

        it "shows both notes in the summary" do
          expect(find('#summary')).to have_text(<<~TEXT.strip)
            2019-01-01
            updated note for email 1
            # foo1@bar.com: Foo Bar

            2019-01-03
            updated note for email 3
            # foo3@baz.com: Foo3 Bar
          TEXT
        end
      end
    end
  end
end
