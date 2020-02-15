import json
import mailbox
import os
import sqlite3

import requests

from codecs import decode
from contextlib import contextmanager
from os.path import abspath, join
from subprocess import PIPE, Popen
from tempfile import TemporaryDirectory

from mamba import context, description, it, fit
from expects import contain, equal, expect
from retrying import retry




@retry(wait_fixed=2000, stop_max_delay=30000)
def wait_for_server(uri="http://localhost:5000/status"):
  requests.get(uri)




@contextmanager
def corpus_server(
  mbox_path=None,
  db_path=None,
  flask_app=abspath("corpus_server.py"),
  wait=True,
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
      server = Popen(["flask", "run"], cwd=tmpd, env=env, stdout=PIPE, stderr=PIPE)

      if wait:
        wait_for_server()

      info = {
        "proc": server,
        "port": 5000,
        "tmpd": tmpd,
      }
      yield info
    except (AssertionError, requests.ConnectionError):
      server.kill()
      outs, errs = server.communicate(timeout=5)
      print("Assertion failed in ctx mgr")
      if outs is not None:
        print("server STDOUT:")
        print(decode(outs, 'utf-8', 'replace'))
      if errs is not None:
        print("server STDERR:")
        print(decode(errs, 'utf-8', 'replace'))
      raise
    finally:
      server.kill()
      outs, errs = server.communicate()




with description('Corpus Server') as self:
  with context('run in a directory with no mbox or DB'):
    with it('fails to run the server'):
      with corpus_server(mbox_path="nonex.mbox", wait=False) as server_info:
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
      with corpus_server(mbox_path=mbox_path) as server_info:
        response = requests.get("http://localhost:5000/api/emails")
        expect(response.status_code).to(equal(200))

        data = json.loads(response.text)
        expect(len(data["emails"])).to(equal(3))


    with context('date filtering'):
      # timestamps in happy are:
      #   1546344000
      #   1546344060
      #   1546516920
      with it('is able to return /api/emails?after='):
        mbox_path = abspath("specs/happy.mbox")
        with corpus_server(mbox_path=mbox_path) as server_info:
          response = requests.get("http://localhost:5000/api/emails?after=1546345000")
          expect(response.status_code).to(equal(200))

          data = json.loads(response.text)
          expect(len(data["emails"])).to(equal(1))


      with it('is able to return /api/emails?before='):
        mbox_path = abspath("specs/happy.mbox")
        with corpus_server(mbox_path=mbox_path) as server_info:
          response = requests.get("http://localhost:5000/api/emails?before=1546345000")
          expect(response.status_code).to(equal(200))

          data = json.loads(response.text)
          expect(len(data["emails"])).to(equal(2))


      with it('is able to return /api/emails?after=&before='):
        mbox_path = abspath("specs/happy.mbox")
        with corpus_server(mbox_path=mbox_path) as server_info:
          response = requests.get("http://localhost:5000/api/emails?after=1546344001&before=1546345000")
          expect(response.status_code).to(equal(200))

          data = json.loads(response.text)
          expect(len(data["emails"])).to(equal(1))



    with context('/api/email/<sender>/<timestamp>/<content>'):
      with it('/api/email/foo@bar.com/1546344000/plain'):
        mbox_path = abspath("specs/happy.mbox")
        with corpus_server(mbox_path=mbox_path) as server_info:
            response = requests.get("http://localhost:5000/api/email/foo@bar.com/1546344000/plain")
            expect(response.status_code).to(equal(200))

            expect(response.text).to(contain("First message."))


      with it('/api/email/foo2@bar.com/1546344060/plain'):
        mbox_path = abspath("specs/happy.mbox")
        with corpus_server(mbox_path=mbox_path) as server_info:
          response = requests.get("http://localhost:5000/api/email/foo2@bar.com/1546344060/plain")
          expect(response.status_code).to(equal(200))

          expect(response.text).to(contain("Second message."))


      with it('/api/email/foo2@bar.com/1546344060/html'):
        mbox_path = abspath("specs/happy.mbox")
        with corpus_server(mbox_path=mbox_path) as server_info:
          response = requests.get("http://localhost:5000/api/email/foo2@bar.com/1546344060/html")
          expect(response.status_code).to(equal(200))

          expect(response.text).to(contain("Second message."))
          expect(response.text).to(contain("<p>"))


      with it('/api/email/foo3@baz.com/1546516920/html'):
        mbox_path = abspath("specs/happy.mbox")
        with corpus_server(mbox_path=mbox_path) as server_info:
          response = requests.get("http://localhost:5000/api/email/foo3@baz.com/1546516920/html")
          expect(response.status_code).to(equal(200))

          expect(response.text).to(contain("HTML only message."))



    if sqlite3.sqlite_version >= "3.24":
      with it('PATCH /api/email/foo@bar.com/1546344000/plain'):
        mbox_path = abspath("specs/happy.mbox")
        with corpus_server(mbox_path=mbox_path) as server_info:
          req_data = json.dumps({
            "note": "updated note"
          })
          response = requests.patch("http://localhost:5000/api/email/foo@bar.com/1546344000", data=req_data)
          expect(response.status_code).to(equal(200))

          expect(response.text).to(contain("updated"))
