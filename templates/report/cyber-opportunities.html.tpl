<!--
  Cyber Opportunities Brief — CONTENT fragment.
  Rendered INTO templates/report/intelligence-base.html.tpl ({{CONTENT}} slot),
  so it inherits the shared premium branding automatically (common branding
  framework). This fragment defines the product's required section skeleton; the
  workflow injects the analyst's Markdown-rendered HTML per section, or this
  skeleton's "No data" fallbacks on reduced coverage (Fail-safe defaults).

  Product defaults for the base template:
    PRODUCT_NAME = Daily Cyber Opportunities Intelligence Brief
    SUBTITLE     = Cybersecurity consulting & managed-services opportunity radar
  Required sections (order): Executive Summary, Top Opportunities,
    Regional Breakdown, High Priority Opportunities, Strategic Relevance,
    Recommended Actions, Win Probability Assessment, Opportunity Archive,
    Historical Trends.
-->
<section data-section="executive-summary">
  <h2>Executive Summary</h2>
  {{EXECUTIVE_SUMMARY}}
</section>

<section data-section="top-opportunities">
  <h2>Top Opportunities</h2>
  {{TOP_OPPORTUNITIES}}
</section>

<section data-section="regional-breakdown">
  <h2>Regional Breakdown</h2>
  <p class="pill">Primary: UAE · Saudi Arabia · Qatar · Oman · Bahrain · Kuwait &nbsp;|&nbsp; Secondary: UK · Europe · Global</p>
  {{REGIONAL_BREAKDOWN}}
</section>

<section data-section="high-priority">
  <h2>High Priority Opportunities</h2>
  {{HIGH_PRIORITY}}
</section>

<section data-section="strategic-relevance">
  <h2>Strategic Relevance</h2>
  {{STRATEGIC_RELEVANCE}}
</section>

<section data-section="recommended-actions">
  <h2>Recommended Actions</h2>
  {{RECOMMENDED_ACTIONS}}
</section>

<section data-section="win-probability">
  <h2>Win Probability Assessment</h2>
  {{WIN_PROBABILITY}}
</section>

<section data-section="opportunity-archive">
  <h2>Opportunity Archive</h2>
  {{OPPORTUNITY_ARCHIVE}}
</section>

<section data-section="historical-trends">
  <h2>Historical Trends</h2>
  {{HISTORICAL_TRENDS}}
</section>
