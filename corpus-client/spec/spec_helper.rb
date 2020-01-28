# This file was generated by the `rspec --init` command. Conventionally, all
# specs live under a `spec` directory, which RSpec adds to the `$LOAD_PATH`.
# The generated `.rspec` file contains `--require spec_helper` which will cause
# this file to always be loaded, without a need to explicitly require it in any
# files.
#
# Given that it is always loaded, you are encouraged to keep this file as
# light-weight as possible. Requiring heavyweight dependencies from this file
# will add to the boot time of your test suite on EVERY test run, even for an
# individual file that may not need all of that loaded. Instead, consider making
# a separate helper file that requires the additional dependencies and performs
# the additional setup, and require it from the spec files that actually need
# it.
#
# See http://rubydoc.info/gems/rspec-core/RSpec/Core/Configuration

require 'capybara'
require 'capybara/rspec'

require 'logger'

require 'os'

require 'pry'

require 'rspec'

require 'tempfile'

require './spec/lib/wait_for_server'

Capybara.default_driver =
  case ENV['SELENIUM_BROWSER']
  when 'selenium_chrome'
    :selenium_chrome
  when 'selenium_chrome_headless'
    :selenium_chrome_headless
  when 'selenium'
    :selenium
  else
    :selenium_headless
  end

Capybara.default_max_wait_time = 30 if ENV['CI']

ELM_PORT=8900

CLIENT_PATH='/index.html'

RSpec.configure do |config|
  config.before(:suite) do
    BUILD_DIR =
      if OS.windows?
        Dir.mktmpdir("rspec-elm")
      else
        Dir.mkdir('build') unless File.exists?('build')
        'build'
      end
    tmp_out = Tempfile.new("rspec-elm-out")
    tmp_err = Tempfile.new("rspec-elm-err")
    cmd = "elm make src/Main.elm --output=#{BUILD_DIR}/index.html"
    elm_make_pid = Process.spawn(
      cmd,
      out: tmp_out.path,
      err: tmp_err.path
    )

    _, status = Process.wait2 elm_make_pid

    unless status.exitstatus.zero?
      puts "command: '#{cmd}'"
      puts "exit status: #{status.exitstatus}"
      puts "out log file:"
      puts File.read(tmp_out)
      puts "err log file:"
      puts File.read(tmp_err)
      raise "failed to build"
    end
  end
end

RSpec.shared_context "logger" do
  logfile = Tempfile.new("execspec-log")
  logger = Logger.new(logfile)
  logger.level = Logger::INFO
  let(:logger) { logger }
end

RSpec.shared_context "runs elm reactor" do
  # Run/kill the elm-reactor
  around(:example) do |example|
    logger.info("running static server on port #{ELM_PORT}")
    tmp_out = Tempfile.new("rspec-static-out")
    tmp_err = Tempfile.new("rspec-static-err")
    server_pid = Process.spawn(
      "python -m http.server #{ELM_PORT}",
      out: tmp_out.path,
      err: tmp_err.path,
      chdir: BUILD_DIR,
    )

    begin
      WaitForServer.poll!("http://localhost:#{ELM_PORT}/")
    rescue RuntimeError
      puts "out log file:"
      puts File.read(tmp_out)
      puts "err log file:"
      puts File.read(tmp_err)
      raise "failed to run static server"
    end

    Capybara.app_host = "http://localhost:#{ELM_PORT}"

    example.run
  ensure
    logger.info("killing statis server port=#{ELM_PORT}; pid=#{server_pid}")
    Process.kill('KILL', server_pid)
  end
end

