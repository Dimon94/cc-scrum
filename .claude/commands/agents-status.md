---
name: agents-status
description: Check status and capabilities of all CC-Scrum agents
---

## 🤖 CC-Scrum Agents Status Check

This command verifies that all CC-Scrum agents are properly configured and ready for use.

### Usage
```
/agents-status
```

### Agent Verification

#### Core Scrum Team Agents

**🎯 @po (Product Owner)**
- **Role**: Requirements analysis, user story creation, business value alignment
- **Tools**: WebSearch, WebFetch, Read, Edit, Grep
- **Specialties**: INVEST principles, MoSCoW prioritization, acceptance criteria
- **Status**: ✅ Active

**🏃‍♂️ @sm (Scrum Master)**
- **Role**: Process facilitation, impediment removal, progress tracking
- **Tools**: Read, Edit, Grep, Bash
- **Specialties**: Sprint metrics, burndown analysis, team health monitoring
- **Status**: ✅ Active

**🏗️ @arch (Solution Architect)**
- **Role**: Technical design, architecture decisions, system evolution
- **Tools**: Read, Edit, Write, Bash, Grep, Glob, WebSearch, WebFetch
- **Specialties**: ADR documentation, technology selection, scalability planning
- **Status**: ✅ Active

**💻 @dev (Developer)**
- **Role**: Code implementation, technical delivery, algorithm validation
- **Tools**: Read, Edit, MultiEdit, Write, Bash, Grep, Glob, WebSearch, WebFetch
- **Specialties**: REPL validation, code quality, testing integration
- **Status**: ✅ Active

**🧪 @qa (Quality Assurance)**
- **Role**: Test strategy, coverage analysis, quality validation
- **Tools**: Read, Edit, Write, Bash, Grep, Glob, WebSearch
- **Specialties**: Test pyramid, edge case analysis, quality metrics
- **Status**: ✅ Active

**🛡️ @sec (Security Specialist)**
- **Role**: Security review, vulnerability assessment, compliance
- **Tools**: Read, Edit, Bash, Grep, Glob, WebSearch, WebFetch
- **Specialties**: OWASP Top 10, threat modeling, security testing
- **Status**: ✅ Active

### Quick Verification Test

#### Test Each Agent
```bash
# Test Product Owner
echo "Testing @po agent..."
# Expected: Should respond with user story analysis capabilities

# Test Scrum Master
echo "Testing @sm agent..."
# Expected: Should respond with sprint tracking capabilities

# Test Architect
echo "Testing @arch agent..."
# Expected: Should respond with architecture design capabilities

# Test Developer
echo "Testing @dev agent..."
# Expected: Should respond with implementation capabilities

# Test QA
echo "Testing @qa agent..."
# Expected: Should respond with testing strategy capabilities

# Test Security
echo "Testing @sec agent..."
# Expected: Should respond with security analysis capabilities
```

### Agent Configuration Summary

```yaml
Total Agents: 6
Active Agents: 6
Coverage Areas:
  - Product Management: @po
  - Process Management: @sm
  - Technical Architecture: @arch
  - Implementation: @dev
  - Quality Assurance: @qa
  - Security: @sec

Tool Distribution:
  - Read: All agents
  - Edit: All agents
  - WebSearch: @po, @arch, @dev, @qa, @sec
  - WebFetch: @po, @arch, @dev, @sec
  - Bash: @sm, @arch, @dev, @qa, @sec
  - Grep: All agents
  - Glob: @arch, @dev, @qa, @sec
  - Write: @arch, @dev, @qa
  - MultiEdit: @dev
```

### Integration Verification

#### Agent Collaboration Chains
```mermaid
graph LR
    A[@po] --> B[@arch]
    B --> C[@dev]
    C --> D[@qa]
    D --> E[@sec]
    E --> F[@sm]
    F --> A
```

**Primary Workflows:**
1. **Requirements → Implementation**: @po → @arch → @dev → @qa → @sec
2. **Quality Assurance**: @dev → @qa → @sec → @sm
3. **Process Management**: @sm ↔ All agents
4. **Architecture Review**: @arch ↔ @dev, @sec, @qa

### Health Check Results

```markdown
## Agent Health Report

✅ **Configuration Files**: All 6 agents have valid Markdown configurations
✅ **Tool Permissions**: All required tools are properly assigned
✅ **Model Assignment**: All agents use claude-3-5-sonnet-20241022
✅ **Prompt Quality**: All agents have comprehensive system prompts
✅ **Integration Points**: Cross-agent collaboration patterns defined

## Readiness Status: 🟢 READY FOR PRODUCTION

All CC-Scrum agents are properly configured and ready for use.
You can now start using the full Scrum workflow with AI assistance.
```

### Next Steps

After verifying agent status, you can:

1. **Start with Requirements**: `@po "Convert this business need into a user story"`
2. **Plan Architecture**: `@arch "Design technical approach for [feature]"`
3. **Break Down Tasks**: `/meta-todo "Your user story here"`
4. **Implement Features**: `@dev "Implement [specific task]"`
5. **Ensure Quality**: `@qa "Create test strategy for [feature]"`
6. **Secure Implementation**: `@sec "Review security implications of [feature]"`
7. **Track Progress**: `/standup` or `@sm "Generate sprint progress report"`

### Troubleshooting

If any agent appears inactive:
1. Check `.claude/agents/[agent].md` file exists
2. Verify YAML frontmatter is properly formatted
3. Ensure agent name matches file name
4. Restart Claude Code if necessary

For detailed usage examples, see `GETTING_STARTED.md`.