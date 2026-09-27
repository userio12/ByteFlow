# ByteFlow — Graphify Knowledge Graph & AST Codebase Intelligence

This document details the integration of **[Graphify](https://github.com/Graphify-Labs/graphify)** into ByteFlow as an AI agent skill and architectural intelligence tool.

---

## 1. What is Graphify?

**Graphify** turns any codebase, documentation, and system architecture into a queryable, persistent **Knowledge Graph** using deterministic local AST (Abstract Syntax Tree) parsing and community detection algorithms.

### Key Capabilities:
- **100% Local & Private**: AST parsing runs entirely on-device with zero code leakage or external API cost.
- **God Node & Community Detection**: Automatically uncovers architectural centralities, tightly coupled modules, and cross-cutting dependencies.
- **Interactive Visualizations**: Generates interactive HTML graph maps (`graphify-out/index.html`) showing the entire structure of the application.
- **AI Agent Skill**: Equipped as a native agent skill at [`.agents/skills/graphify/SKILL.md`](file:///storage/emulated/0/AndroidPEProjects/ByteFlow/.agents/skills/graphify/SKILL.md).

---

## 2. Installed Skill Location

The complete `/graphify` agent skill is installed in your project:
📁 [`.agents/skills/graphify/SKILL.md`](file:///storage/emulated/0/AndroidPEProjects/ByteFlow/.agents/skills/graphify/SKILL.md)

---

## 3. How to Use Graphify with ByteFlow

### 3.1 Generating & Updating the Knowledge Graph
```bash
# Build the baseline knowledge graph for ByteFlow (AST extraction)
python3 -m graphify extract . --code-only

# Export interactive standalone HTML visualizer
python3 -m graphify export html

# Incremental update after completing an implementation phase
python3 -m graphify update .
```

### 3.2 Continuous Phase Verification Protocol
In ByteFlow, Graphify is executed at the end of every implementation phase to update the AST graph:
1. `flutter analyze` ➔ Verify 0 issues.
2. `python3 -m graphify extract . --code-only` ➔ Refresh AST nodes and edges.
3. `python3 -m graphify export html` ➔ Refresh standalone visualizer.

---

## 4. Graphify Output Artifacts (`graphify-out/`)

When run on ByteFlow, Graphify produces:
1. `graphify-out/graph.html`: Standalone, interactive, searchable 2D force-directed knowledge graph of all Dart files, Kotlin services, and documentation nodes.
2. `graphify-out/graph.json`: Machine-readable graph structure for GraphRAG agent traversal (120+ nodes, 126+ edges).
3. `graphify-out/.graphify_analysis.json`: Structural community groupings and god node metrics.
