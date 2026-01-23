# Architectural Principles Reference

Use this reference to analyze PRs. **Dynamically select only relevant principles** for each review. Do not include all principles in every report—that defeats the "high-signal, low-noise" philosophy.

For each selected principle, explain:
1. The theory and concept (with original author attribution)
2. Why it matters (what problems it prevents)
3. Point to specific code locations for the reader to examine
4. Ask thought-provoking questions that guide discovery

## 1. Code Organization & Dependencies

### Dependency Rule (Clean Architecture)
- **Author:** Robert C. Martin
- **Core concept:** Source code dependencies must point only inward, toward higher-level policies. Inner circles are policies (domain logic); outer circles are mechanisms (frameworks, databases, UI).
- **Why it matters:** Inner layers contain stable business rules; outer layers contain volatile details. If inner depends on outer, infrastructure changes force business logic changes. Dependency arrows should point toward stability.
- **Look for:** Import statements that go from inner layers (domain, core) to outer layers (api, infrastructure); business logic importing framework-specific code.
- **Guiding questions:**
  - "If you switched from FastAPI to Flask, which files would change?"
  - "Can you test your business logic without starting a web server?"
  - "Draw the dependency arrows—do they point toward stability or volatility?"

### Ports & Adapters (Hexagonal Architecture)
- **Author:** Alistair Cockburn
- **Core concept:** Application core depends on interfaces (ports), not implementations (adapters). The core defines ports (interfaces); adapters implement them (database, API, message queue).
- **Why it matters:** Enables testing without real infrastructure; allows swapping implementations (different database, different cloud provider) without touching business logic.
- **Look for:** Direct instantiation of infrastructure clients inside business logic; inability to unit test without mocking SDK internals; business logic methods that take concrete infrastructure types as parameters.
- **Guiding questions:**
  - "Can you test this business logic with an in-memory implementation?"
  - "What would you need to change to switch from Databricks to Pinecone?"
  - "Who defines the interface—the core or the infrastructure?"

### Dependency Inversion Principle
- **Author:** Robert C. Martin (SOLID)
- **Core concept:** High-level modules should not depend on low-level modules; both should depend on abstractions. Abstractions should not depend on details; details should depend on abstractions.
- **Why it matters:** Decouples policy from mechanism; high-level business rules don't change when low-level details change. Enables independent testing and deployment.
- **Look for:** Business logic importing concrete infrastructure classes; no interfaces/protocols between layers; high-level code calling low-level constructors directly.
- **Guiding questions:**
  - "Who owns the interface definition—the caller or the implementer?"
  - "If the database schema changes, does business logic need to change?"
  - "Are dependencies inverted or just indirect?"

---

## 2. Responsibility & Cohesion

### Single Responsibility Principle
- **Author:** Robert C. Martin (SOLID)
- **Core concept:** A module should have one, and only one, reason to change. "Reason to change" means one stakeholder/actor who might request changes.
- **Why it matters:** Multiple responsibilities mean unrelated changes can break unrelated features. Code serving multiple actors creates merge conflicts, fragile changes, and obscured intent.
- **Look for:** Long functions handling multiple concerns; classes that change for different business reasons; modules that combine business logic with presentation, persistence, and error handling.
- **Guiding questions:**
  - "Which stakeholder would ask for each change in this module?"
  - "If the search algorithm changes, should this file change?"
  - "If the API response format changes, should this file change?"
  - "If both answers are yes, does this module have one responsibility?"

### Separation of Concerns
- **Author:** Edsger Dijkstra
- **Core concept:** Different concerns (UI, business logic, data access, logging, validation) should be handled by different modules with clear boundaries.
- **Why it matters:** Changes to one concern don't ripple into others; code is understandable in isolation; you can reason about each concern independently.
- **Look for:** Mixed concerns in single functions (HTTP handling + business logic + database calls in one place); logging logic intertwined with business logic; validation mixed with persistence.
- **Guiding questions:**
  - "Can you describe this function's purpose without using the word 'and'?"
  - "If you needed to change the logging format, how many files would you touch?"
  - "Can you test the business logic without HTTP mocks?"

