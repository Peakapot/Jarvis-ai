# Branding assets (local)

Drop your **sign-off avatar** here as:

    config/branding/jarvis-avatar.png

The intelligence briefs embed it (base64) as a footer sign-off automatically on
every run. The image is **git-ignored** (this is a public repo) but is mounted
into n8n at `/config/branding/` and is included in `./backup.sh`, so it survives
restores. Keep it small (≈256×256) so emails stay light.
