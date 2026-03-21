#!/usr/bin/env node

/**
 * AI Daily Digest - 每日技术资讯自动抓取
 *
 * 7 板块:
 *   1. AI 产品与发布 (Top 5)
 *   2. AI 工程与工具 (Top 10) ← 重点
 *   3. AI 增强生态 (Top 5) — Skills / MCP / Plugins
 *   4. Agent / RAG / LLM 应用 (Top 5)
 *   5. 开源热点 (Top 5, 近 30 天活跃)
 *   6. 前端 / 数据可视化 (Top 5)
 *   7. 值得精读的论文 (Top 5)
 *
 * Output: ~/AI-Daily/{YYYY-MM}/{YYYY-MM-DD}.md + .txt
 *
 * Usage:
 *   node ai-daily.mjs              # today
 *   node ai-daily.mjs 2026-03-21   # specific date
 *   node ai-daily.mjs --force      # re-fetch even if exists
 */

import { writeFileSync, mkdirSync, existsSync } from "fs";
import { join } from "path";
import { homedir } from "os";


const ICLOUD_BASE = join(
  homedir(),
  "Library/Mobile Documents/com~apple~CloudDocs/AI-Daily"
);
const FORCE = process.argv.includes("--force");

// ─── Keyword Sets ──────────────────────────────────────────

const KW_AI_PRODUCT = [
  "openai", "anthropic", "claude ai", "claude code", "claude 4",
  "gpt-4", "gpt-5", "gpt4", "gpt5", "chatgpt",
  "gemini", "google ai", "meta ai", "meta llama",
  "mistral", "cohere", "deepseek", "qwen",
  "copilot", "perplexity", "midjourney",
  "stable diffusion", "sora",
  "ai model", "ai launch", "ai release", "ai announce",
  "llm release", "llm launch",
];

const KW_AI_TOOLS = [
  "ai tool", "ai sdk", "ai framework", "ai api", "ai platform",
  "llm tool", "llm framework", "llm api", "llm sdk",
  "langchain", "llamaindex", "autogen", "crewai", "dspy",
  "vllm", "ollama", "lmstudio", "jan.ai",
  "cursor", "windsurf", "aider", "continue.dev",
  "vercel ai", "ai gateway", "ai proxy",
  "mcp", "tool use", "function calling",
  "fine-tun", "lora", "qlora", "unsloth",
  "inference", "serving", "deployment",
  "ai code", "ai dev", "ai engineer",
  "vector database", "embedding", "semantic search",
];

const KW_AGENT_RAG = [
  "agent", "agentic", "multi-agent", "agent framework",
  "rag", "retrieval augmented", "retrieval-augmented",
  "nl2sql", "text-to-sql", "text2sql",
  "prompt engineer", "prompt template", "prompt chain",
  "chain of thought", "cot", "react agent",
  "tool use", "function call", "planning",
  "memory", "context window", "long context",
  "knowledge graph", "graph rag",
  "evaluation", "eval", "benchmark",
];

const KW_AI_ENHANCE = [
  "mcp server", "mcp tool", "mcp client", "model context protocol",
  "claude skill", "claude hook", "claude extension",
  "cursor rule", "cursor plugin", "cursor extension", ".cursorrules",
  "windsurf rule", "cline rule",
  "system prompt", "custom instruction", "custom prompt",
  "ai plugin", "ai extension", "ai addon",
  "copilot extension", "copilot plugin",
  "claude.md", "claude code skill", "claude code hook",
  "ai workflow", "ai automation", "ai pipeline",
  "openai plugin", "gpt plugin", "gpts",
  "ai memory", "ai persona", "ai assistant",
];

const KW_FRONTEND_DATAVIZ = [
  "react", "next.js", "nextjs", "vue", "svelte", "solid",
  "typescript", "javascript", "node.js", "nodejs", "deno", "bun",
  "tailwind", "css", "web component",
  "vite", "turbopack", "rspack", "webpack",
  "monorepo", "micro frontend",
  "d3", "echarts", "antv", "g2", "g6", "l7", "s2",
  "observable", "plotly", "chart.js", "recharts", "nivo",
  "deck.gl", "mapbox", "react-flow", "xyflow",
  "three.js", "webgl", "webgpu", "canvas",
  "data viz", "visualization", "dashboard",
  "monaco editor", "codemirror",
];

// ─── Helpers ───────────────────────────────────────────────

function getTargetDate() {
  const args = process.argv.slice(2).filter((a) => !a.startsWith("--"));
  if (args[0]) return args[0];
  return new Date().toISOString().split("T")[0];
}

