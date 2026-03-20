#!/usr/bin/env node

/**
 * AI Daily Digest - 每日 AI 资讯自动抓取
 *
 * Output: ~/AI-Daily/{YYYY-MM}/{YYYY-MM-DD}.md + .txt (iCloud synced)
 * Dedup: skips if today's .md already exists (safe for multi-Mac cron)
 *
 * Usage:
 *   node ai-daily.mjs              # today
 *   node ai-daily.mjs 2026-03-21   # specific date
 *   node ai-daily.mjs --force      # ignore dedup, re-fetch today
 */

import { writeFileSync, mkdirSync, existsSync } from "fs";
import { join } from "path";
import { homedir } from "os";

const ICLOUD_BASE = join(
  homedir(),
  "Library/Mobile Documents/com~apple~CloudDocs/AI-Daily"
);
const FORCE = process.argv.includes("--force");

const AI_KEYWORDS = [
  "ai",
  "artificial intelligence",
  "machine learning",
  "deep learning",
  "llm",
  "gpt",
  "claude",
  "gemini",
  "transformer",
  "neural",
  "openai",
  "anthropic",
  "diffusion",
  "embedding",
  "rag",
  "agent",
  "fine-tun",
  "langchain",
  "vector database",
  "prompt",
  "multimodal",
  "reasoning",
  "inference",
  "model",
  "nlp",
  "computer vision",
  "generative",
  "copilot",
  "stable diffusion",
  "midjourney",
  "hugging face",
  "lora",
  "rlhf",
  "mcp",
  "ai tool",
];

function isAIRelated(text) {
  const lower = text.toLowerCase();
  return AI_KEYWORDS.some((kw) => lower.includes(kw));
}

function getTargetDate() {
  const args = process.argv.slice(2).filter((a) => !a.startsWith("--"));
  if (args[0]) return args[0];
  const now = new Date();
  return now.toISOString().split("T")[0];
}

async function fetchJSON(url, options = {}) {
  try {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 15000);
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
    const timeout = setTimeout(() => controller.abort(), 15000);
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

  const top60 = topIds.slice(0, 60);
  const stories = await Promise.all(
    top60.map((id) =>
      fetchJSON(`https://hacker-news.firebaseio.com/v0/item/${id}.json`)
    )
  );

  const aiStories = stories
    .filter((s) => s && s.title && isAIRelated(s.title))
    .sort((a, b) => (b.score || 0) - (a.score || 0))
    .slice(0, 15)
    .map((s) => ({
      title: s.title,
      url: s.url || `https://news.ycombinator.com/item?id=${s.id}`,
      score: s.score || 0,
      comments: s.descendants || 0,
      hn_url: `https://news.ycombinator.com/item?id=${s.id}`,
    }));

  console.log(`  Found ${aiStories.length} AI-related stories`);
  return aiStories;
}

// ─── GitHub Trending ───────────────────────────────────────

async function fetchGitHubTrending() {
  console.log("🐙 Fetching GitHub Trending...");

  const today = new Date();
  const weekAgo = new Date(today - 7 * 24 * 60 * 60 * 1000);
  const since = weekAgo.toISOString().split("T")[0];

  const queries = [
    `q=topic:artificial-intelligence+pushed:>${since}&sort=stars&order=desc&per_page=10`,
    `q=topic:llm+pushed:>${since}&sort=stars&order=desc&per_page=10`,
    `q=topic:machine-learning+pushed:>${since}&sort=stars&order=desc&per_page=10`,
  ];

  const seen = new Set();
  const repos = [];

  for (const query of queries) {
    const data = await fetchJSON(
      `https://api.github.com/search/repositories?${query}`,
      { headers: { Accept: "application/vnd.github.v3+json" } }
    );

    if (data?.items) {
      for (const repo of data.items) {
        if (seen.has(repo.full_name)) continue;
        seen.add(repo.full_name);
        repos.push({
          name: repo.full_name,
          description: repo.description || "",
          stars: repo.stargazers_count,
          language: repo.language || "N/A",
          url: repo.html_url,
        });
      }
    }
  }

  const sorted = repos.sort((a, b) => b.stars - a.stars).slice(0, 15);
  console.log(`  Found ${sorted.length} trending AI repos`);
  return sorted;
}

// ─── ArXiv ─────────────────────────────────────────────────

async function fetchArxiv() {
  console.log("📄 Fetching ArXiv papers...");

  const categories = ["cs.AI", "cs.LG", "cs.CL"];
  const query = categories.map((c) => `cat:${c}`).join("+OR+");
  const url = `https://export.arxiv.org/api/query?search_query=${query}&sortBy=submittedDate&sortOrder=descending&max_results=15`;

  const xml = await fetchText(url);
  if (!xml) return [];

  const entries = xml.split("<entry>").slice(1);
  const papers = entries.map((entry) => {
    const getTag = (tag) => {
      const match = entry.match(
        new RegExp(`<${tag}[^>]*>([\\s\\S]*?)</${tag}>`)
      );
      return match ? match[1].trim() : "";
    };

    const title = getTag("title").replace(/\s+/g, " ");
    const summary = getTag("summary").replace(/\s+/g, " ").slice(0, 200);
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

    const categoryMatches = entry.matchAll(/term="([^"]+)"/g);
    const cats = [];
    for (const m of categoryMatches) {
      if (m[1].startsWith("cs.")) cats.push(m[1]);
    }

    return { title, summary, authors, link, published, categories: cats };
  });

  console.log(`  Found ${papers.length} recent papers`);
  return papers;
}

