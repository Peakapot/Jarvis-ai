<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <!--
    Shared premium base template for ALL Jarvis intelligence products
    (common branding framework). Product workflows fill {{MUSTACHE}} tokens via
    their render node. Palette/typography mirror config/intelligence/branding.json
    so every brief — Cyber, Cyber Opportunities, Energy and future products —
    shares one consistent, premium visual style across HTML / PDF / email.

    Tokens: {{PRODUCT_NAME}} {{DATE}} {{SUBTITLE}} {{COVER_IMAGE_URL}}
            {{CONFIDENTIALITY}} {{CONTENT}} {{FOOTER_DISCLAIMER}} {{WORDMARK}}
  -->
  <title>{{PRODUCT_NAME}} — {{DATE}}</title>
  <style>
    :root {
      --primary:#0A1A2F; --primary-dark:#05101F; --accent:#C9A24B;
      --accent-bright:#E7C76A; --surface:#FFFFFF; --surface-muted:#F4F6F9;
      --ink:#11151C; --ink-muted:#5A6472; --line:#E2E6EC;
      --high:#B02525; --medium:#B8860B; --low:#1E8E5A;
    }
    * { box-sizing: border-box; }
    body { font-family: -apple-system,'Segoe UI',Roboto,Helvetica,Arial,sans-serif;
           color: var(--ink); margin:0; background: var(--surface-muted); line-height:1.55; }
    .page { max-width: 860px; margin: 0 auto; background: var(--surface); }
    /* Cover */
    .cover { position: relative; background: var(--primary); color:#fff; }
    .cover img { width:100%; height:280px; object-fit:cover; display:block; opacity:0.9; }
    .cover .overlay { position:absolute; inset:0; background:linear-gradient(180deg, rgba(5,16,31,0.25), rgba(5,16,31,0.85)); }
    .cover .cap { position:absolute; left:0; right:0; bottom:0; padding:24px 32px; }
    .wordmark { font-family:Georgia,'Times New Roman',serif; letter-spacing:2px; color:var(--accent-bright); font-size:13px; text-transform:uppercase; }
    .cover h1 { font-family:Georgia,serif; font-size:26px; margin:6px 0 2px; }
    .cover .subtitle { color:#cdd5e0; font-size:14px; }
    .cover .date { color:var(--accent-bright); font-size:13px; margin-top:6px; }
    .conf { position:absolute; top:16px; right:24px; font-size:11px; letter-spacing:1px;
            border:1px solid var(--accent); color:var(--accent-bright); padding:3px 8px; border-radius:3px; }
    /* Body */
    main { padding: 28px 32px 8px; }
    h2 { font-family:Georgia,serif; font-size:18px; color:var(--primary);
         border-left:4px solid var(--accent); padding-left:12px; margin:30px 0 10px; }
    h3 { font-size:15px; margin:18px 0 6px; }
    a { color:#1457a8; }
    .sev-high { color:var(--high); font-weight:700; }
    .sev-medium { color:var(--medium); font-weight:700; }
    .sev-low { color:var(--low); font-weight:700; }
    .pill { display:inline-block; font-size:11px; padding:2px 8px; border-radius:10px;
            background:var(--surface-muted); border:1px solid var(--line); color:var(--ink-muted); }
    table { border-collapse:collapse; width:100%; font-size:14px; margin:8px 0; }
    th,td { border:1px solid var(--line); padding:8px 10px; text-align:left; vertical-align:top; }
    th { background:var(--surface-muted); }
    footer { margin-top:24px; padding:18px 32px; border-top:3px solid var(--accent);
             background:var(--primary); color:#aeb8c6; font-size:12px; }
    footer .fw { color:var(--accent-bright); font-family:Georgia,serif; letter-spacing:1px; }
    pre { white-space:pre-wrap; font-family:inherit; }
  </style>
</head>
<body>
  <div class="page">
    <header class="cover">
      <span class="conf">{{CONFIDENTIALITY}}</span>
      <img src="{{COVER_IMAGE_URL}}" alt="" onerror="this.style.display='none'" />
      <div class="overlay"></div>
      <div class="cap">
        <div class="wordmark">{{WORDMARK}}</div>
        <h1>{{PRODUCT_NAME}}</h1>
        <div class="subtitle">{{SUBTITLE}}</div>
        <div class="date">{{DATE}}</div>
      </div>
    </header>

    <main>
      <!-- Analyst output (Markdown rendered to HTML) injected here. -->
      {{CONTENT}}
    </main>

    <footer>
      <div class="fw">{{WORDMARK}}</div>
      {{FOOTER_DISCLAIMER}}
    </footer>
  </div>
</body>
</html>
