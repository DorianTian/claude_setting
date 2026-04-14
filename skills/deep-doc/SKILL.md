---
name: deep-doc
description: "Generate deep technical analysis documents. Trigger when user asks to: write/create/generate a technical document, 写文档, 总结, 技术总结, 深度解析, 源码分析, 原理分析, 深入分析, 知识整理, 学习笔记, 写一篇, 技术文档, 梳理一下XX, 帮我整理, deep dive, technical analysis, write a doc about."
user-invocable: true
---

# Deep Technical Document Generator

Generate a comprehensive deep-dive technical document on the given topic.

## Topic

$ARGUMENTS

## Pre-flight

1. **Parse arguments**: Extract the topic and optional `--output` path. Default output: `/Users/tianqiyin/Documents/<topic>深度解析.md`
2. **Check existing docs**: Search `/Users/tianqiyin/Documents/` for existing documents on this topic. If found, inform the user and ask whether to overwrite or supplement.
3. **Scope confirmation**: Before writing, briefly confirm with the user:
   - The scope and depth level (source-code level / architecture level / engineering practice level)
   - Any specific sub-topics to focus on or skip
   - Target audience assumption (default: senior frontend engineer with 5+ years experience)

## Document Standards

文档必须 **学术深度与工程实践并重**，不能停留在概念科普层面。

### Core Principles
1. **深度优先**：每个技术点必须追溯到底层实现原理（源码级、算法级、数据结构级），不接受"黑箱式"描述
2. **原理驱动**：每个论点必须提供论据（为什么这样设计）、底层实现（源码怎么做的）、代码示例（可运行片段）
3. **生产导向**：每个知识点都要回答"在真实项目中怎么用、会遇到什么问题"
4. **全面性**：覆盖 设计动机 → 底层原理 → 实现细节 → 生产实践 → 局限与坑点 完整链路

### Depth Requirements
- Every technical point must trace back to **underlying implementation** (source code, algorithms, data structures)
- No "black-box" descriptions — explain HOW things work, not just WHAT they do
- Include **time/space complexity analysis** where applicable
- Reference **source code paths** (e.g., `react-reconciler/src/ReactFiberBeginWork.js`)

### For Each Knowledge Point, Follow This Chain

```
Thesis (What & Why)
  → Underlying Principle (How - source code / algorithm level)
  → Evidence & Trade-offs (Why this approach over alternatives)
  → Code Example (runnable, with key lines annotated)
  → Production Application (real-world usage, config, tuning)
  → Limitations (when NOT to use, performance boundaries)
  → Pitfalls (production issues with root cause + solution)
```

### 论证链路（每个知识点必须完成的链条）

```
论点（What & Why）
  │  这个东西是什么？为什么需要它？解决什么问题？
  ▼
底层原理（How - 学术/源码层面）
  │  核心算法、数据结构、设计模式
  │  源码关键路径（如 React Fiber 树的 beginWork → completeWork）
  │  时间/空间复杂度分析（如适用）
  ▼
论据与权衡（Why this way）
  │  为什么选择这个方案而非其他？
  │  设计权衡（trade-off）是什么？
  ▼
代码示例（Proof）
  │  可运行的代码片段，验证原理。标注关键行的作用
  ▼
生产应用（Real-world）
  │  在实际项目中如何落地。配置、调优、最佳实践
  ▼
缺陷与局限（Limitations）
  │  不适合什么场景？性能瓶颈在哪？
  ▼
坑点（Pitfalls）
    生产上实际遇到的问题，附带根因分析和解决方案
```

### Document Structure

```
# Title

> **Scope**: one-line description of depth level
> **Conventions**: language/version constraints

## Table of Contents

## 一、Background & Motivation
## 二、Core Principles & Implementation
## 三 ~ N-3、Deep-dive Topics
## N-2、Comparison Analysis (if applicable)
## N-1、Production Pitfalls & Best Practices
## N、Interview Quick Answers (if applicable)
```

### Formatting Rules
- Major sections: Chinese ordinals (一二三四五...)
- Subtitles with `——` separator (e.g., `## 三、Inverted Index——The Soul of ES`)
- Comparisons in tables, flows in ASCII art
- Code blocks with language tags (```typescript / ```go / ```sql)
- Key terms **bold**, definitions in `> blockquote`
- Source references with file paths (e.g., `react-reconciler/src/ReactFiberBeginWork.js`)

## Writing Process

1. **Research phase**: Use WebSearch and WebFetch to gather authoritative sources (official docs, RFCs, source code repos, academic papers). Do NOT fabricate information.
2. **Outline phase**: Draft the table of contents and confirm structure with user before writing full content.
3. **Writing phase**: Write section by section. For each section:
   - Start with the core thesis
   - Dive into underlying implementation
   - Provide runnable code examples
   - Connect to production scenarios
   - Note pitfalls and limitations
4. **Review phase**: After completion, self-check:
   - [ ] Every principle has source-level explanation
   - [ ] Every principle has code examples
   - [ ] Production pitfalls section is substantive (not generic)
   - [ ] No black-box descriptions remain
   - [ ] Comparisons are multi-dimensional (not just "A is better")
   - [ ] ASCII architecture diagrams are accurate

## Quality Bar

- Target: a document that a **senior engineer** would find genuinely useful for deepening understanding, not a beginner tutorial
- Depth: equivalent to a well-written technical blog post on a top engineering blog (like Meta Engineering, Netflix Tech Blog)
- Accuracy: every claim must be verifiable. If unsure, mark with "[needs verification]" rather than guessing
- Length: as long as needed to cover the topic thoroughly. Typically 500-2000 lines for a major topic.
