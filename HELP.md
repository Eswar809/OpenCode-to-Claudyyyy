# HELP.md — How to run & set up the OpenCode proxy

This repository contains a high-performance OpenCode -> Anthropic (Claude) compatibility proxy. Below are detailed, step-by-step instructions to build, run, configure Claude Code to use the proxy, and troubleshoot common problems.

---

## Quick overview

- The proxy listens on http://127.0.0.1:8084 by default.
- The included `setup.cmd` script for Windows can automatically configure Claude Code to point at the proxy.
- To run the proxy from source you need Rust (cargo). The README and some scripts assume `cargo run --release` to start the proxy.

---

## Prerequisites

- Rust toolchain (rustc + cargo). Install from https://rustup.rs/.
- On Windows: PowerShell 5.1 (built-in on Windows 10/11) for `setup.cmd` merge steps.
- (Optional) `netstat` is used by `setup.cmd` to detect if the proxy is listening.

---

## 1) Build & run the proxy (development)

These steps assume you're in the repository root.

Windows / macOS / Linux (recommended using a terminal):

1. Install Rust toolchain if you haven't: `curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh` (or visit https://rustup.rs/)
2. Build & run in release mode:
   - From the repo root run: `cargo run --release`
3. By default the proxy binds to 127.0.0.1:8084. If the binary prints startup logs, verify the "listening" message.

Notes:
- If you only have the published executable (for Windows: `opencode-to-Claudying.exe`), you can run that instead of `cargo run`.
- If you prefer background running on Linux, consider `nohup cargo run --release &` or create a systemd service for production use.

---

## 2) Configure Claude Code (Windows helper)

A ready-made helper is included at `setup.cmd`. It will:

- Create or merge the `%USERPROFILE%\.claude\settings.json` file.
- Set the following values:
  - `env.ANTHROPIC_BASE_URL = http://127.0.0.1:8084`
  - `env.ANTHROPIC_API_KEY = public`
  - `enableArtifact = false`

Usage (Windows):
1. Start the proxy (see section 1).
2. Run `setup.cmd` by double-clicking it or from PowerShell/CMD.
3. The script checks if port 8084 is listening and will create/merge `settings.json`.

If you prefer to set values manually instead of running `setup.cmd`, edit `%USERPROFILE%\.claude\settings.json` and add/merge the `env` block (example below):

Example settings.json snippet:

{
  "env": {
    "ANTHROPIC_BASE_URL": "http://127.0.0.1:8084",
    "ANTHROPIC_API_KEY": "public"
  },
  "enableArtifact": false
}

---

## 3) Configure Claude Code (macOS / Linux)

Claude Code stores settings in a settings.json file under the user's home `.claude` folder. Create or update `~/.claude/settings.json` to include the same `env` block as the Windows example.

Example (bash):

mkdir -p ~/.claude
cat > ~/.claude/settings.json <<'JSON'
{
  "env": {
    "ANTHROPIC_BASE_URL": "http://127.0.0.1:8084",
    "ANTHROPIC_API_KEY": "public"
  },
  "enableArtifact": false
}
JSON

Note: Adjust the base URL and API key if you run the proxy on a different host/port or use stronger authentication.

---

## 4) Test the proxy

After starting the proxy, test it with curl or a browser:

1. Get model routing metadata (example):

curl -v -X GET "http://127.0.0.1:8084/v1/models" -H "Content-Type: application/json"

2. Simple messages endpoint test (replace payload with a valid Claude-compatible body if needed):

curl -v -X POST "http://127.0.0.1:8084/v1/messages" -H "Content-Type: application/json" -d '{"input": "hello"}'

If the proxy is up you'll get an HTTP response (200 or other code) and possibly a JSON body.

---

## 5) Common troubleshooting

- Port 8084 appears closed / connection refused:
  - Make sure the proxy process is running.
  - On Windows run `netstat -ano | findstr 8084` to see if the port is bound.
  - Check firewall rules that might block local connections.

- `setup.cmd` shows a PowerShell merge failure:
  - Run the script from an elevated terminal (Run as Administrator) or run the PowerShell snippet manually.
  - Verify PowerShell's ExecutionPolicy allows running scripts, or run with `-ExecutionPolicy Bypass` as the script does.

- Claude Code still tries to talk to the upstream provider:
  - Ensure `ANTHROPIC_BASE_URL` and `ANTHROPIC_API_KEY` are correctly set in `~/.claude/settings.json` (or `%USERPROFILE%\.claude\settings.json` on Windows).
  - Restart Claude Code after changes.

- Proxy fails with timeout / 5xx when forwarding:
  - Check the proxy logs printed on startup for the upstream error.
  - The README lists fallback behavior; some upstream models may be unstable. Try a different mapped model alias.

---

## 6) Running as a background service (Linux systemd example)

Create `/etc/systemd/system/opencode-proxy.service` with contents:

[Unit]
Description=OpenCode Proxy
After=network.target

[Service]
Type=simple
WorkingDirectory=/path/to/OpenCode-to-Claudyyyy
ExecStart=/usr/bin/env cargo run --release
Restart=on-failure
User=youruser

[Install]
WantedBy=multi-user.target

Then enable and start:

sudo systemctl daemon-reload
sudo systemctl enable --now opencode-proxy

Adjust `ExecStart` to the built binary path if you build a release binary first.

---

## 7) Security notes

- The repository ships with a default API key `public` for local testing. Do not expose the proxy to the public Internet with this key.
- If you need authentication, configure reverse proxying (nginx) with TLS and auth, or modify the proxy to require stronger API keys.

---

## 8) Help & contributions

If something is unclear, open an issue in this repository with the OS, Rust version, exact command you ran, and any logs. Contributions and pull requests to improve docs/scripts are welcome.

---

End of HELP.md
