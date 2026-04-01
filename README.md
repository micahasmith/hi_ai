# Hi (Heurai Intelligence)

An agentic Entity-Relation-Value (ERV) Information Representation (IR) system built in Common Lisp. 

`Hi` is designed to perceive its environment (filesystems, codebases), derive higher-level implications using a queryable ontology, formulate deterministic goal states, and generate plans to achieve them using Large Language Models (LLMs) as translation and reasoning tools.

## Architecture Pipeline

1.  **Perception**: Scanners (`fs`, `lisp`, `asdf`) walk the workspace and generate a raw list of `:ephemeral` facts.
2.  **Implications**: A rules-based engine (`derive-implications`) uses the system's **Absolute Ontology** to deduce higher-level meaning (e.g., "this file is a startup script").
3.  **Intent Classification**: LLMs (via Certainty Score Prompting) translate human requests into specific system intents.
4.  **Goal Formulation**: The system deduces a precise `:target-state` (a set of facts that must be true for success) based on the intent and context.
5.  **Planning**: A means-ends analyzer (`generate-plan`) bridges the gap between the current state and the target state.

---

## Quick Start (REPL)

### 1. Load the System
Ensure you have **SBCL** and **Quicklisp** installed. The easiest way to get started and automatically ensure your local Ollama LLM is running is using `make`:

```bash
make repl
```

Once in the REPL:
```lisp
(in-package :hi)
```

### 2. Run a Human Request
The `handle-input` function is the primary entry point for natural language.

```lisp
;; Scan the current workspace and ask the AI to formulate a task
(defparameter *task* (handle-input :cli "Summarize this project."))

;; Derive the target goal state based on the intent
(setf (second (find 'target-state (rest *task*) :key #'first)) 
      (derive-target-state *task*))

;; Generate the execution plan
(generate-plan *task*)
```

---

## LLM Configuration (Ollama / Gemini / Claude)

Configurations live in `src/config.lisp`. By default, the system uses **Ollama** with `qwen3-coder:30b`.

### Prerequisites:
- **Ollama**: Download and run the Ollama app. Ensure `qwen3-coder:30b` is pulled (`ollama pull qwen3-coder:30b`).
- **API Keys**: For Google or Anthropic, set environment variables:
  - `export GEMINI_API_KEY="..."`
  - `export ANTHROPIC_API_KEY="..."`

### Defining Roles:
You can assign different models to different system roles in `src/config.lisp`:
```lisp
(defparameter *llm-roles*
  '((:translator . (:provider :ollama    :model "qwen3-coder:30b"))
    (:planner    . (:provider :google    :model "gemini-2.5-pro"))
    (:default    . (:provider :google    :model "gemini-2.5-flash"))))
```

---

## Web Dashboard & API

`Hi` includes a built-in HTTP server (Hunchentoot) to expose its capabilities to the web and provide visibility into task execution.

### Start the Server:
```lisp
(hi:start-server :port 8080)
```

### 1. Execution Dashboard
Monitor system logic, state queries, and plan generation in real-time.
- **URL**: [http://localhost:8080/dashboard/](http://localhost:8080/dashboard/)
- **How it works**: Uses the `with-log` macro to generate structured JSONL traces which are served via the dashboard.

### 2. Task API
You can POST human language to the system from external tools.
- **Endpoint**: `POST /api/task`
- **Payload**: `{"request": "verify the project"}`
- **Response**: Returns the inferred intent, status, and task summary.

---

## Development & Testing

### Running Tests
The project maintains a rigorous test suite using **Parachute**.

**Unit Tests**:
```lisp
(asdf:test-system :hi)
```

**Integration Tests** (Requires active Ollama server):
```lisp
(asdf:test-system "hi/integration-tests")
```

### Structured Logging
Use `with-log` to instrument functions. Logs are automatically summarized to keep the payload size manageable while preserving the full `task` context.
```lisp
(with-log "filename.lisp" 'function-name :arg1 val1 :arg2 val2)
```

---

## Future Roadmap

1. **NLP Fact Extraction Tool**: 3D tree-based analysis of human language structure.
2. **3D Ontology Visualizer**: Explore the fact graph in 3D using Three.js.
3. **Missing Context Resolution**: Interactive follow-up questions when task context is ambiguous.
