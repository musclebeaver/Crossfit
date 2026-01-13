---
trigger: always_on
---

# Project Context
- Project Name: Crossfit-Competition-Platform
- Description: A CrossFit competition platform with Box management, Daily WODs, and Real-time Rankings.
- Tech Stack: Java 17+, Spring Boot 3.x, Spring Security, Spring Data JPA, MySQL, Redis, Gradle.
- Auth: JWT based Authentication, OAuth2 (Google, Kakao).

# Coding Guidelines
1. **Architecture**: Use a Domain-Driven Design (DDD) approach. Organize packages by domain features (e.g., user, box, wod, record) rather than layers.
2. **Entity & DTO**:
   - Never expose Entity classes directly in Controllers. Always use DTOs (Request/Response).
   - Use `@Builder` for object creation.
   - Use JPA Auditing for `createdAt` and `updatedAt`.
3. **Error Handling**:
   - Use a global `@RestControllerAdvice` to handle exceptions.
   - Return standardized `ApiResponse<T>` wrapper for all API responses.
4. **Business Logic**:
   - All business logic must reside in Service classes, not Controllers.
   - Complex ranking logic (AMRAP vs For Time) should use the Strategy Pattern or clear conditional logic in the Service layer.
5. **Database**:
   - Use snake_case for column names in DB, camelCase in Java.
   - Indexing is crucial for the Ranking/Record table.
6. **Documentation**: Add Swagger/OpenAPI annotations to all Controller endpoints.

# Key Business Rules
- **WOD Types**:
  - AMRAP: Rank by highest reps (Score DESC).
  - FOR_TIME: Rank by lowest time (Score ASC). If time capped, rank lower than finished users.
  - EMOM: Pass/Fail or Round based.
- **Ranking**:
  - Rx'd (Prescribed) records always rank higher than Scaled records, regardless of the score.