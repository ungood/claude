# Hooks Reference

Complete technical reference for Claude Code hooks.

## Overview

Hooks are automated scripts or LLM-based evaluations that trigger at specific points in Claude Code's workflow. They enable you to intercept, validate, modify, or block actions based on custom logic.

## Configuration Format

Hooks are defined in JSON configuration files:

```typescript
{
  hooks: {
    [eventName: string]: Array<{
      matcher: string;        // Regex pattern to match against tool name
      hooks: Array<{
        type: "command" | "prompt";
        command?: string;     // Shell command (for type: "command")
        prompt?: string;      // LLM instruction (for type: "prompt")
      }>;
    }>;
  };
}
```

## Configuration Files

### Location Priority

1. `.claude/settings.local.json` - Highest priority, local overrides, git-ignored
2. `.claude/settings.json` - Project level, committed to repository
3. `~/.claude/settings.json` - User level, global across all projects

Settings merge with local overriding project, and project overriding user.

### Plugin Hooks

Plugins define hooks inline in `plugin.json`:

```json
{
  "name": "my-plugin",
  "hooks": {
    "PostToolUse": [{
      "matcher": "Write|Edit",
      "hooks": [{"type": "command", "command": "${CLAUDE_PLUGIN_ROOT}/scripts/format.sh"}]
    }]
  }
}
```

Plugin hooks are loaded automatically when the plugin is active.

## Hook Types

### Command Hooks

Execute bash scripts for deterministic validation. Best for rule-based decisions and external tool integration.

```json
{
  "type": "command",
  "command": "${CLAUDE_PROJECT_DIR}/.claude/hooks/validate.sh"
}
```

**When to use:**

- File format validation
- Running linters or formatters
- Checking system state
- Enforcing deterministic rules

**Environment:**

- `CLAUDE_PROJECT_DIR` - Project root absolute path
- `CLAUDE_PLUGIN_ROOT` - Plugin root absolute path (plugins only)
- `CLAUDE_SESSION_ID` - Current session ID
- Standard `PATH`, `HOME`, etc.

**Execution:**

- Script must be executable (`chmod +x`)
- Must include shebang (`#!/usr/bin/env bash`)
- Runs in project working directory
- 30-second default timeout

### Prompt Hooks

Query LLM (Claude Haiku) for context-aware decisions. Best for semantic analysis and natural language rules.

```json
{
  "type": "prompt",
  "prompt": "Evaluate if this code change follows project conventions. Return JSON with decision field."
}
```

**When to use:**

- Semantic code analysis
- Natural language rule evaluation
- Context-dependent decisions
- Complex validation requiring understanding

**Execution:**

- Hook input serialized as JSON and provided to LLM
- Custom prompt instructs LLM on evaluation
- LLM response parsed as JSON
- More expensive than command hooks (API call, ~500ms-2s, ~$0.001 per execution)

## Hook Events

### PreToolUse

**When it runs:** Before Claude executes any tool

**Purpose:** Validate, block, or modify tool usage before execution

**Can block:** Yes | **Can modify input:** Yes

**Use cases:**

- Block dangerous bash commands
- Validate file paths before writes
- Enforce write permissions
- Modify tool parameters
- Log tool usage

**Input structure:**

```typescript
{
  sessionId: string;
  transcriptPath: string;
  cwd: string;
  tool: string;              // e.g., "Write", "Bash"
  parameters: object;        // Tool-specific parameters
}
```

**Output options:**

```json
{"decision": "allow"}
{"decision": "deny", "message": "Write not allowed in this directory"}
{"decision": "ask"}
{"decision": "allow", "updatedInput": {"parameters": {"timeout": 5000}}}
```

**Example:**

```bash
#!/usr/bin/env bash
set -e
input=$(cat)
tool=$(echo "$input" | jq -r '.tool')

if [[ "$tool" == "Bash" ]]; then
  command=$(echo "$input" | jq -r '.parameters.command')
  if echo "$command" | grep -qE 'rm -rf|mkfs|dd'; then
    echo '{"decision": "deny", "message": "Blocked dangerous command"}' >&2
    exit 2
  fi
fi

echo '{"decision": "allow"}'
exit 0
```

### PostToolUse

**When it runs:** After successful tool execution

**Purpose:** React to completed operations, perform cleanup or follow-up actions

**Can block:** No | **Can modify input:** No

**Use cases:**

- Auto-format files after edits
- Run tests after code changes
- Update documentation
- Generate artifacts
- Log successful operations

**Input structure:**

```typescript
{
  sessionId: string;
  transcriptPath: string;
  cwd: string;
  tool: string;
  parameters: object;
  result: string;           // Tool result output
}
```

**Example:**