// Negative keywords — stories matching these are excluded from all sections
const KW_EXCLUDE = [
  "cell phone ban", "phone ban", "school ban",
  "sports", "football", "basketball", "soccer",
  "cooking", "recipe", "gardening",
  "real estate", "mortgage", "housing market",
  "crypto scam", "ponzi",
];

function matchKeywords(text, keywords) {
  const lower = text.toLowerCase();
  if (KW_EXCLUDE.some((kw) => lower.includes(kw))) return false;
  return keywords.some((kw) => lower.includes(kw));
}

function matchScore(text, keywords) {
  const lower = text.toLowerCase();
  return keywords.filter((kw) => lower.includes(kw)).length;
}

async function fetchJSON(url, options = {}) {
  try {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 20000);
    const res = await fetch(url, { signal: controller.signal, ...options });
    clearTimeout(timeout);
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    return await res.json();
  } catch (e) {
    console.error(`  [WARN] ${url}: ${e.message}`);
    return null;
  }
}

async function fetchText(url) {
  try {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 20000);
    const res = await fetch(url, { signal: controller.signal });
    clearTimeout(timeout);
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    return await res.text();
  } catch (e) {
    console.error(`  [WARN] ${url}: ${e.message}`);
    return null;
  }
}

// ─── Hacker News ───────────────────────────────────────────

async function fetchHackerNews() {
  console.log("📰 Fetching Hacker News...");

  const topIds = await fetchJSON(
    "https://hacker-news.firebaseio.com/v0/topstories.json"
  );
  if (!topIds) return [];

  const top100 = topIds.slice(0, 100);
  const stories = await Promise.all(
    top100.map((id) =>
      fetchJSON(`https://hacker-news.firebaseio.com/v0/item/${id}.json`)
    )
  );

  return stories
    .filter((s) => s && s.title && (s.score || 0) >= 30)
    .map((s) => ({
      title: s.title,
      url: s.url || `https://news.ycombinator.com/item?id=${s.id}`,
      score: s.score || 0,
      comments: s.descendants || 0,
      hn_url: `https://news.ycombinator.com/item?id=${s.id}`,
      text: s.title + " " + (s.url || ""),
    }));
}

// ─── GitHub: New & Trending Repos ──────────────────────────

async function fetchGitHubRepos(query, label) {
  const data = await fetchJSON(
    `https://api.github.com/search/repositories?${query}`,
    { headers: { Accept: "application/vnd.github.v3+json" } }
  );

  if (!data?.items) return [];

  return data.items.map((repo) => ({
    name: repo.full_name,
    description: repo.description || "",
    stars: repo.stargazers_count,
    language: repo.language || "N/A",
    url: repo.html_url,
    created: repo.created_at?.split("T")[0] || "",
    text: `${repo.full_name} ${repo.description || ""} ${repo.topics?.join(" ") || ""}`,
    source: label,
  }));
}

async function fetchGitHub() {
  console.log("🐙 Fetching GitHub...");

  const today = new Date();
  const daysAgo = (n) => {
    const d = new Date(today - n * 24 * 60 * 60 * 1000);
    return d.toISOString().split("T")[0];
  };

  // "近期火" = 30天内有 push 活动 + 按 star 排序（不限创建时间）
  const queries = [
    // AI tools & LLM — active in last 30 days
    `q=topic:llm+pushed:>${daysAgo(30)}+stars:>100&sort=stars&order=desc&per_page=15`,
    // AI repos — active in last 30 days
    `q=topic:artificial-intelligence+pushed:>${daysAgo(30)}+stars:>100&sort=stars&order=desc&per_page=15`,
    // Agent — active in last 30 days
    `q=topic:ai-agent+pushed:>${daysAgo(30)}+stars:>50&sort=stars&order=desc&per_page=10`,
    // MCP / Skills / Plugins — active in last 30 days
    `q=mcp+server+pushed:>${daysAgo(30)}+stars:>5&sort=stars&order=desc&per_page=10`,
    // Data Viz — active in last 30 days
    `q=topic:data-visualization+pushed:>${daysAgo(30)}+stars:>50&sort=stars&order=desc&per_page=10`,
  ];

  const seen = new Set();
  const allRepos = [];

  for (const query of queries) {
    const repos = await fetchGitHubRepos(query, "github");
    for (const repo of repos) {
      if (seen.has(repo.name)) continue;
      seen.add(repo.name);
      allRepos.push(repo);
    }
    // Rate limit: GitHub allows 10 req/min unauthenticated
    await new Promise((r) => setTimeout(r, 1500));
  }

  console.log(`  Found ${allRepos.length} repos`);
  return allRepos;
}

