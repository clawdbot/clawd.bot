---
title: "OpenClaw Partners with VirusTotal for Skill Security"
description: "ClawHub skills are now scanned by VirusTotal's threat intelligence platform—bringing industry-leading security to the AI agent ecosystem."
date: 2026-02-05
authors:
  - name: "Peter Steinberger"
    handle: "steipete"
  - name: "Jamieson O'Reilly"
    handle: "theonejvo"
  - name: "Bernardo Quintero"
    handle: "bquintero"
draft: true
tags: ["security", "announcement", "clawhub"]
image: "/blog/openclaw-virustotal.svg"
---

Today we're announcing a partnership with [VirusTotal](https://www.virustotal.com), the world's leading threat intelligence platform, to bring security scanning to ClawHub—OpenClaw's skill marketplace.

**TL;DR:** All skills published to ClawHub are now scanned using VirusTotal's threat intelligence, including their new Code Insight capability. This provides an additional layer of security for the OpenClaw community.

## Why This Matters

For the past 20 years, security models have been built around locking devices and applications down—setting boundaries between inter-process communications, separating internet from local, sandboxing untrusted code. These principles remain important.

But AI agents represent a fundamental shift.

Unlike traditional software that does exactly what code tells it to do, AI agents interpret natural language and make decisions about actions. They blur the boundary between user intent and machine execution. They can be manipulated through language itself.

We understand that with the great utility of a tool like OpenClaw comes great responsibility. Done wrong, an AI agent is a liability. Done right, we can change personal computing for the better.

OpenClaw skills are powerful. They extend what your AI agent can do—from controlling smart home devices to managing finances to automating workflows. But with that power comes risk.

Skills are code that runs in your agent's context, with access to your tools and your data. A malicious skill could:

- Exfiltrate sensitive information
- Execute unauthorized commands
- Send messages on your behalf
- Download and run external payloads

As the OpenClaw ecosystem grows, so does the attack surface. We've already seen [documented cases](https://blog.virustotal.com/2026/02/from-automation-to-infection-how.html) of malicious actors attempting to exploit AI agent platforms. We're not waiting for this to become a bigger problem.

## How It Works

When a skill is published to ClawHub:

1. **Deterministic Packaging** — The skill files are bundled into a ZIP with consistent compression and timestamps, along with a `_meta.json` containing publisher info and version history
2. **Hash Computation** — A SHA-256 hash is computed for the entire bundle, creating a unique fingerprint
3. **VirusTotal Lookup** — The hash is checked against VirusTotal's database. If the file exists with a Code Insight verdict, results are returned immediately
4. **Upload & Analysis** — If not found (or no AI analysis exists), the bundle is uploaded to VirusTotal for fresh scanning via their v3 API
5. **Code Insight** — VirusTotal's LLM-powered Code Insight analyzes what the code actually does, catching obfuscated and novel threats that signature-based scanning misses
6. **Auto-Approval** — Skills with a "benign" Code Insight verdict are automatically approved. Anything flagged as malicious or suspicious requires manual review

Scan results are displayed on every skill page and in version history, with direct links to the full VirusTotal report.

This is the same approach VirusTotal uses with [Hugging Face](https://huggingface.co/blog/virustotal) to protect ML models and datasets.

## What This Is—And What It Isn't

Let's be clear: **this is not a silver bullet.**

VirusTotal scanning won't catch everything. A skill that uses natural language to instruct an agent to do something malicious won't trigger a virus signature. A carefully crafted prompt injection payload won't show up in a threat database.

What this does provide:

- **Detection of known malware** — Trojans, stealers, backdoors, malicious payloads
- **Behavioral analysis** — Code Insight identifies suspicious patterns even in novel threats
- **Supply chain visibility** — Catching compromised dependencies and embedded executables
- **A signal of intent** — We're investing in security, and this is the first of many layers

Security is defense in depth. This is one layer. More are coming.

## The Bigger Picture

This partnership is part of a broader security initiative at OpenClaw. In the coming days, we'll be publishing:

- **A comprehensive threat model** for the OpenClaw ecosystem
- **A public security roadmap** tracking defensive engineering goals
- **Details on our code review** covering the entire codebase
- **A formal security reporting process** with defined SLAs

We've brought on [Jamieson O'Reilly](https://twitter.com/theonejvo) (founder of Dvuln, co-founder of Aether AI, CREST Advisory Council member) as lead security advisor to guide this program.

AI agents that take real-world actions deserve real security processes. We're building them.

## For Skill Publishers

If you publish skills to ClawHub, your code will now be scanned automatically. Here's how it works:

1. Your skill is published and the VT scan runs asynchronously
2. If the scan returns a "benign" verdict, your skill is automatically approved
3. If something is flagged, your skill remains in a pending state until reviewed
4. You can check scan status on your skill's detail page with a direct link to the full VirusTotal report

We expect some false positives initially—security tooling isn't perfect. If your skill is incorrectly flagged, reach out to us at security@openclaw.ai and we'll review it.

## For Users

When browsing ClawHub, you'll see scan status for each skill. This gives you one more data point when deciding what to trust. But remember:

- A clean scan doesn't mean a skill is safe
- Always review what permissions a skill requests
- Start with skills from publishers you trust
- Report suspicious behavior to security@openclaw.ai

## Thank You, VirusTotal

We're grateful to Bernardo Quintero and the VirusTotal team for their partnership. Their platform protects millions of users every day, and we're proud to bring that protection to the OpenClaw community.

## What's Next

This is the beginning, not the end. We're committed to making OpenClaw the most secure AI agent platform available. Expect more announcements soon.

The lobster grows stronger. 🦞

---

*Questions about security? security@openclaw.ai*

*Publish skills: clawhub.ai*

*Join the discussion: Discord*

— Peter, Jamieson, and Bernardo