---

## 3. Extensibility & Flexibility

### Open/Closed Principle
- **Author:** Bertrand Meyer
- **Core concept:** Software entities should be open for extension, but closed for modification. Add new behavior by adding code, not modifying existing tested code.
- **Why it matters:** Modifications risk breaking what works; extensions isolate risk. Testable extension points enable growth without regression risk.
- **Look for:** if/else or switch statements that grow with each new type/case; adding features requires changing multiple existing files; central dispatch logic that knows about all cases.
- **Guiding questions:**
  - "To add a new product type, which existing files would you modify?"
  - "Can you extend this behavior without touching tested code?"
  - "What would need to change to support a fourth recommendation strategy?"

### Liskov Substitution Principle
- **Author:** Barbara Liskov
- **Core concept:** Subtypes must be substitutable for their base types without altering program correctness. Subclasses should honor the contract of the parent.
- **Why it matters:** Polymorphism becomes unreliable if subclasses break expectations; leads to defensive type-checking everywhere, defeating the purpose of polymorphism.
- **Look for:** Subclasses that throw exceptions for inherited methods; overrides that change expected behavior (e.g., returns None instead of a list); `isinstance` checks before calling methods.
- **Guiding questions:**
  - "Can callers use any implementation interchangeably?"
  - "Do any implementations fail for valid inputs the interface promises to handle?"
  - "Why are isinstance checks needed—is the abstraction leaky?"

### Interface Segregation Principle
- **Author:** Robert C. Martin (SOLID)
- **Core concept:** Clients should not depend on interfaces they don't use. Fat interfaces force implementers to provide methods they don't need.
- **Why it matters:** Large interfaces force implementers to stub out unused methods; changes to unused methods cause unnecessary recompilation; clients depend on more than they need.
- **Look for:** Large interfaces where implementations leave methods empty or throw NotImplemented; clients importing interfaces and using only 20% of the methods.
- **Guiding questions:**
  - "Do all implementations actually implement all methods meaningfully?"
  - "Which clients actually use which methods?"
  - "Could this interface split into role-specific interfaces?"

### Composition over Inheritance
- **Authors:** Gang of Four (Design Patterns)
- **Core concept:** Favor composing objects over class inheritance. Compose behaviors from smaller, focused objects rather than inheriting from monolithic base classes.
- **Why it matters:** Inheritance creates tight coupling (fragile base class problem); composition is flexible and explicit. Inheritance is "is-a"; composition is "has-a" or "uses-a".
- **Look for:** Deep inheritance trees; overriding methods just to disable behavior; difficulty testing due to inherited dependencies; "God" base classes with many responsibilities.
- **Guiding questions:**
  - "Is this truly an 'is-a' relationship or a 'has-a' relationship?"
  - "Can you test this class without instantiating its parent?"
  - "What happens when you need behavior from two base classes?"

---

## 4. Domain Modeling

### Ubiquitous Language
- **Author:** Eric Evans (Domain-Driven Design)
- **Core concept:** Team shares consistent terminology in code, documentation, and conversation. Code uses the same words domain experts use.
- **Why it matters:** Inconsistent terms cause translation errors, onboarding friction, and miscommunication between developers and domain experts. Mental translation overhead slows everyone down.
- **Look for:** Same concept with different names in different places (e.g., "Item" vs "Product" vs "Article"); technical jargon instead of business terms; translation layers between business and code.
- **Guiding questions:**
  - "Would a domain expert recognize these terms?"
  - "Do different parts of the codebase use different words for the same concept?"
  - "Can you read this code aloud to a domain expert without translating?"

### Rich vs Anemic Domain Model
- **Author:** Eric Evans (term "Anemic" coined by Martin Fowler)
- **Core concept:** Domain objects should encapsulate both data AND behavior. Anemic models are data classes with no behavior; all logic lives in service classes.
- **Why it matters:** Anemic models scatter logic across service classes; objects can't protect their own invariants; leads to duplication as multiple services manipulate the same data.
- **Look for:** Data classes with no methods; service classes that manipulate external data; validation logic far from the data it validates; public setters that allow invalid state.
- **Guiding questions:**
  - "Can this object enforce its own invariants?"
  - "Do services manipulate this object's data directly?"
  - "Where does the behavior related to this concept live?"