// ─── ArXiv ─────────────────────────────────────────────────

async function fetchArxiv() {
  console.log("📄 Fetching ArXiv...");

  const categories = ["cs.AI", "cs.LG", "cs.CL"];
  const query = categories.map((c) => `cat:${c}`).join("+OR+");
  const url = `https://export.arxiv.org/api/query?search_query=${query}&sortBy=submittedDate&sortOrder=descending&max_results=30`;

  const xml = await fetchText(url);
  if (!xml) return [];

  const entries = xml.split("<entry>").slice(1);
  return entries.map((entry) => {
    const getTag = (tag) => {
      const match = entry.match(
        new RegExp(`<${tag}[^>]*>([\\s\\S]*?)</${tag}>`)
      );
      return match ? match[1].trim() : "";
    };

    const title = getTag("title").replace(/\s+/g, " ");
    const summary = getTag("summary").replace(/\s+/g, " ").slice(0, 300);
    const published = getTag("published").split("T")[0];

    const linkMatch = entry.match(
      /href="(https:\/\/arxiv\.org\/abs\/[^"]+)"/
    );
    const link = linkMatch ? linkMatch[1] : "";

    const authors = [];
    const authorMatches = entry.matchAll(/<name>([^<]+)<\/name>/g);
    for (const m of authorMatches) {
      if (authors.length < 3) authors.push(m[1]);
    }

    return {
      title,
      summary,
      authors,
      link,
      published,
      text: title + " " + summary,
    };
  });
}

// ─── Hugging Face Daily Papers ─────────────────────────────

async function fetchHFPapers() {
  console.log("🤗 Fetching Hugging Face Daily Papers...");

  // Try daily_papers first, then flat /papers as fallback
  let data = await fetchJSON("https://huggingface.co/api/daily_papers");

  if (data && Array.isArray(data) && data.length > 0) {
    // Wrapped format: { paper: { ... }, submittedBy, ... }
    const papers = data
      .filter((p) => p.paper && (p.paper.upvotes || 0) >= 3)
      .slice(0, 15)
      .map((p) => ({
        title: p.paper.title || "",
        summary: (p.paper.ai_summary || p.paper.summary || "").replace(/\s+/g, " ").slice(0, 300),
        link: `https://huggingface.co/papers/${p.paper.id}`,
        upvotes: p.paper.upvotes || 0,
        published: p.paper.publishedAt?.split("T")[0] || p.publishedAt?.split("T")[0] || "",
        authors: p.paper.authors?.slice(0, 3).map((a) => a.name || a.fullname || a.user?.fullname || a._id || "") || [],
        text: (p.paper.title || "") + " " + (p.paper.summary || ""),
      }));
    console.log(`  Found ${papers.length} papers from /daily_papers (upvotes ≥ 3)`);
    return papers;
  }

  // Fallback: flat /papers endpoint
  data = await fetchJSON("https://huggingface.co/api/papers");
  if (!data || !Array.isArray(data)) return [];

  const papers = data
    .filter((p) => (p.upvotes || 0) >= 3)
    .slice(0, 15)
    .map((p) => ({
      title: p.title || "",
      summary: (p.ai_summary || p.summary || "").replace(/\s+/g, " ").slice(0, 300),
      link: `https://huggingface.co/papers/${p.id}`,
      upvotes: p.upvotes || 0,
      published: p.publishedAt?.split("T")[0] || "",
      authors: p.authors?.slice(0, 3).map((a) => a.name || a.fullname || a._id || "") || [],
      text: (p.title || "") + " " + (p.summary || ""),
    }));

  console.log(`  Found ${papers.length} papers from /papers (upvotes ≥ 3)`);
  return papers;
}

// ─── Categorize & Build Sections ───────────────────────────

