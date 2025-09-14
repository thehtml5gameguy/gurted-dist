use anyhow::{Result, Context};
use tokio::time::{interval, Instant};
use tracing::{info, error};

use crate::config::Config;
use crate::crawler::run_crawl_all;
use crate::indexer::SearchEngine;

pub struct CrawlScheduler {
    config: Config,
}

impl CrawlScheduler {
    pub fn new(config: Config) -> Self {
        Self { config }
    }

    pub async fn start(&self) -> Result<()> {
        info!("Starting crawl scheduler");
        info!(
            "Crawl interval: {} hours ({} seconds)",
            self.config.search.crawl_interval_hours,
            self.config.crawl_interval().as_secs()
        );
        info!(
            "Index rebuild interval: {} hours ({} seconds)",
            self.config.search.index_rebuild_interval_hours,
            self.config.index_rebuild_interval().as_secs()
        );

        let mut crawl_interval = interval(self.config.crawl_interval());
        let mut index_rebuild_interval = interval(self.config.index_rebuild_interval());

        crawl_interval.tick().await;
        index_rebuild_interval.tick().await;

        info!("Running initial crawl...");
        if let Err(e) = self.run_scheduled_crawl().await {
            error!("Initial crawl failed: {}", e);
            error!("Error details: {:?}", e);
            
            // Log the error chain
            let mut source = e.source();
            let mut depth = 1;
            while let Some(err) = source {
                error!("  Caused by ({}): {}", depth, err);
                source = err.source();
                depth += 1;
            }
        }

        loop {
            tokio::select! {
                _ = crawl_interval.tick() => {
                    info!("Running scheduled crawl");
                    if let Err(e) = self.run_scheduled_crawl().await {
                        error!("Scheduled crawl failed: {}", e);
                        error!("Error details: {:?}", e);
                        
                        // Log the error chain
                        let mut source = e.source();
                        let mut depth = 1;
                        while let Some(err) = source {
                            error!("  Caused by ({}): {}", depth, err);
                            source = err.source();
                            depth += 1;
                        }
                    }
                }
                _ = index_rebuild_interval.tick() => {
                    info!("Running scheduled index rebuild");
                    if let Err(e) = self.run_scheduled_index_rebuild().await {
                        error!("Scheduled index rebuild failed: {}", e);
                    }
                }
                _ = tokio::signal::ctrl_c() => {
                    info!("Received shutdown signal, stopping scheduler");
                    break;
                }
            }
        }

        info!("Crawl scheduler stopped");
        Ok(())
    }

    async fn run_scheduled_crawl(&self) -> Result<()> {
        let start_time = Instant::now();
        
        run_crawl_all(self.config.clone()).await
            .context("Scheduled crawl failed")?;

        let duration = start_time.elapsed();
        info!("Scheduled crawl completed in {:.2} seconds", duration.as_secs_f64());
        
        Ok(())
    }

    async fn run_scheduled_index_rebuild(&self) -> Result<()> {
        let start_time = Instant::now();

        let search_engine = SearchEngine::new(self.config.clone())?;
        let stats_before = search_engine.get_stats().await?;
        
        info!(
            "Starting index rebuild - current index has {} documents from {} domains ({:.2} MB)",
            stats_before.total_documents,
            stats_before.total_domains,
            stats_before.index_size_mb
        );

        crate::indexer::rebuild_index(self.config.clone()).await
            .context("Index rebuild failed")?;

        info!("Repopulating rebuilt index with fresh crawl");
        run_crawl_all(self.config.clone()).await
            .context("Post-rebuild crawl failed")?;

        let duration = start_time.elapsed();
        
        let new_search_engine = SearchEngine::new(self.config.clone())?;
        let stats_after = new_search_engine.get_stats().await?;

        info!(
            "Index rebuild completed in {:.2} seconds - new index has {} documents from {} domains ({:.2} MB)",
            duration.as_secs_f64(),
            stats_after.total_documents,
            stats_after.total_domains,
            stats_after.index_size_mb
        );

        Ok(())
    }
}

pub struct BackgroundScheduler {
    scheduler: CrawlScheduler,
}

impl BackgroundScheduler {
    pub fn new(config: Config) -> Self {
        Self {
            scheduler: CrawlScheduler::new(config),
        }
    }

    pub fn start(self) -> tokio::task::JoinHandle<Result<()>> {
        tokio::spawn(async move {
            self.scheduler.start().await
        })
    }
}
