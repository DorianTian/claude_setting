---
name: wiki
description: "LLM Wiki — Karpathy-pattern knowledge base with parallel research, thesis-driven investigation, cross-domain synthesis, and artifact generation. Commands: init/ingest/query/research/thesis/compile/output/lint/plan. Triggers: wiki, 知识库, knowledge base, ingest this, 收录, 查知识库, research, 调研, thesis, lint wiki, compile wiki"
user-invocable: true
---

# LLM Wiki — Persistent Compounding Knowledge Base

A schema-driven, LLM-maintained knowledge base that compounds over time. Based on Karpathy's LLM Wiki pattern, extended with parallel research, thesis-driven investigation, cross-domain synthesis, and artifact generation.

## Command

`/wiki [subcommand] [args]`

Parse `$ARGUMENTS` to determine action:

### Smart routing (no subcommand needed)

If the first argument is NOT a known subcommand, auto-detect and route:

| Input | Detection | Action |
|-------|-----------|--------|
| File path (`.md`, `.pdf`, `.txt`, etc.) | Path exists on disk | → **ingest** the file |
| Image path (`.png`, `.jpg`, `.jpeg`, `.webp`) | Path exists on disk | → **ingest**: Read image, extract knowledge, create wiki articles |
| URL (`http://` or `https://`) | Starts with protocol | → **ingest** from URL |
| Quoted text or multi-line | Not a path, not a URL, not a subcommand | → **ingest** as inline text |
| Question (contains `?` or starts with interrogative) | Natural language question | → **query** |
| No arguments | Empty | → Show available commands |

Examples:
```
/wiki ~/Downloads/paper.pdf                    # auto-ingest file
/wiki /tmp/screenshot.png                      # auto-ingest screenshot
/wiki https://blog.example.com/article         # auto-ingest URL
/wiki "Transformer 的 attention 机制"           # auto-ingest text
/wiki Flink checkpoint 怎么排查?                # auto-query (has ?)
/wiki                                          # show help
```

### Explicit subcommands

| Command | Usage | Description |
|---------|-------|-------------|
| `init` | `/wiki init [path]` | Bootstrap a new wiki at given path |
| `ingest` | `/wiki ingest <file\|URL\|text>` | Process source into wiki pages |
| `query` | `/wiki query <question>` | Search wiki and synthesize answer |
| `research` | `/wiki research <topic>` | Parallel multi-agent deep investigation |
| `thesis` | `/wiki thesis <claim>` | Evidence-based claim evaluation |
| `compile` | `/wiki compile [category]` | Recompile wiki pages from raw sources |
| `output` | `/wiki output <format> <topic>` | Generate artifact (report/slides/table) |
| `lint` | `/wiki lint [--fix]` | Health check, optionally auto-repair |
| `plan` | `/wiki plan <topic>` | Wiki-grounded implementation planning |

---

## Configuration

On every invocation, read `schema.md` from the wiki root to load configuration. If no schema.md exists, prompt user to run `/wiki init`.

**Schema provides:** wiki root path, raw root path, category taxonomy, article template, naming conventions, quality thresholds.

**Defaults (if schema.md not found):**
- Wiki root: `~/Knowledge/`
- Raw root: `~/Knowledge-raw/`

---

## Init

`/wiki init [path]`

Bootstrap a new wiki or retrofit an existing directory.

### Flow

1. If `path` provided, use it as wiki root. Otherwise use `~/Knowledge/`.
2. Scan directory for existing content. If articles exist, enter **retrofit mode** (preserve everything, add infrastructure).
3. Create if missing:
   - `schema.md` — generate from directory scan (detect existing categories, naming patterns)
   - `index.md` — scan all `.md` files, build catalog with one-line summaries
   - `log.md` — initialize with `## [YYYY-MM-DD] init | Wiki initialized`
   - `output/` directory for generated artifacts
4. Create raw root if missing (default `~/Knowledge-raw/` with `papers/`, `articles/`, `clippings/`, `assets/` subdirs)
5. Report: how many existing articles found, categories detected, index entries created.

---

## Ingest

`/wiki ingest <source>`

Process a raw source into the wiki. This is the core operation — a single ingest can touch 5-15 wiki pages.

