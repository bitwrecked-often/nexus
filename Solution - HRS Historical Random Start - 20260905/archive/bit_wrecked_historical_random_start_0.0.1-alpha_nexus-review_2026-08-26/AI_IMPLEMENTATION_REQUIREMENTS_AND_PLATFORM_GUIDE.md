# Historical Random Start — AI Implementation Requirements and Platform Guide

Date assessed: 2026-08-21  
Purpose: cold-start staffing, model selection, context sizing, and execution
continuity for the core frontend-to-runtime vertical slice

## Executive recommendation

This project does not require an exotic research team or an unlimited-context
model. It requires one technically capable operator and one frontier-class
agentic coding model working from the stable project manifest and evidence
hierarchy.

Recommended execution profile:

- one IT/software person comfortable with Windows, PowerShell, Git, logs,
  backups, and carefully following an owner-operated game test protocol;
- one frontier reasoning/coding model with local filesystem and terminal tools;
- at least a **200k-token context window**, with **400k or more recommended**;
- **1M tokens ideal** for fewer context-management interruptions, not because
  the entire project should be loaded indiscriminately;
- session continuation or compaction plus durable project-local handoff files;
- permission controls that restrict work to the named project/staging paths;
  and
- a human available for Steam authentication, in-game menu operation, visual
  confirmation, and any explicitly approved live-copy/reload step.

The preferred model tier is the provider's strongest generally available
reasoning/coding model. A balanced near-frontier model can perform bounded
implementation and test work after the architecture is fixed, but the
integration, anomalous runtime diagnosis, final audit, and release-boundary
review should use the frontier tier.

## Why this size is sufficient

As measured on 2026-08-21, the project contains approximately:

- 205 text/source/configuration files;
- 891,591 bytes of readable project material; and
- roughly 223k tokens if every readable byte were naively loaded at once using
  the coarse estimate of four bytes per token.

The core cold-start packet is much smaller:

- `README_FIRST.md`;
- `DOCUMENT_ROUTING.md`;
- `CURRENT_SITUATIONAL_AWARENESS.md`;
- the main manifest and plan;
- the scientific-methods whitepaper;
- the software-assurance contract; and
- the UX state model.

Those eight files total 222,373 bytes, or approximately 56k tokens by the same
coarse estimate. The agent should then retrieve source, fixtures, and evidence
on demand. It does not need every historical evidence note in active context.

This makes 200k workable: approximately 56k for governing context leaves room
for the current source, tests, tool definitions, command output, reasoning, and
the implementation diff. A 400k-class window provides substantially safer room
for runtime logs and cross-file review. A 1M window permits broad audits and
longer uninterrupted sessions, but careful routing remains necessary because
recall can degrade when irrelevant material is included.

## Human/operator requirements

The operator need not invent the architecture. The manifest owns that. The
operator should be able to:

1. Use Windows Explorer, PowerShell, and a text/code editor safely.
2. Understand absolute versus relative paths and verify exact targets before
   copying, moving, or removing anything.
3. Use Git for status, diff, branches, commits, remotes, and recovery without
   discarding unrelated work.
4. Run PowerShell 5.1 and PowerShell 7 scripts and preserve complete output.
5. Understand basic C#/.NET concepts well enough to recognize build failures,
   assembly references, hashes, and stack traces.
6. Follow the pinned Roslyn build and 7 Days to Die ModAPI/Harmony boundaries;
   deep Unity reverse engineering is not required for the first bridge because
   the atomic mechanism is already proven.
7. Start the game through its normal non-EAC option, enter the exact test game
   name, observe the first arrival, exit normally, and report only the requested
   categorical observations.
8. Preserve disposable saves, backups, logs, hashes, and recovery artifacts.
9. Distinguish a private DEV proof from a public release and never infer upload,
   publication, compatibility, or broader game-directory authority.
10. Stop a human action when the AI's expected target or evidence does not match
    what is visible on screen.

An experienced IT generalist or junior-to-mid software developer can operate
the process. A senior C#/Unity specialist is valuable for unexpected game-API
changes, but is not a standing requirement for the planned core slice.

## AI-agent capability requirements

### Required

The agent must have:

- strong multi-file software reasoning and the ability to obey a normative
  manifest over older contradictory notes;
- local read/write access limited to approved project and staging paths;
- terminal execution for PowerShell, Git, hashing, compilation, static scans,
  and automated tests;
- patch/diff-based editing that preserves unrelated user work;
- the ability to inspect C#, PowerShell, JSON/schema, batch launchers, logs,
  and Markdown evidence;
- long-horizon task persistence: diagnose, patch, rebuild, retest, and update
  evidence until the completion gate passes;
- explicit uncertainty handling and fail-closed behavior;
- context recovery from `README_FIRST.md`, current awareness, the manifest,
  the plan, the `PEG-*` grid, and evidence rather than conversation memory;
- disciplined separation between launcher control plane, runtime data plane,
  and categorical evidence plane; and
- truthful claim calibration: observed, pure/static, planned, pending, failed,
  contaminated, and unproven must remain distinct.

### Strongly preferred

- configurable reasoning effort at a high setting;
- resumable sessions or automatic compaction;
- tool-output management so large logs can be summarized without erasing the
  original files;
- checkpointing and a visible execution plan;
- image/screenshot inspection for the human-visible UX and runtime evidence;
- web access for current official game/modding/dependency research; and
- a separate review pass by the same frontier model in a fresh context, or by
  a second frontier model, before any live/publish promotion.

### Insufficient by itself

- a chat-only model with no repository or terminal access;
- autocomplete-only IDE assistance;
- a small/fast model asked to infer the project solely from conversation;
- a cloud coding agent that can edit GitHub but cannot access the local Steam
  installation for the required runtime evidence;
- an agent with broad unattended write permission over the whole game folder;
  or
- a nominally large context window without durable manifests, selective
  retrieval, tests, and evidence discipline.

## Context-window requirement

| Tier | Window | Assessment for this project |
| --- | ---: | --- |
| Below minimum | Under 128k | Not recommended for the primary implementer. It can handle isolated files or review tasks but is more likely to lose cross-document constraints during build/test loops. |
| Minimum viable | 200k | Sufficient if the agent starts with the ~56k core packet, reads task-specific source/evidence selectively, and writes checkpoints before compaction. |
| Recommended | 400k–600k | Comfortable for the governing packet, current source/tests, substantial logs, diffs, and a full repair/retest cycle. |
| Ideal | About 1M | Best for cold-start audits and long uninterrupted integration work. Still use routing; filling the window with archives and duplicate evidence is counterproductive. |

Context size is not the same as continuity. The implementation environment
must also preserve or regenerate:

- the active objective and completion boundary;
- exact files changed;
- current test/evidence status;
- artifact and target hashes;
- the last safe rollback point; and
- the next executable action.

If a platform compacts or starts a new session, the agent should re-enter
through the project documents rather than attempt to reconstruct intent from a
chat summary alone.

## Common AI platform translation

Platform capabilities and model limits change. The entries below reflect
official documentation checked on 2026-08-21 and should be rechecked when the
bridge is actually executed.

