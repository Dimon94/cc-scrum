---
name: meta-todo
description: Intelligent task breakdown using Meta-Todo methodology with multi-agent validation
---

## 🧠 Meta-Todo: Intelligent Task Orchestration

Advanced task breakdown system that converts user stories into comprehensive, validated, executable task trees using multi-agent intelligence and background execution.

### Usage
```
/meta-todo "[user_story]" [options]
```

**Options:**
- `--tier=1|2|3` - Complexity tier (auto-detected if not specified)
- `--background` - Enable background research and preparation
- `--validate` - Run full validation cycle
- `--update` - Update existing story in SPRINT.md

**Examples:**
```
/meta-todo "As a user, I want to login with OAuth so that I can access my account securely"
/meta-todo "Implement real-time chat with WebSocket" --tier=3 --background
/meta-todo "Fix login button styling" --tier=1
```

### Meta-Todo Processing Pipeline

#### Phase 1: Smart Intent Capture
```
Multi-Approach Analysis:
┌─ Keyword Analysis ────────────────────┐
│ • Extract domain terms and patterns   │
│ • Identify complexity indicators      │
│ • Map to known successful patterns    │
└───────────────────────────────────────┘

┌─ Semantic Parsing ────────────────────┐
│ • AI understanding of requirements   │
│ • Context-aware interpretation       │
│ • Ambiguity resolution               │
└───────────────────────────────────────┘

┌─ Comparative Analysis ────────────────┐
│ • Match against historical success   │
│ • Learn from similar implementations │
│ • Apply proven breakdown patterns    │
└───────────────────────────────────────┘

┌─ Context Integration ─────────────────┐
│ • Current project constraints        │
│ • Team capacity and skills           │
│ • Architectural requirements         │
└───────────────────────────────────────┘

Confidence Scoring: Keyword(0.8) + Semantic(0.9) + Context(0.7) + Comparative(0.8) = 0.825
```

#### Phase 2: Multi-Agent Validation
```
Parallel Validation Pipeline:

@pmgr (Completeness Validator)
├─ Ensures all aspects covered
├─ Validates against comprehensive patterns
├─ Identifies missing components
└─ Score: 0.92

@arch (Feasibility Validator)
├─ Realistic time/resource estimates
├─ Technical feasibility assessment
├─ Dependency validation
└─ Score: 0.88

@qa (Accuracy Validator)
├─ Verifies tasks match intent
├─ Validates testability
├─ Ensures quality gates
└─ Score: 0.90

@sec (Security Validator)
├─ Security considerations
├─ Compliance requirements
├─ Risk assessment
└─ Score: 0.85

Consensus Score: (0.92 + 0.88 + 0.90 + 0.85) / 4 = 0.89 ✅
```

#### Phase 3: Task Tree Generation

**Tier 1: Simple Tasks (1-4 hours)**
```
Story: "Fix login button styling"

Generated Tasks:
A1. Identify current styling issues (30 min)
    ├─ Dependencies: None
    ├─ Skills: CSS, Design review
    ├─ Background eligible: No
    └─ Acceptance: Button appears correctly

A2. Update CSS styles (1 hour)
    ├─ Dependencies: A1
    ├─ Skills: CSS, Cross-browser testing
    ├─ Background eligible: No
    └─ Acceptance: Styles applied and tested

A3. Test across browsers (30 min)
    ├─ Dependencies: A2
    ├─ Skills: Manual testing
    ├─ Background eligible: Yes
    └─ Acceptance: Works in all target browsers
```

**Tier 2: Complex Features (1-3 sprints)**
```
Story: "As a user, I want OAuth login for secure access"

Generated Tasks:
A1. OAuth provider research and selection (2 hours)
    ├─ Dependencies: None
    ├─ Background eligible: Yes
    ├─ Parallel with: A2, A3
    └─ Deliverable: Provider comparison and recommendation

A2. Security requirements analysis (1 hour)
    ├─ Dependencies: None
    ├─ Agent: @sec
    ├─ Background eligible: Yes
    └─ Deliverable: Security requirements document

A3. Architecture design (3 hours)
    ├─ Dependencies: A1, A2
    ├─ Agent: @arch
    ├─ Background eligible: No
    └─ Deliverable: OAuth integration architecture

A4. Backend OAuth implementation (8 hours)
    ├─ Dependencies: A3
    ├─ Agent: @dev
    ├─ Background eligible: No
    └─ Deliverable: OAuth backend with tests

A5. Frontend integration (6 hours)
    ├─ Dependencies: A4
    ├─ Agent: @dev
    ├─ Background eligible: No
    └─ Deliverable: OAuth login UI

A6. Security testing (4 hours)
    ├─ Dependencies: A5
    ├─ Agent: @sec + @qa
    ├─ Background eligible: Partial
    └─ Deliverable: Security test report

A7. End-to-end testing (3 hours)
    ├─ Dependencies: A6
    ├─ Agent: @qa
    ├─ Background eligible: Yes
    └─ Deliverable: E2E test suite
```

