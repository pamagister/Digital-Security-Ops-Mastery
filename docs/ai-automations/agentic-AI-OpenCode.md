# Agentic AI and OpenCode

## 🧭 Introduction

Agentic AI is a new way of working with artificial intelligence. Instead of merely answering questions, an AI agent can independently perform tasks, use tools, interact with software, and work toward a defined goal.

This document introduces the fundamental concepts, explains how to set up OpenCode on Linux, and demonstrates how to connect free or self-hosted language models.

The examples focus on Linux and the terminal. However, the concepts are applicable to many operating systems and workflows.

## What is an AI Agent?

A conventional AI chatbot responds to individual prompts. An AI agent goes one step further: it can use its capabilities to accomplish tasks autonomously.

### From Chatbot to Agent

A conventional chatbot typically follows this pattern:

1. The user asks a question.
2. The AI generates an answer.
3. The conversation ends or waits for another prompt.

An AI agent follows a more flexible approach:

1. The user defines a goal.
2. The AI analyzes the task and develops an approach.
3. It uses tools to gather information or perform actions.
4. It evaluates the results.
5. It repeats the process when necessary.
6. It delivers a result or asks for human input.

This process is commonly referred to as **agentic AI**.

### What Can an Agent Do?

Depending on its configuration, an AI agent can:

- Read, create, modify, and organize files.
- Execute commands in a terminal.
- Search the web and retrieve information.
- Interact with APIs and external services.
- Analyze source code and refactor projects.
- Create documents, spreadsheets, and presentations.
- Use Model Context Protocol (MCP) servers to access additional tools.
- Perform multi-step tasks with limited human intervention.

An agent does not automatically possess all these capabilities. They depend on the selected model, available tools, permissions, and configuration.

### Models, Agents, and Tools

These three concepts should be distinguished:

| Component | Responsibility |
|---|---|
| **LLM (Large Language Model)** | Understands instructions, reasons about problems, and generates responses. |
| **Agent** | Coordinates the model, tools, instructions, and execution loop to accomplish a task. |
| **Tools** | Provide capabilities such as accessing files, executing commands, or interacting with external services. |

An agent without tools is essentially a chatbot with additional instructions. A model with powerful tools but insufficient reasoning capabilities may also struggle to use them effectively.

The combination of a capable model, a well-configured agent, and appropriate tools is what makes agentic AI useful.

## OpenCode

