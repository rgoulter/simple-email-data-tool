# A simple flask server to serve both the static index.html
# file built by elm,
# and forward requests that the elm client makes against /api/*
# to the sinatra servers under ./spec/zoo.
import json

import requests

from flask import Flask, Response, request

app = Flask(__name__, static_folder="../build/")


@app.route('/status')
def status():
    return json.dumps({'success': True})


@app.route('/')
@app.route('/elm')
@app.route('/index.html')
def elm():
    return app.send_static_file('index.html')


@app.route('/api/<path:subpath>', methods=['GET', 'PATCH'])
def sinatra_api(subpath):
    forward_to = "http://localhost:8901/" + subpath
    if (request.method == "PATCH"):
      r = requests.patch(forward_to, data=request.data)
    else:
      r = requests.get(forward_to + "?" + request.query_string.decode("utf-8"))
    return Response(
      r.text,
      status=r.status_code,
      content_type=r.headers['content-type'],
    )
