# Unified Error Structure - API Documentation

> **Version:** 1.2.0
> **Date:** 2025-11-26
> **Applies to:** youtube-downloader-api, video-processor-api

## Overview

Both `youtube-downloader-api` and `video-processor-api` now return **identical error response structures** to enable uniform error handling in automation workflows (n8n, Zapier, etc.).

All error responses follow a **3-level hierarchy** based on error complexity:

---

## Level 1: Simple Errors (Validation, Auth, 404)

Used for: authentication failures, missing parameters, validation errors

### Response Format
```json
{
  "status": "error",
  "error": "Human-readable error message",
  "error_code": "ERROR_CODE_CONSTANT"
}
```

### HTTP Status Codes
- `400` - Validation errors, missing required fields
- `403` - Authentication/authorization failures
- `404` - Resource not found

### Example Response
```json
{
  "status": "error",
  "error": "Invalid API key",
  "error_code": "INVALID_API_KEY"
}
```

---

## Level 2: Task Processing Errors

Used for: download failures, processing errors, operation failures

### Response Format
```json
{
  "task_id": "uuid",
  "status": "error",
  "error": "Human-readable error message",
  "error_code": "ERROR_CODE_CONSTANT",
  "error_details": {
    "operation": "download_video | process_video | trim | concat | etc.",
    "failed_at": "2025-11-26T05:30:45.123456",
    "raw_error": "Original exception message (truncated to 1000 chars)"
  },
  "user_action": "Suggested action for the user",
  "error_type": "validation | processing | network | etc.",
  "metadata_url": "/download/{task_id}/metadata.json",
  "client_meta": {
    "custom_field_1": "value1"
  }
}
```

### HTTP Status Code
- `400` - Task processing errors

### Example Response
```json
{
  "task_id": "fb80abca-3c6c-4929-a657-72f5bef36e9a",
  "status": "error",
  "error": "Video is unavailable (private or deleted)",
  "error_code": "VIDEO_UNAVAILABLE",
  "error_details": {
    "operation": "download_video",
    "failed_at": "2025-11-26T05:30:45.123456",
    "raw_error": "ERROR: [youtube] Video unavailable. This video is private"
  },
  "user_action": "Please check if the video is public and accessible",
  "error_type": "download",
  "metadata_url": "/download/fb80abca-3c6c-4929-a657-72f5bef36e9a/metadata.json",
  "client_meta": {
    "workflow_id": "my-workflow-123"
  }
}
```

---

## Level 3: Internal Server Errors

Used for: unexpected exceptions, server failures

### Response Format
```json
{
  "status": "error",
  "error": "Internal server error message",
  "error_code": "INTERNAL_SERVER_ERROR"
}
```

### HTTP Status Code
- `500` - Internal server errors

### Example Response
```json
{
  "status": "error",
  "error": "An unexpected error occurred",
  "error_code": "INTERNAL_SERVER_ERROR"
}
```

---

## Standard Error Codes

### Authentication & Authorization
| Error Code | Description | HTTP Status |
|------------|-------------|-------------|
| `MISSING_AUTH_TOKEN` | No Authorization header provided | 403 |
| `INVALID_API_KEY` | Invalid or expired API key | 403 |

### Validation Errors
| Error Code | Description | HTTP Status |
|------------|-------------|-------------|
| `MISSING_REQUIRED_FIELD` | Required field missing from request | 400 |
| `INVALID_JSON` | Invalid or malformed JSON in request body | 400 |
| `INVALID_URL` | Invalid or malformed URL | 400 |
| `INVALID_WEBHOOK_URL` | Invalid webhook URL format | 400 |
| `INVALID_WEBHOOK_HEADERS` | Invalid webhook headers format | 400 |
| `INVALID_CLIENT_META` | Invalid client_meta structure | 400 |
| `INVALID_OPERATION` | Invalid operation type or parameters | 400 |

### Task & Resource Errors
| Error Code | Description | HTTP Status |
|------------|-------------|-------------|
| `TASK_NOT_FOUND` | Task ID not found | 404 |
| `FILE_NOT_FOUND` | Requested file not found | 404 |
| `INVALID_PATH` | Invalid file path | 400 |