[OpenCode](https://opencode.ai/) is an open-source AI agent that primarily operates through a terminal-based interface (TUI).

It is particularly popular among software developers, but it is not limited to programming. OpenCode can be used as a general-purpose agent for interacting with files, APIs, and other applications.

### Why OpenCode?

- Open source and extensible.
- Works directly in the terminal.
- Supports many different AI models and providers.
- Can use local models through compatible backends.
- Supports MCP (Model Context Protocol).
- Provides configurable agents, tools, permissions, and instructions.
- Can operate independently of a particular IDE.
- Can be integrated into existing workflows, scripts, and development environments.

OpenCode can be used in several ways:

| Interface | Description |
|---|---|
| Terminal (TUI) | Interactive agent directly in the terminal. |
| CLI | Execute prompts and tasks directly from shell scripts or commands. |
| IDE | Use the terminal inside PyCharm, VS Code, or another editor. |
| Desktop / Web | Alternative interfaces for interacting with the agent. |

The terminal-based interface is particularly flexible because it can be used both interactively and through automation.

## 📦 Installation on Linux

The official installation script is the recommended starting point.

```bash
curl -fsSL https://opencode.ai/v2/install | bash
```

After installation, verify that OpenCode is available:

```bash
opencode --version
```

Start the interactive interface:

```bash
opencode
```

OpenCode can also be started directly in a project directory:

```bash
cd ~/dev/my-project
opencode
```

This allows the agent to work with the files in the current project.

### Updating OpenCode

Use the same installation command to install or update OpenCode:

```bash
curl -fsSL https://opencode.ai/v2/install | bash
```

Official documentation:

- [OpenCode](https://opencode.ai/)
- [Installation](https://opencode.ai/v2/docs)
- [Configuration](https://dev.opencode.ai/v2/docs/config/)

## Connecting an AI Model

OpenCode does not provide an AI model by itself. It needs access to a language model through an API, a gateway, or a local inference server.

### Model Providers

A model provider is a service that makes AI models available through an API.

Common examples include:

- OpenAI
- Anthropic
- Google
- NVIDIA
- OpenRouter
- Kilo AI
- Ollama (local models)
- LM Studio (local models)

Many providers implement the OpenAI-compatible API standard. This makes it possible to use different models without changing the agent or its workflow.

### Free Models

There are several options for experimenting with AI agents without paying for API usage.

A useful collection of free API providers and models is maintained here:

[**Awesome Free LLM APIs**](https://github.com/mnfst/awesome-free-llm-apis)

The list includes services with different requirements:

- Free models without registration.
- Free models requiring an account.
- API access requiring a credit card for verification.
- Limited free usage quotas.
- Open-source models available for local deployment.

Free availability, rate limits, and model quality change frequently. Always verify the current conditions before integrating a provider into a workflow.

## Kilo AI Gateway

[Kilo AI](https://kilo.ai/) provides a unified API gateway for accessing models from different providers.

The gateway offers a selection of free models that can be accessed **without an API key or account**, subject to rate limits.

### Free Models

Current information and available models:

[**Kilo Free Models**](https://kilo.ai/landing/free-models)

The gateway provides an OpenAI-compatible API.

Base URL:

```text
https://api.kilo.ai/api/gateway
```

The following endpoints are particularly useful:

| Endpoint | Purpose |
|---|---|
| `/models` | Retrieve the currently available models. |
| `/chat/completions` | Send a prompt and receive a response. |

Anonymous access is restricted to free models and currently subject to a limit of approximately 200 requests per hour per IP address.

This is a request limit, not a token allowance. Individual models may have additional restrictions or temporary availability issues.

### OpenCode Configuration

OpenCode supports global and project-specific configuration files.

On Linux, the global configuration is typically located at:

```text
~/.config/opencode/opencode.json
```

or:

```text
~/.config/opencode/opencode.jsonc
```

The JSONC format allows comments and is particularly convenient for maintaining configurations.

The configuration used in this repository is available here:

[**opencode.jsonc**](../opencode.jsonc)

It defines the Kilo AI Gateway as a provider and registers the available free models.

The configuration can be reused across multiple projects. Once the provider is registered, its models can be selected within OpenCode.

### Selecting a Model

Start OpenCode:

```bash
opencode
```

Then open the model selection dialog:

```text
/models
```

Select the desired provider and model.

A few interesting models for experimentation include:

| Model | Potential application |
|---|---|
| `cohere/north-mini-code:free` | Coding and software development |
| `recursive/flint-v1.0:free` | Coding and agentic workflows |
| `poolside/laguna-s-2.1:free` | Code-oriented tasks |
| `nvidia/nemotron-3.5-lightning:free` | General-purpose tasks |
| `kilo-auto/free` | Automatic routing between available free models |

Model quality varies considerably. A model that performs well in a simple conversation may struggle with complex agentic tasks involving multiple tools.

For software development, prioritize reliable tool calling, code quality, and the ability to complete multi-step tasks.

## Testing the API

Before configuring an agent, it is useful to verify that the API works independently.

### List Available Models

The following command retrieves the available models and filters for free offerings:

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

### Send a One-Shot Prompt

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

The model can be changed simply by modifying the `model` field.

### One-Shot Prompt with a Shell Variable

For repeated use, a prompt can be stored in a variable:

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

This approach also makes it possible to integrate AI requests into shell scripts and other automation.

**Note:** One-shot requests are stateless. The model does not automatically remember previous requests. Conversation history must be explicitly included if a multi-step interaction is required.

## 🚀 Using OpenCode Without an IDE

OpenCode is not dependent on PyCharm or another development environment.

A terminal is sufficient:

```bash
mkdir -p ~/ai-work
cd ~/ai-work
opencode
```

The agent can work with files in the current directory, subject to its permissions and configuration.

### Example: Organizing Files

An agent can be instructed to analyze and organize a directory:

```text
Analyze the files in this directory.

Create a proposed folder structure based on file types and content.
Identify duplicates and files that may belong together.

Do not delete or move anything yet.
Present a plan and wait for my approval.
```

After reviewing the plan, the user can authorize the next step.

This is particularly useful for large collections of documents, photographs, archives, and miscellaneous files.

### Example: Creating a Presentation

An agent can also be used to generate presentations:

```text
Create a presentation about the history of Linux.

Use the available MCP tools to create a PowerPoint presentation.
Include an introduction, historical milestones, important distributions,
and a conclusion.

Save the result in the current directory.
```

The exact capabilities depend on the available MCP servers and their tools.

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

An MCP server exposes tools that an agent can call when needed.

This means that OpenCode can be extended beyond software development into a general-purpose automation environment.

Official documentation:

[**OpenCode MCP Servers**](https://opencode.ai/docs/mcp/)

## 🔐 Security and Responsible Usage

Agentic AI can perform actions that have real consequences. Appropriate precautions are therefore essential.

### Permissions

Do not automatically grant unrestricted access to the entire filesystem or system.

Prefer:

- Working in dedicated directories.
- Reviewing proposed changes before execution.
- Restricting access to sensitive files.
- Using explicit permissions for potentially destructive operations.
- Keeping backups of important data.
- Reviewing shell commands before approving them.

### Free Model Privacy

Free models may be provided by third-party services with different data-processing policies.

In particular, Kilo's free model catalog warns that some providers may log prompts and responses or use them to improve their services.

**Never submit passwords, API keys, confidential documents, personal data, or proprietary source code to free models unless the provider's data-processing conditions have been explicitly reviewed and accepted.**

For sensitive tasks, consider locally hosted models using Ollama or another inference backend.

## 📚 Further Reading

- [OpenCode – Official Website](https://opencode.ai/)
- [OpenCode – Documentation](https://opencode.ai/v2/docs)
- [OpenCode – Configuration](https://dev.opencode.ai/v2/docs/config/)
- [OpenCode – MCP Integration](https://opencode.ai/docs/mcp/)
- [Kilo AI – Free Models](https://kilo.ai/landing/free-models)
- [Kilo AI – Gateway Documentation](https://kilo.ai/docs/gateway)
- [Awesome Free LLM APIs](https://github.com/mnfst/awesome-free-llm-apis)
- [Ollama – Local Models](https://ollama.com/)
- [Model Context Protocol](https://modelcontextprotocol.io/)

## Conclusion

Agentic AI makes it possible to automate complex tasks using natural language instructions.

OpenCode provides a flexible, open-source interface for interacting with AI models and tools. By combining it with free model providers, MCP servers, and appropriate permissions, it can become a powerful general-purpose assistant for software development, research, document creation, and everyday automation.

The key is to start with simple tasks, evaluate the results, and gradually extend the agent's capabilities.
