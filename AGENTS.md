# Agent guidance

This repo is video-description, a Bun/TypeScript CLI for drafting and revising YouTube descriptions through OpenRouter. It runs on Windows and macOS.

## Working here

- Keep source in this clone. `C:\dev\tools` holds generated Windows stubs and separately installed large binaries, never source files. Do not commit `.exe` or `.dll` files.
- Use test-first development for non-trivial changes. Extract a test seam if necessary, then add the test before changing behavior.
- Rerun relevant tests after behavior, startup, copy, persistence or tested contracts change. Update expectations in the same change.
- Before committing, run `bun test` and `bunx tsc --noEmit`, then smoke-test the affected launcher or script and check exit codes. Use local fixtures and mocked processes rather than paid API calls.
- Parse every `.ps1` with `[System.Management.Automation.Language.Parser]::ParseFile`. Run `pwsh -NoProfile -File tests/install.Tests.ps1` for installer helper checks. Windows registry checks need Windows.
- Write `.bat` stubs with `-Encoding ASCII`. Use ASCII paths for the Windows clone and quote paths with spaces.
- `install.ps1` installs only this tool; `install.sh` links only its POSIX launcher. Rerun the installer after moving the clone or changing generated stubs. Source edits take effect without reinstalling.
- Keep the shared `Mike's Tools` submenu intact. Create it if missing, preserve other verbs and existing submenu properties, and remove only this tool's entries during uninstall.

## deps.ps1 convention

- Dependency setup is idempotent and self-contained: `powershell -NoProfile -ExecutionPolicy Bypass -File .\deps.ps1` must work by itself.
- Detect system tools with `Get-Command`, report missing prerequisites clearly, and propagate install failures. Always restore the working directory with `try/finally`.
- `install.ps1` runs this repo's `deps.ps1` unless `-SkipDeps` is supplied.
- Large manual-download binaries stay outside this repo. Transcription dependencies belong to the separately installed transcribe tool.

## video-description specifics

- `index.ts` is the CLI entry point. Read `.env` from this clone's root, independent of the user's working directory. `.env.example` lists the required key, `OPENROUTER_API_KEY`.
- Preserve adjacent `<videoname>.srt` inputs and `<videoname>-description.txt` conversation files. Existing conversations must remain resumable.
- `lib/run-transcribe.ts` calls the optional [transcribe](https://github.com/mikecann/transcribe) tool. On Windows it prefers `C:\dev\tools\transcribe.bat`; otherwise it uses PATH. Keep path-with-spaces handling covered by tests. Do not add a sibling checkout dependency.
- `video-description` is the macOS Bash launcher and resolves symlinks through Python 3. Test it through the installed symlink from a different working directory.
- This is an interactive console tool, so Explorer commands intentionally use `cmd.exe /k`. No silent GUI launcher is needed.
- Model and output instructions are the `MODEL` and `SYSTEM_PROMPT` constants. Keep network tests mocked and never require API keys in CI.

## Writing

Keep docs plain, friendly and personal where expressing Mike's opinion. Do not use em dashes or en dashes. PR descriptions begin with `## Why` and explain what prompted the change.
