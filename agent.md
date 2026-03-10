# AI Agent Development Rules & Guidelines

**Purpose**: Ensure AI-assisted development produces reliable, maintainable, and production-ready software.

---

## 1. CODE QUALITY FUNDAMENTALS

### 1.1 Always Understand Before Changing
- **NEVER** modify code without reading and understanding the existing implementation
- Read at least 50 lines of context around the target code
- Trace dependencies and imports before making changes
- Understand the full execution flow, not just the immediate function

### 1.2 Principle of Least Surprise
- Follow existing code patterns and conventions in the codebase
- Don't introduce new paradigms without explicit request
- Match naming conventions, file structure, and architectural patterns already in use
- If the codebase uses `camelCase`, don't switch to `snake_case`

### 1.3 Type Safety First
- Always use strong typing (avoid `dynamic` in Dart, `any` in TypeScript)
- Define interfaces/models before implementation
- Use null-safety features of the language
- Validate data at boundaries (API responses, user inputs, external data)

### 1.4 Error Handling is Not Optional
```dart
// BAD - Silent failures
try {
  await riskyOperation();
} catch (e) {
  print(e); // Never do this in production
}

// GOOD - Proper error handling
try {
  await riskyOperation();
} catch (e, stackTrace) {
  logger.error('Failed to perform operation', error: e, stackTrace: stackTrace);
  // Either recover or propagate with context
  throw CustomException('Operation failed: ${e.toString()}', originalError: e);
}
```

---

## 2. TESTING REQUIREMENTS

### 2.1 Test Coverage Rules
- Every new function/method must have corresponding tests
- Aim for 80%+ code coverage for business logic
- Test both happy paths AND edge cases
- Include negative test cases (what happens when things go wrong)

### 2.2 Test Types Required
1. **Unit Tests**: Individual functions/methods
2. **Integration Tests**: Module interactions
3. **Widget Tests**: UI components (Flutter/React)
4. **E2E Tests**: Critical user flows

### 2.3 Test Quality Standards
```dart
// Every test needs:
test('descriptive name explaining what is being tested', () {
  // 1. ARRANGE - Set up test data
  final service = MyService();
  
  // 2. ACT - Execute the function
  final result = service.doSomething();
  
  // 3. ASSERT - Verify the outcome
  expect(result, expectedValue);
});
```

---

## 3. SECURITY FIRST MINDSET

### 3.1 Never Commit Secrets
- API keys, passwords, tokens belong in environment variables
- Use `.env` files (excluded from git)
- Validate `.gitignore` before committing sensitive configs
- Check for accidental secret exposure before pushing

### 3.2 Input Validation
- **ALL** user inputs are untrusted
- Validate, sanitize, and escape user data
- Use parameterized queries (prevent SQL injection)
- Validate file uploads (type, size, content)

### 3.3 Authentication & Authorization
- Never trust client-side validation alone
- Verify permissions on server/backend for every operation
- Use secure token storage (secure storage, keychain)
- Implement proper session management

### 3.4 Data Protection
```dart
// BAD - Exposing sensitive data
print('User password: $password');
logger.info('Credit card: $ccNumber');

// GOOD - Protecting sensitive data
logger.info('User authenticated: ${user.id}');
// Never log passwords, tokens, or PII
```

---

## 4. ARCHITECTURE & DESIGN PATTERNS

### 4.1 Separation of Concerns
- **UI Layer**: Presentation only (widgets, screens)
- **Business Logic Layer**: Services, controllers, state management
- **Data Layer**: Repositories, API clients, database access
- Each layer should be independently testable

### 4.2 Dependency Management
- Use dependency injection
- Avoid hardcoded dependencies
- Make components loosely coupled
- Program to interfaces, not implementations

### 4.3 State Management Rules (Flutter/React)
- Keep state as local as possible
- Lift state only when necessary
- Use immutable state objects
- Follow unidirectional data flow

### MOST OF ALL FOLLOW THE OOP PRINCIPLES

