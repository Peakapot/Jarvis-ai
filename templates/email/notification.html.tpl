<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <!--
    Generic notification email template. Provider-neutral (works across
    Gmail / Microsoft 365 / SMTP via the Email Provider Abstraction).
    Placeholders: {{SUBJECT}}, {{HEADING}}, {{BODY}}, {{FOOTER}}.
  -->
  <title>{{SUBJECT}}</title>
</head>
<body style="font-family: -apple-system, Segoe UI, Roboto, Arial, sans-serif; color:#1a1a1a; margin:0; padding:0; background:#f5f6f8;">
  <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background:#f5f6f8; padding:24px 0;">
    <tr>
      <td align="center">
        <table role="presentation" width="600" cellpadding="0" cellspacing="0" style="background:#ffffff; border-radius:8px; overflow:hidden;">
          <tr>
            <td style="background:#0b5; color:#fff; padding:16px 24px; font-size:18px; font-weight:600;">
              🤖 Jarvis · {{HEADING}}
            </td>
          </tr>
          <tr>
            <td style="padding:24px; font-size:15px; line-height:1.6;">
              {{BODY}}
            </td>
          </tr>
          <tr>
            <td style="padding:16px 24px; border-top:1px solid #eee; color:#888; font-size:12px;">
              {{FOOTER}}
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
</body>
</html>
