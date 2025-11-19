# 📋 YouTube Downloader API - Release Notes v1.1.0

**Release Date:** November 19, 2025
**Version:** 1.1.0
**Type:** Major Update (Breaking Changes)

---

## ⚠️ BREAKING CHANGES

### Webhook Format Standardization

**Old formats are NO LONGER SUPPORTED:**

```json
// ❌ DEPRECATED - No longer works
{
  "webhook_url": "https://...",
  "webhook_headers": {"X-API-Key": "..."}
}

// ❌ DEPRECATED - No longer works
{
  "callback_url": "https://..."
}

// ❌ DEPRECATED - No longer works
{
  "webhook": "https://..."  // String format
}
```

**New unified format (REQUIRED):**

```json
// ✅ CORRECT - Use this format
{
  "webhook": {
    "url": "https://your-webhook.com/endpoint",
    "headers": {
      "X-API-Key": "your-secret-key",
      "Authorization": "Bearer token-123"
    }
  }
}
```

**Migration Guide:**

```diff
  {
    "url": "https://youtube.com/watch?v=...",
    "async": true,
-   "webhook_url": "https://webhook.com/callback",
-   "webhook_headers": {
-     "X-API-Key": "secret"
-   }
+   "webhook": {
+     "url": "https://webhook.com/callback",
+     "headers": {
+       "X-API-Key": "secret"
+     }
+   }
  }
```

---

## 🆕 What's New

### 1. Unified Webhook Object Format

**Benefits:**
- ✅ Consistent API across all endpoints
- ✅ Cleaner request structure
- ✅ Better validation with clear error messages
- ✅ Aligns with industry standards (similar to video-processor-api)

**Features:**
- `webhook.url` - Required string, must start with http(s)://, max 2048 chars
- `webhook.headers` - Optional object with custom authentication headers
- Full validation with helpful error messages
- Priority: per-request headers > global `WEBHOOK_HEADERS` env var

**Example:**
```json
{
  "url": "https://youtube.com/watch?v=dQw4w9WgXcQ",
  "async": true,
  "webhook": {
    "url": "https://n8n.example.com/webhook/video-ready",
    "headers": {
      "X-API-Key": "project-A-key",
      "X-User-ID": "12345",
      "Authorization": "Bearer custom-token"
    }
  }
}
```

### 2. Enhanced Validation

**Webhook Validation:**
- ✅ `webhook` must be an object (strings rejected with clear error)
- ✅ `webhook.url` validated for http(s):// prefix
- ✅ `webhook.url` max length: 2048 characters
- ✅ `webhook.headers` must be object with string key/value pairs
- ✅ Header name max: 256 characters
- ✅ Header value max: 2048 characters

**Error Messages:**
```json
// Invalid format
{"error": "Invalid webhook (must be an object with 'url' and optional 'headers')"}

// Invalid URL
{"error": "Invalid webhook.url (must start with http(s)://)"}

// Invalid headers
{"error": "Invalid webhook.headers (keys and values must be strings)"}
```

### 3. Webhook State Tracking in Metadata

Webhook delivery state is now saved in `metadata.json`:

```json
{
  "webhook": {
    "url": "https://webhook.com/callback",
    "headers": {"X-API-Key": "***"},
    "status": "delivered",
    "attempts": 1,
    "last_attempt": "2025-11-19T15:49:54.210225",
    "last_status": 200,
    "last_error": null,
    "next_retry": null,
    "task_id": "abc123..."
  }
}
```

**Fields:**
- `status`: `pending` | `delivered` | `failed`
- `attempts`: Number of delivery attempts
- `last_attempt`: ISO 8601 timestamp of last attempt
- `last_status`: HTTP status code from last attempt
- `last_error`: Error message if failed
- `next_retry`: ISO 8601 timestamp of next retry attempt

---

## 📚 Updated Documentation

### README.md
- ✅ Updated all webhook examples to new format
- ✅ Updated parameter descriptions
- ✅ Added WEBHOOK_HEADERS environment variable docs
- ✅ Clarified validation rules

### CHANGELOG.md
- ✅ Added breaking change notice
- ✅ Updated webhook format examples
- ✅ Added migration guide

