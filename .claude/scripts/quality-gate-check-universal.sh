#!/bin/bash

# CC-Scrum Universal Quality Gate Checker
# Cross-platform validator for Definition of Done (DoD) requirements
# Compatible with Bash 3.2+ (macOS default) and Bash 4+

set -euo pipefail

# Version info
SCRIPT_VERSION="1.1.0"

# Platform detection
PLATFORM=""
case "$(uname -s)" in
    Darwin*) PLATFORM="macOS" ;;
    Linux*)
        if [[ -f /proc/version ]] && grep -q Microsoft /proc/version; then
            PLATFORM="WSL"
        else
            PLATFORM="Linux"
        fi
        ;;
    CYGWIN*|MINGW*|MSYS*) PLATFORM="Windows" ;;
    *) PLATFORM="Unknown" ;;
esac

# Bash version compatibility
BASH_MAJOR_VERSION=$(echo "${BASH_VERSION:-3}" | cut -d. -f1)
USE_ASSOCIATIVE_ARRAYS=false
if [[ "$BASH_MAJOR_VERSION" -ge 4 ]]; then
    USE_ASSOCIATIVE_ARRAYS=true
fi

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
LOG_FILE="$PROJECT_ROOT/.claude/logs/quality-gate.log"

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

# Colors for output (with fallback for systems without color support)
if [[ -t 1 ]] && command -v tput >/dev/null 2>&1 && tput colors >/dev/null 2>&1; then
    RED=$(tput setaf 1)
    GREEN=$(tput setaf 2)
    YELLOW=$(tput setaf 3)
    NC=$(tput sgr0)
else
    RED=''
    GREEN=''
    YELLOW=''
    NC=''
fi

# Quality gate results - using arrays for Bash 3.2 compatibility
GATE_NAMES=()
GATE_RESULTS=()
OVERALL_SCORE=0
TOTAL_GATES=0

# Helper functions for cross-platform array handling
add_gate_result() {
    local name="$1"
    local result="$2"
    GATE_NAMES+=("$name")
    GATE_RESULTS+=("$result")
}

get_gate_result() {
    local name="$1"
    local i
    for i in "${!GATE_NAMES[@]}"; do
        if [[ "${GATE_NAMES[$i]}" == "$name" ]]; then
            echo "${GATE_RESULTS[$i]}"
            return
        fi
    done
    echo "UNKNOWN"
}

# Individual gate functions
check_linting() {
    log "🔍 Checking code linting..."

    if command -v npm >/dev/null 2>&1 && [[ -f "$PROJECT_ROOT/package.json" ]]; then
        if cd "$PROJECT_ROOT" && npm run lint --silent >/dev/null 2>&1; then
            add_gate_result "linting" "PASS"
            log "✅ Linting: PASSED"
            return 0
        else
            add_gate_result "linting" "FAIL"
            log "❌ Linting: FAILED"
            return 1
        fi
    elif command -v flake8 >/dev/null 2>&1 && [[ -f "$PROJECT_ROOT/setup.py" || -f "$PROJECT_ROOT/pyproject.toml" ]]; then
        if cd "$PROJECT_ROOT" && flake8 . >/dev/null 2>&1; then
            add_gate_result "linting" "PASS"
            log "✅ Python linting: PASSED"
            return 0
        else
            add_gate_result "linting" "FAIL"
            log "❌ Python linting: FAILED"
            return 1
        fi
    elif command -v cargo >/dev/null 2>&1 && [[ -f "$PROJECT_ROOT/Cargo.toml" ]]; then
        if cd "$PROJECT_ROOT" && cargo clippy -- -D warnings >/dev/null 2>&1; then
            add_gate_result "linting" "PASS"
            log "✅ Rust linting: PASSED"
            return 0
        else
            add_gate_result "linting" "FAIL"
            log "❌ Rust linting: FAILED"
            return 1
        fi
    elif command -v golint >/dev/null 2>&1 && [[ -f "$PROJECT_ROOT/go.mod" ]]; then
        if cd "$PROJECT_ROOT" && golint ./... >/dev/null 2>&1 && go vet ./... >/dev/null 2>&1; then
            add_gate_result "linting" "PASS"
            log "✅ Go linting: PASSED"
            return 0
        else
            add_gate_result "linting" "FAIL"
            log "❌ Go linting: FAILED"
            return 1
        fi
    else
        add_gate_result "linting" "SKIP"
        log "⏭️ Linting: SKIPPED (no compatible linter found)"
        return 0
    fi
}