| Platform | Suitable configuration | Context | Assessment |
| --- | --- | ---: | --- |
| OpenAI Codex / tool-enabled OpenAI agent | GPT-5.6 Sol with high or xhigh reasoning; GPT-5.6 Terra is a cost-balanced implementation option with Sol used for architecture/anomaly/final review | 1.05M for GPT-5.6 Sol and Terra | **Preferred.** Strong fit when it has local filesystem, PowerShell, Git, patching, and resumable task execution. OpenAI describes Sol as its flagship for complex reasoning/coding and Terra as the balance tier. |
| Anthropic Claude Code | Claude Opus 4.7 or newer frontier Opus; Claude Sonnet 4.6 is a credible cost/speed implementation tier with Opus review | 1M for current Opus 4.7 and Sonnet 4.6 | **Preferred/strong alternative.** Claude Code has local terminal/repository operation and resumable sessions. Use project routing plus compaction; do not rely on one ever-growing chat. |
| Google Gemini API/CLI or a custom local tool harness | Gemini 3.1 Pro Preview with thinking and filesystem/terminal/custom tools | 1,048,576 input, 65,536 output | **Technically strong, conditional.** The model is documented as optimized for software engineering and agentic tool use. The chosen client must actually provide safe local file, PowerShell, Git, and session-state handling. Preview status adds model-change risk, so pin and revalidate before execution. |
| Gemini Code Assist agent mode | Highest available Pro reasoning model exposed by the account, with the local IDE/agent allowed to run tools | Product/model dependent | **Potentially suitable.** Agentic chat supports system tools and MCP, but do not assume the standalone Gemini API's 1M limit or exact model is exposed by Code Assist. Verify the selected model and effective context first. |
| GitHub Copilot coding agent | Frontier Codex or Claude partner agent for repository-only packets; local Copilot CLI/IDE agent for local staged work | Model and surface dependent; GitHub does not promise one universal effective window | **Useful but not sufficient alone for final runtime proof.** Cloud agents can implement and open PRs, but they cannot operate this local Steam test environment. Use them for sanitized repository work, then use a local agent/operator for build, copy, game, reload, and evidence steps. |
| ChatGPT, Claude.ai, Gemini web chat, or similar chat-only surface | Frontier model with uploaded core packet | Often large but surface-dependent | **Planner/reviewer only.** It can understand the manifest and review evidence, but without durable local tools it should not be the sole implementation agent. |

Official references:

