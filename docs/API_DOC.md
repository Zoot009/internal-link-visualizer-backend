# Internal Linking Analyzer - API Documentation

Complete API specification for the Internal Linking Analysis service.

**Version:** 2.0.0  
**Base URL:** `http://localhost:3000` (development)  
**Protocol:** HTTP/HTTPS  
**Format:** JSON

---

## Table of Contents

1. [Overview](#overview)
2. [API Endpoints](#api-endpoints)
3. [Data Models](#data-models)
4. [Error Handling](#error-handling)
5. [Examples](#examples)

---

## Overview

The Internal Linking Analyzer API provides asynchronous website crawling and internal link analysis capabilities. The API uses a job-based workflow:

1. Submit a crawl job
2. Poll for job status and progress
3. Retrieve complete analysis results when job completes

### Key Features

- ✅ Asynchronous job processing with BullMQ
- ✅ Real-time progress tracking
- ✅ Comprehensive link graph analysis
- ✅ Orphan page detection
- ✅ Detailed crawl metadata and error reporting
- ✅ Statistical analysis of link structure

### Architecture

- **Queue System:** Redis + BullMQ for background job processing
- **Crawling:** ScrapeDo API for web scraping
- **Parsing:** Sitemapper for sitemap discovery
- **Storage:** In-memory job results with Redis persistence

---

## API Endpoints

### 1. Get API Information

Retrieve API version and available endpoints.

**Endpoint:** `GET /`

**Authentication:** None required

**Request Parameters:** None

**Request Example:**
```bash
GET / HTTP/1.1
Host: localhost:3000
```

**Success Response:**

**Code:** `200 OK`

**Response Body:**
```json
{
  "status": "running",
  "message": "Internal Linking Analysis API",
  "version": "2.0.0",
  "endpoints": {
    "analyze": "/api/analyze?url=<target-url>",
    "submitJob": "POST /api/jobs/submit",
    "listJobs": "GET /api/jobs",
    "jobStatus": "GET /api/jobs/:jobId/status",
    "jobResult": "GET /api/jobs/:jobId/result",
    "health": "/health"
  }
}
```

**Response Fields:**

| Field | Type | Description |
|-------|------|-------------|
| `status` | string | Current API status |
| `message` | string | API name |
| `version` | string | API version number |
| `endpoints` | object | Available API endpoints |

**Error Response:** None (always returns 200)

---

### 2. Health Check

Check if the API service is operational.

**Endpoint:** `GET /health`

**Authentication:** None required

**Request Parameters:** None

**Request Example:**
```bash
GET /health HTTP/1.1
Host: localhost:3000
```

**Success Response:**

**Code:** `200 OK`

**Response Body:**
```json
{
  "status": "healthy",
  "timestamp": "2026-04-14T10:30:00.000Z"
}
```

**Response Fields:**

| Field | Type | Description |
|-------|------|-------------|
| `status` | string | Health status: `"healthy"` or `"unhealthy"` |
| `timestamp` | string | ISO 8601 timestamp of the check |

**Error Response:**

**Code:** `503 Service Unavailable`

**Response Body:**
```json
{
  "status": "unhealthy",
  "timestamp": "2026-04-14T10:30:00.000Z"
}
```

---

### 3. Submit Crawl Job

Submit a new website crawl and analysis job.

**Endpoint:** `POST /api/jobs/submit`

**Alternative:** `GET /api/jobs/submit` (query parameters)

**Authentication:** None required

**Content-Type:** `application/json` (for POST)

**Request Parameters:**

| Parameter | Type | Required | Default | Min | Max | Description |
|-----------|------|----------|---------|-----|-----|-------------|
| `url` | string | **Yes** | - | - | - | Full URL of website to analyze (must include http:// or https://) |
| `maxPages` | integer | No | 500 | 1 | 1000 | Maximum number of pages to crawl |
| `maxDepth` | integer | No | 5 | 0 | 10 | Maximum depth from homepage (0 = homepage only) |
| `rateLimit` | integer | No | 500 | 0 | 5000 | Delay between requests in milliseconds |

**Request Example (POST):**
```bash
POST /api/jobs/submit HTTP/1.1
Host: localhost:3000
Content-Type: application/json

{
  "url": "https://example.com",
  "maxPages": 500,
  "maxDepth": 5,
  "rateLimit": 500
}
```

**Request Example (GET):**
```bash
GET /api/jobs/submit?url=https://example.com&maxPages=500&maxDepth=5&rateLimit=500 HTTP/1.1
Host: localhost:3000
```

**Success Response:**

**Code:** `202 Accepted`

**Response Body:**
```json
{
  "success": true,
  "message": "Crawl job submitted successfully",
  "jobId": "crawl-1713039000000-abc123",
  "statusUrl": "/api/jobs/crawl-1713039000000-abc123/status",
  "resultUrl": "/api/jobs/crawl-1713039000000-abc123/result"
}
```

**Response Fields:**

| Field | Type | Description |
|-------|------|-------------|
| `success` | boolean | Always `true` for successful submission |
| `message` | string | Confirmation message |
| `jobId` | string | Unique job identifier (use for status/result queries) |
| `statusUrl` | string | Relative URL to check job status |
| `resultUrl` | string | Relative URL to retrieve results (when complete) |

**Error Responses:**

#### Missing URL Parameter

**Code:** `400 Bad Request`

**Response Body:**
```json
{
  "error": "Missing required parameter: url",
  "message": "Please provide a valid URL to analyze"
}
```

#### Invalid URL Format

**Code:** `400 Bad Request`

**Response Body:**
```json
{
  "error": "Invalid URL format",
  "message": "Please provide a valid HTTP or HTTPS URL"
}
```

#### Missing ScrapeDo Token

**Code:** `400 Bad Request`

**Response Body:**
```json
{
  "error": "Missing scrape.do token",
  "message": "SCRAPE_DO_TOKEN environment variable is not set"
}
```

#### Invalid maxPages Parameter

**Code:** `400 Bad Request`

**Response Body:**
```json
{
  "error": "Invalid maxPages parameter",
  "message": "maxPages must be a positive integer"
}
```

#### Invalid maxDepth Parameter

**Code:** `400 Bad Request`

**Response Body:**
```json
{
  "error": "Invalid maxDepth parameter",
  "message": "maxDepth must be a non-negative integer"
}
```

#### Invalid rateLimit Parameter

**Code:** `400 Bad Request`

**Response Body:**
```json
{
  "error": "Invalid rateLimit parameter",
  "message": "rateLimit must be a non-negative integer"
}
```

#### Internal Server Error

**Code:** `500 Internal Server Error`

**Response Body:**
```json
{
  "error": "Internal server error",
  "message": "Failed to submit job"
}
```

---

### 4. Get Job Status

Retrieve the current status and progress of a crawl job.

**Endpoint:** `GET /api/jobs/:jobId/status`

**Authentication:** None required

**URL Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `jobId` | string | **Yes** | Job ID returned from submit endpoint |

**Request Example:**
```bash
GET /api/jobs/crawl-1713039000000-abc123/status HTTP/1.1
Host: localhost:3000
```

**Success Response:**

**Code:** `200 OK`

**Response varies by job state:**

#### State: `waiting`

Job is queued and waiting to be processed.

```json
{
  "jobId": "crawl-1713039000000-abc123",
  "state": "waiting",
  "createdAt": "2026-04-14T10:30:00.000Z",
  "data": {
    "url": "https://example.com",
    "maxPages": 500,
    "maxDepth": 5
  }
}
```

#### State: `active`

Job is currently processing.

```json
{
  "jobId": "crawl-1713039000000-abc123",
  "state": "active",
  "createdAt": "2026-04-14T10:30:00.000Z",
  "processedAt": "2026-04-14T10:30:05.000Z",
  "data": {
    "url": "https://example.com",
    "maxPages": 500,
    "maxDepth": 5
  },
  "progress": {
    "percentage": 45,
    "current": 225,
    "total": 500,
    "currentUrl": "https://example.com/blog/article-45"
  }
}
```

#### State: `completed`

Job finished successfully.

```json
{
  "jobId": "crawl-1713039000000-abc123",
  "state": "completed",
  "createdAt": "2026-04-14T10:30:00.000Z",
  "processedAt": "2026-04-14T10:30:05.000Z",
  "finishedAt": "2026-04-14T10:35:30.000Z",
  "duration": 325000,
  "data": {
    "url": "https://example.com",
    "maxPages": 500,
    "maxDepth": 5
  },
  "progress": {
    "percentage": 100,
    "current": 487,
    "total": 500
  },
  "resultSummary": {
    "success": true,
    "pagesCrawled": 487,
    "orphanPages": 12
  },
  "resultUrl": "/api/jobs/crawl-1713039000000-abc123/result"
}
```

#### State: `failed`

Job encountered an error.

```json
{
  "jobId": "crawl-1713039000000-abc123",
  "state": "failed",
  "createdAt": "2026-04-14T10:30:00.000Z",
  "processedAt": "2026-04-14T10:30:05.000Z",
  "finishedAt": "2026-04-14T10:31:30.000Z",
  "duration": 85000,
  "data": {
    "url": "https://example.com",
    "maxPages": 500,
    "maxDepth": 5
  },
  "error": "Failed to fetch sitemap: Network timeout after 30 seconds"
}
```

**Response Fields:**

| Field | Type | Present When | Description |
|-------|------|--------------|-------------|
| `jobId` | string | Always | Unique job identifier |
| `state` | string | Always | Job state: `"waiting"`, `"active"`, `"completed"`, `"failed"` |
| `createdAt` | string | Always | ISO 8601 timestamp when job was created |
| `processedAt` | string | `active`, `completed`, `failed` | When job started processing |
| `finishedAt` | string | `completed`, `failed` | When job finished |
| `duration` | integer | `completed`, `failed` | Processing time in milliseconds |
| `data` | object | Always | Original job parameters |
| `progress` | object | `active`, `completed` | Current crawl progress |
| `progress.percentage` | number | `active`, `completed` | Completion percentage (0-100) |
| `progress.current` | integer | `active`, `completed` | Pages processed so far |
| `progress.total` | integer | `active`, `completed` | Total pages to process |
| `progress.currentUrl` | string | `active` | URL currently being processed |
| `resultSummary` | object | `completed` | Quick summary of results |
| `resultSummary.success` | boolean | `completed` | Whether analysis succeeded |
| `resultSummary.pagesCrawled` | integer | `completed` | Total pages crawled |
| `resultSummary.orphanPages` | integer | `completed` | Number of orphan pages found |
| `resultUrl` | string | `completed` | URL to fetch full results |
| `error` | string | `failed` | Error message explaining failure |

**Error Responses:**

#### Missing jobId Parameter

**Code:** `400 Bad Request`

**Response Body:**
```json
{
  "error": "Missing required parameter: jobId"
}
```

#### Job Not Found

**Code:** `404 Not Found`

**Response Body:**
```json
{
  "error": "Job not found",
  "message": "No job found with ID: crawl-1713039000000-abc123"
}
```

#### Internal Server Error

**Code:** `500 Internal Server Error`

**Response Body:**
```json
{
  "error": "Internal server error",
  "message": "Failed to get job status"
}
```

---

### 5. Get Job Result

Retrieve the complete analysis results for a completed job.

**Endpoint:** `GET /api/jobs/:jobId/result`

**Authentication:** None required

**URL Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `jobId` | string | **Yes** | Job ID from submit endpoint |

**Request Example:**
```bash
GET /api/jobs/crawl-1713039000000-abc123/result HTTP/1.1
Host: localhost:3000
```

**Success Response:**

**Code:** `200 OK`

**Response Body:**
```json
{
  "success": true,
  "jobId": "crawl-1713039000000-abc123",
  "data": {
    "url": "https://example.com",
    "linkGraph": {
      "https://example.com/": [
        "https://example.com/about",
        "https://example.com/blog",
        "https://example.com/contact",
        "https://example.com/products"
      ],
      "https://example.com/about": [
        "https://example.com/",
        "https://example.com/team",
        "https://example.com/contact"
      ],
      "https://example.com/blog": [
        "https://example.com/",
        "https://example.com/blog/post-1",
        "https://example.com/blog/post-2",
        "https://example.com/blog/post-3"
      ],
      "https://example.com/products": [
        "https://example.com/",
        "https://example.com/products/item-1",
        "https://example.com/products/item-2"
      ]
    },
    "inboundLinksCount": {
      "https://example.com/": 25,
      "https://example.com/about": 8,
      "https://example.com/blog": 12,
      "https://example.com/contact": 15,
      "https://example.com/products": 10,
      "https://example.com/team": 3,
      "https://example.com/blog/post-1": 5,
      "https://example.com/blog/post-2": 0,
      "https://example.com/blog/post-3": 2,
      "https://example.com/products/item-1": 4,
      "https://example.com/products/item-2": 1
    },
    "orphanPages": [
      "https://example.com/blog/post-2",
      "https://example.com/old-page-1",
      "https://example.com/forgotten-content"
    ],
    "stats": {
      "totalPages": 487,
      "totalLinks": 3241,
      "avgOutboundLinks": 6.65,
      "avgInboundLinks": 6.65,
      "maxInboundLinks": 45,
      "pagesWithNoInbound": 12
    },
    "metadata": {
      "startTime": "2026-04-14T10:30:05.000Z",
      "endTime": "2026-04-14T10:35:30.000Z",
      "durationMs": 325000,
      "totalPagesCrawled": 487,
      "totalPagesInSitemap": 500,
      "maxDepthReached": 5,
      "errorsEncountered": 13,
      "errorDetails": [
        {
          "url": "https://example.com/broken-link",
          "error": "HTTP 404: Not Found",
          "timestamp": "2026-04-14T10:31:15.123Z"
        },
        {
          "url": "https://example.com/timeout-page",
          "error": "Request timeout after 30 seconds",
          "timestamp": "2026-04-14T10:32:45.456Z"
        },
        {
          "url": "https://example.com/server-error",
          "error": "HTTP 500: Internal Server Error",
          "timestamp": "2026-04-14T10:33:20.789Z"
        }
      ]
    }
  }
}
```

**Response Fields:**

| Field | Type | Description |
|-------|------|-------------|
| `success` | boolean | Always `true` for successful retrieval |
| `jobId` | string | Job identifier |
| `data` | object | Complete analysis data |
| `data.url` | string | Base URL that was analyzed |
| `data.linkGraph` | object | Adjacency list of outbound links (URL → Array of URLs) |
| `data.inboundLinksCount` | object | Map of URLs to their inbound link count |
| `data.orphanPages` | array | List of URLs with zero inbound links |
| `data.stats` | object | Statistical summary |
| `data.stats.totalPages` | integer | Total pages discovered and crawled |
| `data.stats.totalLinks` | integer | Total internal links found |
| `data.stats.avgOutboundLinks` | number | Average outbound links per page |
| `data.stats.avgInboundLinks` | number | Average inbound links per page |
| `data.stats.maxInboundLinks` | integer | Highest inbound link count (hub page) |
| `data.stats.pagesWithNoInbound` | integer | Count of orphan pages |
| `data.metadata` | object | Crawl execution details |
| `data.metadata.startTime` | string | ISO 8601 timestamp when crawl started |
| `data.metadata.endTime` | string | ISO 8601 timestamp when crawl finished |
| `data.metadata.durationMs` | integer | Total crawl time in milliseconds |
| `data.metadata.totalPagesCrawled` | integer | Actual pages crawled |
| `data.metadata.totalPagesInSitemap` | integer | Pages found in sitemap |
| `data.metadata.maxDepthReached` | integer | Maximum depth level reached |
| `data.metadata.errorsEncountered` | integer | Total errors during crawl |
| `data.metadata.errorDetails` | array | Detailed error log |
| `data.metadata.errorDetails[].url` | string | URL that caused error |
| `data.metadata.errorDetails[].error` | string | Error description |
| `data.metadata.errorDetails[].timestamp` | string | When error occurred |

**Error Responses:**

#### Missing jobId Parameter

**Code:** `400 Bad Request`

**Response Body:**
```json
{
  "error": "Missing required parameter: jobId"
}
```

#### Job Not Found

**Code:** `404 Not Found`

**Response Body:**
```json
{
  "error": "Job not found",
  "message": "No job found with ID: crawl-1713039000000-abc123"
}
```

#### Job Not Completed

**Code:** `400 Bad Request`

**Response Body:**
```json
{
  "error": "Job not completed",
  "message": "Job is currently in 'active' state. Please check status endpoint.",
  "statusUrl": "/api/jobs/crawl-1713039000000-abc123/status"
}
```

Returned when job is still `waiting`, `active`, or `failed`.

#### Result Not Available

**Code:** `404 Not Found`

**Response Body:**
```json
{
  "error": "Result not found",
  "message": "Job completed but result data is not available"
}
```

#### Internal Server Error

**Code:** `500 Internal Server Error`

**Response Body:**
```json
{
  "error": "Internal server error",
  "message": "Failed to get job result"
}
```

---

### 6. List Jobs

Retrieve a list of all jobs with optional filtering.

**Endpoint:** `GET /api/jobs`

**Authentication:** None required

**Query Parameters:**

| Parameter | Type | Required | Default | Valid Values | Description |
|-----------|------|----------|---------|--------------|-------------|
| `state` | string | No | all | `waiting`, `active`, `completed`, `failed` | Filter jobs by state |
| `limit` | integer | No | 50 | 1-100 | Maximum number of jobs to return |

**Request Example:**
```bash
# Get all jobs (default)
GET /api/jobs HTTP/1.1
Host: localhost:3000

# Get only completed jobs
GET /api/jobs?state=completed HTTP/1.1
Host: localhost:3000

# Get last 10 active jobs
GET /api/jobs?state=active&limit=10 HTTP/1.1
Host: localhost:3000
```

**Success Response:**

**Code:** `200 OK`

**Response Body:**
```json
{
  "jobs": [
    {
      "jobId": "crawl-1713039000000-abc123",
      "state": "completed",
      "url": "https://example.com",
      "createdAt": "2026-04-14T10:30:00.000Z",
      "finishedAt": "2026-04-14T10:35:30.000Z"
    },
    {
      "jobId": "crawl-1713038000000-def456",
      "state": "active",
      "url": "https://another-site.com",
      "createdAt": "2026-04-14T09:45:00.000Z",
      "finishedAt": null
    },
    {
      "jobId": "crawl-1713037000000-ghi789",
      "state": "failed",
      "url": "https://broken-site.com",
      "createdAt": "2026-04-14T09:00:00.000Z",
      "finishedAt": "2026-04-14T09:02:15.000Z"
    }
  ],
  "count": 3
}
```

**Response Fields:**

| Field | Type | Description |
|-------|------|-------------|
| `jobs` | array | List of job objects |
| `jobs[].jobId` | string | Unique job identifier |
| `jobs[].state` | string | Current job state |
| `jobs[].url` | string | Website URL being analyzed |
| `jobs[].createdAt` | string | ISO 8601 timestamp of job creation |
| `jobs[].finishedAt` | string\|null | ISO 8601 timestamp of completion (null if not finished) |
| `count` | integer | Number of jobs returned |

**Error Response:**

#### Internal Server Error

**Code:** `500 Internal Server Error`

**Response Body:**
```json
{
  "error": "Internal server error",
  "message": "Failed to list jobs"
}
```

---

### 7. Synchronous Analysis (Legacy)

**⚠️ Deprecated:** Use job-based endpoints instead for better reliability.

Perform synchronous website analysis (blocks until complete).

**Endpoint:** `GET /api/analyze`

**Authentication:** None required

**Query Parameters:**

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `url` | string | **Yes** | - | Website URL to analyze |
| `maxPages` | integer | No | 500 | Maximum pages to crawl |
| `maxDepth` | integer | No | 5 | Maximum crawl depth |
| `delayMs` | integer | No | 500 | Delay between requests (ms) |

**Request Example:**
```bash
GET /api/analyze?url=https://example.com&maxPages=100&maxDepth=3 HTTP/1.1
Host: localhost:3000
```

**Success Response:**

**Code:** `200 OK`

Response format identical to job result endpoint `data` field.

**Error Responses:**

Same as job submit endpoint (400 for validation errors, 500 for server errors).

**⚠️ Warning:** This endpoint can take several minutes to respond and may timeout on large websites. Use the job-based API instead.

---

## Data Models

### Job States

```typescript
type JobState = 'waiting' | 'active' | 'completed' | 'failed';
```

- **waiting:** Job queued, not yet started
- **active:** Job currently processing
- **completed:** Job finished successfully
- **failed:** Job encountered an error

### Link Graph

Adjacency list representation where each URL maps to its outbound links.

```typescript
{
  [sourceUrl: string]: string[]  // Array of destination URLs
}
```

**Example:**
```json
{
  "https://example.com/": ["https://example.com/about", "https://example.com/blog"],
  "https://example.com/about": ["https://example.com/"]
}
```

### Inbound Links Count

Map of URLs to their inbound link count (how many pages link to them).

```typescript
{
  [url: string]: number  // Count of inbound links
}
```

**Example:**
```json
{
  "https://example.com/": 25,
  "https://example.com/about": 8,
  "https://example.com/blog": 12
}
```

### Orphan Pages

Array of URLs with zero inbound internal links.

```typescript
string[]
```

**Example:**
```json
[
  "https://example.com/forgotten-page",
  "https://example.com/old-content"
]
```

### Error Details

```typescript
{
  url: string;       // Page that caused error
  error: string;     // Error description
  timestamp: string; // ISO 8601 timestamp
}
```

---

## Error Handling

### HTTP Status Codes

| Code | Meaning | When Used |
|------|---------|-----------|
| `200` | OK | Request succeeded |
| `202` | Accepted | Job submitted successfully |
| `400` | Bad Request | Invalid parameters or precondition not met |
| `404` | Not Found | Resource (job) not found |
| `500` | Internal Server Error | Server-side error occurred |
| `503` | Service Unavailable | Service is down (health check) |

### Error Response Format

All error responses follow this structure:

```json
{
  "error": "Error Type",
  "message": "Human-readable error description",
  "statusUrl": "/api/jobs/:jobId/status"  // Optional, when relevant
}
```

### Common Error Scenarios

#### 1. Invalid URL

**Trigger:** URL missing protocol or invalid format

**Response:**
```json
{
  "error": "Invalid URL format",
  "message": "Please provide a valid HTTP or HTTPS URL"
}
```

**Solution:** Ensure URL starts with `http://` or `https://`

#### 2. Job Not Found

**Trigger:** Requesting status/result for non-existent jobId

**Response:**
```json
{
  "error": "Job not found",
  "message": "No job found with ID: crawl-invalid-123"
}
```

**Solution:** Verify jobId is correct and job wasn't deleted

#### 3. Job Not Ready

**Trigger:** Requesting results before job completes

**Response:**
```json
{
  "error": "Job not completed",
  "message": "Job is currently in 'active' state. Please check status endpoint.",
  "statusUrl": "/api/jobs/crawl-123/status"
}
```

**Solution:** Poll status endpoint until state is `completed`

#### 4. Parameter Validation

**Trigger:** Invalid parameter values (negative numbers, out of range)

**Response:**
```json
{
  "error": "Invalid maxPages parameter",
  "message": "maxPages must be a positive integer"
}
```

**Solution:** Check parameter constraints in endpoint documentation

#### 5. Server Configuration

**Trigger:** Missing environment variables (SCRAPE_DO_TOKEN)

**Response:**
```json
{
  "error": "Missing scrape.do token",
  "message": "SCRAPE_DO_TOKEN environment variable is not set"
}
```

**Solution:** Contact API administrator to configure server

---

## Examples

### Complete Workflow Example (cURL)

```bash
# 1. Check API health
curl http://localhost:3000/health

# 2. Submit crawl job
RESPONSE=$(curl -X POST http://localhost:3000/api/jobs/submit \
  -H "Content-Type: application/json" \
  -d '{
    "url": "https://example.com",
    "maxPages": 100,
    "maxDepth": 3
  }')

# Extract jobId
JOB_ID=$(echo $RESPONSE | jq -r '.jobId')
echo "Job ID: $JOB_ID"

# 3. Poll job status (repeat until completed)
while true; do
  STATUS=$(curl http://localhost:3000/api/jobs/$JOB_ID/status)
  STATE=$(echo $STATUS | jq -r '.state')
  
  echo "Status: $STATE"
  
  if [ "$STATE" = "completed" ]; then
    break
  elif [ "$STATE" = "failed" ]; then
    echo "Job failed"
    exit 1
  fi
  
  sleep 2
done

# 4. Get results
curl http://localhost:3000/api/jobs/$JOB_ID/result | jq '.' > analysis.json
echo "Results saved to analysis.json"
```

### Example with Python

```python
import requests
import time
import json

BASE_URL = "http://localhost:3000"

# Submit job
response = requests.post(f"{BASE_URL}/api/jobs/submit", json={
    "url": "https://example.com",
    "maxPages": 100,
    "maxDepth": 3,
    "rateLimit": 500
})

job_data = response.json()
job_id = job_data["jobId"]
print(f"Job submitted: {job_id}")

# Poll until complete
while True:
    status_response = requests.get(f"{BASE_URL}/api/jobs/{job_id}/status")
    status = status_response.json()
    
    state = status["state"]
    print(f"Status: {state}", end="")
    
    if "progress" in status:
        print(f" - {status['progress']['percentage']}%")
    else:
        print()
    
    if state == "completed":
        break
    elif state == "failed":
        print(f"Error: {status['error']}")
        exit(1)
    
    time.sleep(2)

# Get results
result_response = requests.get(f"{BASE_URL}/api/jobs/{job_id}/result")
result = result_response.json()

# Save to file
with open("analysis.json", "w") as f:
    json.dump(result, f, indent=2)

print(f"\nAnalysis complete!")
print(f"Pages crawled: {result['data']['metadata']['totalPagesCrawled']}")
print(f"Orphan pages: {len(result['data']['orphanPages'])}")
print(f"Results saved to analysis.json")
```

### Example with JavaScript (Node.js)

```javascript
const fetch = require('node-fetch');

const BASE_URL = 'http://localhost:3000';

async function analyzeWebsite(url) {
  // Submit job
  const submitResponse = await fetch(`${BASE_URL}/api/jobs/submit`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      url,
      maxPages: 100,
      maxDepth: 3,
    }),
  });
  
  const { jobId } = await submitResponse.json();
  console.log(`Job submitted: ${jobId}`);
  
  // Poll status
  let status;
  do {
    await new Promise(resolve => setTimeout(resolve, 2000));
    
    const statusResponse = await fetch(`${BASE_URL}/api/jobs/${jobId}/status`);
    status = await statusResponse.json();
    
    if (status.progress) {
      console.log(`Progress: ${status.progress.percentage}%`);
    } else {
      console.log(`Status: ${status.state}`);
    }
    
    if (status.state === 'failed') {
      throw new Error(status.error);
    }
  } while (status.state !== 'completed');
  
  // Get results
  const resultResponse = await fetch(`${BASE_URL}/api/jobs/${jobId}/result`);
  const result = await resultResponse.json();
  
  console.log('\nAnalysis complete!');
  console.log(`Pages crawled: ${result.data.metadata.totalPagesCrawled}`);
  console.log(`Orphan pages: ${result.data.orphanPages.length}`);
  
  return result;
}

// Usage
analyzeWebsite('https://example.com')
  .then(result => {
    console.log('Result:', result);
  })
  .catch(error => {
    console.error('Error:', error.message);
  });
```

---

## Best Practices

### 1. Always Poll with Delays

Don't poll faster than every 1-2 seconds to avoid unnecessary server load.

```javascript
// Good
setInterval(checkStatus, 2000);

// Bad
setInterval(checkStatus, 100); // Too frequent
```

### 2. Handle All Job States

Always check for `failed` state to catch errors.

```javascript
if (status.state === 'completed') {
  // Get results
} else if (status.state === 'failed') {
  // Handle error
  console.error(status.error);
}
```

### 3. Store JobId for Resume

Save the jobId to resume monitoring after disconnection.

```javascript
localStorage.setItem('currentJobId', jobId);

// Later...
const jobId = localStorage.getItem('currentJobId');
if (jobId) {
  resumeMonitoring(jobId);
}
```

### 4. Set Appropriate Timeouts

For large crawls, set long timeouts or no timeout.

```javascript
fetch(url, {
  timeout: 0, // No timeout for result polling
});
```

### 5. Validate URLs Before Submitting

Check URL format client-side before API call.

```javascript
function isValidUrl(url) {
  try {
    const parsed = new URL(url);
    return parsed.protocol === 'http:' || parsed.protocol === 'https:';
  } catch {
    return false;
  }
}
```

---

## Rate Limiting

**Current Status:** No rate limiting implemented

**Future Plans:** Rate limits may be added per IP address or API key:
- Free tier: 10 jobs/hour
- Pro tier: 100 jobs/hour
- Enterprise: Unlimited

---

## Changelog

### Version 2.0.0 (Current)
- ✅ Job-based async API with BullMQ
- ✅ Real-time progress tracking
- ✅ Enhanced error reporting
- ✅ Statistical analysis
- ✅ Job listing and filtering

### Version 1.0.0 (Legacy)
- ✅ Synchronous `/api/analyze` endpoint
- ❌ No progress tracking
- ❌ Limited error handling

---

## Support & Resources

- **GitHub Repository:** [Link to repo]
- **API Status:** Check `/health` endpoint
- **Documentation:** [/docs](/docs)

---

**Last Updated:** April 14, 2026  
**Maintainer:** Internal Linking Analyzer Team  
**License:** MIT
