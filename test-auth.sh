#!/bin/bash
# Authentication Testing Script
# Tests all authentication scenarios for the Internal Linking API

BASE_URL="http://localhost:3000"
API_KEY="${API_KEY:-your_api_key_here}"
TEST_URL="https://example.com"

echo "🔐 API Authentication Testing"
echo "=============================="
echo ""
echo "Base URL: $BASE_URL"
echo "API Key: ${API_KEY:0:10}..." 
echo ""

# Function to print test results
print_result() {
  local test_name=$1
  local status_code=$2
  local expected=$3
  
  if [ "$status_code" -eq "$expected" ]; then
    echo "✅ $test_name - Status: $status_code (Expected: $expected)"
  else
    echo "❌ $test_name - Status: $status_code (Expected: $expected)"
  fi
}

# Test 1: No authentication (should fail with 401)
echo "Test 1: Request without API key"
response=$(curl -s -w "\n%{http_code}" "$BASE_URL/api/external/analyze?url=$TEST_URL")
status_code=$(echo "$response" | tail -n1)
print_result "No API key" "$status_code" "401"
echo ""

# Test 2: Invalid API key (should fail with 403)
echo "Test 2: Request with invalid API key"
response=$(curl -s -w "\n%{http_code}" -H "Authorization: Bearer invalid_key_12345" "$BASE_URL/api/external/analyze?url=$TEST_URL")
status_code=$(echo "$response" | tail -n1)
print_result "Invalid API key" "$status_code" "403"
echo ""

# Test 3: Valid API key in Authorization header (should succeed with 200)
echo "Test 3: Request with valid API key (Authorization header)"
response=$(curl -s -w "\n%{http_code}" -H "Authorization: Bearer $API_KEY" "$BASE_URL/api/external/analyze?url=$TEST_URL&maxPages=1")
status_code=$(echo "$response" | tail -n1)
print_result "Valid API key (Bearer)" "$status_code" "200"
echo ""

# Test 4: Valid API key in X-API-Key header (should succeed with 200)
echo "Test 4: Request with valid API key (X-API-Key header)"
response=$(curl -s -w "\n%{http_code}" -H "X-API-Key: $API_KEY" "$BASE_URL/api/external/analyze?url=$TEST_URL&maxPages=1")
status_code=$(echo "$response" | tail -n1)
print_result "Valid API key (X-API-Key)" "$status_code" "200"
echo ""

# Test 5: Valid API key in query parameter (should succeed with 200)
echo "Test 5: Request with valid API key (query parameter)"
response=$(curl -s -w "\n%{http_code}" "$BASE_URL/api/external/analyze?url=$TEST_URL&maxPages=1&apiKey=$API_KEY")
status_code=$(echo "$response" | tail -n1)
print_result "Valid API key (query param)" "$status_code" "200"
echo ""

# Test 6: Health endpoint (should be accessible without auth)
echo "Test 6: Health endpoint (should be public)"
response=$(curl -s -w "\n%{http_code}" "$BASE_URL/health")
status_code=$(echo "$response" | tail -n1)
print_result "Health endpoint" "$status_code" "200"
echo ""

# Test 7: Root endpoint (should be accessible without auth)
echo "Test 7: Root endpoint (should be public)"
response=$(curl -s -w "\n%{http_code}" "$BASE_URL/")
status_code=$(echo "$response" | tail -n1)
print_result "Root endpoint" "$status_code" "200"
echo ""

echo "=============================="
echo "Testing complete!"
echo ""
echo "💡 Tips:"
echo "  - Set API_KEY environment variable before running: export API_KEY='your_key'"
echo "  - Ensure server is running: npm run dev"
echo "  - Check .env file has API_KEY configured"
echo ""