function buildSections(hnStories, githubRepos, arxivPapers, hfPapers) {
  const usedHN = new Set();
  const usedGH = new Set();

  // Helper: pick top N from list by score, mark as used
  // minMatches: require at least N keyword matches (default 1)
  function pickHN(keywords, n, scoreThreshold = 30, minMatches = 1) {
    return hnStories
      .filter((s) => !usedHN.has(s.url) && matchScore(s.text, keywords) >= minMatches && s.score >= scoreThreshold)
      .sort((a, b) => {
        const sa = matchScore(a.text, keywords);
        const sb = matchScore(b.text, keywords);
        return sb - sa || b.score - a.score;
      })
      .slice(0, n)
      .map((s) => { usedHN.add(s.url); return s; });
  }

  function pickGH(keywords, n) {
    return githubRepos
      .filter((r) => !usedGH.has(r.name) && matchKeywords(r.text, keywords))
      .sort((a, b) => {
        const sa = matchScore(a.text, keywords);
        const sb = matchScore(b.text, keywords);
        return sb - sa || b.stars - a.stars;
      })
      .slice(0, n)
      .map((r) => { usedGH.add(r.name); return r; });
  }

  // ── Section 1: AI 产品与发布 (Top 5) ──
  const sec1_hn = pickHN(KW_AI_PRODUCT, 5, 50);

  // ── Section 2: AI 工程与工具 (Top 10) ──
  const sec2_gh = pickGH(KW_AI_TOOLS, 7);
  const sec2_hn = pickHN(KW_AI_TOOLS, 3);

  // ── Section 3: AI 增强生态 (Top 5) — Skills / MCP / Plugins ──
  const sec3_gh = pickGH(KW_AI_ENHANCE, 3);
  const sec3_hn = pickHN(KW_AI_ENHANCE, 2);

  // ── Section 4: Agent / RAG / LLM 应用 (Top 5) ──
  const sec4_hn = pickHN(KW_AGENT_RAG, 3);
  const sec4_arxiv = arxivPapers
    .filter((p) => matchKeywords(p.text, KW_AGENT_RAG))
    .slice(0, 2);

  // ── Section 5: 开源热点 (Top 5) — 未被其他板块选中的高 star 活跃项目 ──
  const sec5_gh_hot = githubRepos
    .filter((r) => !usedGH.has(r.name))
    .sort((a, b) => b.stars - a.stars)
    .slice(0, 5)
    .map((r) => { usedGH.add(r.name); return r; });

  // ── Section 6: 前端 / 数据可视化 (Top 5) ──
  const sec6_gh = pickGH(KW_FRONTEND_DATAVIZ, 3);
  const sec6_hn = pickHN(KW_FRONTEND_DATAVIZ, 2, 30, 2);

  // ── Section 7: 值得精读的论文 (Top 5) ──
  const sec7_hf = hfPapers.slice(0, 5);

  return { sec1_hn, sec2_gh, sec2_hn, sec3_gh, sec3_hn, sec4_hn, sec4_arxiv, sec5_gh_hot, sec6_gh, sec6_hn, sec7_hf };
}

// ─── Markdown Output ───────────────────────────────────────

function mdHNList(items) {
  const l = [];
  for (const s of items) {
    l.push(`- **[${s.title}](${s.url})**`);
    l.push(`  ⬆ ${s.score} pts | 💬 ${s.comments} 评论 | [讨论](${s.hn_url})`);
    l.push("");
  }
  return l;
}

function mdGHList(items, showAge = false) {
  const l = [];
  for (const r of items) {
    const desc = (r.description).slice(0, 80);
    const age = showAge && r.created ? ` | 创建于 ${r.created}` : "";
    l.push(`- **[${r.name}](${r.url})** ⭐ ${r.stars.toLocaleString()} [${r.language}]${age}`);
    l.push(`  ${desc}`);
    l.push("");
  }
  return l;
}

