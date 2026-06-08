# awareness · poster-explainer

System prompt for the Poster & Explainer generator (embedded in the AI nodes of
`workflows/awareness/poster-explainer.json`). The AI returns a JSON object with
`poster {headline, tagline, points[]}` and `explainer {title, intro, why,
redFlags[], dos[], donts[]}` for the requested topic, in plain non-technical
language. The poster backdrop is a separate AI image (no text/faces); Gotenberg
renders a 2-page PDF (poster + explainer).
