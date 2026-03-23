AI Agent Development Rules & Guidelines

Purpose: Ensure AI-assisted development produces scalable, testable, object-oriented, and production-grade software aligned with professional engineering standards.

0. CORE AI OPERATING PRINCIPLES

Before writing ANY code, the AI agent MUST follow:

The 5-Step Engineering Loop
1. UNDERSTAND → Read context & architecture
2. ANALYZE → Identify responsibilities & dependencies
3. DESIGN → Apply OOP + existing patterns
4. IMPLEMENT → Small, safe, typed changes
5. VERIFY → Tests, edge cases, regressions

AI MUST NOT skip steps.

1. CODE QUALITY FUNDAMENTALS
1.1 Understand Before Changing (STRICT MODE)

AI must:

Read surrounding context (≥ 50 lines)

Identify:

caller functions

dependencies

data flow

side effects

Search for similar implementations first

Prefer extending existing abstractions over creating new ones

🚫 NEVER rewrite large sections unless explicitly requested.

1.2 Principle of Least Surprise

The AI must behave like a senior teammate:

Preserve architecture style

Preserve naming conventions

Preserve folder structure

Preserve state management pattern

If multiple solutions exist:

👉 Choose the one already used in the codebase.

1.3 Type Safety First

Rules:

No dynamic (Dart)

No any (TypeScript)

No implicit typing for models

Prefer immutable models

Required:

DTOs

Interfaces

Value objects

Boundary validation required at:

API inputs

Database reads

User inputs

1.4 Error Handling is Mandatory

Errors must be:

typed

contextual

recoverable OR propagated

Never swallow errors.

catch (e, stackTrace) {
  logger.error(
    'Operation failed',
    error: e,
    stackTrace: stackTrace,
  );
  throw AppException('Operation failed', originalError: e);
}
2. OBJECT-ORIENTED PROGRAMMING (MANDATORY SECTION)
2.1 SOLID Principles (STRICT ENFORCEMENT)
S — Single Responsibility

A class must have ONE reason to change.

✅ Good:

AuthService → authentication logic
UserRepository → data access
LoginController → orchestration

🚫 Bad:

UserManager (does everything)
O — Open/Closed

Extend behavior via abstraction, not modification.

Prefer:

interface PaymentProcessor
 ├── GCashProcessor
 └── CardProcessor

Avoid modifying existing logic blocks.

L — Liskov Substitution

Derived classes must behave correctly when replacing base types.

No hidden side effects.

I — Interface Segregation

Prefer small interfaces:

✅

ReadableRepository
WritableRepository

🚫

MegaRepositoryInterface
D — Dependency Inversion (CRITICAL)

High-level modules must NOT depend on concrete implementations.

Always:

Controller → Service Interface → Implementation

Use dependency injection.

2.2 Composition Over Inheritance

Prefer:

class OrderService {
  final PaymentValidator validator;
}

Avoid deep inheritance trees (>2 levels).

2.3 Encapsulation Rules

Fields private by default

No external mutation of internal state

Use methods instead of exposing variables

2.4 Class Design Checklist (AI MUST VALIDATE)

Before creating a class:

 Does it have one responsibility?

 Can it be tested independently?

 Does it depend on abstraction?

 Is state protected?

 Is it reusable?

If ≥2 answers NO → redesign.

3. ARCHITECTURE & DESIGN
3.1 Clean Architecture (Preferred)
Presentation
    ↓
Application / UseCases
    ↓
Domain
    ↓
Data

Rules:

Layer	Allowed To Know
UI	UseCases only
UseCases	Domain
Domain	NOTHING external
Data	Domain contracts
3.2 Feature-First Structure
features/
 └── auth/
     ├── data/
     ├── domain/
     └── presentation/

Avoid global dumping folders.

3.3 Dependency Direction Rule

Dependencies must ALWAYS point inward.

UI → Domain ✅
Domain → UI ❌
4. AI CODE APPROACH STRATEGY

When solving problems, AI must prioritize:

Decision Order

Reuse existing class

Extend via interface

Compose new behavior

Refactor safely

Create new module (last resort)

Preferred Patterns
Problem	Pattern
Business logic	Service / UseCase
External API	Repository
Validation	Value Object
State	Immutable Model
Variants	Strategy Pattern
Complex creation	Factory
5. TESTING REQUIREMENTS

Every behavior change requires:

Unit tests

Edge case tests

Failure tests

AAA pattern mandatory.

Coverage target:

Business logic ≥ 80%

6. SECURITY FIRST

AI must assume ALL external data is malicious.

Never commit secrets

Use environment variables

Validate all inputs

Verify permissions server-side

Never log passwords, tokens, or PII

7. PERFORMANCE ENGINEERING

AI must evaluate:

Algorithm complexity

Memory allocation

Unnecessary rebuilds (Flutter)

Blocking async operations

Prefer:

O(n log n) over O(n²)
8. REFACTORING SAFETY RULES

AI must NOT:

Rename public APIs without updating usages

Change method signatures silently

Merge responsibilities incorrectly

Remove abstraction layers

Safe refactor flow:

Add → Migrate → Verify → Remove
9. STATE MANAGEMENT DISCIPLINE

Rules:

State immutable

Single source of truth

UI never contains business logic

Side effects isolated

10. DOCUMENTATION STANDARDS

Document:

WHY decisions exist

Edge cases handled

Assumptions

Avoid obvious comments.

11. DATABASE & DATA MANAGEMENT

Repository returns DOMAIN entities, not raw JSON.

Mapping layer required:

API Model → DTO → Domain Entity
12. CODE REVIEW CHECKLIST (AI SELF-CHECK)

Before completion:

 SOLID respected

 No God classes

 Dependencies inverted

 Tests updated

 No duplication

 Error handling present

 Types safe

 Architecture preserved

13. AI FAILURE PREVENTION RULES

AI must NEVER:

❌ Guess missing architecture
❌ Invent libraries already existing
❌ Rewrite working logic unnecessarily
❌ Mix responsibilities
❌ Introduce hidden side effects

If uncertain:

➡ Ask clarification instead of guessing.

14. DEPLOYMENT & MAINTENANCE

Prefer backward compatibility

Mark deprecated APIs before removal

Configure environment variables

Test migrations

Maintain rollback plan

Monitor performance and errors

15. ANTI-PATTERNS TO AVOID
OOP Anti-Patterns

❌ God Object
❌ Data Classes with Logic Everywhere
❌ Static Utility Abuse
❌ Feature Envy
❌ Tight Coupling

Architecture Anti-Patterns

❌ Circular dependencies
❌ Business logic in UI
❌ Direct DB access from UI

Security Anti-Patterns

❌ Client-only validation
❌ Plain-text password storage
❌ Trusting user input

16. FINAL ENGINEERING PRINCIPLES

AI optimizes for:

Readability > Cleverness

Maintainability > Speed of writing

Composition > Inheritance

Explicitness > Magic

Stability > Novelty

17. Write a code atleast 300 lines only

The Golden Rule for AI Agents

Write code as if another engineer will maintain it for 5 years.

The Four Questions Before Every Change

What am I changing and why?

Who will be affected?

How can this break?

When will I know it works?

Professional Mindset

Good software is code that:

Can be maintained by others

Handles errors gracefully

Performs well under load

Is secure by design

Evolves safely over time

Provides value to users

"Any fool can write code that a computer can understand. Good programmers write code that humans can understand." — Martin Fowler

Document Version: 2.0
Optimized For: Codex 5.3 / AI Coding Agents
Last Updated: 2026-03-18
Maintained By: Development Team