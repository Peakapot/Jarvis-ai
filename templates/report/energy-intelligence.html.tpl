<!--
  Energy Intelligence Brief — CONTENT fragment.
  Rendered INTO templates/report/intelligence-base.html.tpl ({{CONTENT}} slot),
  inheriting the shared premium branding (common branding framework). Defines
  the product's required section skeleton; the workflow injects analyst output
  per section, with "No data" fallbacks on reduced coverage (Fail-safe defaults).

  Product defaults for the base template:
    PRODUCT_NAME = Daily Energy Intelligence Brief
    SUBTITLE     = UAE & ADNOC ecosystem · regional & global oil, gas and energy
  Required sections (order): Executive Summary, Top Stories, ADNOC Focus,
    UAE Focus, Regional Focus, Global Focus, Strategic Implications,
    Investment Activity, Digital Transformation Activity, Cybersecurity Activity,
    Emerging Trends.
-->
<section data-section="executive-summary">
  <h2>Executive Summary</h2>
  {{EXECUTIVE_SUMMARY}}
</section>

<section data-section="top-stories">
  <h2>Top Stories</h2>
  {{TOP_STORIES}}
</section>

<section data-section="adnoc-focus">
  <h2>ADNOC Focus</h2>
  <p class="pill">ADNOC · ADNOC Gas · ADNOC Drilling · TA'ZIZ · Borouge</p>
  {{ADNOC_FOCUS}}
</section>

<section data-section="uae-focus">
  <h2>UAE Focus</h2>
  <p class="pill">TAQA · Masdar · Mubadala Energy · UAE energy sector</p>
  {{UAE_FOCUS}}
</section>

<section data-section="regional-focus">
  <h2>Regional Focus</h2>
  <p class="pill">Saudi Aramco · QatarEnergy · GCC developments</p>
  {{REGIONAL_FOCUS}}
</section>

<section data-section="global-focus">
  <h2>Global Focus</h2>
  <p class="pill">Shell · BP · Chevron · ExxonMobil · TotalEnergies</p>
  {{GLOBAL_FOCUS}}
</section>

<section data-section="strategic-implications">
  <h2>Strategic Implications</h2>
  {{STRATEGIC_IMPLICATIONS}}
</section>

<section data-section="investment-activity">
  <h2>Investment Activity</h2>
  {{INVESTMENT_ACTIVITY}}
</section>

<section data-section="digital-transformation">
  <h2>Digital Transformation Activity</h2>
  {{DIGITAL_TRANSFORMATION}}
</section>

<section data-section="cybersecurity-activity">
  <h2>Cybersecurity Activity</h2>
  {{CYBERSECURITY_ACTIVITY}}
</section>

<section data-section="emerging-trends">
  <h2>Emerging Trends</h2>
  {{EMERGING_TRENDS}}
</section>