### Bounded Contexts
- **Author:** Eric Evans (Domain-Driven Design)
- **Core concept:** Large domains should be divided into bounded contexts with explicit boundaries and translations. The same term can mean different things in different contexts.
- **Why it matters:** Prevents models from becoming bloated trying to serve all purposes; each context can evolve independently; explicit boundaries prevent accidental coupling.
- **Look for:** God objects that mean different things to different parts of the system; unclear ownership of concepts; shared models causing coordination bottlenecks.
- **Guiding questions:**
  - "Does 'Product' mean the same thing to search, recommendation, and inventory?"
  - "Who owns the definition of this concept?"
  - "Where do translations between contexts happen?"

### Aggregates & Entities
- **Author:** Eric Evans (Domain-Driven Design)
- **Core concept:** Group related entities into aggregates with a root that controls access and ensures consistency. External references only go to the root.
- **Why it matters:** Defines transaction boundaries; prevents inconsistent updates across related objects; clarifies what changes together.
- **Look for:** Uncoordinated updates to related objects; no clear boundaries for what changes together; direct access to internal objects bypassing the root.
- **Guiding questions:**
  - "What should change atomically with this object?"
  - "Can you modify child objects without going through the parent?"
  - "What are the consistency boundaries in this domain?"

---

## 5. Code Quality

### DRY (Don't Repeat Yourself)
- **Authors:** Andy Hunt & Dave Thomas (The Pragmatic Programmer)
- **Core concept:** Every piece of knowledge must have a single, unambiguous, authoritative representation within a system. Duplication of knowledge, not just code.
- **Why it matters:** Duplication means bug fixes and changes applied inconsistently; behavior drifts over time; violates single source of truth.
- **Look for:** Copy-pasted code blocks with minor variations; same business rule encoded in multiple places; duplicated validation logic.
- **Warning:** Don't over-apply. Similar-looking code might represent different concepts that should evolve independently (different bounded contexts).
- **Guiding questions:**
  - "If this business rule changes, how many places need to change?"
  - "Is this duplication of knowledge or accidental similarity?"
  - "Would extracting this create artificial coupling?"

### YAGNI (You Aren't Gonna Need It)
- **Author:** Kent Beck (Extreme Programming)
- **Core concept:** Don't implement functionality until it's actually needed. No speculative generality; no "just in case" code.
- **Why it matters:** Premature abstraction adds complexity without benefit; you'll probably guess wrong about future needs; simpler code is easier to change when you know what you actually need.
- **Look for:** Abstract classes with single implementation; configuration for hypothetical scenarios; unused extension points; overly generic designs.
- **Guiding questions:**
  - "Is this generality solving a current problem or a hypothetical future one?"
  - "How many implementations currently exist?"
  - "What evidence suggests this will be needed?"

### Principle of Least Surprise
- **Core concept:** Code should behave as readers expect; function names should describe what they do; no hidden side effects or implicit dependencies.
- **Why it matters:** Surprising behavior causes bugs from misunderstanding; developers write defensive code everywhere; cognitive load increases.
- **Look for:** Functions with hidden side effects; misleading names (e.g., `get_user` that also creates one); implicit dependencies or ordering requirements.
- **Guiding questions:**
  - "Does this function name accurately describe all it does?"
  - "Are there side effects readers wouldn't expect?"
  - "Can you call functions in any order, or is there hidden ordering?"

---

## 6. API Design & Contracts

### REST Constraints
- **Author:** Roy Fielding
- **Core concept:** Stateless, uniform interface, resource-based URLs, layered system, client-server separation. Verbs in HTTP methods, not URLs.
- **Why it matters:** Enables caching, scalability, and interoperability; clients and servers evolve independently; infrastructure can inspect and optimize requests.
- **Look for:** Stateful sessions required; inconsistent URL patterns; verbs in URLs instead of resources (e.g., `/getUser` vs `/users/{id}`); mixing resource types in one endpoint.
- **Guiding questions:**
  - "Are URLs resource-based or action-based?"
  - "Can you cache responses based on URLs alone?"
  - "Does the server maintain session state?"

