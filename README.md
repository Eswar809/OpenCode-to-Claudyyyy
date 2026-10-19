# opencode-proxy-rs — High-Performance Anthropic API Gateway for OpenCode Zen

Existing community proxies in the wild suffer from broken tool calls, infinite thinking-spinner hangs, dropped image attachments, and non-functional web search. After extensive live testing against the upstream endpoints, I built **`opencode-proxy-rs`** from the ground up in Rust to serve as a zero-compromise, production-grade translation gateway between **Claude Code (`[http://127.0.0.1:8084/v1/messages](http://127.0.0.1:8084/v1/messages)`)** and **OpenCode Zen (`opencode.ai/inference/v1/chat/completions` & `/v1/responses`)**.

---

## Core Architecture & Supported Anthropic Features

* **Full Anthropic `/v1/messages` & `/v1/messages/count_tokens` Parity:** Implements the complete Anthropic streaming SSE state machine (`message_start`, `content_block_start`, `content_block_delta`, `signature_delta`, `content_block_stop`, `message_delta`, `message_stop`) alongside non-streaming event folding. Token counting is computed conservatively on the transformed upstream payload so Claude Code triggers context compaction at the exact right threshold.


* **Multi-Agent Fan-Out, Subagents & Dynamic Tool Resolution:** Built for parallel agent execution with a `10ms` burst-safe request pacer that prevents subagents from serializing behind a global lock. Tracks mid-conversation tool mutations (`tool_addition`, `tool_removal`, `tool_reference`, and `defer_loading`), normalizes schema argument aliases (`path` ↔ `file_path`, `cmd` ↔ `command`), and automatically injects required OpenCode v2 fingerprint tools (`read`, `shell`).


* **Native Web Search & Deep Research (`web_search_20250305`):** Because upstream OpenCode models cannot browse the live web, the gateway intercepts native `web_search_*` turns before model routing and executes them locally against **Exa (`mcp.exa.ai`)** and **Parallel (`search.parallel.ai`)** MCP endpoints. Supports `allowed_domains` and `blocked_domains` filtering, URL canonicalization, deduplication, and untrusted-evidence framing, returning native `server_tool_use` and `web_search_tool_result` blocks.


* **Extended Thinking & Interleaved Reasoning:** Strictly gates thinking blocks to prevent unasked reasoning from hanging the Claude Code UI, coalesces tiny reasoning deltas into `384B` / `30ms` frames, and signs every thinking block with a valid `SHA-256` base64 `signature_delta`. Automatically preserves `reasoning_content` across multi-turn assistant history for interleaved reasoning models (`deepseek-*`, `glm-*`, `big-pickle`).


* **Multimodal Vision, PDF Extraction & Smart Media Budgeting:** Preserves screenshots at `detail: "high"` (including images returned inside `tool_result` blocks) and extracts text from base64 PDFs in-memory via `lopdf`. Enforces a sliding media budget (retaining up to `8` media items and `12 MB` across the newest `8` messages) and automatically strips media when falling back to text-only models.


* **Session Affinity & Prompt Caching (4-Breakpoint Cap):** Mints and caches canonical OpenCode session IDs (`ses_<12hex><14base62>`) with valid inverted timestamps and forwards `prompt_cache_key` for multi-turn cache hits. Applies `cache_control: {"type": "ephemeral"}` on the system prompt and trailing conversation turns while strictly enforcing the 4-breakpoint upstream ceiling.


* **Resilient Auto-Fallback Chain & Sticky Proxy Pool:** Automatically walks the fallback model chain on `429`, `5xx`, transport timeouts, or intermittent `403 FreeTierError` responses. 


## Model Routing Table (`/v1/models`)

| Client Model Alias (Claude Code) | Mapped OpenCode Upstream Model | Context Window | Vision Support |
| --- | --- | --- | --- |
| `default` / `minimax-m3.1-flash-free` / `space-bunny*` | `minimax-m3.1-flash-free` | `1,000,000` | Yes (`high` detail) |
| `claude-opus-5-5` / `opus-5-5` | `deepseek-v4.1-flash-free` | `200,000` | Yes |
| `claude-opus-5` / `claude-opus-4-7` / `opus` | `step-5-preview-free` | `1,000,000` | Yes |
| `claude-fable-5` | `longcat-2.5-preview-free` | `1,000,000` | Yes |
| `claude-fable-5-1` | `glm-5.3-flash-free` | `200,000` (`32k` out cap) | Yes |
| `claude-sonnet-5-5` / `claude-sonnet-5` / `sonnet` | `cat-jam-free` | `1,000,000` | Text-only |
| `claude-haiku-5-5` / `claude-haiku-4-5` / `haiku` | `nemotron-3.5-super-vl-free` | `1,000,000` | Yes |

---

## Important Note on `glm-5.3-flash-free` & Reasoning Effort (`max` vs `high`/`xhigh`)

* **`glm-5.3-flash-free` (`claude-fable-5-1`) Upstream Instability:** Based on extensive testing, `glm-5.3-flash-free` is currently unstable on the OpenCode provider side and enforces a strict `32,000` max output token ceiling.


* **Avoid `max` Reasoning Effort:** Do **not** use `max` effort (especially on `glm-5.3-flash-free`), as `max` reasoning effort causes severe upstream latency spikes, timeouts, and provider-side errors on OpenCode's backend.


* **Recommended Setting:** Use **`high`** or **`xhigh`** effort for fast, reliable reasoning and tool execution without hitting upstream timeouts.



---

## Quick Start & Setup

1. **Configure Claude Code Automatically (Windows):**
Run `setup.cmd` to automatically create or merge the proxy configuration into `%USERPROFILE%\.claude\settings.json` (`ANTHROPIC_BASE_URL=[http://127.0.0.1:8084](http://127.0.0.1:8084)`, `ANTHROPIC_API_KEY=public`, and `enableArtifact=false`) while preserving all existing settings.

