# n.b. see spec_helper for imports and constants

feature "client can view the contents of the selected email" do
  # Run/kill the elm-reactor
  around(:example) do |example|
    puts "running elm reactor on port #{ELM_REACTOR_PORT}"
    tmp_elm_out = Tempfile.new("rspec-elm-out")
    tmp_elm_err = Tempfile.new("rspec-elm-err")
    elm_server_pid = Process.spawn(
      "elm reactor --port=#{ELM_REACTOR_PORT}",
      out: tmp_elm_out.path,
      err: tmp_elm_err.path
    )

    Capybara.app_host = "http://localhost:#{ELM_REACTOR_PORT}"

    example.run
  ensure
    puts "killing elm reactor port=#{ELM_REACTOR_PORT}; pid=#{elm_server_pid}"
    Process.kill('KILL', elm_server_pid)
  end

  def run_sinatra(example_name)
    port = 8901  # hardcoded in the Elm client

    puts "running sinatra (#{example_name}) on port #{port}"
    sinatra_src = "spec/zoo/#{example_name}.rb"

    throw "bad sinatra example_name; could not find: #{sinatra_src}" unless File.file? sinatra_src

    tmp_out = Tempfile.new("rspec-sinatra-out")
    tmp_err = Tempfile.new("rspec-sinatra-err")
    server_pid = Process.spawn(
      "ruby #{sinatra_src} -p #{port}",
      out: tmp_out.path,
      err: tmp_err.path
    )

    yield
  ensure
    puts "killing sinatra (#{example_name}) port=#{port}; pid=#{server_pid}"
    Process.kill('KILL', server_pid) if server_pid
  end

  # SEE: /spec/zoo/<example>.rb
  context "when PATCH /email/<from>/<timestamp>/ returns successfully" do
    around(:example) do |example|
      run_sinatra("emails_happy", &example)
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

      it "persists the note on refresh" do
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

      it "updates the note" do
        find('#note').fill_in(with: 'different arbitrary note')
        find('#note').send_keys :enter
        # wait for the request to finish
        expect(find('#summary')).to have_text('different arbitrary note')

        refresh

        email = "2019-01-01T12:00:00+0000 foo1@bar.com: Foo Bar"
        find('#emails').select(email)

        # XXX race conditions; need to ensure that we wait before refreshing
        expect(page).to have_field('note', with: 'different arbitrary note', wait: 10)
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
