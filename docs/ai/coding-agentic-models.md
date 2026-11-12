# Coding and Agentic Models

A short comparison of language models that work well for software development and agentic tool use in OpenCode.

Benchmark scores and prices come from vendors and third-party trackers. They are not directly comparable and change
frequently, so verify the current conditions before choosing a model.

> **Verified on 2026-11-12.** The free model IDs and prices can change. Check the
> [OpenCode Console models](https://opencode.ai/docs/console/models/),
> [Kilo free models](https://kilo.ai/landing/free-models), and
> [OpenRouter models](https://openrouter.ai/models?max_price=0) before relying on them.

## 🧭 Overview

| Model | Provider | Best for | Notes |
|---|---|---|---|
| DeepSeek V4.1 Flash | DeepSeek | Default for coding and agentic loops | Strong reasoning and tool calling, 1M context, low cost |
| Nemotron 3 Ultra 550B-A55B | NVIDIA | Enterprise agentic work, long context | 55B active parameters, native speculative decoding |
| Inkling | Thinking Machines | Multimodal agentic work | Text, image, audio, and video input; adjustable thinking depth |
| Nemotron 3.5 Super VL | NVIDIA | Vision and video agentic work | Hybrid Mamba-Transformer, agentic software engineering |
| MiMo-V2.6-Flash | Xiaomi | Cost-sensitive multimodal tasks | Cheapest per token, but weaker agentic score |
| North Mini Code | Cohere | Lightweight code-focused tasks | Small and cheap, limited agentic capability |

## 📊 Architecture and Parameters

Flagship models:

| Feature | Inkling | Nemotron 3.5 Super VL | Nemotron 3 Ultra 550B-A55B |
|---|---|---|---|
| Total parameters | 975B | 120B | 550B |
| Active parameters | 41B | 12B | 55B |
| Architecture | MoE Transformer | Hybrid Mamba-Transformer (MoE) | Hybrid Mamba-Transformer (MoE) |
| Modalities | Text, image, audio, video (input) | Text, image, video (input) | Text (input/output) |
| Context window | up to 1M tokens | up to 1M tokens | up to 1M tokens |
| Special features | Adjustable thinking effort, encoder-free audio/vision | Native speculative decoding (MTP), agentic software engineering | Native speculative decoding (MTP), enterprise agents |

Efficient and code-focused models:

| Feature | DeepSeek V4.1 Flash | MiMo-V2.6-Flash | North Mini Code |
|---|---|---|---|
| Provider | DeepSeek | Xiaomi | Cohere |
| Context window | 1M tokens | 1.05M tokens | 256K tokens |
| Input price | about $0.09–0.30 / 1M tokens | $0.10 / 1M tokens | varies by provider |
| Output price | about $0.25–1.20 / 1M tokens | $0.28 / 1M tokens | varies by provider |
| Modalities | Text, image, reasoning | Text, image, audio, video, PDF | Text / code |
| Coding index | strong (e.g. 62.9 on BenchLM) | not separately listed | 36.5 (OpenRouter / Artificial Analysis) |
| Agentic score | strong (e.g. AutomationBench about 60.5%) | lower (about 48.8% on AutomationBench) | Agentic Index 1.1 |
| Latency / throughput | fast, responsive in agent loops | about 2.85 s p50, 26 tok/s | no public p50 data |

## 🎯 Recommendations

1. **Default:** DeepSeek V4.1 Flash. It combines a 1M context window, reliable tool calling, and low cost. It is the
   recommended default in this guide.
2. **Multimodal:** Inkling when audio or video input matters, or Nemotron 3.5 Super VL for image and video-heavy
   agentic workflows.
3. **Enterprise and long-running agents:** Nemotron 3 Ultra 550B-A55B with native speculative decoding.
4. **Budget:** MiMo-V2.6-Flash. Accept a lower agentic score in exchange for very low token prices.
5. **Small code helper:** North Mini Code for lightweight completion and refactoring tasks, not for long agent loops.

For agentic work, prioritize reliable tool calling, context handling, and multi-step completion over raw chat quality.

## 🆓 Free and Included Providers

### OpenCode (built-in)

The `opencode` provider is integrated into OpenCode and needs no `provider` block in the configuration. Sign in with
`/connect` or set `OPENCODE_API_KEY`; free models then appear in `/models`.

Free model IDs:

| Model ID | Use case |
|---|---|
| `opencode/deepseek-v4.1-flash-free` | Coding and agentic work (recommended default) |
| `opencode/nemotron-3-ultra-free` | Long-context agentic work |
| `opencode/nemotron-3.5-super-vl-free` | Image and video input |
| `opencode/glm-5.3-flash-free` | Coding and general tasks |
| `opencode/mimo-v2.6-flash-free` | Cost-sensitive multimodal tasks |
| `opencode/flint-40b-free` | Coding experiments |
| `opencode/beam-free` | Agentic experiments |

Free models are offered for a limited time and can disappear or change. Free availability and privacy conditions are
documented at [OpenCode Console Models](https://opencode.ai/docs/console/models/#free-models).

### Kilo AI Gateway and OpenRouter

Both gateways provide free model catalogs and are described in
[Agentic AI and OpenCode](./agentic-opencode.md). Kilo also serves the free variants of Nemotron 3 Ultra and
Nemotron 3.5 Super VL.

## ⚙️ Configuration

The `opencode` provider is built in, so a minimal configuration only sets the default models:

```jsonc
{
  "$schema": "https://opencode.ai/config.json",
  "model": "opencode/deepseek-v4.1-flash-free",
  "small_model": "kilo/nvidia/nemotron-3-ultra-550b-a55b:free",
}
```

Notes:

- Use the `-free` suffix for the free OpenCode variants. `opencode/deepseek-v4.1-flash` without the suffix is a paid
  Console model.
- A model ID always needs a provider prefix. `nvidia/nemotron-3-ultra-550b-a55b` does not resolve on its own; use
  `kilo/nvidia/nemotron-3-ultra-550b-a55b:free` or the OpenCode equivalent.
- `small_model` is deprecated in OpenCode V2 and kept here for compatibility with existing configurations.

## 🚀 Usage

Select a model for the current session:

```text
/models
```

Run a single prompt with an explicit model:

```bash
opencode run --model opencode/deepseek-v4.1-flash-free "Refactor parseToken"
```

Hide all free models on a server:

```bash
OPENCODE_DISABLE_FREE_MODELS=1 opencode serve
```

## 📝 Notes

- Prices, free quotas, and benchmark values are volatile. Re-check them before relying on a model in a workflow.
- Some free endpoints log requests or use them to improve the model. Do not submit confidential source code, secrets, or
  personal data unless the provider's terms allow it.
- For local or self-hosted alternatives, see [Agentic AI and OpenCode](./agentic-opencode.md).
