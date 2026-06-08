# awareness · elearning

System prompt for the E-learning Module generator (embedded in the AI nodes of
`workflows/awareness/elearning.json`). The AI acts as an instructional designer
and returns a single JSON object describing a short interactive micro-course:

```
{ title, intro,
  sections: [ { heading, body, keyPoints[] } ],   // 4-6 sections
  questions:[ { q, options[4], answer, why } ] }   // 4-6 knowledge-check items
```

`Render HTML` turns this into **one self-contained interactive lesson** (vanilla
JS: section navigation, progress bar, scored knowledge check, pass/fail and
answer review). The same HTML is **SCORM-aware** — it feature-detects an LMS
`API` in parent frames and, when present, reports `cmi.core.lesson_status` and
`cmi.core.score.raw` (and no-ops standalone). For SCORM delivery a pure-JS ZIP
writer packs `imsmanifest.xml` (SCORM 1.2, `index.html` as the SCO) + the lesson
into a `.zip`. Output (`.html` and/or `-scorm.zip`) is written to
`/reports/awareness/elearning/`. Content is tailored to the chosen **Audience**
and honours the **Pass mark**; no Gotenberg (interactive HTML, not PDF).
