# Heurai (Hi) AGI Engine: AI Contributor Guide

Welcome to the `hi` AGI engine codebase. This project implements a verifiable, self-improving AI engine in Common Lisp based on an Entity-Relation-Value (ERV) graph and driven by a Phenomenal Calculus. 

## Code Modification Protocol

**CRITICAL RULE:** All code changes must go through an approval process. Before modifying any file, you must present the issue in the following format and wait for user approval:
`PROBLEM -> PROPOSED FIX`

## Architectural Philosophy (The Phenomenal Calculus)

This system abandons relational database concepts and neural network black boxes in favor of a strictly defined Aristotelian graph. Every piece of knowledge, every operator, every task, and every physical object is mathematically unified into the `*working-ontology*`.

**1. The 3-Pillar Universe (Hylomorphism):**
The root of reality is `∆:∆`. It branches into three distinct, non-overlapping pillars:
*   `:concept` (Morphe/Form): Abstract definitions, math, and schemas (e.g., `:operator`, `:human`).
*   `:material` (Hyle/Matter): Instantiated, physical reality (e.g., `:micah-smith`, `:erv-engine`, `:my-file`).
*   `:system` (The Observer): The engine's internal cognitive state (e.g., `:users`, `:sessions`, `:tasks`).

**2. The 3-Operator Basis Set (Topology):**
The *only* verbs permitted in the cognitive AST (EAIL) to structure relationships between nodes are the basis vectors of physics:
*   `∆:is-a`: Identity, Taxonomy, or Static Structure.
*   `∆:requires`: Input, Precondition, Dependency, or Cause.
*   `∆:produces`: Output, Effect, Implication, or Yields.

**3. The Unbalance and The Void (`∆:∴`):**
The engine operates by detecting voids in the graph (represented by the Functor of Assured Expectation: `∆:∴`). When a user asks a question, the parser projects a `∆:∴` void. The STRIPS planner then uses `ops:` operators to resolve the void, returning the local sub-graph to a state of absolute balance (`∆:∆`).

## Core Rules for Code Generation

### 1. Common Lisp Standards
*   For all Lisp code, after defining a function, provide a `#+nil(assert ...)` example immediately following the docstring to demonstrate its usage and allow easy REPL testing. (Skip if output > 5 lines).
*   **Composability & Pure Functions:** Write pure, single-purpose functions that are highly composable. Avoid monolithic functions that mix concerns (e.g., parsing an AST *and* generating database tasks in the same function).
*   **Threading Macros:** You MUST actively use the threading macros (`->`, `->>`, `some->`, `some->>`, `cond->`, etc.) from `util.lisp` to chain pure functions together. This is the primary indicator that the system's architecture is correctly modularized.
*   The system uses atomic, thread-safe macro wrappers for state mutation (`swap-ontology!`). **Never** mutate the global `*working-ontology*` directly outside of this wrapper.

### 2. The 4-Tuple Fact Structure
*   Facts are immutable lists of exactly 4 elements: `(fact entity relation value temporality)`.
    *   **Entity:** The subject. MUST be a Lisp keyword (e.g., `:united-states`, `:task-123`).
    *   **Relation:** The edge/predicate. MUST be a namespaced symbol (e.g., `∆:is-a`, `prop:status`).
    *   **Value:** The object. Can be any Lisp type (keyword, string, integer).
    *   **Temporality:** Enum of either `:ephemeral` (fleeting session facts) or `:absolute` (universal truths).

### 3. Namespacing is Mathematically Strict
There is no ambiguity in relations. You must use the correct namespace prefix:
*   `∆:` -> Foundational physics, topology, and schema math (e.g., `∆:is-a`, `∆:∴`, `∆:relation`).
*   `core:` -> Engine mechanical states and variables (e.g., `core:status`, `core:intent`, `core:execution-log`).
*   `prop:` -> Descriptive attributes of concepts or material things (e.g., `prop:name`, `prop:color`, `prop:speed`).
*   `ops:` -> Registered tools the planner can execute (e.g., `ops:execute`, `ops:infer`).

### 4. Testing & Execution
*   **Never mock the LLM or API boundaries in integration tests.** Tests in `api-tests/` must hit the live endpoints. 
*   Run tests via `make check` (unit) and `make test-integration` (E2E against a local Ollama model).
*   Add unit tests for any new logic to the appropriate file in `tests/`.

### 5. Multi-Tenant Session Isolation
The engine supports multi-user concurrency via a Postgres-backed ERV graph. 
*   Always retrieve the current session state via `(get-session-ontology session-id user-id)`. 
*   Any newly discovered material or concept must be anchored to the user's specific sub-roots (`user-material-anchor`, `user-concept-anchor`) to prevent cross-user contamination before Phase 3 (Dreaming) consensus.

## Current Architecture: Phase 7 & 8 (Action & Accommodation Lifecycle)

The system operates via a decoupled agentic lifecycle:

1. **The Master Agentic Loop (`src/lifecycle/loop.lisp`):** Orchestrates the task state through perception, implication, and execution. Catches lexical ignorance traps and triggers taxonomy learning (`hi-learning:learn-taxonomy`).
2. **The STRIPS Planner (`src/planner/core.lisp` & `operators.lisp`):** Maps the `intent` and `voids` into a sequence of mathematical plan steps, validating terms against the Postgres Lexicon firewall (`src/planner/lexicon.lisp`).
3. **The Execution Engine (`src/executor.lisp`):** Iterates over generated plan steps and physically invokes the mapped Lisp operators.
4. **Tooling & Inference (`src/tools/ops/infer-from-void.lisp`):** Resolves voids via a strict fallback hierarchy:
   - A: Taxonomic Projection
   - B: Deterministic Postgres Memory Hit-Test
   - C: pgvector Intuition Hit-Test
   - D: Focused LLM Hallucination
