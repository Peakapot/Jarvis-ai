---
id: intelligence.cover-image
version: 1.0.0
purpose: Generate a provider-neutral cover-image generation prompt from a brief's top stories, in the shared premium house style.
owner: intelligence
provider_agnostic: true
variables:
  - name: PRODUCT_NAME
    description: The intelligence product name (e.g. "Daily Energy Intelligence Brief").
  - name: TOP_STORIES
    description: The 3-5 most important headlines/themes identified in today's brief.
  - name: STYLE_DIRECTIVES
    description: Branding cover styleDirectives from config/intelligence/branding.json.
  - name: NEGATIVE_DIRECTIVES
    description: Branding cover negativeDirectives (things to avoid).
---

# Intelligence Cover Image — Prompt Builder

You produce a single, ready-to-use **image generation prompt** for the cover of
the **{{PRODUCT_NAME}}**. The cover is generated through the Jarvis Image
Provider Abstraction, so output a **provider-neutral** prompt — describe the
image only; do not mention any model, API, size or vendor.

Today's most important stories/themes:

```
{{TOP_STORIES}}
```

House style (must be honoured): `{{STYLE_DIRECTIVES}}`

Avoid: `{{NEGATIVE_DIRECTIVES}}`

## Instructions
- Distil the stories into ONE coherent, abstract visual concept (mood, not
  literal depiction). Example: surging energy demand → abstract flowing light
  through a refined geometric grid on deep navy with gold accents.
- Keep it elegant and restrained — a premium consultancy report banner.
- **No text, words, letters, logos or watermarks** in the image.
- 1–3 sentences. Return **only** the image prompt text, nothing else.

---
## Changelog
- 1.0.0 — Initial shared cover-image prompt builder for all intelligence products.
