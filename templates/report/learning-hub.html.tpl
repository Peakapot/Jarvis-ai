<!--
  Learning Hub magazine — CONTENT fragment (section skeleton).

  NOTE: the Learning Hub workflow renders a self-contained, print-ready A4
  magazine HTML inline in its "Render Magazine" code node (like cyber-brief),
  so this fragment is not strictly required at runtime. It is provided for the
  shared-branding path and to document the edition's section order, matching the
  module.json `report.sections`. To render via the shared base template instead,
  inject the analyst's section HTML into the tokens below and wrap with
  templates/report/intelligence-base.html.tpl ({{CONTENT}} slot).

  Section order: Editor's Welcome, Feature, Emerging Threats, The Human Firewall,
  Skills & Qualifications, Jargon Buster.
-->
<section data-section="editorial">
  <h2>Editor’s Welcome</h2>
  {{EDITORIAL}}
</section>

<section data-section="feature">
  <h2>Feature</h2>
  {{FEATURE}}
</section>

<section data-section="threats">
  <h2>Emerging Threats</h2>
  {{THREATS}}
</section>

<section data-section="human-firewall">
  <h2>The Human Firewall</h2>
  {{AWARENESS}}
</section>

<section data-section="skills">
  <h2>Skills &amp; Qualifications</h2>
  {{QUALS}}
</section>

<section data-section="glossary">
  <h2>Jargon Buster</h2>
  {{GLOSSARY}}
</section>
