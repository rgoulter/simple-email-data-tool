from mamba import description, context, it
from expects import expect, equal

from specs.context import email_db

import mailbox

from os.path import abspath, join
import os

import requests

from subprocess import Popen, PIPE, TimeoutExpired
import subprocess

import sys

from tempfile import TemporaryDirectory




with description('Corpus Server') as self:
  # n.b. Python/mamba doesn't allow sharing variables here?!
  with context('run in a directory with no mbox or DB'):
    with it('fails to run the server'):
      with TemporaryDirectory() as tmpd:
        flask_app = abspath("corpus_server.py")
        env = {
          "FLASK_APP": flask_app,
        }
        if 'SYSTEMROOT' in os.environ:  # Windows http://bugs.python.org/issue20614
          env[str('SYSTEMROOT')] = os.environ['SYSTEMROOT']
        server = Popen(["flask", "run"], cwd = tmpd, env = env, stdout=PIPE, stderr = PIPE)

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
        }
        if 'SYSTEMROOT' in os.environ:  # Windows http://bugs.python.org/issue20614
          env[str('SYSTEMROOT')] = os.environ['SYSTEMROOT']

        server = Popen(["flask", "run"], cwd = tmpd, env = env, stdout = PIPE, stderr = PIPE)

        response = requests.get("http://localhost:5000/status")
        expect(response.status_code).to(equal(200))

        server.kill()
        outs, errs = server.communicate()