**Tier 3: Project-Level (Multiple sprints)**
```
Story: "Build real-time chat application with user authentication"

Generated Epic Breakdown:
Epic 1: Authentication System (1 sprint)
Epic 2: Real-time Messaging Core (1 sprint)
Epic 3: User Interface (1 sprint)
Epic 4: Advanced Features (1 sprint)

Each epic contains 8-15 detailed tasks with full dependency mapping...
```

#### Phase 4: Background Execution Queue

**Research Tasks** (Background eligible):
```bash
# Run in parallel while user continues work
WebSearch "OAuth 2.0 best practices 2025"
WebFetch top security guidelines
Read existing authentication patterns
Grep current codebase for auth implementations
```

**Analysis Tasks** (Background eligible):
```bash
# Performance and compatibility analysis
Bash npm audit --audit-level=moderate
Grep "auth|login|session" src/**/*.js
Read package.json dependencies
Analyze current architecture constraints
```

**Preparation Tasks** (Background eligible):
```bash
# Environment and scaffold preparation
Bash npm install oauth-library
Write test-oauth-config.json template
Create migration scripts if needed
Set up testing environment
```

### Learning and Evolution

#### Pattern Storage (CLAUDE.md Integration)
```markdown
## Successful Task Patterns (Auto-updated)

### OAuth Implementation Pattern
- Research + Security analysis: 3 hours (parallel)
- Architecture design: 3 hours (after research)
- Backend implementation: 8 hours
- Frontend integration: 6 hours
- Security + E2E testing: 7 hours (partial parallel)
- **Total**: 27 hours, **Success Rate**: 95%

### Simple UI Fix Pattern
- Issue identification: 30 min
- Implementation: 1 hour
- Cross-browser testing: 30 min (background)
- **Total**: 2 hours, **Success Rate**: 98%
```

#### Estimation Accuracy Improvement
```javascript
// Learning algorithm (conceptual)
const historicalData = {
  "oauth_implementation": {
    estimated: 24, actual: 27, variance: +12.5%
  },
  "ui_fixes": {
    estimated: 2, actual: 1.8, variance: -10%
  }
};

// Adjust future estimates based on patterns
function adjustEstimate(taskType, baseEstimate) {
  const pattern = historicalData[taskType];
  if (pattern) {
    return baseEstimate * (1 + pattern.variance / 100);
  }
  return baseEstimate;
}
```

### Output Format (SPRINT.md Integration)

```markdown
## Task Tree: OAuth Login Implementation

**Meta-Todo Analysis:**
- **Intent Confidence**: 89% (High)
- **Complexity Tier**: 2 (Complex Feature)
- **Estimated Duration**: 27 hours
- **Background Tasks**: 5 of 7 tasks eligible
- **Critical Path**: A1→A3→A4→A5→A6→A7 (18 hours)
- **Parallel Opportunities**: A1,A2,A3 can run concurrently

**Validation Results:**
- ✅ Completeness: 92% (All major components identified)
- ✅ Feasibility: 88% (Realistic timeline and resources)
- ✅ Accuracy: 90% (Tasks align with story intent)
- ✅ Security: 85% (Security considerations included)

**Task Breakdown:**
[Detailed task tree as shown above]

**Background Execution Started:**
- 🔄 OAuth provider research (WebSearch + WebFetch)
- 🔄 Security requirements analysis (@sec agent)
- 🔄 Current auth patterns analysis (Grep + Read)
```

### Success Metrics

**Accuracy Improvements:**
- Week 1: 70% task completion accuracy
- Week 4: 85% accuracy (pattern learning)
- Week 12: 92% accuracy (domain expertise)

**Time Estimation:**
- Initial: ±40% variance
- After learning: ±15% variance
- Mature system: ±8% variance

**Background Productivity:**
- 40-60% of tasks run in background
- 2-3x effective productivity increase
- Zero conversation blocking for research tasks

The Meta-Todo system transforms reactive task creation into proactive, intelligent orchestration that gets smarter with every use.