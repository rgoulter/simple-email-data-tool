from flask import Flask, Response, request

import json

import mailbox

from os import getenv
import os
from os.path import abspath, dirname, isfile, join

import requests

import sqlite3

from subprocess import Popen, run

import sys

from . import email_db




mbox_path = getenv("CORPUS_MBOX", 'receipts.mbox')
db_path = getenv("CORPUS_MBOX", 'receipts.db')




if not isfile(mbox_path):
  print("no mbox at CORPUS_MBOX (%s) or CWD/receipts.mbox" % (mbox_path), file=sys.stderr)
  sys.exit(1)




schema_file = join(dirname(__file__), "schema.sql")
if not isfile(db_path):
  # create an empty file
  run(["sqlite3", db_path, "-init", schema_file])




static_folder = join(dirname(__file__), "corpus-client/build/")
app = Flask(__name__, static_folder = static_folder)




@app.route('/status')
def status():
  return json.dumps({'success': True})




@app.route('/')
@app.route('/elm')
@app.route('/index.html')
def elm():
  return app.send_static_file('index.html')




@app.route('/api/emails')
def emails():
  global db_name, mbox_path

  mbox = mailbox.mbox(mbox_path)
  conn = sqlite3.connect(db_name)

  emails = email_db.fetch_emails_info(conn, mbox)

  mbox.close()
  conn.close()

  return json.dumps(emails)




@app.route('/api/email/<sender>/<timestamp>', methods=['GET', 'PATCH'])
def email(sender, timestamp):
  global db_name, mbox_path

  mbox = mailbox.mbox(mbox_path)
  conn = sqlite3.connect(db_name)

  if (request.method == "PATCH"):
    data = json.loads(request.data)
    note = data["note"]

    email = email_db.update_note(conn, mbox, sender, int(timestamp), note)
  else:
    email = email_db.fetch_emails_info(conn, mbox, sender, int(timestamp))

  mbox.close()
  conn.close()

  return json.dumps(email)




@app.route('/api/email/<sender>/<timestamp>/<content_subtype>')
def email_content(sender, timestamp, content_subtype):
  global mbox_path

  mbox = mailbox.mbox(mbox_path)

  msg = email_db.get_message_from_mbox(mbox, sender, int(timestamp))
  content = plaintext_payloads_of_mail(msg)

  mbox.close()

  return Response(content[content_subtype], mimetype = "text/" + content_subtype)
