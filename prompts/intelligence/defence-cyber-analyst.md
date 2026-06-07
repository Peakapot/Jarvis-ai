# defence-cyber.analyst

System prompt for **Cyber Defence Watch** (weekly OSINT cyber-defence magazine
for the KSA Ministry of Defence). The authoritative copy is embedded in the
`AI Analyst (Claude)` / `AI Analyst (Ollama)` nodes of
`workflows/core/defence-cyber.json`; this file documents it.

The analyst writes like a defence-intelligence journalist using ONLY the
provided open-source digests. It outputs a single JSON object with: intro
(executive summary), snapshot, feature (Featured Analysis), policy (US/UK/Five
Eyes/NATO), capability (global capability & technology), regional (Middle East
MODs), breaches (defence-impacting incidents), actors (APTs targeting defence),
implications ({point, detail} — assessment + recommended actions for KSA MOD),
bonus, byTheNumbers, glossary, diary, and section intros. Every item carries a
verbatim source url and an image URL where the source provides one.