function generateMarkdown(date, sections) {
  const { sec1_hn, sec2_gh, sec2_hn, sec3_gh, sec3_hn, sec4_hn, sec4_arxiv, sec5_gh_hot, sec6_gh, sec6_hn, sec7_hf } = sections;
  const lines = [];

  lines.push(`# 技术日报 — ${date}`);
  lines.push("");
  lines.push(`> 自动生成于 ${new Date().toISOString()}`);
  lines.push("");

  // 1. AI 产品与发布
  lines.push("## 🤖 AI 产品与发布");
  lines.push("");
  if (sec1_hn.length === 0) lines.push("_今日暂无重大 AI 产品动态_");
  else lines.push(...mdHNList(sec1_hn));
  lines.push("");

  // 2. AI 工程与工具
  lines.push("## 🔧 AI 工程与工具（重点）");
  lines.push("");
  if (sec2_gh.length === 0 && sec2_hn.length === 0) lines.push("_今日暂无 AI 工具更新_");
  else { lines.push(...mdGHList(sec2_gh, true)); lines.push(...mdHNList(sec2_hn)); }
  lines.push("");

  // 3. AI 增强生态
  lines.push("## 🧩 AI 增强生态（Skills / MCP / Plugins）");
  lines.push("");
  if (sec3_gh.length === 0 && sec3_hn.length === 0) lines.push("_今日暂无相关更新_");
  else { lines.push(...mdGHList(sec3_gh, true)); lines.push(...mdHNList(sec3_hn)); }
  lines.push("");

  // 4. Agent / RAG / LLM 应用
  lines.push("## 🧠 Agent / RAG / LLM 应用");
  lines.push("");
  if (sec4_hn.length === 0 && sec4_arxiv.length === 0) {
    lines.push("_今日暂无相关更新_");
  } else {
    lines.push(...mdHNList(sec4_hn));
    for (const p of sec4_arxiv) {
      const authStr = p.authors.join(", ") + (p.authors.length >= 3 ? " et al." : "");
      lines.push(`- **[${p.title}](${p.link})**`);
      lines.push(`  ${authStr} | ${p.published}`);
      lines.push(`  ${p.summary.slice(0, 150)}...`);
      lines.push("");
    }
  }
  lines.push("");

  // 5. 开源热点
  lines.push("## 🔥 开源热点（近 30 天活跃）");
  lines.push("");
  if (sec5_gh_hot.length === 0) lines.push("_今日暂无新兴开源项目_");
  else lines.push(...mdGHList(sec5_gh_hot, true));
  lines.push("");

  // 6. 前端 / 数据可视化
  lines.push("## 📊 前端 / 数据可视化");
  lines.push("");
  if (sec6_gh.length === 0 && sec6_hn.length === 0) lines.push("_今日暂无相关更新_");
  else { lines.push(...mdGHList(sec6_gh)); lines.push(...mdHNList(sec6_hn)); }
  lines.push("");

  // 7. 值得精读的论文
  lines.push("## 📄 值得精读的论文");
  lines.push("");
  if (sec7_hf.length === 0) {
    lines.push("_今日暂无推荐论文_");
  } else {
    for (const p of sec7_hf) {
      const authStr = p.authors.join(", ") + (p.authors.length >= 3 ? " et al." : "");
      lines.push(`- **[${p.title}](${p.link})** 👍 ${p.upvotes}`);
      lines.push(`  ${authStr}`);
      lines.push(`  ${p.summary.slice(0, 150)}...`);
      lines.push("");
    }
  }

  const total = Object.values(sections).flat().length;
  lines.push("---");
  lines.push("");
  lines.push(`📊 **今日统计**：共 ${total} 条`);

  return lines.join("\n");
}

// ─── Plain Text Output ────────────────────────────────────