`<source>` can be: file path, URL, or inline text (quoted).

### Flow

1. **Acquire source:**
   - File: copy to `{raw_root}/` under appropriate subdir (papers/, articles/, clippings/). Preserve original filename.
   - URL: fetch content via WebFetch, save as markdown to `{raw_root}/articles/{slug}.md`.
   - Text: save to `{raw_root}/clippings/{date}-{slug}.md`.

2. **Read and understand:**
   - Read the full source document.
   - Extract: key concepts, entities, claims, relationships, domain classification.
   - Map to existing wiki categories (read schema.md for taxonomy).

3. **Discuss with user (brief):**
   - Surface 3-5 key takeaways in 1-2 sentences each.
   - Ask: "Any emphasis or angle to prioritize?" (wait for response, or proceed if user says nothing / says "go ahead")

4. **Integrate into wiki:**
   - Read `index.md` to identify existing related articles.
   - For each related article, Read it and determine what needs updating.
   - **Update existing articles:** Add new information, strengthen or challenge existing claims, add cross-references. Mark contradictions explicitly with `> ⚠️ Contradiction:` blockquotes.
   - **Create new articles:** For concepts/entities that deserve their own page but don't have one. Use the article template from schema.md.
   - Every article must have YAML frontmatter (see Article Format below).

5. **Backlink audit:**
   - After all writes, scan updated/created articles for concepts that match other article titles.
   - Add `[[wiki-link]]` cross-references where missing.
   - Ensure bidirectional: if A links to B, B should link to A.

6. **Update infrastructure:**
   - Update `index.md` — add new entries, update summaries for modified articles.
   - Append to `log.md`: `## [YYYY-MM-DD] ingest | {source_title}` with list of pages touched.

7. **Report:**
   - New articles created (with paths)
   - Existing articles updated (with what changed)
   - Contradictions found (if any)
   - New cross-references added

### Quality bar
- Do NOT just summarize the source into one page. The goal is **knowledge integration** — update every relevant existing article.
- A 5-page research paper should touch at minimum 5 wiki pages.
- Every factual claim in a wiki article must be traceable to a source in raw/.

---

## Query

`/wiki query <question>`

Search the wiki and synthesize an answer grounded in wiki content.

### Flow

1. Read `index.md` to identify candidate articles (keyword + category matching).
2. Read candidate articles (typically 3-8 depending on query scope).
3. Synthesize answer with **explicit citations**: `[source: article-name.md]` for every claim.
4. **Multi-hop reasoning:** If answering requires combining knowledge from multiple articles, explicitly show the reasoning chain: "From A we know X, from B we know Y, combining: Z."
5. **Confidence-aware:** If cited articles have low confidence scores in frontmatter, note this.
6. **Gap detection:** If the question can't be fully answered from the wiki, say what's missing and suggest sources to ingest.

### Save back
If the synthesized answer is substantive (comparison, analysis, novel synthesis), offer to save it as a new wiki article. If user agrees, create article and update index.

### Append to log
`## [YYYY-MM-DD] query | {question_summary}` — note which articles were consulted.

---

## Research

`/wiki research <topic> [--depth quick|standard|deep]`

Parallel multi-agent investigation on a topic. Generates a comprehensive research report and ingests findings into the wiki.

### Flow

1. **Scope:** Read existing wiki articles on this topic to understand current knowledge state.

2. **Generate research questions:** Based on gaps in current wiki coverage, generate 4-6 specific research questions covering different angles.

3. **Dispatch parallel agents:**
   - `quick`: 3 agents (Sonnet), surface-level web search
   - `standard` (default): 5 agents (Opus), each with a specific research question + web search
   - `deep`: 5 agents (Opus), multi-round investigation per agent

   Each agent prompt:
   - The specific research question assigned
   - Current wiki context (relevant article summaries)
   - Instruction: return structured findings with sources, confidence, and key claims

4. **Synthesize:**
   - Collect all agent results
   - Deduplicate and cross-validate findings
   - Identify consensus vs disagreements between agents
   - Write research report to `{wiki_root}/output/research-{topic}-{date}.md`

5. **Ingest findings:**
   - Save raw agent outputs to `{raw_root}/clippings/research-{topic}-{date}/`
   - Run ingest flow on the synthesized report (updates wiki pages, creates new ones)

