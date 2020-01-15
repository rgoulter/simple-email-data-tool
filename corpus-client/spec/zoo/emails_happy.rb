require 'json'
require 'sinatra'

get '/emails' do
  response['Access-Control-Allow-Origin'] = '*'
  {
    status: 'success',
    emails: [
      {
        from: "foo1@bar.com",
        timestamp: "1546344060",
        datetime: "2019-01-01T12:00:00+0000",
        subject: "Foo Bar",
        plain: true,
        html: false,
      },
      {
        from: "foo2@bar.com",
        datetime: "2019-01-01T12:01:00+0000",
        timestamp: "1546344120",
        subject: "Foo2 Bar",
        plain: true,
        html: false,
      },
      {
        from: "foo3@baz.com",
        datetime: "2019-01-01T12:02:00+0000",
        timestamp: "1546344180",
        subject: "Foo3 Bar",
        plain: true,
        html: false,
      },
    ]
  }.to_json
end