### 4.4 File Organization
```
lib/
├── core/              # App-wide utilities, constants
│   ├── config/
│   ├── errors/
│   └── utils/
├── features/          # Feature-based organization
│   ├── auth/
│   │   ├── data/     # Repositories, models
│   │   ├── domain/   # Business logic
│   │   └── presentation/  # UI
│   └── profile/
└── shared/           # Shared across features
    ├── components/
    ├── models/
    └── services/
```

---

## 5. PERFORMANCE CONSIDERATIONS

### 5.1 Optimize Early, But Not Prematurely
- Profile before optimizing
- Focus on algorithmic complexity first (O(n²) → O(n log n))
- Cache expensive operations
- Use pagination for large data sets

### 5.2 Resource Management
```dart
// ALWAYS dispose resources
class MyWidget extends StatefulWidget {
  late StreamSubscription _subscription;
  late TextEditingController _controller;
  
  @override
  void dispose() {
    _subscription.cancel();
    _controller.dispose();
    super.dispose();
  }
}
```

### 5.3 Network Efficiency
- Implement proper caching strategy
- Use compression for API responses
- Lazy load images and assets
- Implement retry logic with exponential backoff

---

## 6. CODE DOCUMENTATION

### 6.1 When to Document
- Public APIs and interfaces: **ALWAYS**
- Complex algorithms: **ALWAYS**
- Business logic with non-obvious requirements: **ALWAYS**
- Simple getters/setters: **RARELY**

### 6.2 Documentation Standards
```dart
/// Fetches user profile data from the backend.
///
/// This method implements caching with a 5-minute TTL.
/// Throws [NetworkException] if the request fails.
/// Throws [UnauthorizedException] if the token is invalid.
///
/// Parameters:
///   - [userId]: The unique identifier of the user
///   - [forceRefresh]: Skip cache and fetch fresh data
///
/// Returns: A [UserProfile] object or null if user not found
Future<UserProfile?> fetchUserProfile(
  String userId, {
  bool forceRefresh = false,
}) async {
  // Implementation
}
```

### 6.3 README Requirements
Every feature module should have a README explaining:
- Purpose and responsibility
- Key components
- Dependencies
- How to test
- Known limitations

---

## 7. VERSION CONTROL PRACTICES

### 7.1 Commit Message Format
```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types**: `feat`, `fix`, `refactor`, `test`, `docs`, `chore`, `style`, `perf`

**Examples**:
```
feat(auth): add biometric authentication support

- Implement fingerprint and face ID
- Add settings toggle for biometric login
- Update security documentation

Closes #123
```

### 7.2 Commit Best Practices
- One logical change per commit
- Never commit commented-out code (delete it, git remembers)
- Never commit debug logs or temporary test code
- Run tests before committing
- Keep commits focused and atomic

### 7.3 Branch Strategy
- `main/master`: Production-ready code only
- `develop`: Integration branch
- `feature/feature-name`: New features
- `fix/bug-description`: Bug fixes
- `hotfix/critical-issue`: Emergency production fixes

---

## 8. ERROR HANDLING & LOGGING

### 8.1 Error Hierarchies
```dart
// Define custom exception types
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;
  
  AppException(this.message, {this.code, this.originalError});
}

class NetworkException extends AppException { }
class ValidationException extends AppException { }
class BusinessLogicException extends AppException { }
```

### 8.2 Logging Levels
- **ERROR**: Something failed, needs attention
- **WARN**: Unexpected but handled situation
- **INFO**: Important business events
- **DEBUG**: Detailed diagnostic information (dev only)

### 8.3 User-Facing Errors
```dart
// BAD - Technical jargon to users
"NullPointerException at line 45"

// GOOD - User-friendly message
"Unable to load your profile. Please try again."
```

---

## 9. API & BACKEND INTEGRATION

### 9.1 API Client Structure
- Centralize API configuration
- Use interceptors for auth, logging, error handling
- Implement request/response models
- Handle network timeouts gracefully

### 9.2 Response Handling
```dart
// Always handle all response scenarios
final response = await apiClient.get('/users');

