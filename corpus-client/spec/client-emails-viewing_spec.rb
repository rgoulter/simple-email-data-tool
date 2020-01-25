require 'capybara'
require 'capybara/rspec'

require 'rspec'

require 'tempfile'

Capybara.default_driver = :selenium_chrome

ELM_REACTOR_PORT=8900

CLIENT_PATH='/src/Main.elm'

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
  context "when /email/<from>/<timestamp>/ returns successfully" do
    around(:example) do |example|
      run_sinatra("emails_happy", &example)
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

      it "shows the email" do
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

      it "shows the email" do
        within_frame('email_content') do
          expect(page).to have_text("Second message.")
        end
      end
    end
  end
end
