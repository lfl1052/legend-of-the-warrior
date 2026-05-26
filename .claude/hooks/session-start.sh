#!/bin/bash
# Claude Code Game Studios — SessionStart hook (customized for Legend of the Warrior)
# Godot 4.6 + GDScript project
echo "=== Legend of the Warrior — Session Context ==="

# Current branch
BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
if [ -n "$BRANCH" ]; then
    echo "Branch: $BRANCH"
    echo ""
    echo "Recent commits:"
    git log --oneline -5 2>/dev/null | while read -r line; do
        echo "  $line"
    done
fi

# Sprint status from YAML
if [ -f "production/sprint-status.yaml" ]; then
    echo ""
    echo "--- Sprint Status ---"
    grep -E "^(sprint:|goal:|updated:|last_action:)" production/sprint-status.yaml 2>/dev/null | while read -r line; do
        echo "  $line"
    done
    echo ""
    DONE_COUNT=$(grep -c "status: done" production/sprint-status.yaml 2>/dev/null || echo 0)
    TOTAL_COUNT=$(grep -c "\- id:" production/sprint-status.yaml 2>/dev/null || echo 0)
    echo "  Stories: ${DONE_COUNT}/${TOTAL_COUNT} done"
fi

# Code health (GDScript in scripts/)
if [ -d "scripts" ]; then
    TODO_COUNT=$(grep -r "TODO" scripts/ 2>/dev/null | wc -l)
    FIXME_COUNT=$(grep -r "FIXME" scripts/ 2>/dev/null | wc -l)
    if [ "$TODO_COUNT" -gt 0 ] || [ "$FIXME_COUNT" -gt 0 ]; then
        echo ""
        echo "Code health: ${TODO_COUNT} TODOs, ${FIXME_COUNT} FIXMEs in scripts/"
    fi
fi

# Test file count
if [ -d "tests/unit" ]; then
    TEST_COUNT=$(find tests/unit -name "test_*.gd" 2>/dev/null | wc -l)
    echo "Unit test files: ${TEST_COUNT}"
fi

# Active session state recovery
STATE_FILE="production/session-state/active.md"
if [ -f "$STATE_FILE" ]; then
    echo ""
    echo "=== ACTIVE SESSION STATE ==="
    tail -20 "$STATE_FILE" 2>/dev/null
    echo "=== END SESSION STATE ==="
fi

echo "==================================="
exit 0
