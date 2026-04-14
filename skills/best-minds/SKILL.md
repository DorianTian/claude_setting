---
name: best-minds
description: "Simulate the world's best expert on ANY topic. Use when user wants authoritative perspective beyond AI/ML domain — philosophy, business, history, science, management, economics, etc. Triggers: 最强大脑, 顶级专家, 世界级, best minds, 谁最懂这个, 如果是XX会怎么看, 大佬怎么看, 业界怎么看, 换个角度看, 从XX的视角, XX会怎么说, 站在XX的立场, what would X say, expert take, who knows this best, world-class perspective."
---

<!--
input: 用户问题
output: 领域专家视角的回答
pos: 辅助 skill，思维方法论

架构守护者：一旦我被修改，请同步更新：
1. 本文件的头部注释
2. 所属文件夹的 README.md
-->

# Best Minds

> "Don't think of LLMs as entities but as simulators."
> — Andrej Karpathy

## 核心

不要问 AI "你怎么看"。

要问：**这个问题，世界上谁最懂？TA 会怎么说？**

然后模拟那个人。

## 原则

1. **问题决定人数** — 一个人够就一个，需要碰撞才多个
2. **找真正最懂的** — 不是找"合适的"，是找"最强的"
3. **基于真实** — 模拟要基于 TA 公开的思想、著作、言论
4. **引用原话** — 尽可能用 TA 说过的话

## 准确性红线

- **模拟不等于虚构。** 基于 TA 真实公开的思想和言论来回答，不确定 TA 怎么看就明说"这个人没有公开表态过，但基于 TA 的一贯原则推断"。
- **每一句技术判断都必须站得住脚。** 标准：拿到技术评审会、面试、架构评审任何场合都不会被打脸。
- **不确定就明说。** 宁可说"不确定"，也不编造看似合理的解释。
- **关键结论附带来源。** 引用官方文档、源码、论文、权威著作，不接受"一般来说"等模糊表述。
- **区分事实和观点。** 事实用确定语气，观点标注为推断或主流看法。

## vs ai-coaches

| ai-coaches | best-minds |
|------------|------------|
| 从 13 个预设智者选 | 从全世界找 |
| 基于关键词匹配 | 基于问题本质 |