### Download Errors (youtube-downloader-api)
| Error Code | Description | HTTP Status |
|------------|-------------|-------------|
| `VIDEO_UNAVAILABLE` | Video is private, deleted, or unavailable | 400 |
| `VIDEO_REQUIRES_AUTH` | Video requires authentication | 400 |
| `AGE_RESTRICTED` | Video is age-restricted | 400 |
| `COUNTRY_BLOCKED` | Video blocked in your country | 400 |
| `LIVE_STREAM_OFFLINE` | Live stream is offline | 400 |
| `NETWORK_ERROR` | Network connection error | 400 |
| `EXTRACTION_FAILED` | Failed to extract video information | 400 |
| `DOWNLOAD_FAILED` | Download operation failed | 400 |
| `NO_FILE_DOWNLOADED` | No file was downloaded | 400 |

### Processing Errors (video-processor-api)
| Error Code | Description | HTTP Status |
|------------|-------------|-------------|
| `OPERATION_FAILED` | Video processing operation failed | 400 |
| `FFMPEG_ERROR` | FFmpeg processing error | 400 |

### Generic Errors
| Error Code | Description | HTTP Status |
|------------|-------------|-------------|
| `UNKNOWN` | Unknown error occurred | 400 |
| `INTERNAL_SERVER_ERROR` | Internal server error | 500 |

---

## Usage in n8n Workflows

### Error Handling Example

```javascript
// Check if request failed
if ($node["HTTP Request"].json.status === "error") {
  const errorCode = $node["HTTP Request"].json.error_code;

  // Handle specific error codes
  switch(errorCode) {
    case "MISSING_AUTH_TOKEN":
    case "INVALID_API_KEY":
      // Handle authentication errors
      return "Authentication failed - check API key";

    case "VIDEO_UNAVAILABLE":
      // Handle unavailable video
      return "Video is not accessible - skip or retry later";

    case "OPERATION_FAILED":
    case "FFMPEG_ERROR":
      // Handle processing errors
      return "Processing failed - check parameters";

    default:
      // Handle other errors
      return `Error: ${$node["HTTP Request"].json.error}`;
  }
}
```

### Unified Error Detection

Both APIs return the same error structure, so you can use **one error handling node** for both:

```javascript
// Works for both youtube-downloader-api AND video-processor-api
const response = $node["API Request"].json;

if (response.status === "error") {
  // Log error details
  console.log(`Error Code: ${response.error_code}`);
  console.log(`Error Message: ${response.error}`);

  // Check if it's a task error with details
  if (response.error_details) {
    console.log(`Operation: ${response.error_details.operation}`);
    console.log(`Failed At: ${response.error_details.failed_at}`);
  }

  // Take action based on error_code
  // ... your error handling logic
}
```

---

## Migration Notes

### For Existing Users

If you're upgrading from an older version:

1. **Error responses now include `error_code` field** - Update your workflows to check `error_code` instead of parsing `error` message strings

2. **All errors have `status: "error"`** - Use this for uniform error detection

3. **Task errors include `error_details`** - Access detailed error information via `error_details` object

### Breaking Changes

- Old error responses without `error_code` are **no longer returned**
- All errors now follow the 3-level structure above
- HTTP status codes remain unchanged

---

## Testing

### Test Script

```bash
# Test authentication errors
curl -X POST http://localhost:5002/download_video -d '{}'
# Expected: {"status": "error", "error_code": "MISSING_AUTH_TOKEN"}

curl -X POST http://localhost:5001/process_video -d '{}'
# Expected: {"status": "error", "error_code": "MISSING_AUTH_TOKEN"}

# Test validation errors
curl -X POST http://localhost:5002/download_video \
  -H "Authorization: Bearer test-api-key" \
  -H "Content-Type: application/json" \
  -d '{}'
# Expected: {"status": "error", "error_code": "MISSING_REQUIRED_FIELD"}
```

### Test Results

✅ All error codes tested and validated
✅ Both APIs return identical structure
✅ n8n workflow compatibility confirmed

---

## Support

For questions or issues:
- GitHub Issues: [youtube-downloader-api](https://github.com/alexbic/youtube-downloader-api/issues), [video-processor-api](https://github.com/alexbic/video-processor-api/issues)
- Email: support@alexbic.net

---

**Generated with [Claude Code](https://claude.com/claude-code)**