```bash
#!/usr/bin/env bash
set -e
input=$(cat)
file=$(echo "$input" | jq -r '.parameters.file_path // empty')

if [[ "$file" =~ \.(ts|tsx|js|jsx)$ ]]; then
  npx prettier --write "$file" 2>/dev/null || true
fi

exit 0
```

### PermissionRequest

**When it runs:** When permission dialog would appear

**Purpose:** Automate permission decisions based on tool and context

**Can block:** Yes | **Can modify input:** No

**Use cases:**

- Auto-approve safe read operations
- Auto-deny sensitive file access
- Implement custom permission logic
- Reduce permission dialog interruptions

**Input structure:**

```typescript
{
  sessionId: string;
  transcriptPath: string;
  cwd: string;
  tool: string;
  parameters: object;
}
```

**Output options:**

```json
{"decision": "allow"}    // Auto-approve
{"decision": "deny"}     // Auto-deny
{"decision": "ask"}      // Show permission dialog
```

**Example:**

```bash
#!/usr/bin/env bash
set -e
input=$(cat)
tool=$(echo "$input" | jq -r '.tool')

# Auto-approve read operations
if [[ "$tool" =~ ^(Read|Glob|Grep)$ ]]; then
  echo '{"decision": "allow"}'
  exit 0
fi

# Auto-approve safe git commands
if [[ "$tool" == "Bash" ]]; then
  command=$(echo "$input" | jq -r '.parameters.command')
  if [[ "$command" =~ ^git\ (status|log|diff) ]]; then
    echo '{"decision": "allow"}'
    exit 0
  fi
fi

echo '{"decision": "ask"}'
exit 0
```

### UserPromptSubmit

**When it runs:** When user submits a prompt, before Claude processes it

**Purpose:** Validate, block, or modify user prompts

**Can block:** Yes | **Can modify input:** Yes

**Use cases:**

- Block prompts requesting unsafe operations
- Enforce prompt format requirements
- Add context to prompts
- Log user requests
- Implement content policies

**Input structure:**

```typescript
{
  sessionId: string;
  transcriptPath: string;
  cwd: string;
  prompt: string;          // User's submitted prompt text
}
```

**Output options:**

```json
{"decision": "allow"}
{"decision": "block", "message": "This type of request is not allowed"}
{"decision": "allow", "updatedInput": {"prompt": "Modified prompt..."}}
```

**Example (LLM evaluation):**

```json
{
  "hooks": {
    "UserPromptSubmit": [{
      "matcher": ".*",
      "hooks": [{
        "type": "prompt",
        "prompt": "Evaluate if this user prompt requests destructive operations like deleting files, dropping databases, or force-pushing to main. Return {\"decision\": \"block\", \"message\": \"reason\"} if unsafe, otherwise {\"decision\": \"allow\"}."
      }]
    }]
  }
}
```

### Stop

**When it runs:** When Claude attempts to finish working

**Purpose:** Decide whether Claude should continue or stop

**Can block:** Yes | **Can modify input:** No

**Use cases:**

- Ensure all tests pass before stopping
- Check if documentation is updated
- Verify build succeeds
- Enforce completion criteria

**Input structure:**

```typescript
{
  sessionId: string;
  transcriptPath: string;
  cwd: string;
}
```

**Output options:**

```json
{"decision": "allow"}    // Allow Claude to stop
{"decision": "ask", "message": "Tests failing. Continue to fix?"}
```

**Example:**

```bash
#!/usr/bin/env bash
set -e

if npm test 2>/dev/null; then
  echo '{"decision": "allow"}'
else
  echo '{"decision": "ask", "message": "Tests failing. Continue?"}' >&2
  exit 2
fi

exit 0
```

### SubagentStop

**When it runs:** When a subagent (Task tool) attempts to finish

**Purpose:** Control when subagents complete their work

**Can block:** Yes | **Can modify input:** No

**Use cases:**

- Validate subagent output quality
- Ensure subagent goals are met
- Request additional work from subagents

### SessionStart

**When it runs:** At the beginning of a conversation session

**Purpose:** Initialize session state and inject context

**Can block:** No | **Can modify input:** No

**Use cases:**

- Add project documentation to context
- Load coding guidelines
- Set session-specific rules
- Display welcome messages
- Check environment setup

**Input structure:**

```typescript
{
  sessionId: string;
  transcriptPath: string;
  cwd: string;
}
```

**Output options:**

```json
{
  "additionalContext": "Project uses TypeScript with strict mode. Run tests before committing."
}
```

**Example:**

```bash
#!/usr/bin/env bash
set -e

context="# Project Guidelines\n\n"
context+="- TypeScript with strict mode\n"
context+="- Use named exports\n"
context+="- Write tests for all features\n"
context+="- Run \`npm test\` before committing"

jq -n --arg ctx "$context" '{"additionalContext": $ctx}'
exit 0
```

