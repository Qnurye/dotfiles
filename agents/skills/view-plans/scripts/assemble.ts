#!/usr/bin/env bun

import { parseArgs } from "util";
import { readdirSync, readFileSync, writeFileSync, existsSync } from "fs";
import { join } from "path";

const { values } = parseArgs({
  args: Bun.argv.slice(2),
  options: {
    "plans-dir": { type: "string" },
    "cn-dir": { type: "string", default: "/tmp/view-plans-output/cn" },
    "html": { type: "string", default: "/tmp/view-plans-output/index.html" },
  },
  strict: true,
});

const plansDir = values["plans-dir"];
const cnDir = values["cn-dir"]!;
const htmlPath = values["html"]!;

if (!plansDir) {
  console.error("Error: --plans-dir is required");
  process.exit(1);
}

if (!existsSync(plansDir)) {
  console.error(`Error: plans directory does not exist: ${plansDir}`);
  process.exit(1);
}

if (!existsSync(htmlPath)) {
  console.error(`Error: HTML template not found: ${htmlPath}`);
  process.exit(1);
}

const files = readdirSync(plansDir).filter(f => f.endsWith(".md")).sort();

const plans = files.map(f => {
  const name = f
    .replace(/\.md$/, "")
    .replace(/-/g, " ")
    .replace(/\b\w/g, c => c.toUpperCase());
  const en = readFileSync(join(plansDir, f), "utf8");
  const cnPath = join(cnDir, f);
  const cn = existsSync(cnPath) ? readFileSync(cnPath, "utf8") : "";
  return { name, en, cn };
});

let html = readFileSync(htmlPath, "utf8");
html = html.replace(
  "<!-- PLANS_DATA -->",
  "<script>window.__PLANS__ = " + JSON.stringify(plans) + ";</script>"
);
writeFileSync(htmlPath, html);

console.log(JSON.stringify({ count: plans.length, names: plans.map(p => p.name) }));
