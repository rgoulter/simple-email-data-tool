require 'capybara'
require 'capybara/rspec'

require 'rspec'

require 'tempfile'

Capybara.default_driver = :selenium_chrome

ELM_REACTOR_PORT=8900

CLIENT_PATH='/src/Main.elm'

feature "client displays email-address" do
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

  context "when /email-addresses returns successfully" do
    # TODO: SERVE happy-path (run sinatra)
    it "shows the email-addresses" do
      visit CLIENT_PATH

      expect(page).to have_selector('option')
    end
  end
end
