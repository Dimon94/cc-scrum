---
name: review
description: Comprehensive code review with multi-agent orchestration and DoD validation
---

## 🔍 Comprehensive Code Review

This command orchestrates a multi-agent code review process with Definition of Done (DoD) validation.

### Usage
```
/review [scope] [files...]
```

**Scopes:**
- `staged` - Review staged files (default)
- `pr` - Review changes in current PR/branch
- `files` - Review specific files
- `all` - Review all recent changes

**Examples:**
```
/review
/review staged
/review pr
/review files src/auth.js src/api.js
```

### Review Process

#### Phase 1: Automated Checks
```bash
# Linting and formatting
npm run lint
npm run typecheck

# Testing and coverage
npm run test:coverage

# Security scanning
npm audit --audit-level=high

# Build validation
npm run build
```

#### Phase 2: Agent Reviews

**@dev Agent Review:**
- Code quality and conventions
- Performance implications
- Error handling patterns
- Test coverage adequacy

**@sec Agent Review:**
- OWASP Top 10 compliance
- Input validation security
- Authentication/authorization
- Cryptographic implementations

**@qa Agent Review:**
- Test strategy validation
- Edge case coverage
- Quality metrics analysis
- Automation opportunities

**@arch Agent Review (if applicable):**
- Architectural consistency
- Design pattern adherence
- Performance characteristics
- Scalability considerations

#### Phase 3: DoD Compliance Check

Validates against Definition of Done requirements:
- [ ] Testing requirements (≥80% coverage)
- [ ] Security scan (0 high/critical issues)
- [ ] Code standards (lint/typecheck pass)
- [ ] Documentation updates
- [ ] Deployment readiness

### Review Output

```
📋 **Code Review Report**

**Status:** 🟢 APPROVED / 🟡 NEEDS IMPROVEMENT / 🔴 CHANGES REQUIRED
**Overall Score:** 85/100

## 🤖 Automated Checks
✅ LINT: PASSED
✅ TYPECHECK: PASSED
✅ TESTS: PASSED (Coverage: 87%)
❌ SECURITY: 2 medium vulnerabilities found
✅ BUILD: PASSED

## 👥 Agent Reviews
🟢 @dev: 88/100 - Good code quality, minor improvements suggested
🟡 @sec: 75/100 - Security issues need attention
🟢 @qa: 90/100 - Excellent test coverage
🟢 @arch: 85/100 - Follows architectural patterns

## ✅ DoD Compliance: 82/100
🟢 Testing: 87% coverage (threshold: 80%)
🟡 Security: 2 medium issues (target: 0 high/critical)
🟢 Code Standards: All checks pass
🟡 Documentation: README needs updates
🟢 Deployment: Ready for staging

## 💡 Recommendations
1. Address security vulnerabilities in authentication module
2. Update README with new API endpoints
3. Consider adding performance tests for data processing

## 🎯 Action Items
**Before merge:**
- Fix 2 security vulnerabilities
- Update documentation
- Re-run /review to validate fixes
```

### Integration with Development Workflow

The review command integrates with:
- **Git hooks** for automatic review triggers
- **CLAUDE.md** patterns for consistent quality
- **Background processes** for continuous monitoring
- **Quality gates** for merge protection

### Success Criteria

- Overall score ≥85 for automatic approval
- All critical/high security issues resolved
- DoD compliance score ≥85
- Agent consensus on code quality

### Background Execution

Long-running checks (security scans, comprehensive tests) run in background while providing immediate feedback on quick validations.