### SessionEnd

**When it runs:** At the end of a conversation session

**Purpose:** Cleanup and session finalization

**Can block:** No | **Can modify input:** No

**Use cases:**

- Generate session reports
- Cleanup temporary files
- Archive conversation logs
- Update metrics

### Notification

**When it runs:** During Claude Code notifications

**Purpose:** React to system notifications

**Can block:** No | **Can modify input:** No

**Use cases:**

- Log notifications
- Send external alerts
- Trigger integrations
- Custom notification handling

**Input structure:**

```typescript
{
  sessionId: string;
  transcriptPath: string;
  cwd: string;
  notification: {
    type: string;
    message: string;
    data?: any;
  };
}
```

### PreCompact

**When it runs:** Before conversation history is compacted

**Purpose:** Preserve important context or modify compaction

**Can block:** No | **Can modify input:** Yes

**Use cases:**

- Tag important messages for preservation
- Extract key information before compaction
- Adjust compaction strategy

**Input structure:**

```typescript
{
  sessionId: string;
  transcriptPath: string;
  cwd: string;
  messages: Array<{
    role: string;
    content: string;
  }>;
}
```

## Hook Input/Output

### Decision Types

```typescript
type Decision = "allow" | "deny" | "ask" | "block";
```

### Output Structure

```typescript
{
  decision?: Decision;
  message?: string;              // User-facing message
  updatedInput?: {               // Modified tool input
    parameters?: object;
    prompt?: string;
  };
  additionalContext?: string;    // Context to inject
}
```

### Exit Codes

- `0` - Success, parse stdout JSON for output
- `2` - Blocking error, use stderr JSON/text as error message
- Other - Non-blocking error, log but continue

## Matcher Patterns

Matchers are regular expressions applied against the tool name.

**Match specific tool:**

```json
{"matcher": "Write"}
```

**Match multiple tools:**

```json
{"matcher": "Write|Edit|Read"}
```

**Match all tools:**

```json
{"matcher": ".*"}
```

**Match tool prefix:**

```json
{"matcher": "^Bash.*"}
```

**Case-insensitive:**

```json
{"matcher": "(?i)bash"}
```

## Script Best Practices

### Input Parsing

Always use jq for JSON parsing:

```bash
#!/usr/bin/env bash
set -e

input=$(cat)
tool=$(echo "$input" | jq -r '.tool')
file=$(echo "$input" | jq -r '.parameters.file_path // empty')
command=$(echo "$input" | jq -r '.parameters.command // empty')
```

### Error Handling

```bash
# Exit 0: Success, parse JSON output
echo '{"decision": "allow"}'
exit 0

# Exit 2: Blocking error, use stderr message
echo '{"message": "Blocked: unsafe operation"}' >&2
exit 2

# Other exit codes: Non-blocking errors
echo "Warning: validation failed" >&2
exit 1
```

### JSON Output

Use jq to construct JSON safely:

```bash
jq -n \
  --arg decision "deny" \
  --arg message "File blocked" \
  '{"decision": $decision, "message": $message}'
```

Use heredoc for static JSON:

```bash
cat << 'EOF'
{
  "decision": "allow"
}
EOF
```

### Logging

