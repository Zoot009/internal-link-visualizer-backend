import dotenv from "dotenv";

// Load environment variables FIRST before any other imports
dotenv.config();

import express from "express";
import { analyzeHandler } from "./routes/analyze.js";
import { 
  submitJobHandler, 
  getJobStatusHandler, 
  getJobResultHandler,
  listJobsHandler 
} from "./routes/jobs.js";
import { createCrawlWorker, closeWorker } from "./queue/worker.js";
import { closeQueue } from "./queue/config.js";
import { closePrisma } from "./services/database.js";
import { closeRedis } from "./utils/redis.js";
import type { Worker } from 'bullmq';

const app = express();
const PORT = process.env.PORT || 3000;

app.use(express.json());

// Health check endpoint
app.get("/", (req, res) => {
  res.json({
    status: "running",
    message: "Internal Linking Analysis API",
    version: "2.0.0",
    endpoints: {
      // Legacy synchronous endpoint
      analyze: "/api/analyze?url=<target-url>",
      // New job-based async endpoints
      submitJob: "POST /api/jobs/submit",
      listJobs: "GET /api/jobs",
      jobStatus: "GET /api/jobs/:jobId/status",
      jobResult: "GET /api/jobs/:jobId/result",
      health: "/health",
    },
  });
});

// Health check endpoint
app.get("/health", (req, res) => {
  res.json({ status: "healthy", timestamp: new Date().toISOString() });
});

// Legacy synchronous analysis endpoint (for backward compatibility)
app.get("/api/analyze", analyzeHandler);

// Job-based async endpoints
app.post("/api/jobs/submit", submitJobHandler);
app.get("/api/jobs/submit", submitJobHandler); // Also support GET for convenience
app.get("/api/jobs", listJobsHandler);
app.get("/api/jobs/:jobId/status", getJobStatusHandler);
app.get("/api/jobs/:jobId/result", getJobResultHandler);

// Start the worker
let worker: Worker | null = null;

async function startServer() {
  try {
    // Start the BullMQ worker
    const workerConcurrency = parseInt(process.env.WORKER_CONCURRENCY || '2');
    worker = createCrawlWorker(workerConcurrency);
    console.log(`🔧 Worker started with concurrency: ${workerConcurrency}`);

    // Start the Express server
    app.listen(PORT, () => {
      console.log(`🚀 Server running at http://localhost:${PORT}`);
      console.log(`📊 Submit job: POST http://localhost:${PORT}/api/jobs/submit`);
      console.log(`📋 List jobs: GET http://localhost:${PORT}/api/jobs`);
      console.log(`💚 Health check: http://localhost:${PORT}/health`);
      
      if (!process.env.SCRAPE_DO_TOKEN) {
        console.warn("⚠️  Warning: SCRAPE_DO_TOKEN not set in environment variables");
        console.warn("   The API will not work without this token configured");
      }

      if (!process.env.REDIS_URL && !process.env.REDIS_HOST) {
        console.warn("⚠️  Warning: Redis configuration not found in environment");
        console.warn("   Using default: localhost:6379");
      }
    });
  } catch (error) {
    console.error("❌ Failed to start server:", error);
    process.exit(1);
  }
}

// Graceful shutdown
async function shutdown(signal: string) {
  console.log(`\n${signal} received, shutting down gracefully...`);
  
  try {
    // Close worker
    if (worker) {
      await closeWorker(worker);
    }
    
    // Close queue connections
    await closeQueue();
    
    // Close Redis connection
    await closeRedis();
    
    // Close Prisma database connection
    await closePrisma();
    
    console.log("✅ Shutdown complete");
    process.exit(0);
  } catch (error) {
    console.error("❌ Error during shutdown:", error);
    process.exit(1);
  }
}

// Handle shutdown signals
process.on('SIGTERM', () => shutdown('SIGTERM'));
process.on('SIGINT', () => shutdown('SIGINT'));

// Start the server
startServer();
