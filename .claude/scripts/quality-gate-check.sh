#!/bin/bash

# CC-Scrum Quality Gate Checker
# Validates Definition of Done (DoD) requirements before allowing merges

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
LOG_FILE="$PROJECT_ROOT/.claude/logs/quality-gate.log"

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Quality gate results
declare -A GATE_RESULTS=()
OVERALL_SCORE=0
TOTAL_GATES=0

# Individual gate functions
check_linting() {
    log "🔍 Checking code linting..."

    if command -v npm >/dev/null 2>&1 && [[ -f "$PROJECT_ROOT/package.json" ]]; then
        if npm run lint --silent 2>/dev/null; then
            GATE_RESULTS["linting"]="PASS"
            log "✅ Linting: PASSED"
            return 0
        else
            GATE_RESULTS["linting"]="FAIL"
            log "❌ Linting: FAILED"
            return 1
        fi
    else
        GATE_RESULTS["linting"]="SKIP"
        log "⏭️ Linting: SKIPPED (no npm/package.json)"
        return 0
    fi
}

check_type_checking() {
    log "🔍 Checking type safety..."

    if command -v npm >/dev/null 2>&1 && [[ -f "$PROJECT_ROOT/package.json" ]]; then
        if npm run typecheck --silent 2>/dev/null; then
            GATE_RESULTS["typecheck"]="PASS"
            log "✅ Type checking: PASSED"
            return 0
        else
            GATE_RESULTS["typecheck"]="FAIL"
            log "❌ Type checking: FAILED"
            return 1
        fi
    else
        GATE_RESULTS["typecheck"]="SKIP"
        log "⏭️ Type checking: SKIPPED (no npm/package.json)"
        return 0
    fi
}

check_test_coverage() {
    log "🔍 Checking test coverage..."

    local coverage_threshold=80

    if command -v npm >/dev/null 2>&1 && [[ -f "$PROJECT_ROOT/package.json" ]]; then
        if npm run test:coverage --silent 2>/dev/null; then
            # Try to extract coverage percentage
            local coverage_file="$PROJECT_ROOT/coverage/lcov-report/index.html"
            if [[ -f "$coverage_file" ]]; then
                # Extract coverage percentage (simplified)
                local coverage=$(grep -o "Functions.*[0-9]\+\%" "$coverage_file" | grep -o "[0-9]\+" | head -1 || echo "0")

                if [[ $coverage -ge $coverage_threshold ]]; then
                    GATE_RESULTS["coverage"]="PASS"
                    log "✅ Test coverage: PASSED ($coverage% >= $coverage_threshold%)"
                    return 0
                else
                    GATE_RESULTS["coverage"]="FAIL"
                    log "❌ Test coverage: FAILED ($coverage% < $coverage_threshold%)"
                    return 1
                fi
            else
                GATE_RESULTS["coverage"]="PASS"
                log "✅ Test coverage: PASSED (tests run successfully)"
                return 0
            fi
        else
            GATE_RESULTS["coverage"]="FAIL"
            log "❌ Test coverage: FAILED (tests failed)"
            return 1
        fi
    else
        GATE_RESULTS["coverage"]="SKIP"
        log "⏭️ Test coverage: SKIPPED (no npm/package.json)"
        return 0
    fi
}

check_security_audit() {
    log "🔍 Checking security vulnerabilities..."

    if command -v npm >/dev/null 2>&1 && [[ -f "$PROJECT_ROOT/package.json" ]]; then
        # Check for high/critical vulnerabilities
        if npm audit --audit-level=high --silent 2>/dev/null; then
            GATE_RESULTS["security"]="PASS"
            log "✅ Security audit: PASSED (no high/critical vulnerabilities)"
            return 0
        else
            GATE_RESULTS["security"]="FAIL"
            log "❌ Security audit: FAILED (high/critical vulnerabilities found)"
            return 1
        fi
    else
        GATE_RESULTS["security"]="SKIP"
        log "⏭️ Security audit: SKIPPED (no npm/package.json)"
        return 0
    fi
}

check_build_success() {
    log "🔍 Checking build process..."

    if command -v npm >/dev/null 2>&1 && [[ -f "$PROJECT_ROOT/package.json" ]]; then
        if npm run build --silent 2>/dev/null; then
            GATE_RESULTS["build"]="PASS"
            log "✅ Build: PASSED"
            return 0
        else
            GATE_RESULTS["build"]="FAIL"
            log "❌ Build: FAILED"
            return 1
        fi
    else
        GATE_RESULTS["build"]="SKIP"
        log "⏭️ Build: SKIPPED (no npm/package.json)"
        return 0
    fi
}

