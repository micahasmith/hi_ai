GEMINI.md

# Coding Instructions

## *.lisp files

1. for all code that is written in lisp, after you define a function, write out (maybe 3) examples that are in the following form

; comment about the following code example
#+nil(assert (equal (function arg1 ...) expected))

HOWEVER, if that output is more than 5 lines long, don't do the assert part.

the nil thing lets me easily forward into the fn and run it without commenting in/out

add a newline after the function in between the doc/examples

2. always use util.lisp thread forwarding macros functions where it makes sense to

3. run `sbcl --load repl_test.lisp` after changes to ensure no breaks

4. write tests as appropriate into the ./tests/ folder

5. symbols. there are A LOT of symbols in this codebase so we want our definitions of them to always categorize them by prefixing. see 'src/task.lisp *known-intents* for an example. Relations (schema) and symbolic values (enums/types) must be namespaced symbols (e.g., `fs:type`, `fs:directory`, `status:draft`).

6. Entities (the subject of a fact) MUST be Keywords (e.g., `:hi-project`, `:workspace`). Value can take on any object type. Facts are 4-tuples with an optional temporality enum: `(fact <entity> <relation> <value> &optional <temporality>)` where temporality is `:ephemeral` (default, from scanners) or `:absolute` (universal truths).

7. never use any values that explicitly reference my filesystem in tests

8. Architecture Pipeline: The system follows a Perception -> Goal Formulation -> Planning -> Execution flow.
   - Perception: Scanners run against the filesystem and populate the `:input-state`.
   - Goal Formulation: The inference engine (`derive-target-state` in `src/targets.lisp`) deduces the required `:target-state` using the task's `:intent` and `:input-state`.
   - Planning/Execution: (Pending implementation) Means-ends analysis bridges the gap using registered `*known-operators*`.

9. Pattern Matching: Use `state-query` for declarative queries against states. Symbols prefixed with `?` (e.g., `?task`, `?project`) are treated as logic variables for unification.

10. Scanners & Extensibility: Scanners (like `fs` and `lisp`) self-register their capabilities to a global registry using `register-file-scanner` (Observer pattern). The central `scan-path` recursive walker handles the dispatching to prevent redundant sweeps.

11. Certainty Score Prompting: For classification tasks (like Intent inference), prompt LLMs to return a pure Common Lisp association list (Alist) mapping options to a float score from 0.0 to 1.0 (e.g., `((intents:summarize . 0.95) (intents:verify-result . 0.05))`). The Lisp side parses the alist, sorts by score, and acts deterministically.

12. Moon-Cycle Driven Development: The project operates on a roughly 4-week cadence aligned with lunar phases. Waxing phase for aggressive feature development, Full Moon for integration testing (the Agentic Loop), Waning phase for UX refinement and bug fixing, and New Moon for deployment/release. Plans are tracked in `moon-cycle-planning/YYYY-[hebrew-month].md`.

13. Task-Meta-Graph & RLHF: Every task execution is mirrored by an isomorphic `task-meta-graph` (the mathematical dual of the execution graph). This graph assigns causative error credit by categorizing failures as topological/categorical breakdowns:
    - **Information Loss (Projection Error):** The LLM mapped a high-dimensional human prompt to a low-dimensional intent, losing critical constraints (e.g., "summarize *only security*").
    - **Domain Deficiency (Lack of Fact):** The input state lacks the necessary entities to satisfy an intent's signature (e.g., missing a workspace).
    - **Functor Mismatch (Lack of Mapping):** The ontology lacks a rule to bridge two distinct domains of knowledge (e.g., `fs:` to `lisp:`).
    - **Unreachable Topology (Disconnected Graph):** The Planner cannot find a path from the input to the target state because the required `ops:` operators do not exist.
    Dual macro-evaluations (holistic vs. aggregated) use these strict failure categories to generate high-confidence RLHF training data.

14. Orthogonal Ontology (Minimal Basis Set): The set of Intents, Operators, and Relations must be kept as small and orthogonally distinct as possible. We do not add new Intents for specific tasks; we define a minimal basis set of functional primitives across three axes: **Mutation** (Read vs. Write), **Target** (Domain namespace), and **Resolution** (Deterministic vs. Heuristic). "Lack of Concept" is inferred when a request cannot be represented in this 3D space.

15. EIL (English Intermediate Language): Natural language inputs should be parsed into EIL format `(head child* '((modifier value) ...))` to provide a symbolic bridge between English and the Ontology. Predicates (Verbs/Prepositions) must preserve positional integrity by using `(nil '())` as a placeholder if a pivot (subject) is missing.

## Architectural Roadmap

**MVP Scope Restriction:**
For the Minimum Viable Product (MVP), the system's operational domains and capabilities are strictly limited to:
1. **Software Projects:** Operating against filesystems, codebases, scripts, and programming tools.
2. **Chat:** Conversational interaction to clarify ambiguity, resolve unbalance (Phase 4), and communicate state.
3. **Web-Only Interaction:** The system ONLY supports interaction via the React Dashboard and the JSON Request/Response web API. **CLI interaction is deprecated for the MVP.** All other hypothetical AGI domains are out of scope.

For the active list of TODOs, pending features, and the Future Product Roadmap, please refer to `docs/todo.yaml` as the single source of truth.

-----

## git

- git commit and push after each change set. always start the commit message with "∆"
