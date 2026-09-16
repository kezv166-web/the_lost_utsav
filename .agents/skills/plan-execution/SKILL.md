---
name: plan-execution
description: >-
  Write and execute implementation plans with bite-sized tasks (2-5 min each).
  Enforces TDD cycle per task, checkpoint tracking, and review gates.
  Keywords: plan, execute, phase, task, implement, checkpoint, progress.
version: 1.0.0
---

# Plan Execution

Write comprehensive implementation plans, then execute them systematically.

**Core principle:** Plans so detailed that an engineer with zero codebase context can follow them perfectly.

## Part 1: Writing Plans

### Scope Check

If the spec covers multiple independent subsystems, break into separate plans — one per subsystem. Each plan should produce working, testable software on its own.

### File Structure First

Before defining tasks, map out which files will be created or modified:

```markdown
## File Map
- CREATE: src/services/order-service.py — Order business logic
- CREATE: tests/test_order_service.py — Order service tests
- MODIFY: src/models/order.py:45-60 — Add status field
- MODIFY: src/routes/api.py:120 — Register new endpoint
```

**Design for isolation:**
- Each file has one clear responsibility
- Well-defined interfaces between units
- Prefer smaller, focused files over large ones
- Files that change together should live together

### Bite-Sized Task Format

**Each task is one action (2-5 minutes):**

```markdown
### Task N: [Component Name]

**Files:**
- Create: `exact/path/to/file.py`
- Modify: `exact/path/to/existing.py:123-145`
- Test: `tests/exact/path/to/test.py`

- [ ] **Step 1: Write the failing test**

    ```python
    def test_specific_behavior():
        result = function(input)
        assert result == expected
    ```

- [ ] **Step 2: Run test — verify it fails**

    Run: `pytest tests/path/test.py::test_name -v`
    Expected: FAIL — "function not defined"

- [ ] **Step 3: Write minimal implementation**

    ```python
    def function(input):
        return expected
    ```

- [ ] **Step 4: Run test — verify it passes**

    Run: `pytest tests/path/test.py -v`
    Expected: PASS

- [ ] **Step 5: Commit**

    ```bash
    git add tests/path/test.py src/path/file.py
    git commit -m "feat: add specific feature"
    ```
```

### Plan Document Header

Every plan MUST start with:

```markdown
# [Feature Name] Implementation Plan

**Goal:** [One sentence]
**Architecture:** [2-3 sentences about approach]
**Tech Stack:** [Key technologies]

---
```

### Remember
- Exact file paths always
- Complete code in plan (not "add validation")
- Exact commands with expected output
- DRY, YAGNI, TDD, frequent commits

### Plan Review Loop

After writing the plan:
1. Review critically — any questions or concerns?
2. If issues found → fix → re-review
3. If 3+ review iterations → escalate to human
4. Once approved → proceed to execution

## Part 2: Executing Plans

### Execution Protocol

For each task:

```
1. Mark as in_progress
2. Follow each step exactly
3. Run verifications as specified
4. Use skills/verification before marking done
5. Mark as completed
```

### Progress Tracking

**After each task:**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ DONE: [Task name]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📝 Changes:
   - [What was implemented]

📁 Files:
   + src/services/order.py (new)
   ~ src/models/order.py (modified)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 Progress: ████████░░ 80% (4/5 tasks)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

→ Continue to task 5? (y/adjust/stop)
```

**After each phase:**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎉 PHASE COMPLETE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ Tasks: 5/5 complete
✅ Tests: All passing
📁 Files: 12 created, 3 modified

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 Overall: ██░░░░░░░░ 17% (1/6 phases)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Execution Handoff

After plan is written, offer execution choice:

1. **Subagent-Driven** (recommended) — Fresh subagent per task, automatic review between tasks → use `skills/subagent-orchestration`
2. **Inline Execution** — Execute in current session with manual checkpoints

### When to Stop and Ask

**STOP immediately when:**
- Hit a blocker (missing dependency, unclear instruction)
- Test fails repeatedly after 3 attempts
- Plan has critical gaps
- You don't understand an instruction

**Ask for clarification rather than guessing.**

### Auto-Test After Each Task

```
Code complete
     │
     ▼
Run related tests
     │
     ├── PASS → Report success, continue
     └── FAIL → Fix Loop (max 3 attempts)
                    │
                    ├── PASS → Continue
                    └── 3x FAIL → Escalate to human
```

## Red Flags

- Starting to code without a plan
- Skipping verification steps
- "Just this once" skipping TDD
- Proceeding when blocked instead of asking
- Not committing after each green test

## Integration

**Auto-triggered by:**
- `/plan` workflow (writing phase)
- `/code` workflow (execution phase)

**Works with:**
- `skills/tdd` — each task follows RED-GREEN-REFACTOR
- `skills/verification` — verify before marking complete
- `skills/code-review` — review between tasks
- `skills/subagent-orchestration` — alternative execution mode
