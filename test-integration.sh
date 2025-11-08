#!/bin/bash
# test-integration.sh - Noctalia Shell Integration Tests
# Tests QML syntax, service files, and shell startup after upstream integration

echo "🧪 Noctalia Shell Integration Tests"
echo "===================================="

# Track failures
FAILURES=0

# Test 1: QML Syntax Check - Main Files
echo ""
echo "1️⃣  QML Syntax Check - Main Files..."
if qmllint shell.qml >/dev/null 2>&1; then
    echo "  ✅ shell.qml"
else
    echo "  ❌ shell.qml - SYNTAX ERROR"
    qmllint shell.qml
    ((FAILURES++))
fi

# Test 2: Service Files Check
echo ""
echo "2️⃣  Service Files Check..."
SERVICE_ERRORS=0
for svc in Services/*.qml; do
    if ! qmllint "$svc" >/dev/null 2>&1; then
        echo "  ❌ $svc"
        qmllint "$svc" 2>&1 | head -3
        ((SERVICE_ERRORS++))
    fi
done
if [ $SERVICE_ERRORS -eq 0 ]; then
    echo "  ✅ All $(ls Services/*.qml | wc -l) service files pass"
else
    echo "  ❌ $SERVICE_ERRORS service file(s) have errors"
    ((FAILURES++))
fi

# Test 3: Widget Files Check
echo ""
echo "3️⃣  Widget Files Check..."
WIDGET_ERRORS=0
for widget in Widgets/*.qml; do
    if ! qmllint "$widget" >/dev/null 2>&1; then
        echo "  ❌ $widget"
        qmllint "$widget" 2>&1 | head -3
        ((WIDGET_ERRORS++))
    fi
done
if [ $WIDGET_ERRORS -eq 0 ]; then
    echo "  ✅ All $(ls Widgets/*.qml | wc -l) widget files pass"
else
    echo "  ❌ $WIDGET_ERRORS widget file(s) have errors"
    ((FAILURES++))
fi

# Test 4: Fork-Specific Services Exist
echo ""
echo "4️⃣  Fork-Specific Services Exist..."
FORK_SERVICES=("SessionService" "AppSearchService" "IdleService")
for svc in "${FORK_SERVICES[@]}"; do
    if [ -f "Services/${svc}.qml" ]; then
        echo "  ✅ ${svc}"
    else
        echo "  ❌ ${svc} MISSING"
        ((FAILURES++))
    fi
done

# Test 5: Fork-Specific Modules Exist
echo ""
echo "5️⃣  Fork-Specific Modules Exist..."
FORK_MODULES=("Modules/Spotlight" "Modules/Bar/AppMenu")
for mod in "${FORK_MODULES[@]}"; do
    if [ -d "$mod" ]; then
        echo "  ✅ ${mod}/"
    else
        echo "  ❌ ${mod}/ MISSING"
        ((FAILURES++))
    fi
done

# Test 6: Check for Conflict Markers
echo ""
echo "6️⃣  Check for Leftover Conflict Markers..."
CONFLICT_FILES=$(git diff --name-only upstream/main 2>/dev/null | xargs grep -l "<<<<<<< HEAD" 2>/dev/null)
if [ -z "$CONFLICT_FILES" ]; then
    echo "  ✅ No conflict markers found"
else
    echo "  ❌ Conflict markers still present in:"
    echo "$CONFLICT_FILES" | sed 's/^/     /'
    ((FAILURES++))
fi

# Test 7: Shell Startup Test
echo ""
echo "7️⃣  Shell Startup Test (10 second timeout)..."
if timeout 10 qs -p . >/tmp/startup-test.log 2>&1; then
    # Timeout is expected - shell runs continuously
    echo "  ⚠️  Shell timed out (normal behavior)"
else
    EXIT_CODE=$?
    if [ $EXIT_CODE -eq 124 ]; then
        # Timeout exit code - this is expected and good
        echo "  ✅ Shell started successfully (timed out after 10s)"
    else
        echo "  ❌ Shell crashed or failed to start (exit code: $EXIT_CODE)"
        ((FAILURES++))
    fi
fi

# Check for runtime errors in startup log
if grep -q "TypeError\|ReferenceError\|SyntaxError" /tmp/startup-test.log; then
    echo "  ❌ Runtime errors detected:"
    grep -E "TypeError|ReferenceError|SyntaxError" /tmp/startup-test.log | head -5
    ((FAILURES++))
else
    echo "  ✅ No runtime errors detected"
fi

# Test 8: Service Initialization Check
echo ""
echo "8️⃣  Service Initialization Check..."
REQUIRED_SERVICES=("WallpaperService" "CompositorService" "AppThemeService")
for svc in "${REQUIRED_SERVICES[@]}"; do
    if grep -q "$svc" /tmp/startup-test.log; then
        echo "  ✅ ${svc} initialized"
    else
        echo "  ⚠️  ${svc} not found in logs"
    fi
done

# Summary
echo ""
echo "===================================="
if [ $FAILURES -eq 0 ]; then
    echo "✅ All integration tests passed!"
    echo ""
    echo "Next steps:"
    echo "  1. Test fork-specific features manually"
    echo "  2. Test on actual Wayland compositor"
    echo "  3. Push to origin if all looks good"
    exit 0
else
    echo "❌ $FAILURES test(s) failed"
    echo ""
    echo "Review the errors above and fix before pushing"
    echo "Startup log saved to: /tmp/startup-test.log"
    exit 1
fi