6. **Report to user:**
   - Key findings summary
   - Articles created/updated
   - Open questions that need further investigation

---

## Thesis

`/wiki thesis <claim>`

Evidence-based claim evaluation. Tests a specific claim against wiki knowledge and external evidence.

### Flow

1. **Parse claim:** Extract the testable assertion.

2. **Wiki evidence:** Read `index.md`, find all relevant articles. Extract evidence for and against the claim.

3. **Dispatch balanced agents (Opus):**
   - **Pro agent:** Find the strongest evidence supporting the claim. Search wiki + web.
   - **Con agent:** Find the strongest evidence against the claim. Search wiki + web.
   - **Context agent:** Find related claims, edge cases, conditions under which the claim holds or fails.

4. **Evaluate:**
   - List evidence for/against in structured table
   - Rate overall confidence: `strong support` / `likely true` / `uncertain` / `likely false` / `strong refutation`
   - Identify **missing evidence** — what data would be needed to settle this definitively
   - Note conditions/scope: "True for X but not Y"

5. **Write verdict:** Save to `{wiki_root}/output/thesis-{slug}-{date}.md`

6. **Update wiki:** If the evaluation reveals new information, update relevant articles. If the claim is well-supported, integrate it as established knowledge.

---

## Compile

`/wiki compile [category]`

Recompile wiki pages from raw sources. Useful when schema changes, quality bar rises, or articles have drifted from sources.

### Flow

1. If `category` specified, scope to that category only. Otherwise compile entire wiki.
2. For each article in scope:
   - Read the article's frontmatter to find linked sources in raw/
   - Re-read those raw sources
   - Compare current article content against source material
   - Rewrite article with improved structure, accuracy, and cross-references
   - Preserve manually-added notes (marked with `<!-- manual -->` comments)
3. Run full backlink audit after compilation.
4. Update index.md with refreshed summaries.
5. Log: `## [YYYY-MM-DD] compile | {scope_description}`

---

## Output

`/wiki output <format> <topic>`

Generate artifacts from wiki knowledge.

### Formats

| Format | Description | File |
|--------|-------------|------|
| `report` | Long-form analysis document | `output/report-{topic}-{date}.md` |
| `slides` | Marp-format slide deck | `output/slides-{topic}-{date}.md` |
| `table` | Comparison/summary table | `output/table-{topic}-{date}.md` |
| `timeline` | Chronological event sequence | `output/timeline-{topic}-{date}.md` |
| `glossary` | Term definitions from wiki | `output/glossary-{topic}-{date}.md` |

### Flow

1. Read relevant wiki articles for the topic.
2. Generate artifact in requested format, with citations to wiki articles.
3. Save to `{wiki_root}/output/`.
4. Log: `## [YYYY-MM-DD] output | {format}: {topic}`

---

## Lint

`/wiki lint [--fix] [--category <cat>]`

Health check the wiki. Detects issues and optionally auto-repairs.

### Checks (priority-ordered)

1. **Contradictions:** Scan for conflicting claims across articles. Report with exact quotes from both sides.
2. **Stale content:** Articles where `last_updated` is old and newer sources exist in raw/.
3. **Orphan pages:** Articles with zero inbound `[[wiki-links]]` from other articles.
4. **Missing pages:** `[[wiki-links]]` that point to non-existent articles.
5. **Broken cross-references:** Links to articles that have been renamed/moved.
6. **Low confidence:** Articles with `confidence: low` that haven't been verified.
7. **Missing sources:** Articles with no `sources:` in frontmatter (ungrounded claims).
8. **Oversized pages:** Articles exceeding 500 lines (should be split).
9. **Index drift:** Articles that exist but aren't in index.md, or index entries for deleted articles.

### Output

For each issue:
```
[P1] Contradiction: {article-a.md} claims X, {article-b.md} claims Y
  → Fix: Read raw sources to determine which is correct, update the wrong article

[P2] Orphan: {article.md} has 0 inbound links
  → Fix: Add link from {related-article.md} section "Related Concepts"
```

### With `--fix`

Auto-repair issues P2 and below (orphans, missing links, index drift, broken refs). P1 (contradictions) always requires user review.

