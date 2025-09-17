# CC-Scrum Hooks System

This directory contains Claude Code hooks that implement intelligent analysis and automation for the CC-Scrum framework.

## Available Hooks

### 1. Pre-Tool Use Hook (`pre_tool_use.sh`)

**Purpose**: Validates tool usage context and enforces quality gates before tool execution.

**Features**:
- **Security Validation**: Blocks dangerous commands and warns about commands requiring confirmation
- **Quality Gate Enforcement**: Validates JSON/YAML syntax and checks DoD compliance
- **Sprint Context Awareness**: Enforces stricter policies during active sprints
- **Agent Collaboration**: Validates referenced agents are properly configured
- **Performance Monitoring**: Logs tool usage for analysis

**Configuration** (via `.claude/settings.json`):
```json
{
  "security": {
    "dangerous_commands": ["rm -rf", "kubectl delete"],
    "require_confirmation": ["git push --force", "npm publish"]
  }
}
```

### 2. Post-Tool Use Hook (`post_tool_use.sh`)

**Purpose**: Analyzes tool results and triggers follow-up actions.

**Features**:
- **Auto-Healing**: Provides intelligent suggestions for failed tool executions
- **Quality Gate Triggers**: Automatically schedules quality checks for code modifications
- **Smart Context Tracking**: Builds usage patterns for optimization suggestions
- **Sprint Progress Tracking**: Updates sprint activities and metrics
- **Background Process Management**: Restarts monitoring after build commands
- **Performance Analytics**: Tracks execution times and identifies anomalies

**Auto-Healing Examples**:
- Missing commands → Installation suggestions
- Permission denied → Permission guidance
- File not found → Path verification tips

### 3. User Prompt Submit Hook (`user_prompt_submit.sh`)

**Purpose**: Analyzes user prompts and provides intelligent routing to appropriate agents.

**Features**:
- **Smart Agent Routing**: Suggests relevant agents based on prompt keywords
- **Workflow Integration**: Provides command suggestions for common tasks
- **Context Analysis**: Warns about missing context in requests
- **Sprint Alignment**: Checks prompt alignment with current sprint goals
- **Quality Hints**: Provides communication tips for better results
- **Emergency Detection**: Prioritizes urgent requests

**Agent Routing Keywords**:
- `@po`: user story, requirement, feature, epic, business
- `@sm`: sprint, standup, retrospective, velocity, process
- `@arch`: architecture, design, pattern, scalability, ADR
- `@dev`: code, implement, function, debug, refactor
- `@qa`: test, quality, bug, coverage, automation
- `@sec`: security, vulnerability, auth, encryption, OWASP

## Hook Configuration

Hooks are configured through the main settings file:

```json
{
  "hooks": {
    "pre_tool_use": true,
    "post_tool_use": true,
    "user_prompt_submit": true
  },
  "automation": {
    "auto_healing": true,
    "smart_context": true
  },
  "background_monitoring": {
    "log_analysis": true
  }
}
```

## Environment Variables

Hooks receive the following environment variables from Claude Code:

### Pre-Tool Use
- `CLAUDE_TOOL_NAME`: Name of the tool being executed
- `CLAUDE_TOOL_ARGS`: JSON string of tool arguments
- `CLAUDE_USER_MESSAGE`: Current user message
- `CLAUDE_CONVERSATION_CONTEXT`: Conversation context

### Post-Tool Use
- `CLAUDE_TOOL_NAME`: Name of the executed tool
- `CLAUDE_TOOL_ARGS`: JSON string of tool arguments
- `CLAUDE_TOOL_RESULT`: Tool execution result
- `CLAUDE_TOOL_SUCCESS`: Boolean indicating success/failure
- `CLAUDE_EXECUTION_TIME`: Execution time in milliseconds

### User Prompt Submit
- `CLAUDE_USER_PROMPT`: The submitted user prompt
- `CLAUDE_CONVERSATION_HISTORY`: Previous conversation context
- `CLAUDE_SESSION_ID`: Unique session identifier

## Logging

All hooks write to a shared log file: `.claude/logs/hooks.log`

Log format: `[YYYY-MM-DD HH:MM:SS] [HOOK-TYPE] message`

Additional specialized logs:
- `.claude/logs/tool_analytics.jsonl`: Tool usage analytics
- `.claude/logs/auto_quality_check.log`: Background quality checks

## Data Files

Hooks maintain several data files for context and analytics:

- `.claude/data/tool_context.json`: Tool usage patterns (last 1000 entries)
- `.claude/data/user_engagement.json`: User interaction patterns (last 500 entries)
- `.claude/data/current_sprint.json`: Sprint tracking and activities

## Security Features

### Dangerous Command Protection
- Blocks execution of configured dangerous commands
- Warns about commands requiring confirmation
- Logs all security-related decisions

### DoD Compliance
- Checks for test files when modifying code
- Validates configuration file syntax
- Enforces documentation requirements

### Sprint Protection
- Blocks direct production deployments during active sprints
- Enforces review processes for critical changes

## Performance Monitoring

### Execution Time Analysis
- Tracks tool execution times
- Identifies performance anomalies (>2x average)
- Provides optimization suggestions

### Usage Pattern Analysis
- Builds tool usage patterns
- Suggests workflow optimizations
- Identifies common failure points

## Integration with CC-Scrum Components

### Quality Gates
- Triggers background quality checks for code changes
- Integrates with `.claude/scripts/quality-gate-check.sh`
- Enforces coverage thresholds and security scans

### Background Monitoring
- Restarts background processes after build commands
- Integrates with `.claude/scripts/background-monitor.sh`
- Provides self-healing capabilities

### Agent System
- Validates agent references in conversation
- Provides intelligent agent routing suggestions
- Tracks multi-agent collaboration patterns

## Troubleshooting

### Hook Not Executing
1. Check hook files are executable: `chmod +x .claude/hooks/*.sh`
2. Verify settings configuration enables hooks
3. Check log files for error messages

### Permission Issues
1. Ensure hooks directory is writable
2. Check log directory permissions
3. Verify script execution permissions

### Performance Issues
1. Review hook execution logs
2. Check data file sizes (auto-cleanup at limits)
3. Disable verbose logging if needed

## Customization

### Adding Custom Validations
Modify `pre_tool_use.sh` to add project-specific validations:

```bash
# Custom validation example
if [[ "$TOOL_NAME" == "Bash" ]] && [[ "$COMMAND" == *"deploy"* ]]; then
    # Add custom deployment checks
fi
```

### Custom Agent Routing
Extend `user_prompt_submit.sh` with additional keywords:

```bash
# Custom agent routing
if echo "$USER_PROMPT" | grep -iE "(custom|special)" >/dev/null; then
    SUGGESTED_AGENTS+=("@custom")
fi
```

### Custom Analytics
Add project-specific metrics to `post_tool_use.sh`:

```bash
# Custom metrics
if [[ "$TOOL_NAME" == "specific_tool" ]]; then
    # Track custom metrics
fi
```

## Best Practices

1. **Keep Hooks Fast**: Hooks should execute quickly to avoid delays
2. **Fail Gracefully**: Always use `|| true` for non-critical operations
3. **Log Appropriately**: Balance between useful logs and noise
4. **Test Thoroughly**: Test hooks with various tool combinations
5. **Monitor Performance**: Watch hook execution times in logs
6. **Security First**: Always validate inputs and sanitize outputs