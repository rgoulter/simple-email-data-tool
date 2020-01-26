require 'json'
require 'sinatra'
require 'sinatra/cross_origin'

configure do
  enable :cross_origin
end

# At the risk of depending too much on this 'mock',
# this lets us persist a note across the emails.
module Notes
  class << self
    attr_accessor :email1
    attr_accessor :email2
    attr_accessor :email3
  end
end

Notes.email1 = ""
Notes.email2 = ""
Notes.email3 = ""

get '/emails' do
  response['Access-Control-Allow-Origin'] = '*'
  {
    status: 'success',
    emails: [
      {
        from: "foo1@bar.com",
        timestamp: 1546344060,
        datetime: "2019-01-01T12:00:00+0000",
        subject: "Foo Bar",
        plain: true,
        html: false,
        note: Notes.email1,
      },
      {
        from: "foo2@bar.com",
        datetime: "2019-01-01T12:01:00+0000",
        timestamp: 1546344120,
        subject: "Foo2 Bar",
        plain: true,
        html: false,
        note: Notes.email2,
      },
      {
        from: "foo3@baz.com",
        datetime: "2019-01-03T12:02:00+0000",
        timestamp: 1546516980,
        subject: "Foo3 Bar",
        plain: true,
        html: false,
        note: Notes.email3,
      },
    ]
  }.to_json
end

get '/email/foo1@bar.com/1546344060/plain' do
  response['Access-Control-Allow-Origin'] = '*'
  response['Content-Type'] = 'text/plain'

  """
  Hi,

  First message.

  Regards,
  Sender
  """
end

get '/email/foo2@bar.com/1546344120/plain' do
  response['Access-Control-Allow-Origin'] = '*'
  response['Content-Type'] = 'text/plain'

  """
  Hi,

  Second message.

  Regards,
  Sender
  """
end

# update notes on the method
patch '/email/foo1@bar.com/1546344060' do
  response['Access-Control-Allow-Origin'] = '*'

  Notes.email1 = JSON.parse(request.body.string)["note"]

  {
    from: "foo1@bar.com",
    timestamp: 1546344060,
    datetime: "2019-01-01T12:00:00+0000",
    subject: "Foo Bar",
    plain: true,
    html: false,
    note: Notes.email1,
  }.to_json
end

patch '/email/foo2@bar.com/1546344120' do
  response['Access-Control-Allow-Origin'] = '*'

  Notes.email2 = JSON.parse(request.body.string)["note"]

  {
    from: "foo2@bar.com",
    datetime: "2019-01-01T12:01:00+0000",
    timestamp: 1546344120,
    subject: "Foo2 Bar",
    plain: true,
    html: false,
    note: Notes.email2,
  }.to_json
end

patch '/email/foo3@baz.com/1546516980' do
  response['Access-Control-Allow-Origin'] = '*'

  Notes.email3 = JSON.parse(request.body.string)["note"]

  {
    from: "foo3@baz.com",
    datetime: "2019-01-03T12:02:00+0000",
    timestamp: 1546516980,
    subject: "Foo3 Bar",
    plain: true,
    html: false,
    note: Notes.email3,
  }.to_json
end

options "*" do
  response.headers["Access-Control-Allow-Headers"] = "X-Requested-With, X-HTTP-Method-Override, Content-Type, Cache-Control, Accept"
  response.headers["Access-Control-Allow-Origin"] = "*"
  response.headers["Access-Control-Allow-Methods"] = "OPTIONS, PATCH"

  200
end