---

## 🔄 Backward Compatibility

**IMPORTANT:** This release contains breaking changes.

**Not Supported:**
- ❌ `webhook_url` parameter (use `webhook.url` instead)
- ❌ `webhook_headers` parameter (use `webhook.headers` instead)
- ❌ `callback_url` parameter (deprecated)
- ❌ String format `webhook: "https://..."` (use object format)

**Still Supported:**
- ✅ `DEFAULT_WEBHOOK_URL` environment variable (fallback when no webhook specified)
- ✅ `WEBHOOK_HEADERS` environment variable (global headers, overridden by per-request headers)
- ✅ All other parameters remain unchanged

---

## 🛠️ Environment Variables

### New:
```bash
# Global webhook headers (applied to all webhooks by default)
WEBHOOK_HEADERS='{"X-API-Key": "global-key", "X-Service": "youtube-downloader"}'
```

### Updated:
```bash
# Now used when no webhook object is provided in request
DEFAULT_WEBHOOK_URL="https://webhook.example.com/callback"
```

---

## 📊 Testing

All webhook scenarios tested:

✅ New webhook object format - **WORKS**
```bash
curl -X POST http://localhost:5000/download_video \
  -H "Content-Type: application/json" \
  -d '{
    "url": "https://youtube.com/watch?v=...",
    "async": true,
    "webhook": {
      "url": "https://httpbin.org/post",
      "headers": {"X-Test": "value"}
    }
  }'
```

❌ Old webhook_url format - **IGNORED** (webhook_url = null)
```bash
curl -X POST http://localhost:5000/download_video \
  -H "Content-Type: application/json" \
  -d '{
    "url": "https://youtube.com/watch?v=...",
    "async": true,
    "webhook_url": "https://httpbin.org/post"
  }'
```

❌ String webhook format - **REJECTED** with error
```bash
curl -X POST http://localhost:5000/download_video \
  -H "Content-Type: application/json" \
  -d '{
    "url": "https://youtube.com/watch?v=...",
    "async": true,
    "webhook": "https://httpbin.org/post"
  }'
# Returns: {"error": "Invalid webhook (must be an object...)"}
```

---

## 🚀 Upgrade Instructions

### For API Consumers:

1. **Update all webhook requests:**
   ```diff
   - "webhook_url": "https://...",
   - "webhook_headers": {"X-Key": "..."}
   + "webhook": {
   +   "url": "https://...",
   +   "headers": {"X-Key": "..."}
   + }
   ```

2. **Test your integration** with the new format

3. **Remove** any references to:
   - `webhook_url`
   - `webhook_headers`
   - `callback_url`

### For Docker Users:

```bash
# Pull latest image
docker pull alexbic/youtube-downloader-api:latest

# Or rebuild from source
docker compose build --no-cache
docker compose up -d
```

---

## 📦 Downloads

- **Docker Hub:** `alexbic/youtube-downloader-api:latest`
- **GHCR:** `ghcr.io/alexbic/youtube-downloader-api:latest`
- **Source:** https://github.com/alexbic/youtube-downloader-api

---

## 🐛 Bug Fixes

- Fixed webhook validation to reject invalid formats with clear error messages
- Removed fallback logic for deprecated parameters to enforce new format

---

## ⚡ Performance

No performance impact. Changes are API-level only.

---

## 🔐 Security

- Enhanced validation prevents malformed webhook configurations
- Sensitive headers (Authorization, X-API-Key, X-Auth-Token) automatically masked in logs

---

## 📞 Support

- **GitHub Issues:** https://github.com/alexbic/youtube-downloader-api/issues
- **Documentation:** https://github.com/alexbic/youtube-downloader-api/blob/main/README.md
- **Email:** support@alexbic.net

---

## 🎯 Next Steps

After upgrading to v1.1.0:

1. ✅ Update all client code to use new webhook format
2. ✅ Test webhook delivery with your endpoints
3. ✅ Review metadata.json for webhook state tracking
4. ✅ Update any documentation referencing old format

---

**Thank you for using YouTube Downloader API!** 🎬✨

For the complete changelog, see [CHANGELOG.md](./CHANGELOG.md)
