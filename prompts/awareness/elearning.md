# awareness · elearning

System prompt for the E-learning Module generator (embedded in the AI nodes of
`workflows/awareness/elearning.json`). The AI acts as an instructional designer
and returns a single JSON object describing a short interactive micro-course:

```
{ title, intro,
  sections: [ { heading, body, keyPoints[], scene } ],   // 4-6 sections
  questions:[ { q, options[4], answer, why } ] }          // 4-6 knowledge-check items
```

Each section's **`scene`** is a one-sentence office-scene description written for
an illustrator. **Generate Section Images** turns each scene into a prompt with a
shared cinematic art direction (modern office, teal/deep-navy grade, soft light,
diverse professionals, no text/logos) and renders one image per section via the
image provider (`IMAGE_PROVIDER`/OpenAI), embedding them as data URIs so the
lesson stays self-contained. It degrades gracefully: with images turned off (form
or `ELEARNING_SECTION_IMAGES=false`) or no image key, each section falls back to a
branded gradient banner.

`Render HTML` turns this into **one self-contained, 16:9 full-screen interactive
lesson** designed to fill a monitor. Flow: an **AI cover** screen → **name entry**
(used on the certificate) → introduction → two-column sections (Ken-Burns hero
image + text + an **animated SVG icon** chosen from the heading) → knowledge
check → an **animated score ring** result → a **bedded-in premium completion
certificate** (gold seal/stamp, ornate border; rendered client-side from the
learner's name, score, date and a generated ID, with Print / Save-as-PDF). A
**voiceover** (browser Speech Synthesis) reads each screen aloud with
Narrate / Pause / Resume — zero-dependency, offline, no audio files. Motion is delivered with CSS/animated
SVG and Ken-Burns drift on the stills — the OpenAI image API returns static
images, not animated GIFs, so true raster animation would need a separate video
model. The lesson is **SCORM-aware** — it feature-detects an LMS `API`,
pre-fills the name from `cmi.core.student_name` when present, and reports
`cmi.core.lesson_status` and `cmi.core.score.raw` (and no-ops standalone). For
SCORM delivery a pure-JS ZIP writer packs `imsmanifest.xml` (SCORM 1.2,
`index.html` as the SCO) + the lesson into a `.zip`. Output (`.html` and/or
`-scorm.zip`) is written to `/reports/awareness/elearning/`. Content is tailored
to the chosen **Audience** and honours the **Pass mark**; no Gotenberg
(interactive HTML, not PDF).
