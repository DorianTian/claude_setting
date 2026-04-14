---
name: adversarial-validation
description: "Triple-perspective validation for critical code changes. Implementer presents, Critic attacks, Judge resolves. Use when validating architecture decisions, security-sensitive code, complex algorithms, or any change where single-reviewer blind spots are a risk. Trigger words: adversarial review, triple check, stress test this, 压力测试, 对抗验证, 仔细检查一下"
---

# Adversarial Validation

> 三角验证模式：从三个对立视角审查代码/设计，消除单一视角盲区。

## When to Use

- Security-sensitive code changes (auth, permissions, data access)
- Architecture decisions with long-term implications
- Complex algorithms or data processing logic
- API contract changes affecting multiple consumers
- Database schema changes in production
- 当 Dorian 说"仔细检查"、"triple check"、"adversarial review"、"压力测试这个" 时

## The Three Roles

### Role 1: Implementer (Presenter)

Present the implementation with:
- Design rationale — why this approach over alternatives
- Key assumptions made
- Known limitations or trade-offs accepted

### Role 2: Critic (Attacker)

Challenge the implementation:
- Find edge cases the implementer missed
- Identify failure modes under load / concurrent access / malicious input
- Question assumptions — what if they're wrong?
- Look for security vulnerabilities (injection, auth bypass, data leaks)
- Check for performance cliffs (O(n^2) hiding in O(n), unbounded allocations)
- Find contract violations (API promises not kept, type safety gaps)

### Role 3: Judge (Resolver)

Synthesize findings:
- Classify each Critic finding: **Critical** (must fix) / **Valid** (should fix) / **Theoretical** (acceptable risk)
- For each Critical/Valid finding, provide a specific fix recommendation
- Final verdict: **PASS** / **PASS WITH FIXES** / **FAIL**

## Execution

使用 3 个 parallel subagents 分别扮演三个角色：

```
Agent 1 (model: sonnet) — Implementer: summarize the code/design, present rationale
Agent 2 (model: opus)   — Critic: find flaws, edge cases, security issues
Agent 3 (model: opus)   — Judge: evaluate findings, produce final verdict
```

**执行顺序**：Implementer 和 Critic 可以并行（各自独立分析代码），Judge 在两者完成后执行。

## Output Format

Judge 的 output 必须使用以下格式：

```markdown
## Adversarial Validation Report

### Verdict: PASS / PASS WITH FIXES / FAIL

### Critical Findings (must fix before merge)
1. [Finding] — [Fix recommendation]

### Valid Findings (should fix, not blocking)
1. [Finding] — [Fix recommendation]

### Theoretical Risks (accepted)
1. [Risk] — [Why acceptable]

### Confidence: X/10
```

## Integration

- 可以在 `/code-review` 之后追加调用，作为 deep validation 层
- 也可以在 `/expert-team` 给出方案后，对选定方案做 adversarial check
- **不替代** code-review，而是补充：code-review 是常规检查，adversarial-validation 是压力测试