### Log

`## [YYYY-MM-DD] lint | {n} issues found, {m} fixed`

---

## Plan

`/wiki plan <topic>`

Generate an implementation plan grounded in wiki knowledge. Useful for technical decisions where the wiki has relevant context.

### Flow

1. Read relevant wiki articles for the topic.
2. Identify constraints, prior decisions, and known trade-offs from wiki.
3. Generate structured plan:
   - Context (from wiki)
   - Options with trade-offs (cite wiki articles)
   - Recommendation
   - Action items
4. Save to `{wiki_root}/output/plan-{topic}-{date}.md`.
5. Offer to create tracking items if user wants.

---

## Article Format

Every wiki article uses this structure:

```markdown
---
title: "Article Title"
category: "01-AI"
tags: [transformer, attention, architecture]
confidence: high|medium|low
sources:
  - raw/papers/attention-is-all-you-need.pdf
  - raw/articles/transformer-explained.md
created: 2026-04-15
last_updated: 2026-04-15
---

# Article Title

Brief overview paragraph.

## Key Concepts

Content...

## Details

Content with [[cross-references]] to other articles...

## Sources

- [Attention Is All You Need](raw/papers/attention-is-all-you-need.pdf) — original paper
- [Transformer Explained](raw/articles/transformer-explained.md) — blog post
```

### Frontmatter fields

| Field | Required | Description |
|-------|----------|-------------|
| `title` | yes | Article title |
| `category` | yes | Directory/category this article belongs to |
| `tags` | yes | Array of topic tags for search |
| `confidence` | yes | `high` (verified from multiple sources), `medium` (single source or partially verified), `low` (unverified or uncertain) |
| `sources` | yes | Array of paths to raw source files |
| `created` | yes | ISO date |
| `last_updated` | yes | ISO date, updated on every edit |

---

## Cross-References

Use `[[article-name]]` wiki-link syntax. Rules:

- Link on first mention of a concept that has its own article.
- Always bidirectional: if A links to B, B must link to A.
- After any write operation, run a quick backlink scan on touched articles.

---

## Index and Log

### index.md

Content catalog. One entry per article, grouped by category:

```markdown
# Knowledge Base Index

## 01-AI
- [Transformer Architecture](01-AI/transformer-architecture.md) — Self-attention mechanism, encoder-decoder structure, positional encoding
- [RLHF Training](01-AI/rlhf-training.md) — Reward model training, PPO optimization, DPO alternative

## 02-Frontend
...
```

Updated on every ingest/compile/lint operation.

### log.md

Append-only. Parseable format:

```markdown
## [2026-04-15] ingest | Attention Is All You Need
- Created: 01-AI/transformer-architecture.md
- Updated: 01-AI/neural-network-fundamentals.md (added transformer section)
- Updated: 05-Architecture/encoder-decoder-patterns.md (cross-reference)
- Backlinks added: 3

## [2026-04-15] query | "How does RLHF compare to DPO?"
- Consulted: 01-AI/rlhf-training.md, 01-AI/dpo-direct-preference.md
- Saved as: 01-AI/rlhf-vs-dpo-comparison.md
```

---

## Quality Standards

### Ingest quality
- A source document should touch a minimum of 3 wiki pages (integration, not isolation).
- Every claim must be traceable to a raw source.
- Contradictions between sources must be explicitly flagged, not silently overwritten.

### Article quality
- No article should just be a summary of one source. Articles synthesize across multiple sources.
- Cross-references should be meaningful (not just "see also" dumps).
- Confidence ratings must be honest — `high` only when verified from 2+ independent sources.

### Research quality
- Parallel agents must have distinct, non-overlapping research questions.
- Synthesis must identify consensus and disagreements, not just concatenate findings.
- Raw agent outputs always saved to raw/ for traceability.

---

## Tool Usage

This skill uses the following tools:
- **Read/Write/Edit/Glob/Grep** — wiki file operations
- **Agent** — parallel research and thesis agents (use `model: "opus"` for research/thesis, `model: "sonnet"` for quick scans)
- **WebSearch/WebFetch** — external research in research/thesis/ingest(URL) operations
- **Skill** — invoke `/deep-doc` when ingest source is complex enough to warrant a full deep-dive article