Log to stderr (doesn't affect hook output):

```bash
echo "Debug: Processing tool=$tool, file=$file" >&2
```

## Security

### Input Validation

```bash
# Always quote variables
file=$(echo "$input" | jq -r '.parameters.file_path')
[[ -f "$file" ]] || exit 1

# Validate paths are within project
[[ "$file" == "${CLAUDE_PROJECT_DIR}"* ]] || exit 1

# Validate file type
[[ "$file" =~ \.(ts|js)$ ]] || exit 0
```

### Command Injection Prevention

```bash
# ❌ DANGEROUS
eval "prettier --write $file"

# ✅ SAFE - properly quoted
prettier --write "$file"

# ✅ SAFE - validated first
if [[ "$file" =~ ^[a-zA-Z0-9/_.-]+$ ]]; then
  prettier --write "$file"
fi
```

### Path Traversal Prevention

```bash
file=$(echo "$input" | jq -r '.parameters.file_path')

# Resolve to absolute path
abs_file=$(realpath "$file" 2>/dev/null) || exit 1

# Ensure within project
[[ "$abs_file" == "${CLAUDE_PROJECT_DIR}"* ]] || {
  echo '{"decision": "deny", "message": "Path outside project"}' >&2
  exit 2
}
```

## Performance

### Command Hook Performance

**Fast (\<100ms):** File existence checks, path validation, regex matching

**Moderate (100ms-1s):** Formatters, linters, git operations, small test suites

**Slow (>1s):** Full test suites, builds, heavy processing, network requests

**Optimization:**

- Cache results when possible
- Use file modification times to skip unchanged files
- Run expensive checks in PostToolUse, not PreToolUse
- Parallelize independent operations

### Prompt Hook Performance

- Typical latency: 500ms-2s
- Cost: ~$0.001 per execution
- Use for semantic analysis, not simple rule checking

## Debugging

### Manual Testing

```bash
# Create test input
cat > test-input.json << 'EOF'
{
  "tool": "Write",
  "parameters": {
    "file_path": "/tmp/test.ts",
    "content": "console.log('test');"
  }
}
EOF

# Run hook
cat test-input.json | .claude/hooks/validate.sh

# Check exit code
echo "Exit: $?"

# Validate output
cat test-input.json | .claude/hooks/validate.sh | jq .
```

### Debug Mode

```bash
#!/usr/bin/env bash
set -e

DEBUG="${DEBUG:-false}"

debug() {
  if [[ "$DEBUG" == "true" ]]; then
    echo "[DEBUG] $*" >&2
  fi
}

input=$(cat)
debug "Input: $input"

tool=$(echo "$input" | jq -r '.tool')
debug "Tool: $tool"

# Hook logic...
```

Run with debugging:

```bash
DEBUG=true cat test-input.json | .claude/hooks/validate.sh
```

## Troubleshooting

### Hook not executing

**Causes:**

- Script not executable
- Invalid shebang
- Matcher pattern doesn't match
- Hook configuration syntax error

**Solutions:**

```bash
# Make executable
chmod +x .claude/hooks/script.sh

# Verify shebang
head -1 .claude/hooks/script.sh

# Test matcher
echo "Write" | grep -E "Write|Edit"

# Validate JSON
cat .claude/settings.json | jq .
```

### Invalid JSON output

**Causes:**

- Missing quotes
- Trailing commas
- Shell variable expansion in JSON
- Non-JSON output on stdout

**Solutions:**

```bash
# Use heredoc
cat << 'EOF'
{
  "decision": "allow"
}
EOF

# Validate JSON
echo '{"decision": "allow"}' | jq .

# Use jq to build JSON
jq -n --arg msg "Blocked" '{"decision": "deny", "message": $msg}'
```

### Hook times out

**Causes:**

- Long-running operations
- Infinite loops
- Blocking I/O

**Solutions:**

```bash
# Add timeout to subprocess
timeout 5s npm test || exit 1

# Set shorter timeouts
curl --max-time 5 "$url"
```

### Permission denied

**Solutions:**

```bash
# Fix script permissions
chmod +x .claude/hooks/script.sh

# Check file permissions
ls -la .claude/hooks/
```

## Common Patterns

### Auto-format on Save

```json
{
  "hooks": {
    "PostToolUse": [{
      "matcher": "Write|Edit",
      "hooks": [{"type": "command", "command": "${CLAUDE_PROJECT_DIR}/.claude/hooks/format.sh"}]
    }]
  }
}
```

### Block Sensitive Files

```bash
#!/usr/bin/env bash
set -e
input=$(cat)
file=$(echo "$input" | jq -r '.parameters.file_path // empty')
basename=$(basename "$file")

if [[ "$basename" =~ ^\.env|\.pem$|\.key$|secrets|credentials ]]; then
  echo '{"decision": "deny", "message": "Cannot modify sensitive file"}' >&2
  exit 2
fi

echo '{"decision": "allow"}'
exit 0
```

### Auto-approve Safe Operations

```bash
#!/usr/bin/env bash
set -e
input=$(cat)
tool=$(echo "$input" | jq -r '.tool')

if [[ "$tool" =~ ^(Read|Glob|Grep)$ ]]; then
  echo '{"decision": "allow"}'
  exit 0
fi

echo '{"decision": "ask"}'
exit 0
```

### Run Tests Before Committing

```bash
#!/usr/bin/env bash
set -e
input=$(cat)
command=$(echo "$input" | jq -r '.parameters.command // empty')

if [[ ! "$command" =~ git\ commit ]]; then
  echo '{"decision": "allow"}'
  exit 0
fi

if npm test 2>/dev/null; then
  echo '{"decision": "allow"}'
  exit 0
else
  echo '{"decision": "ask", "message": "Tests failing. Commit anyway?"}' >&2
  exit 2
fi
```

### Inject Project Context

```bash
#!/usr/bin/env bash
set -e

context="# Project Guidelines\n\n"
if [[ -f "${CLAUDE_PROJECT_DIR}/CLAUDE.md" ]]; then
  context+=$(cat "${CLAUDE_PROJECT_DIR}/CLAUDE.md")
fi

jq -n --arg ctx "$context" '{"additionalContext": $ctx}'
exit 0
```
