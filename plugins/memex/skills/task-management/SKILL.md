---
name: task-management
description: Task management through an external project tracker. Reference this when the user asks about their tasks, wants to add/complete tasks, or needs help tracking commitments.
---

# Task Management

Tasks are managed through `~~tasks` — whatever project tracking tool is connected via MCP (Linear, Asana, Jira, etc.).

## How Tool References Work

`~~tasks` is an agnostic placeholder. When you see `~~tasks`, use whatever project tracking MCP tools are available in the current session. The specific tool names depend on which connector is configured.

If no task tracker is connected, inform the user and suggest connecting one.

## How to Interact

**When user asks "what's on my plate" / "my tasks":**

- Query `~~tasks` for tasks assigned to the user
- Summarize active/in-progress items
- Highlight anything overdue or urgent
- Group by project or priority if the tracker supports it

**When user says "add a task" / "remind me to":**

- Create a task in `~~tasks`
- Include context if provided (who it's for, due date, project)
- Confirm creation with a link or identifier

**When user says "done with X" / "finished X":**

- Find the matching task in `~~tasks`
- Update its status to done/completed
- Add a completion comment if context is available

**When user asks "what am I waiting on":**

- Query `~~tasks` for tasks where the user is waiting on others
- Look for blocked/waiting statuses or tasks assigned to others that the user created
- Note how long each item has been waiting

## Extracting Tasks from Conversations

When summarizing meetings or conversations, offer to create tasks in `~~tasks`:

- Commitments the user made ("I'll send that over")
- Action items assigned to them
- Follow-ups mentioned

Ask before creating — do not auto-create without confirmation. When creating extracted tasks, include conversation context in the task description.

## Conventions

- Include "for [person]" when it's a commitment to someone
- Include due dates when mentioned
- Add relevant project/label/tag if the tracker supports it
- Keep task titles concise but specific

## Integration with Memory

When the memory-management skill is active:

- Decode any shorthand using the memory lookup flow before writing to `~~tasks`
- Resolve people references to full names
- Map project codenames to actual project names/identifiers in the tracker
