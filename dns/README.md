# Domain Name System

The gurted DNS is built with Rust (Actix Web) and PostgreSQL. It provides endpoints to create, read, update, and delete domain information, along with rate limiting for certain operations.

## Table of Contents

- [Authentication Endpoints](#authentication-endpoints)
  - [POST /auth/register](#post-authregister)
  - [POST /auth/login](#post-authlogin)
  - [GET /auth/me](#get-authme)
  - [POST /auth/invite](#post-authinvite)
  - [POST /auth/redeem-invite](#post-authredeem-invite)
  - [GET /auth/domains](#get-authdomains) *
- [Domain Endpoints](#domain-endpoints)
  - [GET /](#get-)
  - [POST /domain](#post-domain) *
  - [GET /domain/:name/:tld](#get-domainnametld)
  - [PUT /domain/:name/:tld](#put-domainnametld) *
  - [DELETE /domain/:name/:tld](#delete-domainnametld) *
  - [GET /domains](#get-domains)
  - [GET /tlds](#get-tlds)
  - [POST /domain/check](#post-domaincheck)

* = Requires authentication

## Authentication Endpoints

### POST /auth/register

Register a new user account. New users have a limit of 3 domain registrations by default.

**Request:**
```json
{
  "username": "myusername",
  "password": "mypassword"
}
```

**Response:**
```json
{
  "token": "jwt-token-here",
  "user": {
    "id": 1,
    "username": "myusername",
    "registrations_remaining": 3,
    "created_at": "2023-01-01T00:00:00Z"
  }
}
```

### POST /auth/login

Login with existing credentials.

**Request:**
```json
{
  "username": "myusername",
  "password": "mypassword"
}
```

**Response:**
```json
{
  "token": "jwt-token-here",
  "user": {
    "id": 1,
    "username": "myusername",
    "registrations_remaining": 2,
    "created_at": "2023-01-01T00:00:00Z"
  }
}
```

### GET /auth/me *

Get current user information. Requires `Authorization: Bearer <token>` header.

**Response:**
```json
{
  "id": 1,
  "username": "myusername",
  "registrations_remaining": 2,
  "created_at": "2023-01-01T00:00:00Z"
}
```

### POST /auth/invite *

Create an invite code that can be redeemed for 3 additional domain registrations. Requires authentication but does NOT consume any of the registrations of the inviting user.

**Response:**
```json
{
  "invite_code": "abc123def456"
}
```

### POST /auth/redeem-invite *

Redeem an invite code to get 3 additional domain registrations. Requires authentication.

**Request:**
```json
{
  "invite_code": "abc123def456"
}
```

**Response:**
```json
{
  "message": "Invite code redeemed successfully",
  "registrations_added": 3
}
```

### GET /auth/domains *

Get all domains owned by the authenticated user, including their status. Requires authentication.

**Query Parameters:**
- `page` - Page number (default: 1)
- `limit` - Items per page (default: 100, max: 1000)

**Response:**
```json
{
  "domains": [
    {
      "name": "myawesome",
      "tld": "dev",
      "ip": "192.168.1.100",
      "status": "approved",
      "denial_reason": null
    },
    {
      "name": "pending",
      "tld": "fr", 
      "ip": "10.0.0.1",
      "status": "pending",
      "denial_reason": null
    },
    {
      "name": "rejected",
      "tld": "mf",
      "ip": "172.16.0.1", 
      "status": "denied",
      "denial_reason": "Invalid IP address"
    }
  ],
  "page": 1,
  "limit": 100
}
```

**Status Values:**
- `pending` - Domain is awaiting approval
- `approved` - Domain has been approved and is active
- `denied` - Domain was rejected (see `denial_reason` for details)

## Domain Endpoints

### GET /

Returns a simple message with the available endpoints and rate limits.

**Response:**

```
Hello, world! The available endpoints are:
GET /domains,
GET /domain/{name}/{tld},
POST /domain,
PUT /domain/{key},
DELETE /domain/{key},
GET /tlds.
Ratelimits are as follows: 10 requests per 60s.
```

### POST /domain *

Submit a domain for approval. Requires authentication and consumes one registration slot. The request will be sent to the moderators via discord for verification.

**Request:**
```json
{
  "tld": "dev",
  "ip": "192.168.1.100",
  "name": "myawesome"
}
```

**Error Responses:**
- `401 Unauthorized` - Missing or invalid JWT token
- `400 Bad Request` - No registrations remaining, invalid domain, or offensive name
- `409 Conflict` - Domain already exists

### GET /domain/:name/:tld

Fetch an approved domain by name and TLD. Only returns domains with 'approved' status.

**Response:**
```json
{
  "tld": "dev",
  "name": "myawesome",
  "ip": "192.168.1.100"
}
```

### PUT /domain/:name/:tld *

Update the IP address of the user's approved domain.

**Request:**
```json
{
  "ip": "10.0.0.50"
}
```

**Response:**
```json
{
  "ip": "10.0.0.50"
}
```

### DELETE /domain/:name/:tld *

Delete a domain owned by the account.

**Response:**
- `200 OK` - Domain deleted successfully
- `404 Not Found` - Domain not found or not owned by the requesting account

### GET /domains

Fetch all approved domains with pagination support.

**Query Parameters:**
- `page` - Page number (default: 1)
- `page_size` (or `s`, `size`, `l`, `limit`) - Items per page (default: 15, max: 100)

**Response:**
```json
{
  "domains": [
    {
      "tld": "dev",
      "name": "myawesome",
      "ip": "192.168.1.100"
    }
  ],
  "page": 1,
  "limit": 15
}
```

### GET /tlds

Get the list of allowed top-level domains.

**Response:**
```json
["mf", "btw", "fr", "yap", "dev", "scam", "zip", "root", "web", "rizz", "habibi", "sigma", "now", "it", "soy", "lol", "uwu", "ohio", "cat"]
```

### POST /domain/check

Check if domain name(s) are available.

**Request:**
```json
{
  "name": "myawesome",
  "tld": "dev"  // Optional - if omitted, checks all TLDs
}
```

**Response:**
```json
[
  {
    "domain": "myawesome.dev",
    "taken": false
  }
]
```

## Discord Integration

When a user submits a domain registration, it's automatically sent to the configured Discord channel with:

- 📝 Domain details (name, TLD, IP, user info)
- ✅ **Approve** button - Marks domain as approved
- ❌ **Deny** button - Opens a modal for inputing a denial reason

Discord admins can approve or deny registrations directly from Discord.

## Configuration

Copy `config.template.toml` to `config.toml` and configure your settings.

## Rate Limits

- **Domain Registration**: 5 requests per 10 minutes (per IP)
- **General API**: No specific limits (yet)

## Domain Registration Limits

- **User Limit**: Each user has a finite number of domain registrations
- **Usage**: Each domain submission consumes 1 registration from your account
- **Replenishment**: Use invite codes to get more registrations (3 per invite)

## User Registration & Invites

- **Registration**: Anyone can register - no invite required
- **New Users**: Start with 3 domain registrations automatically
- **Invite Creation**: Any authenticated user can create invite codes (no cost)
- **Invite Redemption**: Redeem invite codes for 3 additional domain registrations
- **Invite Usage**: Each invite code can only be redeemed once
