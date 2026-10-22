# Joblite frontend

OTP app: `:joblite_web`. Module namespace: `JobliteWeb`.
Phoenix LiveView and HEEx own the browser experience; there is no React app.
Backend is a sibling path dependency at `../backend`.

See `docs/FRONTEND_GUIDE.md` and `../backend/docs/DEVELOPMENT_HANDBOOK.md`.
After completing the toolchain/dependency gates:

```bash
mix deps.get
mix format
mix assets.setup
mix assets.build
mix test
mix phx.server
```

Production assembly: `MIX_ENV=prod mix assets.deploy`, then
`MIX_ENV=prod mix release joblite`. Build both repositories from a tested commit pair.
Compilation, dependency resolution and release boot are not yet verified; see core's STATUS.md.