- [OpenAI model catalog and GPT-5.6 context/tool specifications](https://developers.openai.com/api/docs/models)
- [Anthropic model comparison](https://platform.claude.com/docs/en/about-claude/models/overview)
- [Anthropic context-window and compaction guidance](https://platform.claude.com/docs/en/build-with-claude/context-windows)
- [Claude Code local setup and Windows support](https://docs.anthropic.com/en/docs/claude-code/getting-started)
- [Google Gemini 3.1 Pro model specification](https://ai.google.dev/gemini-api/docs/models/gemini-3.1-pro-preview)
- [Gemini Code Assist overview and agentic-chat capability](https://developers.google.com/gemini-code-assist/docs/overview)
- [GitHub third-party coding agents and selectable Codex/Claude models](https://docs.github.com/en/copilot/concepts/agents/about-third-party-coding-agents)

## Recommended staffing patterns

### Lean and sufficient

- One IT/software operator
- One frontier local coding agent
- Owner available for the short in-game evidence steps
- Fresh frontier-model review before promotion

### Higher assurance

- Primary frontier implementation agent
- Independent frontier review agent or fresh-context review
- Same human operator controlling exact paths and game interaction
- Optional C#/Unity specialist only if the pinned API changes or the runtime
  mechanism stops matching the recorded evidence

Multiple simultaneous implementation agents are not required for the core and
may increase merge/context risk. Parallel agents are most useful later for
independent static review, security review, or evidence audit with non-overlap
and a single manifest authority.

## Microsoft-informed human-in-the-loop refinement

Microsoft's current Agent Framework and responsible-AI guidance closely match
the project's owner-demarcation model:

- approval-required tools pause and return a structured request to the caller
  instead of silently executing;
- the request exposes the proposed function call and arguments so a person can
  approve or reject the concrete action;
- checkpoints preserve executor state, pending messages, and pending
  request/response work so a long-running workflow can resume safely;
- restored pending requests are re-emitted rather than assumed approved;
- consequential, hard-to-reverse, sensitive, or ambiguous actions should route
  visibly to a person with enough context for a quick informed decision;
- checkpoint storage is itself a trust boundary and must not be loaded from an
  untrusted or tampered source; and
- autonomous agent loops need explicit completion conditions and bounds because
  a model can stall or an evaluator can remain probabilistic.

For this project, those principles translate into a two-checkpoint handshake:

```text
AI preflight complete
  -> durable PREPARED checkpoint
  -> exact human request with action, target, expected result, and abort rules
  -> USER performs or rejects the live-game step
  -> typed observation returned
  -> AI correlates logs, hashes, policy, and marker
  -> durable VERIFIED / FAILED / ABORTED checkpoint
  -> autonomous engineering resumes
```

One Microsoft Q&A discussion adds an important implementation warning:
human-in-the-loop suspension is not automatically an authorization or identity
system. A paused workflow can wait for a response, but the project must still
define who may approve, which exact operation is covered, and how that identity
and scope are verified. Forum/Q&A answers are practical guidance rather than a
product guarantee, but this distinction is sound and is now part of the
project protocol.

Microsoft Q&A also contains reports of approval workflows remaining stuck when
the expected notification was not delivered. Accordingly, this project must
show a visible `WAITING_FOR_USER` state in the active session and durable
checkpoint; notification delivery alone can never be treated as proof that the
owner saw, approved, rejected, or completed the request. The owner can resume
directly from the named checkpoint without replaying an already completed
action.

The owner is therefore not a generic confirmation button. The owner is the
authenticated operational boundary for Steam/game interaction and supplies a
typed observation. The manifest and READY packet remain the authority boundary.
Approval is scoped to one prepared attempt and expires when its target or
artifact identity changes.

For the core, this boundary forbids AI- or automation-initiated Steam/game
launch. The frontend may expose the reviewed `Launch Game` handoff, but only
the local person who opened the manager may activate it and Steam must already
be running. No agent, timer, recovery path, default focus, or chained workflow
may click it; the frontend does not sign in, automate Steam, attach to the
process, or alter EAC. Human activation is a scoped permission event, not a
capability that the implementation agent inherits.

Microsoft references:

- [Agent Framework human-in-the-loop tool approvals](https://learn.microsoft.com/en-us/agent-framework/agents/tools/tool-approval)
- [Agent Framework workflow checkpoints and security considerations](https://learn.microsoft.com/en-us/agent-framework/workflows/checkpoints)
- [Responsible AI guidance for keeping humans in consequential agent loops](https://learn.microsoft.com/en-us/agents/center-of-excellence/responsible-ai)
- [Agent looping and the requirement to bound autonomous loops](https://learn.microsoft.com/en-us/agent-framework/agents/looping)
- [Microsoft Q&A discussion distinguishing HITL suspension from authorization](https://learn.microsoft.com/en-us/answers/questions/5962649/azure-ai-foundry-workflow-hitl-shared-approval-wit)
- [Microsoft Q&A report illustrating a stuck approval/notification path](https://learn.microsoft.com/en-us/answers/questions/5576640/start-and-wait-action-not-working-in-agents-when-t)
- [Microsoft Community Hub example combining human approval with durable checkpoints](https://techcommunity.microsoft.com/blog/azure-ai-foundry-blog/multi-agent-workflow-with-human-approval-using-agent-framework/4465927)

## Required cold-start packet for any platform

Give the primary agent this route, in order:

1. `README_FIRST.md`
2. `DOCUMENT_ROUTING.md`
3. `CURRENT_SITUATIONAL_AWARENESS.md`
4. `2026-08-13_historical_random_start_manifest.md`
5. `2026-08-13_historical_random_start_plan.md`, including the canonical
   `PEG-*` grid and core completion gate
6. `PHASE_1A_ATOMIC_RELOCATION_SCIENTIFIC_METHODS_WHITEPAPER_0.0.1.md`
7. `DEV_TEST_AND_SOFTWARE_ASSURANCE_CONTRACT_0.0.1.md`
8. `UX_0_1_CONTROL_INVENTORY_AND_STATE_MODEL_0.0.1.md`
9. the exact source, tests, and evidence named by the active execution packet

Then state explicitly:

> Work only inside the paths authorized by the READY execution packet. Finish
> the exact-name Standard/Random vertical slice before adding later features.
> Resolve ordinary engineering failures through patching and retesting. Pause
> only at the manifest's true human/external blockers, and prepare the exact
> human action and expected evidence when such a boundary is reached.

## Bottom line

The project is large enough to punish weak context management but not large
enough to require extraordinary model capacity. A 200k agent can succeed with
strict routing. A 400k-plus frontier coding agent is the practical target. A
1M frontier agent provides the best cold-start and long-session margin.

The stable manifest, explicit `PEG-*` grid, atomic proof, test harnesses, and
evidence trail reduce the reasoning burden substantially. The remaining hard
work is careful integration and runtime validation—not rediscovering what the
product is supposed to be.
