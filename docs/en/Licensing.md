# Stirling PDF Licensing

This document describes the licensing model of Stirling PDF and its implications for enterprise deployments.

## Overview

Stirling PDF uses a **dual licensing model**:

- **Core Features**: MIT License (Open Source)
- **Enterprise Features**: Proprietary license via [Keygen.sh](https://keygen.sh)

## User Limits

| License Type | User Limit | OAuth/SSO | SAML |
|-------------|-----------|-----------|------|
| Free | 5 users | No | No |
| Server | Unlimited | Yes | No |
| Enterprise | License-defined | Yes | Yes |

## Grandfathering

Users who had Stirling PDF installed before the licensing model was introduced benefit from "grandfathering":

- The user count at migration time is preserved
- These users remain allowed even without a license
- New users beyond the grandfathered count require a license

**Example**: If you had 12 users in V1, after upgrading to V2 those 12 remain allowed. User 13+ requires a license.

## Technical Implementation

### License Validation

Stirling PDF validates licenses through Keygen.sh's remote API:

```
API Endpoint: https://api.keygen.sh/v1/accounts/{ACCOUNT_ID}
Account ID: e5430f69-e834-4ae4-befd-b602aae5f372
```

**Key characteristics:**
- Online validation against Keygen.sh servers
- No local cryptographic key verification
- Machine fingerprinting for activation
- Offline license support since v0.45.0

### Integrity Protection

The grandfathered user count is protected by HMAC-SHA256 signatures:

```
Secret = applicationKey + ":" + uuid + ":" + premiumKey
Signature = HMAC-SHA256(count + ":" + salt, secret)
```

- The secret is installation-specific (generated at first startup)
- Tampering with the database value triggers fallback to 5-user limit
- The signature is verified on each application start

### Relevant Source Files

The licensing logic is implemented in the proprietary module:

- `app/proprietary/src/main/java/stirling/software/proprietary/service/UserLicenseSettingsService.java` - User counting and grandfathering
- `app/proprietary/src/main/java/stirling/software/proprietary/model/UserLicenseSettings.java` - License settings entity
- `KeygenLicenseVerifier.java` - Remote license validation (added in [PR #1994](https://github.com/Stirling-Tools/Stirling-PDF/pull/1994))

## Options for More Than 5 Users

### 1. Purchase a License (Recommended)

Visit [stirlingpdf.com](https://www.stirlingpdf.com/) for licensing options.

### 2. Shared Accounts

Multiple people share accounts (not ideal for audit/compliance).

### 3. Multiple Instances

Deploy separate instances for different teams/departments.

### 4. Fork and Remove Licensing

Technically possible but:
- Requires maintaining a custom fork
- May violate terms of service
- Loses access to updates
- Not recommended for enterprise use

## References

- [Stirling PDF Documentation](https://docs.stirlingpdf.com/)
- [PR #1994 - License Implementation](https://github.com/Stirling-Tools/Stirling-PDF/pull/1994)
- [Release 0.45.0 - Offline License Support](https://github.com/Stirling-Tools/Stirling-PDF/releases/tag/v0.45.0)