RSpec.shared_context "able to run sinatra examples" do
  def run_sinatra_example(example_name)
    port = 8901  # hardcoded in the Elm client

    logger.info("running sinatra (#{example_name}) on port #{port}")
    sinatra_src = "spec/zoo/#{example_name}.rb"

    throw "bad sinatra example_name; could not find: #{sinatra_src}" unless File.file? sinatra_src

    tmp_out = Tempfile.new("rspec-sinatra-out")
    tmp_err = Tempfile.new("rspec-sinatra-err")
    server_pid = Process.spawn(
      "ruby #{sinatra_src} -p #{port}",
      out: tmp_out.path,
      err: tmp_err.path,
    )

    begin
      WaitForServer.poll!("http://localhost:#{port}/")
    rescue RuntimeError
      puts "out log file:"
      puts File.read(tmp_out)
      puts "err log file:"
      puts File.read(tmp_err)
      raise "failed to run sinatra for #{example_name}"
    end

    yield
  ensure
    logger.info("killing sinatra (#{example_name}) port=#{port}; pid=#{server_pid}")
    Process.kill('KILL', server_pid) if server_pid
  end
end

RSpec.configure do |config|
  # rspec-expectations config goes here. You can use an alternate
  # assertion/expectation library such as wrong or the stdlib/minitest
  # assertions if you prefer.
  config.expect_with :rspec do |expectations|
    # This option will default to `true` in RSpec 4. It makes the `description`
    # and `failure_message` of custom matchers include text for helper methods
    # defined using `chain`, e.g.:
    #     be_bigger_than(2).and_smaller_than(4).description
    #     # => "be bigger than 2 and smaller than 4"
    # ...rather than:
    #     # => "be bigger than 2"
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  # rspec-mocks config goes here. You can use an alternate test double
  # library (such as bogus or mocha) by changing the `mock_with` option here.
  config.mock_with :rspec do |mocks|
    # Prevents you from mocking or stubbing a method that does not exist on
    # a real object. This is generally recommended, and will default to
    # `true` in RSpec 4.
    mocks.verify_partial_doubles = true
  end

  # This option will default to `:apply_to_host_groups` in RSpec 4 (and will
  # have no way to turn it off -- the option exists only for backwards
  # compatibility in RSpec 3). It causes shared context metadata to be
  # inherited by the metadata hash of host groups and examples, rather than
  # triggering implicit auto-inclusion in groups with matching metadata.
  config.shared_context_metadata_behavior = :apply_to_host_groups

# The settings below are suggested to provide a good initial experience
# with RSpec, but feel free to customize to your heart's content.
=begin
  # This allows you to limit a spec run to individual examples or groups
  # you care about by tagging them with `:focus` metadata. When nothing
  # is tagged with `:focus`, all examples get run. RSpec also provides
  # aliases for `it`, `describe`, and `context` that include `:focus`
  # metadata: `fit`, `fdescribe` and `fcontext`, respectively.
  config.filter_run_when_matching :focus

  # Allows RSpec to persist some state between runs in order to support
  # the `--only-failures` and `--next-failure` CLI options. We recommend
  # you configure your source control system to ignore this file.
  config.example_status_persistence_file_path = "spec/examples.txt"

  # Limits the available syntax to the non-monkey patched syntax that is
  # recommended. For more details, see:
  #   - http://rspec.info/blog/2012/06/rspecs-new-expectation-syntax/
  #   - http://www.teaisaweso.me/blog/2013/05/27/rspecs-new-message-expectation-syntax/
  #   - http://rspec.info/blog/2014/05/notable-changes-in-rspec-3/#zero-monkey-patching-mode
  config.disable_monkey_patching!

  # This setting enables warnings. It's recommended, but in some cases may
  # be too noisy due to issues in dependencies.
  config.warnings = true

  # Many RSpec users commonly either run the entire suite or an individual
  # file, and it's useful to allow more verbose output when running an
  # individual spec file.
  if config.files_to_run.one?
    # Use the documentation formatter for detailed output,
    # unless a formatter has already been configured
    # (e.g. via a command-line flag).
    config.default_formatter = "doc"
  end

  # Print the 10 slowest examples and example groups at the
  # end of the spec run, to help surface which specs are running
  # particularly slow.
  config.profile_examples = 10

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = :random

  # Seed global randomization in this process using the `--seed` CLI option.
  # Setting this allows you to use `--seed` to deterministically reproduce
  # test failures related to randomization by passing the same `--seed` value
  # as the one that triggered the failure.
  Kernel.srand config.seed
=end
end