### Idempotency
- **Author:** HTTP specification
- **Core concept:** Same request multiple times produces same result. Safe for GET, PUT, DELETE; not guaranteed for POST.
- **Why it matters:** Safe retries after network failures; clients can recover from uncertainty; prevents duplicate operations from network glitches.
- **Look for:** POST endpoints that should be PUT (full replacement); operations that create duplicates on retry; lack of idempotency keys for non-idempotent operations.
- **Guiding questions:**
  - "What happens if this request is sent twice?"
  - "Can clients safely retry?"
  - "Should this be PUT instead of POST?"

### Pagination
- **Core concept:** Don't return unbounded results; use cursor-based or offset pagination with stable iteration.
- **Why it matters:** Unbounded queries kill database and network; memory explodes with large result sets; timeouts on large responses.
- **Look for:** Endpoints that return all records; missing limit/offset parameters; no cursor for stable iteration over changing data.
- **Guiding questions:**
  - "What happens if this collection has 1 million items?"
  - "Can clients get results incrementally?"
  - "Is iteration stable if data changes during pagination?"

### Input Validation
- **Author:** OWASP
- **Core concept:** Never trust user input; validate at system boundaries before use. Defense in depth: validate early and often.
- **Why it matters:** Prevents injection attacks, data corruption, and crashes from malformed input; boundary validation is your security perimeter.
- **Look for:** Missing validation on API inputs; validation only on client side; trusting internal service calls without validation; late validation that allows corruption.
- **Guiding questions:**
  - "What happens if required fields are missing?"
  - "Can malformed input reach business logic?"
  - "Is validation at the boundary or deep inside?"

### API Versioning Strategies
- **Core concept:** Enable evolution without breaking existing clients. Strategies: path (/v1/), header (Accept-Version), query param (?version=1).
- **Why it matters:** Enables evolution without breaking existing clients; multiple versions can coexist; gradual migration.
- **Look for:** No versioning strategy; breaking changes to existing endpoints; no deprecation path.
- **Guiding questions:**
  - "How do you introduce breaking changes?"
  - "Can old clients continue working while new clients use new features?"
  - "What's the version migration strategy?"

### Backward Compatibility
- **Core concept:** Don't break existing clients; make additive changes only. New optional fields are safe; removing or changing existing fields breaks clients.
- **Why it matters:** Clients can't all upgrade simultaneously; breaking changes cause outages; version coordination across services becomes impossible.
- **Look for:** Removed fields; changed field types; new required fields without defaults; renamed fields.
- **Guiding questions:**
  - "Will existing clients break with this change?"
  - "Are new fields optional with defaults?"
  - "Is this change additive or breaking?"

### Request-Response vs Async
- **Core concept:** Synchronous blocking calls vs fire-and-forget asynchronous messaging. Sync is simpler but creates tight coupling; async is resilient but complex.
- **Why it matters:** Sync creates cascading latency and tight coupling; async enables resilience but complicates debugging and guarantees.
- **Look for:** Long synchronous call chains that amplify latency; blocking on operations that could be async; no async options for slow operations (>1s).
- **Guiding questions:**
  - "Does the caller need an immediate response?"
  - "What happens if this takes 30 seconds?"
  - "Is this request-response or event-driven?"

---

## 7. Resilience & Fault Tolerance

### Circuit Breaker Pattern
- **Author:** Michael Nygard (Release It!)
- **Core concept:** Stop calling a failing service; fail fast instead of waiting for timeouts. States: closed (normal), open (failing), half-open (testing recovery).
- **Why it matters:** Prevents cascade failures; allows failing services time to recover; improves user experience with fast failures instead of hanging.
- **Look for:** No circuit breakers on external calls; entire system fails when one dependency fails; no failure isolation.
- **Guiding questions:**
  - "What happens if this external service is down?"
  - "Do timeouts propagate and cascade?"
  - "Can the system degrade gracefully?"

