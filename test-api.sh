#!/bin/bash

# Internal Linking API - Simple Test Script
# This script tests the API with a small crawl job

set -e  # Exit on error

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Configuration
API_URL="${API_URL:-http://localhost:3000}"
TEST_URL="${TEST_URL:-https://example.com}"
MAX_PAGES="${MAX_PAGES:-5}"
POLL_INTERVAL=2

echo -e "${BLUE}==================================${NC}"
echo -e "${BLUE}Internal Linking API - Test Script${NC}"
echo -e "${BLUE}==================================${NC}"
echo ""

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo -e "${RED}Error: jq is not installed${NC}"
    echo "Install with: sudo apt-get install jq (Ubuntu) or brew install jq (Mac)"
    exit 1
fi

# Check if server is running
echo -e "${YELLOW}[1/5] Checking API health...${NC}"
if ! curl -sf "$API_URL/health" > /dev/null; then
    echo -e "${RED}Error: API is not responding at $API_URL${NC}"
    echo "Make sure the server is running: npm run dev"
    exit 1
fi
echo -e "${GREEN}✓ API is healthy${NC}"
echo ""

# Get token from environment or prompt
if [ -z "$SCRAPE_DO_TOKEN" ]; then
    echo -e "${YELLOW}Note: SCRAPE_DO_TOKEN not set in environment${NC}"
    echo "Token will need to be in .env file or server will fail"
    echo ""
    TOKEN_PARAM=""
else
    echo -e "${GREEN}✓ Using SCRAPE_DO_TOKEN from environment${NC}"
    TOKEN_PARAM="\"token\": \"$SCRAPE_DO_TOKEN\","
    echo ""
fi

# Submit job
echo -e "${YELLOW}[2/5] Submitting crawl job...${NC}"
echo "URL: $TEST_URL"
echo "Max Pages: $MAX_PAGES"
echo ""

RESPONSE=$(curl -sf -X POST "$API_URL/api/jobs/submit" \
  -H "Content-Type: application/json" \
  -d "{
    $TOKEN_PARAM
    \"url\": \"$TEST_URL\",
    \"maxPages\": $MAX_PAGES,
    \"maxDepth\": 2
  }")

if [ $? -ne 0 ]; then
    echo -e "${RED}Error: Failed to submit job${NC}"
    exit 1
fi

JOB_ID=$(echo "$RESPONSE" | jq -r '.jobId')

if [ "$JOB_ID" = "null" ] || [ -z "$JOB_ID" ]; then
    echo -e "${RED}Error: No job ID returned${NC}"
    echo "Response: $RESPONSE"
    exit 1
fi

echo -e "${GREEN}✓ Job submitted successfully${NC}"
echo "Job ID: $JOB_ID"
echo ""

# Poll status
echo -e "${YELLOW}[3/5] Waiting for job to complete...${NC}"
ATTEMPTS=0
MAX_ATTEMPTS=60  # 2 minutes max

while true; do
    STATUS_RESPONSE=$(curl -sf "$API_URL/api/jobs/$JOB_ID/status")
    STATE=$(echo "$STATUS_RESPONSE" | jq -r '.state')
    
    if [ "$STATE" = "completed" ]; then
        echo -e "${GREEN}✓ Job completed successfully${NC}"
        
        # Show result summary
        PAGES=$(echo "$STATUS_RESPONSE" | jq -r '.resultSummary.pagesCrawled // "N/A"')
        ORPHANS=$(echo "$STATUS_RESPONSE" | jq -r '.resultSummary.orphanPages // "N/A"')
        DURATION=$(echo "$STATUS_RESPONSE" | jq -r '.duration // "N/A"')
        
        echo "Pages Crawled: $PAGES"
        echo "Orphan Pages: $ORPHANS"
        echo "Duration: ${DURATION}ms"
        echo ""
        break
    elif [ "$STATE" = "failed" ]; then
        echo -e "${RED}✗ Job failed${NC}"
        ERROR=$(echo "$STATUS_RESPONSE" | jq -r '.error // "Unknown error"')
        echo "Error: $ERROR"
        exit 1
    elif [ "$STATE" = "active" ]; then
        PROGRESS=$(echo "$STATUS_RESPONSE" | jq -r '.progress.pagesCrawled // 0')
        echo -ne "\rProcessing... (${PROGRESS} pages crawled)"
    else
        echo -ne "\rStatus: $STATE..."
    fi
    
    ATTEMPTS=$((ATTEMPTS + 1))
    if [ $ATTEMPTS -ge $MAX_ATTEMPTS ]; then
        echo -e "${RED}Timeout: Job did not complete in time${NC}"
        exit 1
    fi
    
    sleep $POLL_INTERVAL
done

# Get full results
echo -e "${YELLOW}[4/5] Fetching full results...${NC}"
RESULT=$(curl -sf "$API_URL/api/jobs/$JOB_ID/result")

if [ $? -ne 0 ]; then
    echo -e "${RED}Error: Failed to fetch results${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Results retrieved${NC}"
echo ""

# Display summary
echo -e "${YELLOW}[5/5] Results Summary:${NC}"
echo ""

TOTAL_PAGES=$(echo "$RESULT" | jq -r '.data.metadata.totalPagesCrawled // 0')
TOTAL_LINKS=$(echo "$RESULT" | jq -r '.data.metadata.totalInternalLinks // 0')
ORPHAN_COUNT=$(echo "$RESULT" | jq -r '.data.metadata.orphanPagesCount // 0')
CREDITS=$(echo "$RESULT" | jq -r '.data.metadata.creditsUsed // 0')

echo "📊 Crawl Statistics:"
echo "  • Total Pages: $TOTAL_PAGES"
echo "  • Internal Links: $TOTAL_LINKS"
echo "  • Orphan Pages: $ORPHAN_COUNT"
echo "  • Credits Used: $CREDITS"
echo ""

# Show sample orphan pages
if [ "$ORPHAN_COUNT" -gt 0 ]; then
    echo "🏝️  Orphan Pages Found:"
    echo "$RESULT" | jq -r '.data.orphanPages[] | "  • \(.url) (source: \(.source))"' | head -5
    
    if [ "$ORPHAN_COUNT" -gt 5 ]; then
        echo "  ... and $((ORPHAN_COUNT - 5)) more"
    fi
    echo ""
fi

# Show sample internal links
LINK_COUNT=$(echo "$RESULT" | jq -r '.data.internalLinks | length')
if [ "$LINK_COUNT" -gt 0 ]; then
    echo "🔗 Sample Internal Links:"
    echo "$RESULT" | jq -r '.data.internalLinks[] | "  • \(.url) → \(.links | length) links (depth: \(.depth))"' | head -5
    
    if [ "$LINK_COUNT" -gt 5 ]; then
        echo "  ... and $((LINK_COUNT - 5)) more"
    fi
    echo ""
fi

# Success
echo -e "${GREEN}==================================${NC}"
echo -e "${GREEN}✓ Test completed successfully!${NC}"
echo -e "${GREEN}==================================${NC}"
echo ""
echo "Full results saved to: results-$JOB_ID.json"
echo "$RESULT" | jq . > "results-$JOB_ID.json"

echo ""
echo "Next steps:"
echo "  • View full results: cat results-$JOB_ID.json | jq ."
echo "  • Check database: npx prisma studio"
echo "  • List all jobs: curl $API_URL/api/jobs | jq ."
echo ""
echo "For more testing options, see: docs/API_TESTING_GUIDE.md"
