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


with description('Corpus Server') as self:
  # n.b. Python/mamba doesn't allow sharing variables here?!
  with context('run in a directory with no mbox or DB'):
    with it('fails to run the server'):
      with TemporaryDirectory() as tmpd:
        flask_app = abspath("corpus_server.py")
        env = {
          "FLASK_APP": flask_app,
          "PATH": os.environ["PATH"],
          "LC_ALL": "C.UTF-8",
          "LANG": "C.UTF-8",
        }
        if 'SYSTEMROOT' in os.environ:  # Windows http://bugs.python.org/issue20614
          env[str('SYSTEMROOT')] = os.environ['SYSTEMROOT']
        server = Popen(["flask", "run"], cwd = tmpd, env = env, stdout=PIPE, stderr = PIPE)

        if os.environ.get("CI"):
          time.sleep(5)

        poll = server.wait(timeout=30)
        outs, errs = server.communicate()

        expect(poll).to(equal(1))

  with context('run in a directory with an empty mbox, but no DB'):
    with it('is able to return /status successfully'):
      with TemporaryDirectory() as tmpd:
        flask_app = abspath("corpus_server.py")
        empty_mbox_path = join(tmpd, "empty.mbox")
        empty_mbox = mailbox.mbox(empty_mbox_path)
        empty_mbox.close()
        env = {
          "FLASK_APP": flask_app,
          "CORPUS_MBOX": empty_mbox_path,
          "PATH": os.environ["PATH"],
          "LC_ALL": "C.UTF-8",
          "LANG": "C.UTF-8",
        }
        if 'SYSTEMROOT' in os.environ:  # Windows http://bugs.python.org/issue20614
          env[str('SYSTEMROOT')] = os.environ['SYSTEMROOT']

        # response = requests.get("http://localhost:5000/status")
        # expect(response.status_code).to(equal(200))
        try:
          server = Popen(["flask", "run"], cwd = tmpd, env = env, stdout = PIPE, stderr = PIPE)

          if os.environ.get("CI"):
            time.sleep(5)

          response = requests.get("http://localhost:5000/status")
          expect(response.status_code).to(equal(200))

        finally:
          server.kill()
          outs, errs = server.communicate()

    with it('is able to return /api/emails successfully with empty result'):
      with TemporaryDirectory() as tmpd:
        flask_app = abspath("corpus_server.py")
        empty_mbox_path = join(tmpd, "empty.mbox")
        empty_mbox = mailbox.mbox(empty_mbox_path)
        empty_mbox.close()
        env = {
          "FLASK_APP": flask_app,
          "CORPUS_MBOX": empty_mbox_path,
          "PATH": os.environ["PATH"],
          "LC_ALL": "C.UTF-8",
          "LANG": "C.UTF-8",
        }
        if 'SYSTEMROOT' in os.environ:  # Windows http://bugs.python.org/issue20614
          env[str('SYSTEMROOT')] = os.environ['SYSTEMROOT']

        try:
          server = Popen(["flask", "run"], cwd = tmpd, env = env, stdout = PIPE, stderr = PIPE)

          if os.environ.get("CI"):
            time.sleep(5)

          response = requests.get("http://localhost:5000/api/emails")
          expect(response.status_code).to(equal(200))

          data = json.loads(response.text)
          expect(len(data["emails"])).to(equal(0))

        finally:
          server.kill()
          outs, errs = server.communicate()

  with context('run with specs/happy.mbox, but no DB'):
    with it('is able to return /api/emails successfully with 3 results'):
      with TemporaryDirectory() as tmpd:
        flask_app = abspath("corpus_server.py")
        mbox_path = abspath("specs/happy.mbox")
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

          if os.environ.get("CI"):
            time.sleep(5)

          response = requests.get("http://localhost:5000/api/emails")
          expect(response.status_code).to(equal(200))

          data = json.loads(response.text)
          expect(len(data["emails"])).to(equal(3))

        finally:
          server.kill()
          outs, errs = server.communicate()

    with context('/api/email/<sender>/<timestamp>/<content>'):
      with it('/api/email/foo@bar.com/1546344000/plain'):
        with TemporaryDirectory() as tmpd:
          flask_app = abspath("corpus_server.py")
          mbox_path = abspath("specs/happy.mbox")
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

            if os.environ.get("CI"):
              time.sleep(5)

            response = requests.get("http://localhost:5000/api/email/foo@bar.com/1546344000/plain")
            expect(response.status_code).to(equal(200))

            expect(response.text).to(contain("First message."))
          finally:
            server.kill()
            outs, errs = server.communicate()

      with it('/api/email/foo2@bar.com/1546344060/plain'):
        with TemporaryDirectory() as tmpd:
          flask_app = abspath("corpus_server.py")
          mbox_path = abspath("specs/happy.mbox")
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

            if os.environ.get("CI"):
              time.sleep(5)

            response = requests.get("http://localhost:5000/api/email/foo2@bar.com/1546344060/plain")
            expect(response.status_code).to(equal(200))

            expect(response.text).to(contain("Second message."))
          finally:
            server.kill()
            outs, errs = server.communicate()

      with it('/api/email/foo2@bar.com/1546344060/html'):
        with TemporaryDirectory() as tmpd:
          flask_app = abspath("corpus_server.py")
          mbox_path = abspath("specs/happy.mbox")
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

            if os.environ.get("CI"):
              time.sleep(5)

            response = requests.get("http://localhost:5000/api/email/foo2@bar.com/1546344060/html")
            expect(response.status_code).to(equal(200))

            expect(response.text).to(contain("Second message."))
            expect(response.text).to(contain("<p>"))
          finally:
            server.kill()
            outs, errs = server.communicate()

      with it('/api/email/foo3@baz.com/1546516920/html'):
        with TemporaryDirectory() as tmpd:
          flask_app = abspath("corpus_server.py")
          mbox_path = abspath("specs/happy.mbox")
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

            if os.environ.get("CI"):
              time.sleep(5)

            response = requests.get("http://localhost:5000/api/email/foo3@baz.com/1546516920/html")
            expect(response.status_code).to(equal(200))

            expect(response.text).to(contain("HTML only message."))
          finally:
            server.kill()
            outs, errs = server.communicate()

    if sqlite3.sqlite_version >= "3.24":
      with it('PATCH /api/email/foo@bar.com/1546344000/plain'):
        with TemporaryDirectory() as tmpd:
          flask_app = abspath("corpus_server.py")
          mbox_path = abspath("specs/happy.mbox")
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

            if os.environ.get("CI"):
              time.sleep(5)

            req_data = json.dumps({
              "note": "updated note"
            })
            response = requests.patch("http://localhost:5000/api/email/foo@bar.com/1546344000", data = req_data)
            expect(response.status_code).to(equal(200))

            expect(response.text).to(contain("updated"))
          finally:
            server.kill()
            outs, errs = server.communicate()
