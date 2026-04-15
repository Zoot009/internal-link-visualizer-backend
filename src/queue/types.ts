/**
 * Job types for BullMQ
 */

import type { InternalLinkAnalysisResponse } from '../types.js';

/**
 * Job data for crawl requests
 */
export interface CrawlJobData {
  url: string;
  scrapeDoToken?: string;
  maxPages?: number;
  maxDepth?: number;
  rateLimit?: number;
}

/**
 * Job result for crawl requests
 */
export interface CrawlJobResult {
  success: boolean;
  data?: InternalLinkAnalysisResponse;
  error?: string;
  startedAt: string;
  completedAt: string;
  duration: number; // in milliseconds
}

/**
 * Job progress update
 */
export interface CrawlJobProgress {
  phase: 'crawling' | 'sitemap' | 'analysis' | 'complete';
  pagesCrawled: number;
  pagesQueued: number;
  currentDepth: number;
  message: string;
}
