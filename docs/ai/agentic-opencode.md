# Agentic AI and OpenCode

## 🧭 Introduction

Agentic AI is a way of working with artificial intelligence in which a model does not only answer a question. It can pursue a goal, use tools, inspect results, and continue working until the task is complete or it needs human input.

This guide introduces the concepts, explains how to set up [OpenCode](https://opencode.ai/) on Linux, and shows how to connect free, hosted, or local models.

> **Verified against the OpenCode documentation on 2026-11-12.** Install commands and model availability change; check the linked official pages before relying on them.

## What is an AI agent?

A conventional chatbot usually follows a short loop:

1. The user asks a question.
2. The model generates an answer.
3. The conversation ends or waits for another prompt.

An agent follows a longer loop:

1. The user defines a goal.
2. The model analyzes the task and chooses an approach.
3. It uses tools to read files, run commands, search the web, or call APIs.
4. It evaluates the result.
5. It repeats the process if necessary.
6. It delivers a result or asks for human input.

Depending on its configuration, an agent can:

- Read, create, modify, and organize files.
- Execute commands in a terminal.
- Search the web and retrieve information.
- Interact with APIs and external services.
- Analyze and refactor source code.
- Create documents, spreadsheets, and presentations.
- Use Model Context Protocol (MCP) servers to access additional tools.
- Perform multi-step tasks with limited human intervention.

An agent does not automatically have all these capabilities. They depend on the selected model, available tools, permissions, and configuration.

## Models, agents, and tools

| Component | Responsibility |
|---|---|
| **LLM (large language model)** | Understands instructions, reasons about problems, and generates responses. |
| **Agent** | Coordinates the model, tools, instructions, and execution loop. |
| **Tools** | Provide capabilities such as file access, command execution, or external API access. |

A model without tools is essentially a chatbot. A model with powerful tools but weak reasoning may use them poorly. The combination of a capable model, a well-configured agent, and appropriate tools is what makes agentic AI useful.

## OpenCode

[OpenCode](https://opencode.ai/) is an open-source AI coding agent. It is available as a terminal interface, a desktop app, a web app, and an SDK. It is popular among developers but is not limited to programming.

### Why OpenCode?

- Open source and extensible.
- Works in the terminal, desktop, or from other tools.
- Supports many model providers and local inference servers.
- Supports MCP servers.
- Provides configurable agents, tools, permissions, and instructions.
- Can be integrated into scripts, CI jobs, and development environments.

### Sub-agents

OpenCode supports sub-agents: specialized assistant profiles that the primary agent can launch in child sessions. A sub-agent combines a system prompt, model preference, permissions, and display details.

For example, a reviewer sub-agent can read files and report findings without editing them.

```text
Use the reviewer subagent to review my current changes.
```

Sub-agents are stored as Markdown files:

- `~/.config/opencode/agents/<name>.md` for all projects.
- `.opencode/agents/<name>.md` for a project.

Built-in sub-agents include `general` (research and multi-step work) and `explore` (search and read sources). Agents can also be defined under the `agents` key in the OpenCode configuration.

Official documentation: [OpenCode – Agents](https://opencode.ai/docs/agents/).

## 📦 Installation on Linux

The official installation script is the recommended starting point.

```bash
curl -fsSL https://opencode.ai/v2/install | bash
```

Verify the installation:

```bash
opencode --version
```

Start the interactive interface:

```bash
opencode
```

Open OpenCode in a project directory:

```bash
cd ~/dev/my-project
opencode
```

### Updating OpenCode

Run the same installation command to install or update OpenCode:

```bash
curl -fsSL https://opencode.ai/v2/install | bash
```

Official documentation:

- [OpenCode](https://opencode.ai/)
- [Installation](https://opencode.ai/docs/)
- [Configuration](https://opencode.ai/docs/config/)
- [Models](https://opencode.ai/docs/models/)
- [Providers](https://opencode.ai/docs/providers/)

## Connecting an AI model

OpenCode does not require a specific model. It connects to model providers through an API, a gateway, or a local inference server. OpenCode Console also offers free and paid models.

### Model providers

A model provider is a service that exposes models through an API. Common examples include:

- OpenAI
- Anthropic
- Google
- OpenRouter
- Kilo AI
- OpenCode Console
- Ollama (local models)
- LM Studio (local models)

Many providers implement the OpenAI-compatible API standard. This makes it possible to use different models without changing the agent or its workflow.

### OpenCode Console

OpenCode ships with a built-in `opencode` provider. It needs no `provider` block in the configuration, only a signed-in OpenCode Console account or an API key.

Sign in with:

```text
/connect
```

Alternatively, provide an API key through `OPENCODE_API_KEY`.

The provider includes free models for a limited time. Free model availability and privacy conditions are documented at [OpenCode Console – Models](https://opencode.ai/docs/console/models/).

### Kilo AI Gateway

[Kilo AI](https://kilo.ai/) provides a unified API gateway for models from different providers. The gateway offers a selection of free models that can be accessed without an API key or account, subject to rate limits.

Current information and available models:

- [Kilo Free Models](https://kilo.ai/landing/free-models)

The gateway provides an OpenAI-compatible API. The base URL is:

```text
https://api.kilo.ai/api/gateway
```

Anonymous access is restricted to free models and may be subject to a request limit per IP address. This is a request limit, not a token allowance. Individual models may have additional restrictions or temporary availability issues.

### OpenRouter

[OpenRouter](https://openrouter.ai/) provides a unified API for models from different providers through a single interface. It offers free and paid models, subject to rate limits and account requirements.

Current information and available models:

- [OpenRouter Free Models](https://openrouter.ai/models?max_price=0)

OpenRouter provides an OpenAI-compatible API. The base URL is:

```text
https://openrouter.ai/api/v1
```

Create and manage API keys at [OpenRouter API Keys](https://openrouter.ai/keys).

Configure the API key in OpenCode:

```bash
opencode auth login
```

Select OpenRouter as the provider and enter the API key.

Alternatively, use an environment variable:

```bash
export OPENROUTER_API_KEY="your-api-key"
```

### Local models

OpenCode can use local models through compatible backends such as Ollama or LM Studio. Local models avoid sending prompts to a third-party API, but they require suitable hardware and setup.

## OpenCode model setup

### Configuration files

OpenCode supports global and project-specific configuration files.

On Linux, the global configuration is typically located at:

```text
~/.config/opencode/opencode.json
```

or:

```text
~/.config/opencode/opencode.jsonc
```

The JSONC format allows comments and is convenient for maintaining configurations.

The configuration used in this repository is available here:

- [opencode-template.jsonc](opencode-template.jsonc)

It selects provider-prefixed model IDs for the Kilo AI Gateway and OpenRouter and registers the available free models. The generated model list can be refreshed with `update_model_catalog.py`.

### Selecting a model

Start OpenCode:

```bash
opencode
```

Open the model selection dialog:

```text
/models
```

Select the desired provider and model.

To list available models from the terminal:

```bash
opencode models
```

Model quality varies considerably. A model that performs well in a simple conversation may struggle with complex agentic tasks involving multiple tools.

For software development, prioritize reliable tool calling, code quality, and the ability to complete multi-step tasks.

A broader comparison of models for coding and agentic work is available in [Coding and Agentic Models](coding-agentic-models.md).

## Testing the API

Before configuring an agent, it is useful to verify that the API works independently.

### List available models

The following command retrieves available models from the Kilo gateway and filters for free offerings:

```bash
curl -s https://api.kilo.ai/api/gateway/models \
  | jq -r '.data[].id' \
  | grep -E 'free|kilo-auto'
```

Prerequisite: `curl` and `jq`.

Install `jq` on Ubuntu:

```bash
sudo apt install jq
```

### Send a one-shot prompt

A one-shot prompt sends a request directly to the model without starting an interactive session.

```bash
curl -s https://api.kilo.ai/api/gateway/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "kilo-auto/free",
    "messages": [
      {
        "role": "user",
        "content": "Summarize the features and advantages of OpenCode."
      }
    ]
  }' | jq -r '.choices[0].message.content'
```

This is useful for:

- Testing whether a model is accessible.
- Comparing different models.
- Automating AI requests in shell scripts.
- Integrating AI into existing tools.
- Prototyping an agent before implementing it in a larger application.

Change the `model` field to use a different model.

### One-shot prompt with a shell variable

For repeated use, store the prompt in a variable:

```bash
MODEL="liquid/lfm-2.5-2.6b"
PROMPT="Explain the purpose of Python virtual environments."

curl -s https://api.kilo.ai/api/gateway/chat/completions \
  -H "Content-Type: application/json" \
  -d "$(jq -n \
    --arg model "$MODEL" \
    --arg prompt "$PROMPT" \
    '{
      model: $model,
      messages: [{role: "user", content: $prompt}]
    }')" \
  | jq -r '.choices[0].message.content'
```

One-shot requests are stateless. The model does not remember previous requests. Include the conversation history explicitly if a multi-step interaction is required.

## 🚀 Using OpenCode without an IDE

OpenCode does not depend on PyCharm or another development environment. A terminal is sufficient:

```bash
mkdir -p ~/ai-work
cd ~/ai-work
opencode
```

The agent can work with files in the current directory, subject to its permissions and configuration.

### Example: Organizing files

```text
Analyze the files in this directory.

Create a proposed folder structure based on file types and content.
Identify duplicates and files that may belong together.

Do not delete or move anything yet.
Present a plan and wait for my approval.
```

Review the plan before authorizing the next step.

### Example: Creating a presentation

```text
Create a presentation about the history of Linux.

Use the available MCP tools to create a PowerPoint presentation.
Include an introduction, historical milestones, important distributions,
and a conclusion.

Save the result in the current directory.
```

The exact capabilities depend on the available MCP servers and tools.

### Example: Working with MCP

The Model Context Protocol (MCP) is a standardized way to provide AI agents with access to external tools and resources.

Examples include:

- Filesystem access.
- Web search.
- Browser automation.
- Database access.
- Office document creation.
- Calendar and task management.
- Custom APIs and applications.

An MCP server exposes tools that an agent can call when needed. This means OpenCode can be extended beyond software development into a general-purpose automation environment.

Official documentation: [OpenCode – MCP Servers](https://opencode.ai/docs/mcp-servers/).

## 🔐 Security and responsible usage

Agentic AI can perform actions with real consequences. Take appropriate precautions.

### Permissions

Do not automatically grant unrestricted access to the entire filesystem or system.

Prefer:

- Working in dedicated directories.
- Reviewing proposed changes before execution.
- Restricting access to sensitive files.
- Using explicit permissions for potentially destructive operations.
- Keeping backups of important data.
- Reviewing shell commands before approving them.

### Free model privacy

Free models may be provided by third-party services with different data-processing policies. Some free models log prompts and responses or use them to improve their services.

Never submit passwords, API keys, confidential documents, personal data, or proprietary source code to a free model unless the provider's data-processing conditions have been explicitly reviewed and accepted.

For sensitive tasks, consider locally hosted models using Ollama or another inference backend.

## 📚 Further reading

- [OpenCode – Official Website](https://opencode.ai/)
- [OpenCode – Documentation](https://opencode.ai/docs/)
- [OpenCode – Configuration](https://opencode.ai/docs/config/)
- [OpenCode – Models](https://opencode.ai/docs/models/)
- [OpenCode – Providers](https://opencode.ai/docs/providers/)
- [OpenCode – Agents](https://opencode.ai/docs/agents/)
- [OpenCode – MCP Servers](https://opencode.ai/docs/mcp-servers/)
- [OpenCode – CLI](https://opencode.ai/docs/cli/)
- [Kilo AI – Free Models](https://kilo.ai/landing/free-models)
- [OpenRouter – Free Models](https://openrouter.ai/models?max_price=0)
- [Awesome Free LLM APIs](https://github.com/mnfst/awesome-free-llm-apis)
- [Ollama – Local Models](https://ollama.com/)
- [Model Context Protocol](https://modelcontextprotocol.io/)

## Conclusion

Agentic AI makes it possible to automate complex tasks using natural language instructions. OpenCode provides a flexible, open-source interface for interacting with AI models and tools.

By combining it with a suitable model provider, MCP servers, and appropriate permissions, it can become a powerful general-purpose assistant for software development, research, document creation, and everyday automation.

Start with simple tasks, evaluate the results, and gradually extend the agent's capabilities.