### Retry with Backoff
- **Core concept:** Retry failed operations with exponential backoff and jitter. Don't retry immediately; don't retry forever.
- **Why it matters:** Transient failures often succeed on retry; jitter prevents thundering herd; backoff gives failing systems time to recover.
- **Look for:** No retries on transient failures (network glitches); immediate retries that overwhelm recovering services; missing jitter; infinite retries.
- **Guiding questions:**
  - "Which failures are transient vs permanent?"
  - "What happens if 1000 clients retry simultaneously?"
  - "How many retries before giving up?"

### Timeouts & Deadlines
- **Author:** Google SRE practices
- **Core concept:** Every external call needs a timeout; propagate deadlines through the call chain so downstream services know how much time remains.
- **Why it matters:** Without timeouts, failures cause threads to hang forever; resource exhaustion follows; cascading slowness.
- **Look for:** Missing timeouts on HTTP calls, database queries, external APIs; no deadline propagation; default infinite timeouts.
- **Guiding questions:**
  - "What happens if this call never returns?"
  - "How long is acceptable to wait?"
  - "Do downstream services know the deadline?"

### Bulkhead Pattern
- **Author:** Michael Nygard (Release It!)
- **Core concept:** Isolate failures to prevent spread. Separate thread pools, connection pools, rate limits per dependency.
- **Why it matters:** One slow dependency shouldn't exhaust resources for all others; blast radius containment; independent failure modes.
- **Look for:** Shared thread pools across all external calls; one slow service blocking everything; no resource isolation.
- **Guiding questions:**
  - "If this dependency is slow, what else breaks?"
  - "Are resources isolated per dependency?"
  - "Can one tenant starve others?"

---

## 10. Data Patterns & Integrity

