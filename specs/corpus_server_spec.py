import json
import mailbox
import os
import sqlite3
import subprocess
import sys
import time

import requests

from contextlib import contextmanager
from os.path import abspath, join
from subprocess import PIPE, Popen, TimeoutExpired
from tempfile import TemporaryDirectory

from mamba import context, description, it
from expects import contain, equal, expect

from specs.context import email_db



@contextmanager
def corpus_server(
  mbox_path = None,
  db_path = None,
  flask_app = abspath("corpus_server.py")
):
  with TemporaryDirectory() as tmpd:
    if mbox_path is None:
      mbox_path = join(tmpd, "empty.mbox")
      mbox = mailbox.mbox(mbox_path)
      mbox.close()
    if db_path is None:
      db_path = join(tmpd, "test.db")
    env = {
      "FLASK_APP": flask_app,
      "CORPUS_MBOX": mbox_path,
      "CORPUS_DB": db_path,
      "PATH": os.environ["PATH"],
      "LC_ALL": "C.UTF-8",
      "LANG": "C.UTF-8",
    }
    if 'SYSTEMROOT' in os.environ:  # Windows http://bugs.python.org/issue20614
      env[str('SYSTEMROOT')] = os.environ['SYSTEMROOT']

    try:
      server = Popen(["flask", "run"], cwd = tmpd, env = env, stdout = PIPE, stderr = PIPE)

      # Wait for Server to be ready
      # XXX
      if os.environ.get("CI"):
        time.sleep(5)

      info = {
        "proc": server,
        "port": 5000,
        "tmpd": tmpd,
      }
      yield info
    except AssertionError:
      print("Assertion failed in ctx mgr")
      print("server STDOUT:")
      print(server.stdout.decode("unicode_escape"))
      print("server STDERR:")
      print(server.stderr.decode("unicode_escape"))
      raise
    finally:
      server.kill()
      outs, errs = server.communicate()




with description('Corpus Server') as self:
  # n.b. Python/mamba doesn't allow sharing variables here?!
  with context('run in a directory with no mbox or DB'):
    with it('fails to run the server'):
      with corpus_server(mbox_path = "nonexistant.mbox") as server_info:
        poll = server_info["proc"].wait(timeout=30)

        expect(poll).to(equal(1))



  with context('run in a directory with an empty mbox, but no DB'):
    with it('is able to return /status successfully'):
      with corpus_server() as server_info:
        response = requests.get("http://localhost:5000/status")
        expect(response.status_code).to(equal(200))


    with it('is able to return /api/emails successfully with empty result'):
      with corpus_server() as server_info:
        response = requests.get("http://localhost:5000/api/emails")
        expect(response.status_code).to(equal(200))

        data = json.loads(response.text)
        expect(len(data["emails"])).to(equal(0))



  with context('run with specs/happy.mbox, but no DB'):
    with it('is able to return /api/emails successfully with 3 results'):
      mbox_path = abspath("specs/happy.mbox")
      with corpus_server(mbox_path = mbox_path) as server_info:
        response = requests.get("http://localhost:5000/api/emails")
        expect(response.status_code).to(equal(200))

        data = json.loads(response.text)
        expect(len(data["emails"])).to(equal(3))

    with context('/api/email/<sender>/<timestamp>/<content>'):
      with it('/api/email/foo@bar.com/1546344000/plain'):
        mbox_path = abspath("specs/happy.mbox")
        with corpus_server(mbox_path = mbox_path) as server_info:
            response = requests.get("http://localhost:5000/api/email/foo@bar.com/1546344000/plain")
            expect(response.status_code).to(equal(200))

            expect(response.text).to(contain("First message."))

      with it('/api/email/foo2@bar.com/1546344060/plain'):
        mbox_path = abspath("specs/happy.mbox")
        with corpus_server(mbox_path = mbox_path) as server_info:
          response = requests.get("http://localhost:5000/api/email/foo2@bar.com/1546344060/plain")
          expect(response.status_code).to(equal(200))

          expect(response.text).to(contain("Second message."))

      with it('/api/email/foo2@bar.com/1546344060/html'):
        mbox_path = abspath("specs/happy.mbox")
        with corpus_server(mbox_path = mbox_path) as server_info:
          response = requests.get("http://localhost:5000/api/email/foo2@bar.com/1546344060/html")
          expect(response.status_code).to(equal(200))

          expect(response.text).to(contain("Second message."))
          expect(response.text).to(contain("<p>"))

      with it('/api/email/foo3@baz.com/1546516920/html'):
        mbox_path = abspath("specs/happy.mbox")
        with corpus_server(mbox_path = mbox_path) as server_info:
          response = requests.get("http://localhost:5000/api/email/foo3@baz.com/1546516920/html")
          expect(response.status_code).to(equal(200))

          expect(response.text).to(contain("HTML only message."))

    if sqlite3.sqlite_version >= "3.24":
      with it('PATCH /api/email/foo@bar.com/1546344000/plain'):
        mbox_path = abspath("specs/happy.mbox")
        with corpus_server(mbox_path = mbox_path) as server_info:
          req_data = json.dumps({
            "note": "updated note"
          })
          response = requests.patch("http://localhost:5000/api/email/foo@bar.com/1546344000", data = req_data)
          expect(response.status_code).to(equal(200))

          expect(response.text).to(contain("updated"))
