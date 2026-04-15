# Internal Linking Map Backend

A TypeScript/Express backend that crawls websites to generate comprehensive internal link maps, compare with sitemaps, and identify orphan pages. Uses [scrape.do](https://scrape.do) API for reliable web scraping that bypasses bot protection.

## Features

- 🕷️ **Two-Phase Crawling**: Depth-based crawling followed by sitemap URL processing
- 🔗 **Link Graph Analysis**: Complete mapping of internal links with inbound/outbound link tracking
- 🏝️ **Orphan Page Detection**: Identifies pages in sitemap with no inbound links
- 🛡️ **Bot Protection Bypass**: Uses scrape.do API to handle protected websites
- ⚡ **Rate Limiting**: Configurable delays between requests (default: 500ms)
- 📊 **Comprehensive Analytics**: Detailed crawl metadata and link statistics

## Architecture

### Two-Phase Crawling Strategy

1. **Phase 1: Depth-Based Crawl**
   - Start from the provided URL
   - Crawl up to `maxDepth` levels deep
   - Respect `maxPages` limit
   - Build initial link graph

2. **Phase 2: Sitemap Processing**
   - Fetch sitemap.xml from the website
   - Crawl any URLs found in sitemap that weren't visited in Phase 1
   - Ensures comprehensive coverage even with depth limits

### Components

```
src/
├── index.ts                      # Express server entry point
├── types.ts                      # TypeScript type definitions
├── routes/
│   └── analyze.ts                # API endpoint handler with validation
├── services/
│   ├── crawler.ts                # Queue-based crawler with two-phase logic
│   ├── linkExtractor.ts          # Cheerio-based HTML link extraction
│   ├── linkAnalyzer.ts           # Link graph analysis and orphan detection
│   ├── scrapeDoClient.ts         # Scrape.do API wrapper
│   └── sitemapParser.ts          # Sitemap fetching and parsing
└── utils/
    └── url.ts                    # URL normalization and validation
```

## Installation

```bash
# Install dependencies
npm install

# Create environment file
cp .env.example .env

# Add your scrape.do token to .env
# Get token from: https://dashboard.scrape.do/
```

## Configuration

Edit `.env` file:

```env
SCRAPE_DO_TOKEN=your_token_here
PORT=3000
```

## Docker Deployment

### Prerequisites
- Docker and Docker Compose installed on your system

### Docker Files Overview

- **`Dockerfile`**: Multi-stage build for optimized production image
- **`docker-compose.yml`**: Full stack deployment (app + database + Redis)
- **`docker-compose.dev.yml`**: Database and Redis only for local development
- **`.dockerignore`**: Excludes unnecessary files from Docker build
- **`Makefile`**: Convenient shortcuts for Docker commands

### Quick Start with Docker

1. **Clone and configure**:
```bash
# Create environment file
cp .env.example .env

# Edit .env and add your scrape.do token
nano .env
```

2. **Build and start all services**:
```bash
# Option 1: Using docker-compose
docker-compose up -d

# Option 2: Using Makefile (recommended)
make up
```

This will start:
- PostgreSQL database (port 5432)
- Redis cache (port 6379)  
- Application server (port 3000)

3. **Verify services are running**:
```bash
# Check container status
docker-compose ps

# View application logs
make logs

# Test the API
curl http://localhost:3000/
```

Expected response:
```json
{
  "status": "running",
  "message": "Internal Linking Analysis API",
  "version": "2.0.0"
}
```

### Docker Commands

```bash
# Stop all services
docker-compose down

# Stop and remove volumes (clears database)
docker-compose down -v

# Rebuild after code changes
docker-compose up -d --build

# Run Prisma migrations
docker-compose exec app npx prisma migrate deploy

# Access database
docker-compose exec postgres psql -U postgres -d internal_linking

# Access Redis CLI
docker-compose exec redis redis-cli
```

**Pro Tip**: Use the provided `Makefile` for easier Docker operations:

```bash
make help        # Show all available commands
make up          # Start all services
make down        # Stop all services
make logs        # View logs
make dev-up      # Start only DB and Redis for local dev
make migrate     # Run database migrations
make clean       # Remove all containers and volumes
```

### Development with Docker

For local development, you can run only the database and Redis in Docker while running the app on your host machine:

```bash
# Start only database and Redis
docker-compose -f docker-compose.dev.yml up -d

# In another terminal, run the app locally
npm run dev
```

This approach gives you:
- Fast code reloading with `tsx`
- Full debugging capabilities
- Database and Redis managed by Docker

### Environment Variables for Docker

The `docker-compose.yml` is pre-configured with default values. To customize, edit your `.env` file:

```env
# Database
DATABASE_URL=postgresql://postgres:postgres@postgres:5432/internal_linking

# Redis
REDIS_HOST=redis
REDIS_PORT=6379

# Application
PORT=3000
NODE_ENV=production

# Scrape.do API
SCRAPEDO_API_KEY=your_api_key_here
```

### Production Deployment

For production use:

1. Change default PostgreSQL password in `docker-compose.yml`
2. Use Docker secrets or external secret management
3. Enable SSL/TLS for database connections
4. Configure proper backup strategy for volumes
5. Use a reverse proxy (nginx) for HTTPS

## Usage

### Start the Server

```bash
# Development mode
npm run dev

# Production mode
npm run build
npm start
```

### API Endpoint

**GET** `/api/analyze`

#### Query Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `url` | string | ✅ | - | Target website URL to analyze |
| `token` | string | * | env | Scrape.do API token (or use env var) |
| `maxPages` | number | ❌ | 500 | Maximum pages to crawl |
| `maxDepth` | number | ❌ | 5 | Maximum crawl depth |
| `delayMs` | number | ❌ | 500 | Delay between requests (ms) |

*Required if `SCRAPE_DO_TOKEN` not set in environment

#### Example Request

```bash
curl "http://localhost:3000/api/analyze?url=https://example.com&token=YOUR_TOKEN"
```

#### Example Response

```json
{
  "success": true,
  "url": "https://example.com",
  "analysis": {
    "linkGraph": {
      "https://example.com": [
        "https://example.com/about",
        "https://example.com/contact"
      ],
      "https://example.com/about": [
        "https://example.com",
        "https://example.com/team"
      ]
    },
    "inboundLinksCount": {
      "https://example.com": 1,
      "https://example.com/about": 1,
      "https://example.com/contact": 1,
      "https://example.com/team": 1
    },
    "orphanPages": [
      "https://example.com/old-page"
    ],
    "metadata": {
      "startTime": "2026-04-13T19:42:00.000Z",
      "endTime": "2026-04-13T19:45:30.000Z",
      "durationMs": 210000,
      "totalPagesCrawled": 45,
      "totalPagesInSitemap": 50,
      "maxDepthReached": 5,
      "errorsEncountered": 2,
      "errorDetails": [
        {
          "url": "https://example.com/broken",
          "error": "HTTP 404",
          "timestamp": "2026-04-13T19:43:15.000Z"
        }
      ],
      "stats": {
        "totalPages": 45,
        "totalLinks": 180,
        "avgOutboundLinks": 4.0,
        "avgInboundLinks": 4.0,
        "maxInboundLinks": 15,
        "pagesWithNoInbound": 5
      }
    }
  }
}
```

## Response Schema

### Link Graph
Map of each page to its outgoing internal links:
```typescript
{
  [pageUrl: string]: string[] // array of linked URLs
}
```

### Inbound Links Count
Number of pages linking to each URL:
```typescript
{
  [pageUrl: string]: number // count of inbound links
}
```

### Orphan Pages
Pages found in sitemap but either:
- Not discovered during crawl, OR
- Have zero inbound links from crawled pages

### Metadata
- Crawl timing and duration
- Pages crawled vs sitemap total
- Maximum depth reached
- Error details with timestamps
- Link graph statistics

## How It Works

### 1. URL Normalization
- Removes trailing slashes and fragments
- Converts relative URLs to absolute
- Validates URL format and protocol

### 2. Phase 1: Depth-Based Crawl
- Starts from provided URL at depth 0
- Uses queue-based BFS traversal
- Respects `maxDepth` and `maxPages` limits
- Extracts internal links using Cheerio
- Maintains visited set to avoid duplicates

### 3. Sitemap Fetching
- Tries common sitemap locations:
  - `/sitemap.xml`
  - `/sitemap_index.xml`
  - `/sitemap-index.xml`
- Parses XML to extract all URLs

### 4. Phase 2: Sitemap URL Crawl
- Crawls unvisited sitemap URLs
- Continues until `maxPages` limit reached
- Does not queue discovered links (depth limit already reached)

### 5. Link Analysis
- Calculates inbound link counts
- Identifies orphan pages:
  - In sitemap but not crawled, OR
  - Crawled but zero inbound links
- Generates comprehensive statistics

## Rate Limiting

Default: **500ms delay** between requests (~2 req/sec)

This is a conservative rate to be respectful to target servers. Adjust with `delayMs` parameter if needed.

## Error Handling

- Invalid URLs return 400 with error message
- Missing scrape.do token returns 400
- Crawl errors are logged in `metadata.errorDetails`
- Failed page fetches recorded but don't stop crawl
- Sitemap fetch failures logged but not critical

## Scrape.do Integration

All HTTP requests go through scrape.do API for:
- ✅ Bot protection bypass (Cloudflare, PerimeterX, etc.)
- ✅ Residential proxy rotation (110M+ IPs)
- ✅ CAPTCHA solving
- ✅ Automatic retries on failure

**Cost**: Uses scrape.do credits per request. Basic requests cost 1 credit each.

See [scrape.do documentation](https://scrape.do/documentation/) for pricing and limits.

## Limitations

### Depth vs Sitemap Trade-off
With `maxDepth=5` and `maxPages=500`, you might crawl only 50 pages but the sitemap contains 200 URLs. Phase 2 addresses this by:
- Crawling unvisited sitemap URLs
- Up to `maxPages` total limit
- Providing accurate orphan detection

However, very large sitemaps (>1000 URLs) may still have partial coverage.

### Recommendations
- **Small sites (<100 pages)**: Use `maxDepth=10, maxPages=200`
- **Medium sites (100-500 pages)**: Use `maxDepth=5, maxPages=500` (default)
- **Large sites (>500 pages)**: Use `maxDepth=3, maxPages=1000` or consider multiple runs

## Testing

Comprehensive testing documentation is available:

- **[API Testing Guide](docs/API_TESTING_GUIDE.md)** - Complete guide with detailed examples, workflows, and troubleshooting
- **[Quick Reference](docs/API_QUICK_REFERENCE.md)** - One-page cheat sheet for common commands and scenarios

Quick test command:
```bash
curl -X POST http://localhost:3000/api/jobs/submit \
  -H "Content-Type: application/json" \
  -d '{"url": "https://example.com", "token": "YOUR_TOKEN", "maxPages": 5}'
```

For more testing examples and use cases, see the testing documentation above.

## Development

```bash
# Run in dev mode with auto-reload
npm run dev

# Build TypeScript
npm run build

# Type checking
npx tsc --noEmit
```

## Technology Stack

- **Runtime**: Node.js with ES Modules
- **Framework**: Express.js
- **Language**: TypeScript
- **HTML Parsing**: Cheerio
- **HTTP Client**: Axios (for scrape.do API)
- **Sitemap Parsing**: sitemap-parser
- **Environment**: dotenv

## License

ISC

## Support

For scrape.do API support, visit: https://scrape.do/documentation/contact/
