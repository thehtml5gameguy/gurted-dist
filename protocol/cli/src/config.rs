use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::path::PathBuf;
use std::sync::Arc;
use std::time::Duration;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GurtConfig {
    pub server: ServerConfig,
    pub tls: Option<TlsConfig>,
    pub logging: Option<LoggingConfig>,
    pub security: Option<SecurityConfig>,
    pub error_pages: Option<ErrorPagesConfig>,
    pub headers: Option<HashMap<String, String>>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ServerConfig {
    #[serde(default = "default_host")]
    pub host: String,
    
    #[serde(default = "default_port")]
    pub port: u16,
    
    #[serde(default = "default_protocol_version")]
    pub protocol_version: String,
    
    #[serde(default = "default_alpn_identifier")]
    pub alpn_identifier: String,
    
    pub timeouts: Option<TimeoutsConfig>,
    
    #[serde(default = "default_max_connections")]
    pub max_connections: u32,
    
    #[serde(default = "default_max_message_size")]
    pub max_message_size: String,
    
    #[serde(skip)]
    pub base_directory: Arc<PathBuf>,
    
    #[serde(skip)]
    pub verbose: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TimeoutsConfig {
    #[serde(default = "default_handshake_timeout")]
    pub handshake: u64,
    
    #[serde(default = "default_request_timeout")]
    pub request: u64,
    
    #[serde(default = "default_connection_timeout")]
    pub connection: u64,
    
    #[serde(default = "default_pool_idle_timeout")]
    pub pool_idle: u64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TlsConfig {
    pub certificate: PathBuf,
    pub private_key: PathBuf,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LoggingConfig {
    #[serde(default = "default_log_level")]
    pub level: String,
    
    pub access_log: Option<PathBuf>,
    pub error_log: Option<PathBuf>,
    
    #[serde(default = "default_log_requests")]
    pub log_requests: bool,
    
    #[serde(default)]
    pub log_responses: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SecurityConfig {
    #[serde(default)]
    pub deny_files: Vec<String>,
    
    #[serde(default = "default_allowed_methods")]
    pub allowed_methods: Vec<String>,
    
    #[serde(default = "default_rate_limit_requests")]
    pub rate_limit_requests: u32,
    
    #[serde(default = "default_rate_limit_connections")]
    pub rate_limit_connections: u32,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ErrorPagesConfig {
    #[serde(flatten)]
    pub pages: HashMap<String, String>,
    
    pub default: Option<ErrorPageDefaults>,
}

impl ErrorPagesConfig {
    pub fn get_page(&self, status_code: u16) -> Option<&String> {
        let code_str = status_code.to_string();
        self.pages.get(&code_str)
    }
    
    pub fn get_default_page(&self, status_code: u16) -> Option<&String> {
        if let Some(defaults) = &self.default {
            let code_str = status_code.to_string();
            defaults.pages.get(&code_str)
        } else {
            None
        }
    }
    
    pub fn get_any_page(&self, status_code: u16) -> Option<&String> {
        self.get_page(status_code)
            .or_else(|| self.get_default_page(status_code))
    }

    pub fn get_page_content(&self, status_code: u16, base_dir: &std::path::Path) -> Option<String> {
        if let Some(page_value) = self.get_page(status_code) {
            if page_value.starts_with('/') || page_value.starts_with("./") {
                let file_path = if page_value.starts_with('/') {
                    base_dir.join(&page_value[1..])
                } else {
                    base_dir.join(page_value)
                };
                
                if let Ok(content) = std::fs::read_to_string(&file_path) {
                    return Some(content);
                } else {
                    tracing::warn!("Failed to read error page file: {}", file_path.display());
                    return None;
                }
            } else {
                return Some(page_value.clone());
            }
        }
        
        if let Some(page_value) = self.get_default_page(status_code) {
            return Some(page_value.clone());
        }
        
        None
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ErrorPageDefaults {
    #[serde(flatten)]
    pub pages: HashMap<String, String>,
}

fn default_host() -> String { "127.0.0.1".to_string() }
fn default_port() -> u16 { 4878 }
fn default_protocol_version() -> String { "1.0.0".to_string() }
fn default_alpn_identifier() -> String { "GURT/1.0".to_string() }
fn default_max_connections() -> u32 { 10 }
fn default_max_message_size() -> String { "10MB".to_string() }
fn default_handshake_timeout() -> u64 { 5 }
fn default_request_timeout() -> u64 { 30 }
fn default_connection_timeout() -> u64 { 10 }
fn default_pool_idle_timeout() -> u64 { 300 }
fn default_log_level() -> String { "info".to_string() }
fn default_log_requests() -> bool { true }
fn default_allowed_methods() -> Vec<String> {
    vec!["GET".to_string(), "POST".to_string(), "PUT".to_string(), 
         "DELETE".to_string(), "HEAD".to_string(), "OPTIONS".to_string(), "PATCH".to_string()]
}
fn default_rate_limit_requests() -> u32 { 100 }
fn default_rate_limit_connections() -> u32 { 10 }

impl Default for GurtConfig {
    fn default() -> Self {
        Self {
            server: ServerConfig::default(),
            tls: None,
            logging: None,
            security: None,
            error_pages: None,
            headers: None,
        }
    }
}

impl Default for ServerConfig {
    fn default() -> Self {
        Self {
            host: default_host(),
            port: default_port(),
            protocol_version: default_protocol_version(),
            alpn_identifier: default_alpn_identifier(),
            timeouts: None,
            max_connections: default_max_connections(),
            max_message_size: default_max_message_size(),
            base_directory: Arc::new(PathBuf::from(".")),
            verbose: false,
        }
    }
}

impl GurtConfig {
    pub fn from_file<P: AsRef<std::path::Path>>(path: P) -> crate::Result<Self> {
        let content = std::fs::read_to_string(path)
            .map_err(|e| crate::ServerError::InvalidConfiguration(format!("Failed to read config file: {}", e)))?;
        
        let config: GurtConfig = toml::from_str(&content)
            .map_err(|e| crate::ServerError::InvalidConfiguration(format!("Failed to parse config file: {}", e)))?;
        
        Ok(config)
    }

    pub fn builder() -> GurtConfigBuilder {
        GurtConfigBuilder::default()
    }

    pub fn address(&self) -> String {
        format!("{}:{}", self.server.host, self.server.port)
    }

    pub fn max_message_size_bytes(&self) -> crate::Result<u64> {
        parse_size(&self.server.max_message_size)
    }

    pub fn get_handshake_timeout(&self) -> Duration {
        Duration::from_secs(
            self.server.timeouts
                .as_ref()
                .map(|t| t.handshake)
                .unwrap_or(default_handshake_timeout())
        )
    }

    pub fn get_request_timeout(&self) -> Duration {
        Duration::from_secs(
            self.server.timeouts
                .as_ref()
                .map(|t| t.request)
                .unwrap_or(default_request_timeout())
        )
    }

    pub fn get_connection_timeout(&self) -> Duration {
        Duration::from_secs(
            self.server.timeouts
                .as_ref()
                .map(|t| t.connection)
                .unwrap_or(default_connection_timeout())
        )
    }

    pub fn should_deny_file(&self, file_path: &str) -> bool {
        if let Some(security) = &self.security {
            for pattern in &security.deny_files {
                if matches_pattern(file_path, pattern) {
                    return true;
                }
            }
        }
        false
    }

    pub fn is_method_allowed(&self, method: &str) -> bool {
        if let Some(security) = &self.security {
            security.allowed_methods.contains(&method.to_uppercase())
        } else {
            default_allowed_methods().contains(&method.to_uppercase())
        }
    }

    pub fn default_with_directory(base_dir: PathBuf) -> Self {
        let mut config = Self::default();
        config.server.base_directory = Arc::new(base_dir);
        config
    }

    pub fn from_toml(toml_content: &str, base_dir: PathBuf) -> crate::Result<Self> {
        let mut config: GurtConfig = toml::from_str(toml_content)
            .map_err(|e| crate::ServerError::InvalidConfiguration(format!("Failed to parse config: {}", e)))?;
        
        config.server.base_directory = Arc::new(base_dir);
        Ok(config)
    }

    pub fn validate(&self) -> crate::Result<()> {
        if !self.server.base_directory.exists() || !self.server.base_directory.is_dir() {
            return Err(crate::ServerError::InvalidConfiguration(
                format!("Invalid base directory: {}", self.server.base_directory.display())
            ));
        }

        if let Some(tls) = &self.tls {
            if !tls.certificate.exists() {
                return Err(crate::ServerError::TlsConfiguration(
                    format!("Certificate file does not exist: {}", tls.certificate.display())
                ));
            }
            if !tls.private_key.exists() {
                return Err(crate::ServerError::TlsConfiguration(
                    format!("Private key file does not exist: {}", tls.private_key.display())
                ));
            }
        }

        Ok(())
    }
}

#[derive(Default)]
pub struct GurtConfigBuilder {
    config: GurtConfig,
}

impl GurtConfigBuilder {
    pub fn new() -> Self {
        Self::default()
    }

    pub fn host<S: Into<String>>(mut self, host: S) -> Self {
        self.config.server.host = host.into();
        self
    }

    pub fn port(mut self, port: u16) -> Self {
        self.config.server.port = port;
        self
    }

    pub fn base_directory<P: Into<PathBuf>>(mut self, dir: P) -> Self {
        self.config.server.base_directory = Arc::new(dir.into());
        self
    }

    pub fn verbose(mut self, verbose: bool) -> Self {
        self.config.server.verbose = verbose;
        self
    }

    pub fn tls_config(mut self, cert_path: PathBuf, key_path: PathBuf) -> Self {
        self.config.tls = Some(TlsConfig {
            certificate: cert_path,
            private_key: key_path,
        });
        self
    }

    pub fn logging_config(mut self, config: LoggingConfig) -> Self {
        self.config.logging = Some(config);
        self
    }

    pub fn security_config(mut self, config: SecurityConfig) -> Self {
        self.config.security = Some(config);
        self
    }

    pub fn error_pages_config(mut self, config: ErrorPagesConfig) -> Self {
        self.config.error_pages = Some(config);
        self
    }

    pub fn headers(mut self, headers: HashMap<String, String>) -> Self {
        self.config.headers = Some(headers);
        self
    }

    pub fn from_file<P: AsRef<std::path::Path>>(mut self, path: P) -> crate::Result<Self> {
        let file_config = GurtConfig::from_file(path)?;
        self.config = merge_configs(file_config, self.config);
        Ok(self)
    }

    pub fn merge_cli_args(mut self, cli_args: &crate::cli::ServeCommand) -> Self {
        self.config.server.host = cli_args.host.clone();
        self.config.server.port = cli_args.port;
        self.config.server.base_directory = Arc::new(cli_args.dir.clone());
        self.config.server.verbose = cli_args.verbose;

        if let (Some(cert), Some(key)) = (&cli_args.cert, &cli_args.key) {
            self.config.tls = Some(TlsConfig {
                certificate: cert.clone(),
                private_key: key.clone(),
            });
        }

        self
    }

    pub fn build(self) -> crate::Result<GurtConfig> {
        let config = self.config;

        if !config.server.base_directory.exists() || !config.server.base_directory.is_dir() {
            return Err(crate::ServerError::InvalidConfiguration(
                format!("Invalid base directory: {}", config.server.base_directory.display())
            ));
        }

        if let Some(tls) = &config.tls {
            if !tls.certificate.exists() {
                return Err(crate::ServerError::TlsConfiguration(
                    format!("Certificate file does not exist: {}", tls.certificate.display())
                ));
            }
            if !tls.private_key.exists() {
                return Err(crate::ServerError::TlsConfiguration(
                    format!("Private key file does not exist: {}", tls.private_key.display())
                ));
            }
        }

        Ok(config)
    }
}


fn parse_size(size_str: &str) -> crate::Result<u64> {
    let size_str = size_str.trim().to_uppercase();
    
    if let Some(captures) = regex::Regex::new(r"^(\d+(?:\.\d+)?)\s*([KMGT]?B?)$").unwrap().captures(&size_str) {
        let number: f64 = captures[1].parse()
            .map_err(|_| crate::ServerError::InvalidConfiguration(format!("Invalid size format: {}", size_str)))?;
        
        let unit = captures.get(2).map_or("", |m| m.as_str());
        
        let multiplier: u64 = match unit {
            "" | "B" => 1,
            "KB" => 1_000,
            "MB" => 1_000_000,
            "GB" => 1_000_000_000,
            "TB" => 1_000_000_000_000,
            _ => return Err(crate::ServerError::InvalidConfiguration(format!("Unknown size unit: {}", unit))),
        };
        let number = (number * multiplier as f64) as u64;
        Ok(number)
    } else {
        Err(crate::ServerError::InvalidConfiguration(format!("Invalid size format: {}", size_str)))
    }
}

fn matches_pattern(path: &str, pattern: &str) -> bool {
    if pattern.ends_with("/*") {
        let prefix = &pattern[..pattern.len() - 2];
        path.starts_with(prefix)
    } else if pattern.starts_with("*.") {
        let suffix = &pattern[1..];
        path.ends_with(suffix)
    } else {
        path == pattern
    }
}

fn merge_configs(base: GurtConfig, override_config: GurtConfig) -> GurtConfig {
    GurtConfig {
        server: merge_server_configs(base.server, override_config.server),
        tls: override_config.tls.or(base.tls),
        logging: override_config.logging.or(base.logging),
        security: override_config.security.or(base.security),
        error_pages: override_config.error_pages.or(base.error_pages),
        headers: override_config.headers.or(base.headers),
    }
}

fn merge_server_configs(base: ServerConfig, override_config: ServerConfig) -> ServerConfig {
    ServerConfig {
        host: if override_config.host != default_host() { override_config.host } else { base.host },
        port: if override_config.port != default_port() { override_config.port } else { base.port },
        protocol_version: if override_config.protocol_version != default_protocol_version() { 
            override_config.protocol_version 
        } else { 
            base.protocol_version 
        },
        alpn_identifier: if override_config.alpn_identifier != default_alpn_identifier() { 
            override_config.alpn_identifier 
        } else { 
            base.alpn_identifier 
        },
        timeouts: override_config.timeouts.or(base.timeouts),
        max_connections: if override_config.max_connections != default_max_connections() { 
            override_config.max_connections 
        } else { 
            base.max_connections 
        },
        max_message_size: if override_config.max_message_size != default_max_message_size() { 
            override_config.max_message_size 
        } else { 
            base.max_message_size 
        },
        base_directory: override_config.base_directory,
        verbose: override_config.verbose,
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::path::PathBuf;

    #[test]
    fn test_default_config_creation() {
        let base_dir = PathBuf::from("/tmp");
        let mut config = GurtConfig::default();
        config.server.base_directory = Arc::new(base_dir.clone());
        
        assert_eq!(config.server.host, "127.0.0.1");
        assert_eq!(config.server.port, 4878);
        assert_eq!(config.server.protocol_version, "1.0.0");
        assert_eq!(config.server.alpn_identifier, "GURT/1.0");
        assert_eq!(*config.server.base_directory, base_dir);
    }

    #[test]
    fn test_config_from_valid_toml() {
        let toml_content = r#"
[server]
host = "0.0.0.0"
port = 8080
protocol_version = "2.0.0"
alpn_identifier = "custom"
max_connections = 1000
max_message_size = "10MB"

[security]
rate_limit_requests = 60
rate_limit_connections = 5
"#;
        
        let base_dir = PathBuf::from("/tmp");
        let config = GurtConfig::from_toml(toml_content, base_dir).unwrap();
        
        assert_eq!(config.server.host, "0.0.0.0");
        assert_eq!(config.server.port, 8080);
        assert_eq!(config.server.protocol_version, "2.0.0");
        assert_eq!(config.server.alpn_identifier, "custom");
        assert_eq!(config.server.max_connections, 1000);
        
        let security = config.security.unwrap();
        assert_eq!(security.rate_limit_requests, 60);
        assert_eq!(security.rate_limit_connections, 5);
    }

    #[test]
    fn test_invalid_toml_returns_error() {
        let invalid_toml = r#"
[server
host = "0.0.0.0"
"#;
        
        let base_dir = PathBuf::from("/tmp");
        let result = GurtConfig::from_toml(invalid_toml, base_dir);
        
        assert!(result.is_err());
    }

    #[test]
    fn test_max_message_size_parsing() {
        let config = GurtConfig::default();
        
        assert_eq!(parse_size("1024").unwrap(), 1024);
        assert_eq!(parse_size("1KB").unwrap(), 1000);
        assert_eq!(parse_size("1MB").unwrap(), 1000 * 1000);
        assert_eq!(parse_size("1GB").unwrap(), 1000 * 1000 * 1000);
        
        assert!(parse_size("invalid").is_err());
        
        assert!(config.max_message_size_bytes().is_ok());
    }

    #[test]
    fn test_tls_config_validation() {
        let mut config = GurtConfig::default();
        
        config.tls = Some(TlsConfig {
            certificate: PathBuf::from("/nonexistent/cert.pem"),
            private_key: PathBuf::from("/nonexistent/key.pem"),
        });
        
        assert!(config.tls.is_some());
        let tls = config.tls.unwrap();
        assert_eq!(tls.certificate, PathBuf::from("/nonexistent/cert.pem"));
        assert_eq!(tls.private_key, PathBuf::from("/nonexistent/key.pem"));
    }

    #[test]
    fn test_address_formatting() {
        let config = GurtConfig::default();
        assert_eq!(config.address(), "127.0.0.1:4878");
        
        let mut custom_config = GurtConfig::default();
        custom_config.server.host = "0.0.0.0".to_string();
        custom_config.server.port = 8080;
        assert_eq!(custom_config.address(), "0.0.0.0:8080");
    }

    #[test]
    fn test_timeout_getters() {
        let config = GurtConfig::default();
        
        assert_eq!(config.get_handshake_timeout(), Duration::from_secs(5));
        assert_eq!(config.get_request_timeout(), Duration::from_secs(30));
        assert_eq!(config.get_connection_timeout(), Duration::from_secs(10));
    }
}
