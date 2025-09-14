use serde::{Deserialize, Serialize};
use std::path::PathBuf;

#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct Config {
    pub database: DatabaseConfig,
    pub server: ServerConfig,
    pub search: SearchConfig,
    pub crawler: CrawlerConfig,
    pub logging: LoggingConfig,
}

#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct DatabaseConfig {
    pub url: String,
    pub max_connections: u32,
}

#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct ServerConfig {
    pub address: String,
    pub port: u16,
    pub cert_path: PathBuf,
    pub key_path: PathBuf,
}

#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct SearchConfig {
    pub index_path: PathBuf,
    pub crawl_interval_hours: u64,
    pub max_pages_per_domain: usize,
    pub crawler_timeout_seconds: u64,
    pub crawler_user_agent: String,
    pub max_concurrent_crawls: usize,
    pub content_size_limit_mb: usize,
    pub index_rebuild_interval_hours: u64,
    pub search_results_per_page: usize,
    pub max_search_results: usize,
    pub allowed_extensions: Vec<String>,
    pub blocked_extensions: Vec<String>,
}

#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct CrawlerConfig {
    pub clanker_txt: bool,
    pub crawl_delay_ms: u64,
    pub max_redirects: usize,
    pub follow_external_links: bool,
    pub max_depth: usize,
    pub request_headers: Vec<(String, String)>,
}

#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct LoggingConfig {
    pub level: String,
    pub format: String,
}

impl Config {
    pub fn load_from_file(path: &str) -> anyhow::Result<Self> {
        let content = std::fs::read_to_string(path)
            .map_err(|e| anyhow::anyhow!("Failed to read config file {}: {}", path, e))?;
        
        let config: Config = toml::from_str(&content)
            .map_err(|e| anyhow::anyhow!("Failed to parse config file {}: {}", path, e))?;
        
        Ok(config)
    }

    pub fn database_url(&self) -> &str {
        &self.database.url
    }

    pub fn server_bind_address(&self) -> String {
        format!("{}:{}", self.server.address, self.server.port)
    }

    pub fn gurt_protocol_url(&self) -> String {
        format!("gurt://{}:{}", self.server.address, self.server.port)
    }

    pub fn is_allowed_extension(&self, extension: &str) -> bool {
        if self.is_blocked_extension(extension) {
            return false;
        }

        if self.search.allowed_extensions.is_empty() {
            return true;
        }
        self.search.allowed_extensions.iter()
            .any(|ext| ext.eq_ignore_ascii_case(extension))
    }

    pub fn is_blocked_extension(&self, extension: &str) -> bool {
        self.search.blocked_extensions.iter()
            .any(|ext| ext.eq_ignore_ascii_case(extension))
    }

    pub fn content_size_limit_bytes(&self) -> usize {
        self.search
            .content_size_limit_mb
            .saturating_mul(1024)
            .saturating_mul(1024)
    }

    pub fn crawler_timeout(&self) -> std::time::Duration {
        std::time::Duration::from_secs(self.search.crawler_timeout_seconds)
    }

    pub fn crawl_delay(&self) -> std::time::Duration {
        std::time::Duration::from_millis(self.crawler.crawl_delay_ms)
    }

    pub fn crawl_interval(&self) -> std::time::Duration {
        std::time::Duration::from_secs(self.search.crawl_interval_hours * 3600)
    }

    pub fn index_rebuild_interval(&self) -> std::time::Duration {
        std::time::Duration::from_secs(self.search.index_rebuild_interval_hours * 3600)
    }
}