check_type_checking() {
    log "🔍 Checking type safety..."

    if command -v npm >/dev/null 2>&1 && [[ -f "$PROJECT_ROOT/package.json" ]]; then
        # Check if TypeScript is configured
        if [[ -f "$PROJECT_ROOT/tsconfig.json" ]] || grep -q '"typescript"' "$PROJECT_ROOT/package.json" 2>/dev/null; then
            if cd "$PROJECT_ROOT" && npm run typecheck --silent >/dev/null 2>&1; then
                add_gate_result "typecheck" "PASS"
                log "✅ Type checking: PASSED"
                return 0
            else
                add_gate_result "typecheck" "FAIL"
                log "❌ Type checking: FAILED"
                return 1
            fi
        else
            add_gate_result "typecheck" "SKIP"
            log "⏭️ Type checking: SKIPPED (no TypeScript config)"
            return 0
        fi
    elif command -v mypy >/dev/null 2>&1 && [[ -f "$PROJECT_ROOT/setup.py" || -f "$PROJECT_ROOT/pyproject.toml" ]]; then
        if cd "$PROJECT_ROOT" && mypy . >/dev/null 2>&1; then
            add_gate_result "typecheck" "PASS"
            log "✅ Python type checking: PASSED"
            return 0
        else
            add_gate_result "typecheck" "FAIL"
            log "❌ Python type checking: FAILED"
            return 1
        fi
    else
        add_gate_result "typecheck" "SKIP"
        log "⏭️ Type checking: SKIPPED (no type checker available)"
        return 0
    fi
}

check_test_coverage() {
    log "🔍 Checking test coverage..."

    local coverage_threshold=80

    if command -v npm >/dev/null 2>&1 && [[ -f "$PROJECT_ROOT/package.json" ]]; then
        if cd "$PROJECT_ROOT" && npm run test:coverage --silent >/dev/null 2>&1; then
            # Try to extract coverage percentage from various formats
            local coverage=0
            local coverage_files=(
                "coverage/lcov-report/index.html"
                "coverage/coverage-summary.json"
                "coverage.json"
            )

            for coverage_file in "${coverage_files[@]}"; do
                if [[ -f "$PROJECT_ROOT/$coverage_file" ]]; then
                    case "$coverage_file" in
                        *.html)
                            coverage=$(grep -o "Functions.*[0-9]\+%" "$PROJECT_ROOT/$coverage_file" | grep -o "[0-9]\+" | head -1 2>/dev/null || echo "0")
                            ;;
                        *.json)
                            if command -v jq >/dev/null 2>&1; then
                                coverage=$(jq -r '.total.functions.pct // .total.lines.pct // 0' "$PROJECT_ROOT/$coverage_file" 2>/dev/null | cut -d. -f1 || echo "0")
                            fi
                            ;;
                    esac
                    break
                fi
            done

            if [[ $coverage -ge $coverage_threshold ]]; then
                add_gate_result "coverage" "PASS"
                log "✅ Test coverage: PASSED ($coverage% >= $coverage_threshold%)"
                return 0
            else
                add_gate_result "coverage" "FAIL"
                log "❌ Test coverage: FAILED ($coverage% < $coverage_threshold%)"
                return 1
            fi
        else
            add_gate_result "coverage" "FAIL"
            log "❌ Test coverage: FAILED (tests failed)"
            return 1
        fi
    elif command -v pytest >/dev/null 2>&1 && [[ -f "$PROJECT_ROOT/setup.py" || -f "$PROJECT_ROOT/pyproject.toml" ]]; then
        if cd "$PROJECT_ROOT" && pytest --cov --cov-report=term-missing >/dev/null 2>&1; then
            add_gate_result "coverage" "PASS"
            log "✅ Python test coverage: PASSED"
            return 0
        else
            add_gate_result "coverage" "FAIL"
            log "❌ Python test coverage: FAILED"
            return 1
        fi
    elif command -v cargo >/dev/null 2>&1 && [[ -f "$PROJECT_ROOT/Cargo.toml" ]]; then
        if cd "$PROJECT_ROOT" && cargo test >/dev/null 2>&1; then
            add_gate_result "coverage" "PASS"
            log "✅ Rust tests: PASSED"
            return 0
        else
            add_gate_result "coverage" "FAIL"
            log "❌ Rust tests: FAILED"
            return 1
        fi
    elif command -v go >/dev/null 2>&1 && [[ -f "$PROJECT_ROOT/go.mod" ]]; then
        if cd "$PROJECT_ROOT" && go test ./... >/dev/null 2>&1; then
            add_gate_result "coverage" "PASS"
            log "✅ Go tests: PASSED"
            return 0
        else
            add_gate_result "coverage" "FAIL"
            log "❌ Go tests: FAILED"
            return 1
        fi
    else
        add_gate_result "coverage" "SKIP"
        log "⏭️ Test coverage: SKIPPED (no test framework detected)"
        return 0
    fi
}