### ACID Properties
- **Author:** Database theory (Jim Gray)
- **Core concept:** Atomicity (all-or-nothing), Consistency (invariants preserved), Isolation (concurrent transactions don't interfere), Durability (committed data survives crashes).
- **Why it matters:** Ensures data integrity; prevents partial updates and race conditions; defines correctness guarantees.
- **Look for:** Operations that should be atomic but aren't; isolation level mismatches causing race conditions; durability assumptions without proper commits.
- **Guiding questions:**
  - "What happens if this operation fails halfway?"
  - "Can concurrent requests create inconsistency?"
  - "Is this transaction boundary correct?"

### Optimistic vs Pessimistic Locking
- **Core concept:** Optimistic: detect conflicts at commit time (version checking). Pessimistic: lock records upfront to prevent conflicts.
- **Why it matters:** Optimistic scales better but requires conflict handling; pessimistic prevents conflicts but limits concurrency and risks deadlocks.
- **Look for:** Lost updates from concurrent modifications; deadlocks from pessimistic locking; no version checking; no conflict resolution.
- **Guiding questions:**
  - "How often do conflicts happen?"
  - "Can multiple users edit simultaneously?"
  - "What happens when two requests modify the same record?"

### Idempotency Keys
- **Author:** Stripe / Industry practice
- **Core concept:** Client-provided key ensures operation executes exactly once even with retries. Server stores key and returns same response for duplicates.
- **Why it matters:** Safe retries after network failures; prevents duplicate charges, duplicate records, double-processing.
- **Look for:** Non-idempotent operations that clients might retry; no deduplication mechanism; state-changing operations without idempotency keys.
- **Guiding questions:**
  - "What happens if the client retries this?"
  - "How do you prevent duplicate operations?"
  - "Can clients provide an idempotency key?"

### N+1 Query Problem
- **Core concept:** Fetching related data in a loop causes N+1 database round trips instead of one query with joins.
- **Why it matters:** Devastating performance impact; latency grows linearly with data size; database connection exhaustion.
- **Look for:** Loops that fetch related data one at a time; missing joins or batch loading; ORM lazy loading in loops.
- **Guiding questions:**
  - "How many database queries does this generate for 100 items?"
  - "Can you fetch this in one query?"
  - "Is lazy loading happening in a loop?"

### Caching Strategies
- **Core concept:** Cache-aside (application manages cache), read-through (cache loads on miss), write-through (write to cache and DB), write-behind (async write to DB).
- **Why it matters:** Reduces database load; improves latency; but introduces consistency challenges (stale data, cache invalidation).
- **Look for:** No caching on hot paths; cache invalidation bugs; stale data issues; missing cache-aside pattern; write-through without considering consistency.
- **Guiding questions:**
  - "Which data is read-heavy vs write-heavy?"
  - "How stale can this data be?"
  - "How do you invalidate the cache when data changes?"

---

## 11. Observability

### Three Pillars of Observability
- **Author:** Charity Majors (Honeycomb)
- **Core concept:** Logs (events), Metrics (aggregates), Traces (request flows)—each serves different purpose. Logs for debugging; metrics for alerting; traces for understanding flow.
- **Why it matters:** Metrics tell you something's wrong; logs help debug; traces show the path. Need all three to understand production behavior.
- **Look for:** Missing any of the three pillars; inability to debug production issues; no request tracing; unstructured logs.
- **Guiding questions:**
  - "How would you debug a slow request in production?"
  - "Can you correlate logs across services?"
  - "What metrics would alert you to this failure?"

### Structured Logging
- **Core concept:** Machine-parseable log format (JSON) with consistent fields. Include context: trace ID, user ID, request ID, timestamps.
- **Why it matters:** Enables querying, alerting, and analysis; grep doesn't scale; context enables correlation.
- **Look for:** Unstructured string logs; inconsistent formats; missing context (trace ID, user ID); interpolated variables not as fields.
- **Guiding questions:**
  - "Can you query for all logs related to a specific request?"
  - "Are logs machine-readable?"
  - "What context helps correlate related logs?"

### Health Checks & Readiness
- **Author:** Kubernetes patterns
- **Core concept:** Liveness (is the process alive?) vs Readiness (can it handle traffic?). Liveness triggers restart; readiness controls traffic routing.
- **Why it matters:** Orchestrators need to know when to restart vs when to stop sending traffic; enables zero-downtime deployments; prevents traffic to warming-up instances.
- **Look for:** Missing health endpoints; liveness checks that fail during normal load; no readiness for warm-up; deep health checks on liveness (should be lightweight).
- **Guiding questions:**
  - "What determines if this service is ready for traffic?"
  - "Should failing dependencies fail liveness or just readiness?"
  - "What triggers a restart vs removing from load balancer?"

---

## 12. Security

### Authentication vs Authorization
- **Core concept:** AuthN = who you are (identity). AuthZ = what you can do (permissions). Separate concerns.
- **Why it matters:** Conflating them leads to security holes; each requires different mechanisms; identity verification vs permission checking.
- **Look for:** Missing authorization checks after authentication; role checks in wrong places; no separation between authn and authz.
- **Guiding questions:**
  - "Can authenticated users access any data?"
  - "Where are permissions checked?"
  - "Is identity verification separate from permission checking?"

### Principle of Least Privilege
- **Author:** Security fundamentals (Saltzer & Schroeder)
- **Core concept:** Grant minimum necessary permissions; no more access than needed for the task. Applies to users, services, processes.
- **Why it matters:** Limits blast radius of compromised accounts; reduces accidental damage; principle of defense in depth.
- **Look for:** Overly broad permissions; shared admin credentials; services running as root; database users with full access.
- **Guiding questions:**
  - "Does this service need full database access or just specific tables?"
  - "Can this user read data they don't need?"
  - "What's the minimum permission set required?"

### Secrets Management
- **Author:** 12-Factor App / Industry practice
- **Core concept:** Never hardcode secrets; use vaults, environment variables, or secret managers. Secrets are credentials, API keys, encryption keys.
- **Why it matters:** Hardcoded secrets leak via version control, logs, error messages; rotation becomes impossible; blast radius of leaks grows.
- **Look for:** Secrets in code or config files; secrets in logs; secrets in error responses; no rotation mechanism.
- **Guiding questions:**
  - "Can you rotate this secret without deploying?"
  - "Are secrets in version control?"
  - "Could secrets appear in logs or errors?"

### Input Sanitization
- **Author:** OWASP
- **Core concept:** Never trust user input; sanitize to prevent injection attacks. SQL injection, XSS, command injection all stem from unsanitized input.
- **Why it matters:** Unsanitized input enables remote code execution, data theft, and system compromise.
- **Look for:** String concatenation for SQL; unescaped user content in HTML; shell commands with user input; file paths from user input.
- **Guiding questions:**
  - "Is user input escaped before database queries?"
  - "Can user input execute code?"
  - "Where does input get sanitized—boundary or deep inside?"

---

## 13. Operations

### 12-Factor App
- **Author:** Heroku / Adam Wiggins
- **Core concept:** Twelve principles for building cloud-native applications:
  1. **Codebase:** One codebase in version control, many deploys
  2. **Dependencies:** Explicitly declare and isolate dependencies
  3. **Config:** Store config in environment, not code
  4. **Backing Services:** Treat databases, queues as attached resources
  5. **Build, Release, Run:** Strictly separate stages
  6. **Processes:** Execute app as stateless processes
  7. **Port Binding:** Export services via port binding
  8. **Concurrency:** Scale out via process model
  9. **Disposability:** Fast startup, graceful shutdown
  10. **Dev/Prod Parity:** Keep development and production similar
  11. **Logs:** Treat logs as event streams
  12. **Admin Processes:** Run admin tasks as one-off processes
- **Why it matters:** Enables horizontal scaling, easy deployment, portability, resilience.
- **Look for:** Config in code; stateful processes; slow startup; environment drift; in-memory sessions; tightly coupled backing services.
- **Guiding questions:**
  - "Can you deploy to a different cloud without code changes?"
  - "Can you scale by adding more processes?"
  - "Is config separate from code?"

### Feature Flags
- **Core concept:** Decouple deployment from release; toggle features without deploying. Use flags to enable/disable features dynamically.
- **Why it matters:** Safe rollouts; A/B testing; quick rollback without redeploy; gradual rollouts; dark launches.
- **Look for:** Big bang releases; inability to disable features quickly; no gradual rollout capability; features that require deployment to enable.
- **Guiding questions:**
  - "Can you disable this feature without redeploying?"
  - "Can you roll out to 10% of users?"
  - "What's the rollback mechanism?"

### Statelessness
- **Author:** REST / 12-Factor
- **Core concept:** No server-side session state; each request contains all needed information. State lives in database, cache, or client (JWT).
- **Why it matters:** Enables horizontal scaling; any instance can handle any request; no sticky sessions; simpler load balancing.
- **Look for:** In-memory session state; sticky sessions required; can't scale horizontally; server-side state that doesn't persist.
- **Guiding questions:**
  - "Can any server handle any request?"
  - "What happens if a server restarts mid-session?"
  - "Is state in the database or in memory?"

---

## 14. Testing

### Test Pyramid
- **Author:** Mike Cohn
- **Core concept:** Many unit tests (fast, cheap, isolated), some integration tests (slower, test interactions), few E2E tests (slow, expensive, fragile). Pyramid shape.
- **Why it matters:** Inverted pyramid = slow feedback, flaky tests, unclear failures. Unit tests are fast and pinpoint failures; E2E tests are slow and obscure root causes.
- **Look for:** Missing test levels; mostly E2E tests; slow test suites; no unit tests; flaky integration tests.
- **Guiding questions:**
  - "How long do tests take to run?"
  - "Can you test this logic in isolation?"
  - "Which test level would catch this bug fastest?"

### Contract Testing
- **Author:** Pact
- **Core concept:** Verify API contracts between services without full integration tests. Consumer defines expectations; provider verifies it meets them.
- **Why it matters:** Catch breaking changes early; test in isolation without standing up full environments; faster than E2E.
- **Look for:** Breaking changes discovered in production; no contract verification between services; integration tests that require full stack.
- **Guiding questions:**
  - "How do you verify this API doesn't break consumers?"
  - "Can you test this service without its dependencies?"
  - "Are contracts explicit and tested?"

### Testing Non-Deterministic Systems
- **Core concept:** For LLMs/ML: test properties (format, constraints, ranges) not exact outputs; use mocks for determinism in unit tests; use fixtures for integration tests.
- **Why it matters:** Can't assert exact outputs from LLMs; need different testing strategies; property-based testing, output format validation, constraint checking.
- **Look for:** Flaky tests due to non-determinism; no testing of AI components; brittle exact-match assertions on LLM outputs.
- **Guiding questions:**
  - "What properties should outputs always satisfy?"
  - "Can you test the format without testing exact content?"
  - "Are tests deterministic with mocks?"

---

## 15. Failure & Exception Handling

### Fail-Fast Principle
- **Author:** Jim Shore
- **Core concept:** Detect and report errors immediately at the point of occurrence. Don't let errors propagate into corrupt state.
- **Why it matters:** Bugs surface early, close to the cause; easier to debug than errors that propagate. Prevents corruption from spreading.
- **Look for:** Errors that surface far from their cause; delayed validation; silent corruption; missing assertions.
- **Guiding questions:**
  - "Can this fail later with a confusing error instead of failing now?"
  - "Is validation at the boundary or deep inside?"
  - "Do errors get reported or swallowed?"

### Silent Failure Anti-Pattern
- **Core concept:** Swallowing exceptions hides bugs; they surface later in confusing ways. Empty catch blocks are red flags.
- **Why it matters:** Empty catch blocks turn bugs into mysteries; "it just doesn't work" with no clue why. Lost error context.
- **Look for:** Empty catch blocks; catch-and-ignore; exceptions logged but not handled; generic `pass` in except blocks.
- **Guiding questions:**
  - "What happens if this operation fails?"
  - "Is the error logged, handled, or ignored?"
  - "Will anyone know this failed?"

### Exception Propagation Strategy
- **Core concept:** Define where exceptions are caught, logged, and transformed across layers. Consistent strategy across codebase.
- **Why it matters:** Inconsistent handling leads to lost context, duplicate logging, or swallowed errors. Need clear boundaries for exception translation.
- **Look for:** Catching too early (losing context); catching too late (leaking implementation details); no consistent strategy; exceptions that escape API boundaries.
- **Guiding questions:**
  - "Where should exceptions be caught and transformed?"
  - "Does this leak implementation details to callers?"
  - "Is error handling consistent across the codebase?"

### Error Boundaries
- **Author:** React pattern / Michael Jackson
- **Core concept:** Contain failures to prevent cascade; isolate blast radius. One component's failure shouldn't crash entire system.
- **Why it matters:** Resilience through isolation; partial degradation better than total failure.
- **Look for:** Single error bringing down entire application; no isolation between components; no fallback behavior.
- **Guiding questions:**
  - "If this fails, what else fails?"
  - "Can the system partially degrade?"
  - "Are failures isolated?"

### Result Types vs Exceptions
- **Author:** Functional programming (Haskell, Rust)
- **Core concept:** Explicit error returns (Result/Either/Option) vs thrown exceptions. Result types make errors visible in signatures.
- **Why it matters:** Result types make errors explicit in type signature; exceptions are invisible. Forces callers to handle errors.
- **Look for:** Exceptions for expected cases (validation failures); missing error handling for Result types; inconsistent error signaling.
- **Guiding questions:**
  - "Is this error expected or exceptional?"
  - "Do callers know this can fail from the signature?"
  - "Should this return Result or throw?"

### Error Context Preservation
- **Core concept:** Include context when re-throwing; don't lose the original cause. Chain exceptions to preserve stack traces.
- **Why it matters:** Lost context makes debugging impossible; "null pointer exception" with no clue where or why.
- **Look for:** Re-throwing without cause; logging without context; generic error messages; missing stack traces.
- **Guiding questions:**
  - "If this fails, do you know why and where?"
  - "Is the original exception preserved?"
  - "What context helps debug this error?"

---