// ─── Output: Markdown ──────────────────────────────────────

function generateMarkdown(date, hn, github, arxiv) {
  const lines = [];

  lines.push(`# AI Daily Digest — ${date}`);
  lines.push("");
  lines.push(`> Auto-generated at ${new Date().toISOString()}`);
  lines.push("");

  lines.push("## 📰 Hacker News — AI Hot Stories");
  lines.push("");
  if (hn.length === 0) {
    lines.push("_No AI-related stories found today._");
  } else {
    for (const s of hn) {
      lines.push(
        `- **[${s.title}](${s.url})** — ⬆ ${s.score} | 💬 ${s.comments} ([discussion](${s.hn_url}))`
      );
    }
  }
  lines.push("");

  lines.push("## 🐙 GitHub Trending — AI/ML Repos");
  lines.push("");
  if (github.length === 0) {
    lines.push("_No trending AI repos found today._");
  } else {
    lines.push("| Repo | Description | ⭐ Stars | Language |");
    lines.push("|------|-------------|----------|----------|");
    for (const r of github) {
      const desc =
        r.description.length > 60
          ? r.description.slice(0, 60) + "..."
          : r.description;
      lines.push(
        `| [${r.name}](${r.url}) | ${desc} | ${r.stars.toLocaleString()} | ${r.language} |`
      );
    }
  }
  lines.push("");

  lines.push("## 📄 ArXiv — Latest AI/ML Papers");
  lines.push("");
  if (arxiv.length === 0) {
    lines.push("_No papers fetched today._");
  } else {
    for (const p of arxiv) {
      const authStr =
        p.authors.join(", ") + (p.authors.length >= 3 ? " et al." : "");
      lines.push(`### [${p.title}](${p.link})`);
      lines.push("");
      lines.push(
        `> ${authStr} | ${p.published} | ${p.categories.join(", ")}`
      );
      lines.push("");
      lines.push(`${p.summary}...`);
      lines.push("");
    }
  }

  lines.push("---");
  lines.push("");
  lines.push(
    `📊 **Today**: ${hn.length} HN stories | ${github.length} GitHub repos | ${arxiv.length} ArXiv papers`
  );

  return lines.join("\n");
}

// ─── Output: Plain Text ───────────────────────────────────

function generatePlainText(date, hn, github, arxiv) {
  const lines = [];
  const sep = "─".repeat(60);

  lines.push(`AI Daily Digest — ${date}`);
  lines.push(sep);
  lines.push("");

  lines.push("[Hacker News — AI Hot Stories]");
  lines.push("");
  if (hn.length === 0) {
    lines.push("  No AI-related stories found today.");
  } else {
    for (let i = 0; i < hn.length; i++) {
      const s = hn[i];
      lines.push(`  ${i + 1}. ${s.title}`);
      lines.push(`     ⬆ ${s.score} pts | 💬 ${s.comments} comments`);
      lines.push(`     ${s.url}`);
      lines.push("");
    }
  }
  lines.push("");

  lines.push("[GitHub Trending — AI/ML Repos]");
  lines.push("");
  if (github.length === 0) {
    lines.push("  No trending AI repos found today.");
  } else {
    for (let i = 0; i < github.length; i++) {
      const r = github[i];
      lines.push(`  ${i + 1}. ${r.name}  ⭐ ${r.stars.toLocaleString()}  [${r.language}]`);
      if (r.description) {
        lines.push(`     ${r.description.slice(0, 80)}`);
      }
      lines.push(`     ${r.url}`);
      lines.push("");
    }
  }
  lines.push("");

  lines.push("[ArXiv — Latest AI/ML Papers]");
  lines.push("");
  if (arxiv.length === 0) {
    lines.push("  No papers fetched today.");
  } else {
    for (let i = 0; i < arxiv.length; i++) {
      const p = arxiv[i];
      const authStr =
        p.authors.join(", ") + (p.authors.length >= 3 ? " et al." : "");
      lines.push(`  ${i + 1}. ${p.title}`);
      lines.push(`     ${authStr} | ${p.published}`);
      lines.push(`     ${p.summary}...`);
      if (p.link) lines.push(`     ${p.link}`);
      lines.push("");
    }
  }

  lines.push(sep);
  lines.push(
    `Today: ${hn.length} HN stories | ${github.length} GitHub repos | ${arxiv.length} ArXiv papers`
  );

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

  // Dedup: skip if already fetched (multi-Mac safety)
  if (existsSync(mdPath) && !FORCE) {
    console.log(`⏭  ${date} already exists, skipping. Use --force to re-fetch.`);
    process.exit(0);
  }

  console.log(`\n🤖 AI Daily Digest — ${date}\n`);

  const [hn, github, arxiv] = await Promise.all([
    fetchHackerNews(),
    fetchGitHubTrending(),
    fetchArxiv(),
  ]);

  const md = generateMarkdown(date, hn, github, arxiv);
  const txt = generatePlainText(date, hn, github, arxiv);

  writeFileSync(mdPath, md, "utf-8");
  writeFileSync(txtPath, txt, "utf-8");

  console.log(`\n✅ Saved to:`);
  console.log(`   ${mdPath}`);
  console.log(`   ${txtPath}`);
  console.log(
    `📊 ${hn.length} HN stories | ${github.length} GitHub repos | ${arxiv.length} ArXiv papers\n`
  );
}

main().catch((e) => {
  console.error("Fatal error:", e);
  process.exit(1);
});