check_security_audit() {
    log "🔍 Checking security vulnerabilities..."

    if command -v npm >/dev/null 2>&1 && [[ -f "$PROJECT_ROOT/package.json" ]]; then
        if cd "$PROJECT_ROOT" && npm audit --audit-level=high --silent >/dev/null 2>&1; then
            add_gate_result "security" "PASS"
            log "✅ Security audit: PASSED (no high/critical vulnerabilities)"
            return 0
        else
            add_gate_result "security" "FAIL"
            log "❌ Security audit: FAILED (high/critical vulnerabilities found)"
            return 1
        fi
    elif command -v safety >/dev/null 2>&1 && [[ -f "$PROJECT_ROOT/requirements.txt" ]]; then
        if cd "$PROJECT_ROOT" && safety check >/dev/null 2>&1; then
            add_gate_result "security" "PASS"
            log "✅ Python security check: PASSED"
            return 0
        else
            add_gate_result "security" "FAIL"
            log "❌ Python security check: FAILED"
            return 1
        fi
    elif command -v cargo >/dev/null 2>&1 && [[ -f "$PROJECT_ROOT/Cargo.toml" ]]; then
        if cd "$PROJECT_ROOT" && cargo audit >/dev/null 2>&1; then
            add_gate_result "security" "PASS"
            log "✅ Rust security audit: PASSED"
            return 0
        else
            add_gate_result "security" "FAIL"
            log "❌ Rust security audit: FAILED"
            return 1
        fi
    elif command -v gosec >/dev/null 2>&1 && [[ -f "$PROJECT_ROOT/go.mod" ]]; then
        if cd "$PROJECT_ROOT" && gosec ./... >/dev/null 2>&1; then
            add_gate_result "security" "PASS"
            log "✅ Go security check: PASSED"
            return 0
        else
            add_gate_result "security" "FAIL"
            log "❌ Go security check: FAILED"
            return 1
        fi
    else
        add_gate_result "security" "SKIP"
        log "⏭️ Security audit: SKIPPED (no security scanner available)"
        return 0
    fi
}

