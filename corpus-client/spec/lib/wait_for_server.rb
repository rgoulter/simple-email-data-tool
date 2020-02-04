require 'net/http'

module WaitForServer
  # Polls the given URI with GET requests until the server
  # returns with a status-code less-than 500.
  #
  def self.poll!(uri_s, poll_interval: 3, open_timeout: 5, timeout: 40)
    uri = URI(uri_s)

    begin
      res = Net::HTTP.start(uri.host, uri.port, open_timeout: open_timeout) do |http|
        request = Net::HTTP::Get.new uri

        response = http.request request # Net::HTTPResponse object
        response.code.to_i
      end
    rescue Errno::ECONNREFUSED, Net::OpenTimeout => e
      timeout -= open_timeout if e.class == Errno::ECONNREFUSED

      unless (res && res < 500) || timeout < 0
        sleep poll_interval
        timeout -= poll_interval
        retry
      end
    end

    raise "waited too long" if timeout <= 0
  end
end
