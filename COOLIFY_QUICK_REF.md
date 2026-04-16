# Coolify Deployment - Quick Reference

Essential commands and URLs for managing your deployment.

## 🔗 Important URLs

```
Production API:     https://api.yourdomain.com       (on your VPS)
Health Check:       https://api.yourdomain.com/health
Coolify Dashboard:  http://localhost:8000             (on your local machine)
Supabase Dashboard: https://supabase.com/dashboard
```

**Note:** Coolify runs on your local machine and deploys to your VPS server.

## 📋 Environment Variables (Set in Coolify)

```bash
NODE_ENV=production
PORT=3000
DATABASE_URL=postgresql://postgres.xxxxx:password@aws-0-region.pooler.supabase.com:6543/postgres?pgbouncer=true&connection_limit=1
REDIS_URL=redis://127.0.0.1:6379
WORKER_CONCURRENCY=2
SCRAPE_DO_TOKEN=your_token
API_KEY=your_key
```

## 🚀 Deployment Commands

### Initial Deployment
```bash
# 1. Add Dockerfile to project
git add Dockerfile.coolify
git commit -m "Add Coolify deployment config"
git push origin main

# 2. Deploy in Coolify dashboard (click "Deploy" button)
```

### Update Deployment
```bash
# Code changes
git add .
git commit -m "Update message"
git push origin main
# Coolify auto-deploys (if enabled)

# Environment variable changes
# → Update in Coolify UI → Click "Restart"

# Force rebuild
# → Coolify UI → Click "Redeploy"
```

## 🧪 Testing Commands

### Health Check
```bash
curl https://api.yourdomain.com/health
# Expected: {"status":"healthy","timestamp":"...","redis":true,"database":true}
```

### Submit Job
```bash
curl -X POST https://api.yourdomain.com/api/jobs/submit \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"url":"https://example.com","useCredits":100}'
```

### Check Job Status
```bash
curl -H "Authorization: Bearer YOUR_API_KEY" \
  https://api.yourdomain.com/api/jobs/JOB_ID/status
```

### Get Results
```bash
curl -H "Authorization: Bearer YOUR_API_KEY" \
  https://api.yourdomain.com/api/jobs/JOB_ID/result
```

## 🔍 Monitoring & Logs

### View Logs (in Coolify)
```
Open Coolify: http://localhost:8000
Navigate to: Dashboard → Your App → Logs tab
Select your VPS server if prompted
```

**Note:** Logs show what's happening on your VPS, even though you're viewing them from your local Coolify instance.

### Watch for Issues
Look for these log messages:
- ✅ `Redis is ready!`
- ✅ `Database connected successfully`
- ✅ `Worker ready (concurrency: 2)`
- ❌ `Redis connection error`
- ❌ `Failed to save crawl results`

### Check Worker Activity
```bash
# In Coolify logs, look for:
"[Job crawl-xxxxx] Starting crawl..."
"✅ Saved crawl results for job crawl-xxxxx"
```

## 🛠️ Troubleshooting

### Redis Not Starting
```bash
# Check logs for "Redis is ready!"
# If missing, redeploy: Coolify → Redeploy button
```

### Database Connection Failed
```bash
# Verify DATABASE_URL in Coolify env vars
# Must use connection pooling URL (port 6543)
# Format: postgresql://user:pass@host.supabase.com:6543/postgres?pgbouncer=true
```

### SSL Certificate Issues
```bash
# Verify DNS:
nslookup api.yourdomain.com
# Should return your VPS IP

# Force SSL regeneration:
# Coolify → Domain settings → Regenerate certificate
```

### Application Not Responding
```bash
# 1. Check if container is running:
# Coolify → Logs → Should show recent activity

# 2. Check health endpoint:
curl https://api.yourdomain.com/health

# 3. Restart:
# Coolify → Restart button
```

## 📊 Supabase Management

### View Database Tables
```sql
-- In Supabase SQL Editor:
SELECT * FROM "CrawlJob" ORDER BY "createdAt" DESC LIMIT 10;
SELECT COUNT(*) FROM "InternalLink";
SELECT COUNT(*) FROM "OrphanPage";
```

### Clear Old Data
```sql
-- Delete jobs older than 30 days:
DELETE FROM "CrawlJob" WHERE "createdAt" < NOW() - INTERVAL '30 days';
-- This cascades to InternalLink and OR rphanPage due to onDelete: Cascade
```

### Check Database Size
```sql
-- In Supabase → Settings → Database → Database size
-- Or SQL Editor:
SELECT 
  pg_size_pretty(pg_database_size('postgres')) as database_size;
```

## 🔐 Security Checklist

- [ ] Strong API_KEY set (32+ random characters)
- [ ] HTTPS enabled in Coolify (should be automatic)
- [ ] DATABASE_URL uses connection pooling
- [ ] Supabase database has strong password
- [ ] `.env` file in `.gitignore` (never commit secrets)
- [ ] SCRAPE_DO_TOKEN kept private

## 📈 Scaling

### Increase Worker Concurrency
```bash
# In Coolify → Environment Variables:
WORKER_CONCURRENCY=4  # or 6, 8 (max 10 recommended)
# Then: Coolify → Restart
```

### Upgrade Supabase Plan
```
Supabase Dashboard → Settings → Billing
Free: 500MB, 2GB bandwidth
Pro: 8GB, 50GB bandwidth ($25/mo)
```

### Upgrade VPS Resources
```
More RAM = more concurrent jobs
More CPU = faster processing
Recommended: 2GB RAM, 2 vCPU minimum
```

## 🔄 Backup & Restore

### Supabase Backups (Automatic)
```
Supabase → Database → Backups
Daily backups on Pro plan
```

### Manual Export
```bash
# In Supabase SQL Editor → Export → Download as CSV
# Or use curl to backup job results via API
```

## 📞 Support Resources

- **Coolify Docs**: https://coolify.io/docs
- **Supabase Docs**: https://supabase.com/docs/guides/database
- **API Docs**: See `docs/API_DOC.md`
- **Testing Guide**: See `docs/SHORT_API_DOC.md`

---

**Last Updated**: 2026-04-16  
**Deployment Guide**: See `docs/COOLIFY_DEPLOYMENT.md` for full instructions