check_build_success() {
    log "🔍 Checking build process..."

    if command -v npm >/dev/null 2>&1 && [[ -f "$PROJECT_ROOT/package.json" ]]; then
        if cd "$PROJECT_ROOT" && npm run build --silent >/dev/null 2>&1; then
            add_gate_result "build" "PASS"
            log "✅ Build: PASSED"
            return 0
        else
            add_gate_result "build" "FAIL"
            log "❌ Build: FAILED"
            return 1
        fi
    elif command -v python >/dev/null 2>&1 && [[ -f "$PROJECT_ROOT/setup.py" ]]; then
        if cd "$PROJECT_ROOT" && python setup.py build >/dev/null 2>&1; then
            add_gate_result "build" "PASS"
            log "✅ Python build: PASSED"
            return 0
        else
            add_gate_result "build" "FAIL"
            log "❌ Python build: FAILED"
            return 1
        fi
    elif command -v cargo >/dev/null 2>&1 && [[ -f "$PROJECT_ROOT/Cargo.toml" ]]; then
        if cd "$PROJECT_ROOT" && cargo build >/dev/null 2>&1; then
            add_gate_result "build" "PASS"
            log "✅ Rust build: PASSED"
            return 0
        else
            add_gate_result "build" "FAIL"
            log "❌ Rust build: FAILED"
            return 1
        fi
    elif command -v go >/dev/null 2>&1 && [[ -f "$PROJECT_ROOT/go.mod" ]]; then
        if cd "$PROJECT_ROOT" && go build ./... >/dev/null 2>&1; then
            add_gate_result "build" "PASS"
            log "✅ Go build: PASSED"
            return 0
        else
            add_gate_result "build" "FAIL"
            log "❌ Go build: FAILED"
            return 1
        fi
    else
        add_gate_result "build" "SKIP"
        log "⏭️ Build: SKIPPED (no build system detected)"
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
        add_gate_result "documentation" "PASS"
        log "✅ Documentation: PASSED"
        return 0
    else
        add_gate_result "documentation" "FAIL"
        log "❌ Documentation: FAILED (missing: ${missing_docs[*]})"
        return 1
    fi
}

# Calculate overall score (compatible with Bash 3.2)
calculate_score() {
    local passed=0
    local total=0
    local i

    for i in "${!GATE_RESULTS[@]}"; do
        case "${GATE_RESULTS[$i]}" in
            "PASS")
                passed=$((passed + 1))
                total=$((total + 1))
                ;;
            "FAIL")
                total=$((total + 1))
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

    echo -e "\\n📋 ${status_color}Quality Gate Report${NC}"
    echo "=================================="
    echo -e "Platform: $PLATFORM | Bash: $BASH_MAJOR_VERSION.x"
    echo -e "Status: $status_icon Overall Score: $OVERALL_SCORE/100"
    echo ""

    # Display results using array iteration
    local gate_order=("linting" "typecheck" "coverage" "security" "build" "documentation")
    local gate

    for gate in "${gate_order[@]}"; do
        local result
        result=$(get_gate_result "$gate")
        if [[ "$result" != "UNKNOWN" ]]; then
            case "$result" in
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
    log "🚀 Starting CC-Scrum Quality Gate Check v$SCRIPT_VERSION on $PLATFORM"

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
        echo "CC-Scrum Universal Quality Gate Checker v$SCRIPT_VERSION"
        echo ""
        echo "Usage: $0 [options]"
        echo ""
        echo "Options:"
        echo "  --help, -h     Show this help message"
        echo "  --quiet, -q    Quiet mode (minimal output)"
        echo "  --verbose, -v  Verbose mode (detailed output)"
        echo ""
        echo "Platform Support:"
        echo "  🍎 macOS (Bash 3.2+)"
        echo "  🐧 Linux (Bash 4+)"
        echo "  🪟 Windows (Git Bash/WSL)"
        echo ""
        echo "Quality Gates:"
        echo "  ✅ Code Linting (language-specific)"
        echo "  ✅ Type Checking (TypeScript/Python)"
        echo "  ✅ Test Coverage (with threshold)"
        echo "  ✅ Security Audit (dependency scanning)"
        echo "  ✅ Build Process (compilation/bundling)"
        echo "  ✅ Documentation (required files)"
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