check_documentation() {
    log "🔍 Checking documentation..."

    local required_docs=("README.md" "CLAUDE.md" "DOD.md")
    local missing_docs=()

    for doc in "${required_docs[@]}"; do
        if [[ ! -f "$PROJECT_ROOT/$doc" ]]; then
            missing_docs+=("$doc")
        fi
    done

    if [[ ${#missing_docs[@]} -eq 0 ]]; then
        GATE_RESULTS["documentation"]="PASS"
        log "✅ Documentation: PASSED"
        return 0
    else
        GATE_RESULTS["documentation"]="FAIL"
        log "❌ Documentation: FAILED (missing: ${missing_docs[*]})"
        return 1
    fi
}

# Calculate overall score
calculate_score() {
    local passed=0
    local total=0

    for gate in "${!GATE_RESULTS[@]}"; do
        case "${GATE_RESULTS[$gate]}" in
            "PASS")
                ((passed++))
                ((total++))
                ;;
            "FAIL")
                ((total++))
                ;;
            "SKIP")
                # Skip doesn't count towards total
                ;;
        esac
    done

    if [[ $total -gt 0 ]]; then
        OVERALL_SCORE=$(( (passed * 100) / total ))
        TOTAL_GATES=$total
    else
        OVERALL_SCORE=100
        TOTAL_GATES=0
    fi
}

# Generate report
generate_report() {
    local status_icon
    local status_color

    if [[ $OVERALL_SCORE -ge 85 ]]; then
        status_icon="🟢"
        status_color="$GREEN"
    elif [[ $OVERALL_SCORE -ge 70 ]]; then
        status_icon="🟡"
        status_color="$YELLOW"
    else
        status_icon="🔴"
        status_color="$RED"
    fi

    echo -e "\n📋 ${status_color}Quality Gate Report${NC}"
    echo "=================================="
    echo -e "Status: $status_icon Overall Score: $OVERALL_SCORE/100"
    echo ""

    for gate in linting typecheck coverage security build documentation; do
        if [[ -n "${GATE_RESULTS[$gate]:-}" ]]; then
            case "${GATE_RESULTS[$gate]}" in
                "PASS")
                    echo -e "✅ $(printf '%-15s' "${gate^}:")"
                    ;;
                "FAIL")
                    echo -e "❌ $(printf '%-15s' "${gate^}:")"
                    ;;
                "SKIP")
                    echo -e "⏭️ $(printf '%-15s' "${gate^}:")"
                    ;;
            esac
        fi
    done

    echo ""

    if [[ $OVERALL_SCORE -ge 85 ]]; then
        echo -e "${GREEN}🎉 Quality gates passed! Ready for merge.${NC}"
        return 0
    elif [[ $OVERALL_SCORE -ge 70 ]]; then
        echo -e "${YELLOW}⚠️ Some quality issues found. Consider fixing before merge.${NC}"
        return 1
    else
        echo -e "${RED}🚫 Quality gates failed. Merge blocked.${NC}"
        return 2
    fi
}

# Main execution
main() {
    log "🚀 Starting CC-Scrum Quality Gate Check"

    cd "$PROJECT_ROOT"

    # Run all quality gates
    check_linting || true
    check_type_checking || true
    check_test_coverage || true
    check_security_audit || true
    check_build_success || true
    check_documentation || true

    # Calculate final score
    calculate_score

    # Generate and display report
    generate_report
    local exit_code=$?

    log "🏁 Quality gate check completed with score: $OVERALL_SCORE/100"

    return $exit_code
}

# Script options
case "${1:-}" in
    "--help"|"-h")
        echo "CC-Scrum Quality Gate Checker"
        echo ""
        echo "Usage: $0 [options]"
        echo ""
        echo "Options:"
        echo "  --help, -h     Show this help message"
        echo "  --quiet, -q    Quiet mode (minimal output)"
        echo "  --verbose, -v  Verbose mode (detailed output)"
        echo ""
        echo "Exit codes:"
        echo "  0    All quality gates passed (score >= 85)"
        echo "  1    Some issues found (score 70-84)"
        echo "  2    Quality gates failed (score < 70)"
        ;;
    "--quiet"|"-q")
        exec > /dev/null
        main
        ;;
    "--verbose"|"-v")
        set -x
        main
        ;;
    *)
        main
        ;;
esac