---
name: standup
description: Generate daily standup report with progress tracking and impediment identification
---

## 📅 Daily Standup Report

Automatically generates a comprehensive daily standup report with sprint progress, team activities, and impediment tracking.

### Usage
```
/standup [date] [team_member]
```

**Examples:**
```
/standup                    # Today's standup for entire team
/standup 2025-01-17        # Specific date standup
/standup today john        # Today's standup for specific member
```

### Report Generation Process

#### 1. Sprint Context Analysis
```bash
# Read current sprint data
Read SPRINT.md
Read BACKLOG.md

# Analyze recent activity
Grep "completed|in-progress|blocked" SPRINT.md
Bash git log --since="yesterday" --oneline
```

#### 2. Progress Tracking
- Story completion status
- Burndown chart updates
- Velocity calculations
- Sprint goal alignment

#### 3. Impediment Detection
- Blocked stories identification
- Technical debt accumulation
- External dependency issues
- Team capacity constraints

### Standup Report Format

```
📅 **Daily Standup - January 17, 2025**

## 🎯 Sprint Overview
**Sprint Goal:** Establish CC-Scrum agent framework with core automation
**Sprint:** #001 (Day 3 of 14)
**Burndown:** 11 story points remaining (13 total)
**Team Velocity:** On track (2 points/day average)

## ✅ Yesterday's Accomplishments
- **@dev**: Completed infrastructure setup (Story #001-A1)
- **@po**: Refined user stories for sprint backlog
- **@qa**: Created initial test strategy documentation
- **Team**: Sprint planning session completed

## 🎯 Today's Focus
- **@dev**: Begin sub-agent implementation (Story #001-A2)
- **@arch**: Review technical architecture constraints
- **@qa**: Set up automated testing framework
- **@sec**: Initial security review of agent architecture

## 🚫 Impediments & Blockers
1. **Medium Priority**: Claude Code tool permissions need configuration
   - **Impact**: Delays sub-agent testing
   - **Owner**: @dev
   - **ETA**: End of day

2. **Low Priority**: Documentation template needs refinement
   - **Impact**: Minor delay in documentation tasks
   - **Owner**: @po
   - **ETA**: Tomorrow morning

## ⚠️ Risks & Concerns
- **Technical Risk**: Agent integration complexity higher than estimated
  - **Mitigation**: Break down into smaller tasks, consult community
- **Schedule Risk**: Background process monitoring may need more time
  - **Mitigation**: Consider MVP approach for first sprint

## 📊 Sprint Metrics
**Story Completion Rate:** 15% (2 of 13 story points)
**Planned vs Actual:** On track
**Quality Metrics:**
- Defects: 0
- Code review approval rate: 100%
- Test coverage: N/A (no code yet)

**Team Health Indicators:**
- Impediment count: 2 (target: <3)
- Average resolution time: 1 day (target: <3 days)
- Team satisfaction: 8/10

## 🔄 Process Notes
- **What's Working Well**: Clear story definitions, good communication
- **Improvement Opportunities**: Need better estimation for technical tasks
- **Action Items**:
  - [ ] Refine estimation process for agent development
  - [ ] Set up automated burndown tracking
```

### Smart Features

#### Impediment Pattern Recognition
- Identifies recurring blockers
- Suggests resolution strategies
- Tracks impediment resolution time
- Flags escalation needs

#### Velocity Prediction
```bash
# Calculate team velocity trends
Bash git log --since="1 week ago" --oneline | wc -l
# Analyze story completion patterns
Grep "completed" SPRINT.md | wc -l
```

#### Risk Assessment
- Sprint goal jeopardy detection
- Scope creep identification
- Team capacity overload warnings
- External dependency tracking

### Integration Points

**With Other Commands:**
- `/review` - Links code review status to progress
- `/retrospective` - Feeds into retrospective data
- `/burndown` - Updates burndown charts

**With Agents:**
- **@sm** - Primary facilitator and report generator
- **@po** - Business value and priority insights
- **@dev** - Technical progress and blockers
- **@qa** - Quality metrics and testing progress

### Automation Features

#### Background Data Collection
```bash
# Automatically gather metrics
git log --since="yesterday" --pretty=format:"%h %s" > /tmp/recent_commits.txt
npm run test:coverage > /tmp/coverage_report.txt 2>&1
npm run lint > /tmp/lint_report.txt 2>&1
```

#### Smart Notifications
- Sends standup reminders
- Flags critical impediments
- Suggests follow-up actions
- Updates team dashboards

### Customization Options

**Team-specific configurations:**
- Time zone adjustments
- Custom metric tracking
- Integration with external tools
- Personalized report formats

**Sprint-specific focus:**
- Goal-oriented reporting
- Milestone tracking
- Release preparation status
- Demo readiness indicators