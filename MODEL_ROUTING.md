# Model Routing — Claude Code → OpenCode Upstream

This proxy sits between Claude Code and OpenCode's free inference tier.
Claude model names are mapped to upstream OpenAI-compatible models.

## Quick Reference

| Claude Model | Upstream Model | Wire | Context |
|---|---|---|---|
| **claude-fable-5-1** | `glm-5.3-flash-free` | chat | 200k |
| **claude-fable-5** | `longcat-2.5-preview-free` | chat | 1M |
| **claude-opus-5** | `step-5-preview-free` | chat | 1M |
| **claude-opus-5-5** | `deepseek-v4.1-flash-free` | chat | 200k |
| **claude-sonnet-5-5** | `cat-jam-free` | chat | 1M |
| **claude-sonnet-5** | `cat-jam-free` | chat | 1M |
| **claude-haiku-5-5** | `nemotron-3.5-super-vl-free` | chat | 1M |
| **claude-haiku-5** | `nemotron-3.5-super-vl-free` | chat | 1M |
| **claude-opus-4-7** | `step-5-preview-free` | chat | 1M |
| **claude-opus-4-6** | `step-5-preview-free` | chat | 1M |
| **claude-opus-4-5** | `step-5-preview-free` | chat | 1M |
| **claude-sonnet-4-6** | `cat-jam-free` | chat | 1M |
| **claude-sonnet-4-5** | `cat-jam-free` | chat | 1M |
| **claude-3-opus** | `step-5-preview-free` | chat | 1M |
| **claude-3-5-sonnet-20241022** | `cat-jam-free` | chat | 1M |
| **claude-3-5-haiku-20241022** | `nemotron-3.5-super-vl-free` | chat | 1M |
| **claude-haiku-4-5** | `nemotron-3.5-super-vl-free` | chat | 1M |
| **claude-haiku-4-5-20251001** | `nemotron-3.5-super-vl-free` | chat | 1M |

## Shortcuts (substring match)

| You type | Routes to |
|---|---|
| `opus` | `step-5-preview-free` |
| `opus-5-5` | `deepseek-v4.1-flash-free` |
| `sonnet` | `cat-jam-free` |
| `haiku` | `nemotron-3.5-super-vl-free` |
| `fable-5-1` / `fable-5.1` | `glm-5.3-flash-free` |
| `fable-5` | `longcat-2.5-preview-free` |
| `bunny` / `minimax` / `m3.1` / `m3-1` | `minimax-m3.1-flash-free` |
| `deepseek` | `deepseek-v4.1-flash-free` |
| `glm` | `glm-5.3-flash-free` |

## Default Model

When no model is specified (or an unknown model is requested), the proxy
falls back to:

```
minimax-m3.1-flash-free
```

## Fallback Chain

On 400/429/5xx errors, the proxy walks this chain in order:

1. `minimax-m3.1-flash-free`
2. `nemotron-3.5-super-vl-free`
3. `glm-5.3-flash-free`
4. `nemotron-3.5-lightning-free`
5. `mimo-v2.6-flash-free`
6. `big-pickle`
7. `longcat-2.5-preview-free`
8. `deepseek-v4.1-flash-free`
9. `cat-jam-free`
10. `step-5-preview-free`

Terminal errors (no fallback): `context_length_error`, `invalid_request_error`,
`authentication_error`.

## Vision-Capable Models

These upstream models accept image/video input:

- `minimax-m3.1-flash-free`
- `glm-5.3-flash-free`
- `longcat-2.5-preview-free`
- `step-5-preview-free`
- `mimo-v2.6-flash-free`
- `deepseek-v4.1-flash-free`
- `nemotron-3.5-super-vl-free`

All other models get media stripped before the payload goes upstream.

## Two Wires

| | Chat wire | Responses wire |
|---|---|---|
| **Models** | everything except muse-spark | `muse-spark*` only |
| **Detection** | `!uses_responses(model)` | `model.starts_with("muse-spark")` |
| **Effort field** | `reasoning_effort` | `reasoning.effort` |
| **Max output** | 65,536 | 131,072 |
| **URL** | `/v1/chat/completions` | `/v1/responses` |

## Context Windows

| Model | Window |
|---|---|
| `minimax-m3.1-flash-free` | 1,000,000 |
| `longcat-2.5-preview-free` | 1,000,000 |
| `cat-jam-free` | 1,000,000 |
| `step-5-preview-free` | 1,000,000 |
| `nemotron-3.5-super-vl-free` | 1,000,000 |
| `nemotron-3.5-lightning-free` | 262,144 |
| `ling-3.1-flash-free` | 262,144 |
| `mimo-v2.6-flash-free` | 200,000 |
| `big-pickle` | 200,000 |
| `deepseek-v4.1-flash-free` | 200,000 |
| `glm-5.3-flash-free` | 200,000 |

## Backward Compatibility

All `space-bunny*` aliases still work and route to `minimax-m3.1-flash-free`:

- `space-bunny` → `minimax-m3.1-flash-free`
- `spacebunny` → `minimax-m3.1-flash-free`
- `space-bunny-alpha` → `minimax-m3.1-flash-free`
- `space-bunny-alpha-free` → `minimax-m3.1-flash-free`
- `space-bunny-free` → `minimax-m3.1-flash-free`
- `space-bunny-free[1m]` → `minimax-m3.1-flash-free`
- `space-bunny[1m]` → `minimax-m3.1-flash-free`