switch (response.statusCode) {
  case 200:
    return UserModel.fromJson(response.data);
  case 401:
    throw UnauthorizedException();
  case 404:
    return null; // User not found
  case 500:
    throw ServerException();
  default:
    throw UnexpectedResponseException(response.statusCode);
}
```

### 9.3 Offline Support
- Implement local caching
- Queue operations when offline
- Sync when connection restored
- Provide clear offline indicators to users

---

## 10. MOBILE-SPECIFIC RULES (Flutter/React Native)

### 10.1 Platform Awareness
- Test on both iOS and Android
- Handle platform-specific behaviors
- Use platform-specific UI patterns when appropriate
- Consider different screen sizes and orientations

### 10.2 Build Size Management
- Use lazy loading for features
- Optimize image assets
- Remove unused dependencies
- Implement code splitting where possible

### 10.3 Battery & Memory
- Minimize background processing
- Cancel timers and streams when not needed
- Optimize image loading and caching
- Profile memory usage regularly

---

## 11. DATABASE & DATA MANAGEMENT

### 11.1 Data Modeling
- Normalize data appropriately
- Define clear relationships
- Use indexes for frequently queried fields
- Consider migration strategies from day one

### 11.2 Query Optimization
```dart
// BAD - N+1 query problem
for (var user in users) {
  final posts = await db.query('SELECT * FROM posts WHERE user_id = ?', [user.id]);
}

