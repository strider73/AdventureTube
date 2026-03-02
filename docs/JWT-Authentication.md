# JWT Authentication System

**⚠️ CRITICAL SECURITY COMPONENT - Handle with extreme care!**

[← Back to CLAUDE.md](../CLAUDE.md)

---

## Table of Contents
1. [Architecture Overview](#architecture-overview)
2. [Token Storage](#1-token-storage)
3. [Token Lifecycle Management](#2-token-lifecycle-management)
4. [Authentication Flow](#3-authentication-flow)
5. [Error Handling](#4-error-handling)
6. [Security Features](#5-security-features)
7. [Token Flow Diagram](#6-token-flow-diagram)
8. [Data Transfer Objects](#7-data-transfer-objects)
9. [Critical Files](#critical-files)
10. [Best Practices](#when-working-with-authentication)

---

## Architecture Overview

AdventureTube uses **hybrid authentication**:
1. **Google OAuth** → User signs in with Google
2. **Google ID Token** → Sent to AdventureTube backend
3. **JWT Tokens** → Backend returns access + refresh tokens
4. **API Authorization** → JWT access token used for all API calls

---

## 1. Token Storage

### UserModel.swift

**Token Structure:**
```swift
struct UserModel: Codable {
    // AdventureTube JWT Tokens
    var adventuretubeJWTToken: String?           // Access token (short-lived)
    var adventuretubeRefreshJWTToken: String?    // Refresh token (long-lived)

    // Google Authentication
    var idToken: String?                         // Google ID token
    var googleUserId: String?

    // User Identity
    var adventureTube_id: UUID?
}
```

### Tokens Explained

| Token | Purpose | Lifetime | Storage |
|-------|---------|----------|---------|
| `adventuretubeJWTToken` | API authorization | Short-lived | UserDefaults |
| `adventuretubeRefreshJWTToken` | Token renewal | Long-lived | UserDefaults |
| `idToken` | Google authentication | Session | UserDefaults |

---

## 2. Token Lifecycle Management

### LoginManager.swift

#### On Sign In
```swift
case .signedIn:
    saveUserStateToUserDefault()  // Persists tokens to UserDefaults
```

#### On Sign Out
```swift
case .signedOut:
    userData.adventuretubeJWTToken = nil
    userData.adventuretubeRefreshJWTToken = nil
    userData.idToken = nil
    userData.signed_in = false
    saveUserStateToUserDefault()
```

### Persistence
All tokens are saved to `UserDefaults` via `ObjectSavable` protocol

⚠️ **Security Note:** Consider migrating to Keychain for production

---

## 3. Authentication Flow

### A. User Registration

**Endpoint:** `POST /auth/users`

**Function:**
```swift
func registerUser(adventureUser: UserModel) -> AnyPublisher<AuthResponse, Error>
```

**Process:**
1. Sends Google ID token to backend
2. Backend validates with Google
3. Returns: `{ userId, accessToken, refreshToken }`

**Request Body:**
```json
{
  "googleIdToken": "...",
  "email": "user@example.com"
}
```

---

### B. Login (Token Exchange)

**Endpoint:** `POST /auth/token`

**Function:**
```swift
func loginWithPassword(adventureUser: UserModel) -> AnyPublisher<AuthResponse, Error>
```

**Process:**
1. Exchanges Google ID token for AdventureTube JWT tokens
2. Returns new access + refresh token pair

**Request Body:**
```json
{
  "googleIdToken": "..."
}
```

---

### C. Token Refresh

**Endpoint:** `POST /auth/refreshToken`

**Function:**
```swift
func refreshToken(adventureUser: UserModel) -> AnyPublisher<AuthResponse, Error>
```

**Headers:**
```
Authorization: <refreshToken>
Content-Type: application/json
```

**Request Body:**
```json
{
  "googleIdToken": "..."
}
```

**Process:**
1. Used when access token expires (401 error)
2. Requires valid refresh token in Authorization header
3. Returns new access + refresh token pair

**⚠️ IMPORTANT:** No automatic refresh on 401 - must be triggered manually

---

### D. Logout

**Endpoint:** `POST /auth/logout`

**Function:**
```swift
func signOut() -> AnyPublisher<RestAPIResponse, Error>
```

**Headers:**
```
Authorization: <refreshToken>
```

**Process:**
1. Invalidates refresh token on server
2. Client clears all tokens locally via `loginState = .signedOut`

---

## 4. Error Handling

### HTTP Status Codes

**AdventureTubeAPIService.swift - handleHttpResponse()**

```swift
switch httpResponse.statusCode {
    case 200...299:
        // Success - decode response
        return try JSONDecoder().decode(decodingType, from: result.data)

    case 401:
        // Unauthorized - token expired/invalid
        throw BackendError.unauthorized(message: errorMessage)

    case 404:
        // Not Found - user doesn't exist
        throw BackendError.notFound(message: errorMessage)

    case 409:
        // Conflict - duplicate registration
        throw BackendError.conflict(message: errorMessage)

    case 500:
        // Server Error
        throw BackendError.internalServerError(message: errorMessage)

    default:
        throw BackendError.serverError(message: errorMessage)
}
```

### Custom Error Types

**BackendError:**
```swift
enum BackendError: LocalizedError {
    case unauthorized(message: String)
    case notFound(message: String)
    case internalServerError(message: String)
    case serverError(message: String)
    case decodingError(message: String)
    case unknownError

    var errorDescription: String? { ... }
}
```

**NetworkError:**
```swift
enum NetworkError: Error {
    case invalidURL
    case responseError
    case unknown
}
```

---

## 5. Security Features

### ✅ Implemented

- JWT-based authentication (access + refresh tokens)
- Refresh tokens stored in Authorization header (not body)
- Google ID token validation on backend
- Automatic token cleanup on sign out
- UserDefaults persistence with Codable
- Private access control on token properties
- Error decoding with user-friendly messages

### ⚠️ Security Considerations

- Tokens stored in UserDefaults (not Keychain)
- No automatic token refresh on 401 errors
- No client-side token expiration checking
- 600-second timeout (very long - consider reducing)
- No token rotation strategy
- Google ID token sent on every refresh (dependency on Google)

### 🔒 Recommendations for Production

1. **Migrate to Keychain** - More secure token storage
2. **Implement 401 Interceptor** - Auto-refresh tokens on unauthorized errors
3. **Add Token Expiration** - Client-side expiry checking
4. **Reduce Timeout** - 30-60 seconds is more appropriate
5. **Implement Certificate Pinning** - Prevent MITM attacks
6. **Add Biometric Lock** - Require Face ID/Touch ID for sensitive operations

---

## 6. Token Flow Diagram

```
┌─────────────┐     Google OAuth      ┌──────────────┐
│   iOS App   │ ───────────────────> │ Google Auth  │
└─────────────┘                       └──────────────┘
      │                                       │
      │  1. Get Google ID Token              │
      │ <─────────────────────────────────────┘
      │
      │  2. Send Google ID Token
      │ ───────────────────────────────────────┐
      │                                         ▼
      │                              ┌──────────────────────┐
      │                              │ AdventureTube Backend│
      │                              │ (Spring Boot)        │
      │                              └──────────────────────┘
      │                                         │
      │  3. Receive JWT Tokens                 │
      │ <───────────────────────────────────────┘
      │    { accessToken, refreshToken }
      │
      │  4. Store in UserDefaults
      │ ──> UserModel.adventuretubeJWTToken
      │ ──> UserModel.adventuretubeRefreshJWTToken
      │
      │  5. Use Access Token for API Calls
      │ ───────────────────────────────────────>
      │
      │  6. When Access Token Expires (401)
      │ ───> Manual refresh with refreshToken
      │ ───────────────────────────────────────>
      │
      │  7. Get New Token Pair
      │ <───────────────────────────────────────
```

---

## 7. Data Transfer Objects

### AuthResponse

**File:** `AuthResponse.swift`

```swift
struct AuthResponse: Codable {
    let userId: UUID?           // AdventureTube user ID
    let accessToken: String?    // JWT access token
    let refreshToken: String?   // JWT refresh token
    let errorMessage: String?   // Error details if failed
}
```

### RestAPIResponse

```swift
struct RestAPIResponse: Codable {
    let success: Bool
    let message: String?
}
```

---

## Critical Files

| File | Purpose | Location |
|------|---------|----------|
| **LoginManager.swift** | Global auth state, token lifecycle | `Services/LoginService/` |
| **AdventureTubeAPIService.swift** | All JWT API endpoints | `Services/APIService/Adventuretube/` |
| **UserModel.swift** | Token storage structure | `Models/User/` |
| **AuthResponse.swift** | Backend response DTO | `Services/APIService/Adventuretube/DTO/` |
| **GoogleLoginService.swift** | Google OAuth implementation | `Services/LoginService/Service/` |

---

## Key Takeaways

1. **Hybrid Authentication:** Google OAuth → AdventureTube JWT
2. **Token Types:** Access token (API calls) + Refresh token (token renewal)
3. **No Automatic Refresh:** Manual token refresh required (no 401 interceptor)
4. **Singleton Pattern:** `LoginManager.shared` manages global auth state
5. **Reactive:** `@Published` properties trigger UI updates
6. **Persistence:** UserDefaults (consider upgrading to Keychain for production)

---

## When Working with Authentication

### 🔴 NEVER

1. Log tokens in production code
2. Store tokens in separate locations
3. Hardcode tokens or credentials
4. Skip token validation
5. Ignore 401 errors

### ✅ ALWAYS

1. Use `LoginManager.shared.userData` for tokens
2. Clear tokens on sign out via `loginState = .signedOut`
3. Test token refresh flow thoroughly
4. Validate backend responses for token presence
5. Handle auth errors gracefully in UI
6. Check token existence before API calls

### 📋 Checklist for Auth Changes

- [ ] Test sign in flow
- [ ] Test sign out flow
- [ ] Test token refresh
- [ ] Test 401 error handling
- [ ] Verify token persistence
- [ ] Check for token leaks in logs
- [ ] Test with expired tokens
- [ ] Verify proper cleanup on logout

---

## Related Documentation

- [Core Data Architecture](./CoreData-Architecture.md) - Data persistence
- [Combine Reactive Programming](./Combine-Reactive.md) - Reactive patterns
- [YouTube API Integration](./YouTube-API-Integration.md) - API authentication

---

[← Back to CLAUDE.md](../CLAUDE.md)
