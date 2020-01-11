require 'json'
require 'sinatra'

get '/email-addresses' do
  response['Access-Control-Allow-Origin'] = '*'
  {
    status: 'success',
    emails: [
      "foo1@bar.com",
      "foo2@bar.com",
      "foo3@baz.com",
    ]
  }.to_json
end