// GOOD - Single query with join
final results = await db.query('''
  SELECT users.*, posts.* 
  FROM users 
  LEFT JOIN posts ON users.id = posts.user_id
''');
```

### 11.3 Data Migration Safety
- Always create backups before migration
- Test migrations on copy of production data
- Make migrations reversible when possible
- Version your schema

---

## 12. CODE REVIEW CHECKLIST

Before submitting code for review (or considering it done):

- [ ] Code compiles without warnings
- [ ] All tests pass (unit, integration, widget)
- [ ] No hardcoded values (use constants/config)
- [ ] No secrets in code
- [ ] Error handling implemented
- [ ] Logging added for important operations
- [ ] Documentation updated
- [ ] Performance impact considered
- [ ] Accessibility considered (a11y)
- [ ] Works on target platforms
- [ ] No commented-out code
- [ ] No debug print statements
- [ ] Code follows project conventions
- [ ] Dependencies updated in pubspec/package.json
- [ ] Breaking changes documented

---

## 13. AI AGENT SPECIFIC RULES

### 13.1 Context Gathering
- **ALWAYS** read existing code before modification
- Search for similar implementations in the codebase
- Understand project structure and patterns
- Check for existing utilities before creating new ones

### 13.2 Multi-File Changes
- Consider impact across all affected files
- Update tests when changing implementation
- Update documentation when changing public APIs
- Use multi_replace for efficiency

### 13.3 Incremental Development
```
1. Understand the requirement
2. Search for existing patterns
3. Read relevant code files
4. Plan the implementation
5. Implement with tests
6. Verify no errors introduced
7. Update documentation
8. Confirm completion
```

### 13.4 When Uncertain
- Search the codebase for existing solutions
- Check project documentation
- Ask clarifying questions rather than guessing
- Suggest multiple approaches when appropriate

### 13.5 Breaking Changes
- Identify all usages before modifying public APIs
- Update all call sites
- Consider deprecation path for major changes
- Document migration steps

---

## 14. DEPLOYMENT & PRODUCTION

### 14.1 Pre-Deployment Checklist
- [ ] All environment variables configured
- [ ] Database migrations tested
- [ ] Backup strategy in place
- [ ] Rollback plan documented
- [ ] Monitoring and alerts configured
- [ ] Performance benchmarks met
- [ ] Security scan completed
- [ ] Load testing passed (if applicable)

### 14.2 Configuration Management
```dart
// Use environment-specific configs
class Config {
  static final String apiUrl = Platform.environment['API_URL'] ?? 'https://api.prod.com';
  static final bool debugMode = Platform.environment['DEBUG'] == 'true';
  static final String sentryDsn = Platform.environment['SENTRY_DSN'] ?? '';
}
```

### 14.3 Monitoring & Observability
- Log critical operations
- Track error rates
- Monitor API latency
- Set up crash reporting (Sentry, Firebase Crashlytics)
- Track key business metrics

---

## 15. MAINTENANCE & TECHNICAL DEBT

### 15.1 Boy Scout Rule
**"Leave the code better than you found it"**
- Refactor when you touch code
- Fix minor issues you encounter
- Improve naming and documentation
- Don't create new technical debt

### 15.2 Deprecation Strategy
```dart
@Deprecated('Use fetchUserProfile instead. Will be removed in v2.0')
Future<User> getUser(String id) {
  return fetchUserProfile(id);
}
```

### 15.3 Dependency Updates
- Review dependencies quarterly
- Check for security vulnerabilities
- Test thoroughly after updates
- Document breaking changes

---

## 16. ACCESSIBILITY (A11Y)

### 16.1 Always Consider
- Screen reader support
- Sufficient color contrast
- Keyboard navigation
- Text scaling support
- Semantic labels for interactive elements

```dart
// Add semantic labels
Semantics(
  label: 'Submit form',
  button: true,
  child: ElevatedButton(
    onPressed: _submitForm,
    child: Text('Submit'),
  ),
)
```

---

## 17. FINAL PRINCIPLES

### The Four Questions Before Every Change:
1. **What** am I changing and why?
2. **Who** will be affected by this change?
3. **How** can this break?
4. **When** will I know if it works?

### Code is Read More Than Written
- Optimize for readability
- Use descriptive names
- Keep functions small and focused
- Prefer clarity over cleverness

### Production is Not a Testing Environment
- Test thoroughly locally
- Use staging environment
- Have rollback strategy
- Monitor after deployment

### Technical Excellence Enables Business Agility
- Good architecture allows fast changes
- Automated tests enable confidence
- Clean code reduces bugs
- Documentation saves time

---

## 18. ANTI-PATTERNS TO AVOID

### 18.1 Code Smells
- ❌ God objects (classes that do everything)
- ❌ Deeply nested conditionals (> 3 levels)
- ❌ Long functions (> 50 lines)
- ❌ Duplicate code (DRY principle)
- ❌ Magic numbers (use named constants)
- ❌ Excessive comments (code should be self-documenting)

### 18.2 Architecture Smells
- ❌ Circular dependencies
- ❌ Tight coupling between layers
- ❌ Business logic in UI layer
- ❌ Direct database access from UI

### 18.3 Security Anti-Patterns
- ❌ Client-side validation only
- ❌ Storing passwords in plain text
- ❌ Using `eval()` or equivalent
- ❌ Trusting user input

---

## SUMMARY: THE PROFESSIONAL DEVELOPER MINDSET

1. **Quality is not negotiable** - Don't cut corners
2. **Tests are documentation** - They show how code should be used
3. **Security is everyone's job** - Not just the security team
4. **Performance matters** - Users notice slow apps
5. **Backward compatibility** - Don't break existing code unnecessarily
6. **Measure before optimizing** - Profile, don't guess
7. **Document decisions, not code** - Explain WHY, not WHAT
8. **Automate repetitive tasks** - Use scripts and tools
9. **Stay current but stable** - Balance innovation with reliability
10. **Communicate constantly** - Especially about blockers and risks

---

**Remember**: Good software is not just code that works. It's code that:
- Can be maintained by others
- Handles errors gracefully
- Performs well under load
- Is secure by design
- Can evolve over time
- Provides value to users

---

*"Any fool can write code that a computer can understand. Good programmers write code that humans can understand."* — Martin Fowler

---

**Document Version**: 1.0  
**Last Updated**: 2026-02-22  
**Maintained By**: Development Team
