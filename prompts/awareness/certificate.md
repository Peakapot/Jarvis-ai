# awareness · certificate

The Completion Certificate generator (`workflows/awareness/certificate.json`) is
**template-driven — there is no AI prompt**. The form (or Telegram command)
supplies the recipient name, course/topic, date and an optional certificate ID
(auto-generated if blank). `Render HTML` builds a diploma-style **landscape A4**
certificate — teal/gold frame, issuer = `CLIENT_NAME` (falls back to "Security
Awareness Team"), signature/date lines and a unique certificate ID — and
Gotenberg renders it to a PDF in `/reports/awareness/certificates/`. It pairs
with the quiz and e-learning module to recognise course completion.
