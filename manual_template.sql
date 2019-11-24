-- receipt, items for email
-- FROM {{from_email}}
-- DATE {{date}}
-- SUBJ {{subject}}
{%- if plaintext %}
-- PLAIN: {{plaintext}}
{% endif %}
{%- if html %}
-- HTML: {{html}}
{% endif %}
WITH emails AS (SELECT id
                FROM emails
                WHERE date = ''
                  AND from_email = ''
                  AND subject = '')
INSERT INTO `receipts` (total, currency, verified, email_id)
VALUES (1.00, 'SGD', 1, emails.id);

UPDATE emails
SET receipt_id = (SELECT id FROM receipts WHERE rowid = last_insert_rowid())
WHERE date = ''
  AND from_email = ''
  AND subject = '';

WITH receipts AS (SELECT id FROM receipts WHERE rowid = last_insert_rowid())
INSERT INTO ITEMS (description, amount, currency, receipt_id)
VALUES ('', 1.00, '', receipts.id)
     , ('', 1.00, '', receipts.id)
     , ('', 1.00, '', receipts.id);