function generatePlainText(date, sections) {
  const { sec1_hn, sec2_gh, sec2_hn, sec3_gh, sec3_hn, sec4_hn, sec4_arxiv, sec5_gh_hot, sec6_gh, sec6_hn, sec7_hf } = sections;
  const lines = [];
  const sep = "─".repeat(60);

  lines.push(`技术日报 — ${date}`);
  lines.push(sep);
  lines.push("");

  const txtHN = (items, label) => {
    lines.push(`[${label}]`);
    lines.push("");
    if (items.length === 0) { lines.push("  今日暂无"); }
    else items.forEach((s, i) => {
      lines.push(`  ${i + 1}. ${s.title}`);
      lines.push(`     ⬆ ${s.score} pts | 💬 ${s.comments} 评论`);
      lines.push(`     ${s.url}`);
      lines.push("");
    });
    lines.push("");
  };

  const txtGH = (items) => {
    items.forEach((r, i) => {
      lines.push(`  ${i + 1}. ${r.name}  ⭐ ${r.stars.toLocaleString()}  [${r.language}]`);
      const desc = r.description;
      if (desc) lines.push(`     ${desc.slice(0, 80)}`);
      lines.push(`     ${r.url}`);
      lines.push("");
    });
  };

  // 1
  txtHN(sec1_hn, "🤖 AI 产品与发布");

  // 2
  lines.push("[🔧 AI 工程与工具（重点）]");
  lines.push("");
  if (sec2_gh.length === 0 && sec2_hn.length === 0) lines.push("  今日暂无");
  else { txtGH(sec2_gh); sec2_hn.forEach((s, i) => {
    lines.push(`  ${sec2_gh.length + i + 1}. ${s.title}`);
    lines.push(`     ⬆ ${s.score} pts`);
    lines.push(`     ${s.url}`);
    lines.push("");
  }); }
  lines.push("");

  // 3
  lines.push("[🧩 AI 增强生态（Skills / MCP / Plugins）]");
  lines.push("");
  if (sec3_gh.length === 0 && sec3_hn.length === 0) lines.push("  今日暂无");
  else { txtGH(sec3_gh); sec3_hn.forEach((s, i) => {
    lines.push(`  ${sec3_gh.length + i + 1}. ${s.title}`);
    lines.push(`     ⬆ ${s.score} pts`);
    lines.push(`     ${s.url}`);
    lines.push("");
  }); }
  lines.push("");

  // 4
  lines.push("[🧠 Agent / RAG / LLM 应用]");
  lines.push("");
  let idx = 1;
  sec4_hn.forEach((s) => { lines.push(`  ${idx++}. ${s.title}`); lines.push(`     ⬆ ${s.score} pts`); lines.push(`     ${s.url}`); lines.push(""); });
  sec4_arxiv.forEach((p) => { lines.push(`  ${idx++}. ${p.title}`); lines.push(`     ${p.summary.slice(0, 120)}...`); lines.push(`     ${p.link}`); lines.push(""); });
  if (idx === 1) lines.push("  今日暂无");
  lines.push("");

  // 5
  lines.push("[🔥 开源热点（近 30 天活跃）]");
  lines.push("");
  if (sec5_gh_hot.length === 0) lines.push("  今日暂无");
  else txtGH(sec5_gh_hot);
  lines.push("");

  // 6
  lines.push("[📊 前端 / 数据可视化]");
  lines.push("");
  idx = 1;
  sec6_gh.forEach((r) => { const d = r.description; lines.push(`  ${idx++}. ${r.name}  ⭐ ${r.stars.toLocaleString()}  [${r.language}]`); if (d) lines.push(`     ${d.slice(0, 80)}`); lines.push(`     ${r.url}`); lines.push(""); });
  sec6_hn.forEach((s) => { lines.push(`  ${idx++}. ${s.title}`); lines.push(`     ⬆ ${s.score} pts`); lines.push(`     ${s.url}`); lines.push(""); });
  if (idx === 1) lines.push("  今日暂无");
  lines.push("");

  // 7
  lines.push("[📄 值得精读的论文]");
  lines.push("");
  if (sec7_hf.length === 0) lines.push("  今日暂无");
  else sec7_hf.forEach((p, i) => {
    lines.push(`  ${i + 1}. ${p.title}  👍 ${p.upvotes}`);
    lines.push(`     ${p.summary.slice(0, 120)}...`);
    lines.push(`     ${p.link}`);
    lines.push("");
  });

  const total = Object.values(sections).flat().length;
  lines.push(sep);
  lines.push(`今日统计：共 ${total} 条`);

  return lines.join("\n");
}

// ─── Main ──────────────────────────────────────────────────

async function main() {
  const date = getTargetDate();
  const month = date.slice(0, 7);
  const monthDir = join(ICLOUD_BASE, month);

  if (!existsSync(monthDir)) {
    mkdirSync(monthDir, { recursive: true });
  }

  const mdPath = join(monthDir, `${date}.md`);
  const txtPath = join(monthDir, `${date}.txt`);

  if (existsSync(mdPath) && !FORCE) {
    console.log(`⏭  ${date} 已存在，跳过。使用 --force 重新抓取。`);
    process.exit(0);
  }

  console.log(`\n🤖 技术日报 — ${date}\n`);

  // HN, ArXiv, HF can run in parallel (different domains)
  // GitHub Top 5 and trending run sequentially (same domain, rate limited)
  const [hnStories, arxivPapers, hfPapers] = await Promise.all([
    fetchHackerNews(),
    fetchArxiv(),
    fetchHFPapers(),
  ]);

  const githubRepos = await fetchGitHub();

  console.log(`\n📊 原始数据: HN ${hnStories.length} | GitHub ${githubRepos.length} | ArXiv ${arxivPapers.length} | HF ${hfPapers.length}`);

  const sections = buildSections(hnStories, githubRepos, arxivPapers, hfPapers);

  const md = generateMarkdown(date, sections);
  const txt = generatePlainText(date, sections);

  writeFileSync(mdPath, md, "utf-8");
  writeFileSync(txtPath, txt, "utf-8");

  const total = Object.values(sections).flat().length;
  console.log(`\n✅ 已保存:`);
  console.log(`   ${mdPath}`);
  console.log(`   ${txtPath}`);
  console.log(`📊 共 ${total} 条资讯\n`);
}

main().catch((e) => {
  console.error("Fatal error:", e);
  process.exit(1);
});
