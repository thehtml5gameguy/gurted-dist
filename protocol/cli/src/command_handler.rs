use crate::{
    cli::ServeCommand,
    config::GurtConfig,
    server::FileServerBuilder,
    Result,
};
use async_trait::async_trait;
use colored::Colorize;
use tracing::{error, info};

#[async_trait]
pub trait CommandHandler {
    async fn execute(&self) -> Result<()>;
}

pub struct CommandHandlerBuilder {
    logging_initialized: bool,
    verbose: bool,
}

impl CommandHandlerBuilder {
    pub fn new() -> Self {
        Self {
            logging_initialized: false,
            verbose: false,
        }
    }

    pub fn with_logging(mut self, verbose: bool) -> Self {
        self.verbose = verbose;
        self
    }

    pub fn initialize_logging(mut self) -> Self {
        if !self.logging_initialized {
            let level = if self.verbose {
                tracing::Level::DEBUG
            } else {
                tracing::Level::INFO
            };
            
            tracing_subscriber::fmt()
                .with_max_level(level)
                .init();
            
            self.logging_initialized = true;
        }
        self
    }

    pub fn build_serve_handler(self, serve_cmd: ServeCommand) -> ServeCommandHandler {
        ServeCommandHandler::new(serve_cmd)
    }
}

impl Default for CommandHandlerBuilder {
    fn default() -> Self {
        Self::new()
    }
}

pub struct ServeCommandHandler {
    serve_cmd: ServeCommand,
}

impl ServeCommandHandler {
    pub fn new(serve_cmd: ServeCommand) -> Self {
        Self { serve_cmd }
    }

    fn validate_command(&self) -> Result<()> {
        if !self.serve_cmd.dir.exists() {
            return Err(crate::ServerError::InvalidPath(
                format!("Directory does not exist: {}", self.serve_cmd.dir.display())
            ));
        }

        if !self.serve_cmd.dir.is_dir() {
            return Err(crate::ServerError::InvalidPath(
                format!("Path is not a directory: {}", self.serve_cmd.dir.display())
            ));
        }

        Ok(())
    }

    fn build_server_config(&self) -> Result<GurtConfig> {
        let mut config_builder = GurtConfig::builder();

        if let Some(config_file) = &self.serve_cmd.config {
            config_builder = config_builder.from_file(config_file)?;
        }

        let config = config_builder
            .merge_cli_args(&self.serve_cmd)
            .build()?;

        Ok(config)
    }

    fn display_startup_info(&self, config: &GurtConfig) {
        println!("{}", "GURT Protocol Server".bright_cyan().bold());
        println!("{} {}", "Version".bright_blue(), config.server.protocol_version);
        println!("{} {}", "Listening on".bright_blue(), config.address());
        println!("{} {}", "Serving from".bright_blue(), config.server.base_directory.display());
        
        if config.tls.is_some() {
            println!("{}", "TLS encryption enabled".bright_green());
        }

        if let Some(logging) = &config.logging {
            println!("{} {}", "Log level".bright_blue(), logging.level);
            if logging.log_requests {
                println!("{}", "Request logging enabled".bright_green());
            }
        }

        if let Some(security) = &config.security {
            println!("{} {} req/min", "Rate limit".bright_blue(), security.rate_limit_requests);
            if !security.deny_files.is_empty() {
                println!("{} {} patterns", "File restrictions".bright_blue(), security.deny_files.len());
            }
        }

        if let Some(headers) = &config.headers {
            if !headers.is_empty() {
                println!("{} {} headers", "Custom headers".bright_blue(), headers.len());
            }
        }

        println!("{} {}", "Max connections".bright_blue(), config.server.max_connections);
        println!("{} {}", "Max message size".bright_blue(), config.server.max_message_size);
        println!();
    }

    async fn start_server(&self, config: &GurtConfig) -> Result<()> {
        let server = FileServerBuilder::new(config.clone()).build()?;
        
        info!("Starting GURT server on {}", config.address());
        
        if let Err(e) = server.listen(&config.address()).await {
            error!("Server error: {}", e);
            std::process::exit(1);
        }

        Ok(())
    }
}

#[async_trait]
impl CommandHandler for ServeCommandHandler {
    async fn execute(&self) -> Result<()> {
        self.validate_command()?;
        
        let config = self.build_server_config()?;
        
        self.display_startup_info(&config);
        self.start_server(&config).await
    }
}
