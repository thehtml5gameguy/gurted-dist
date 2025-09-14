use clap::{Parser, Subcommand};
use std::path::PathBuf;

#[derive(Parser)]
#[command(name = "server")]
#[command(about = "GURT Protocol Server")]
#[command(version = "1.0.0")]
pub struct Cli {
    #[command(subcommand)]
    pub command: Commands,
}

#[derive(Subcommand)]
pub enum Commands {
    Serve(ServeCommand),
}

#[derive(Parser)]
pub struct ServeCommand {
    #[arg(short, long, help = "Configuration file path")]
    pub config: Option<PathBuf>,
    
    #[arg(short, long, default_value_t = 4878)]
    pub port: u16,
    
    #[arg(long, default_value = "127.0.0.1")]
    pub host: String,
    
    #[arg(short, long, default_value = ".")]
    pub dir: PathBuf,
    
    #[arg(short, long)]
    pub verbose: bool,
    
    #[arg(long, help = "Path to TLS certificate file")]
    pub cert: Option<PathBuf>,
    
    #[arg(long, help = "Path to TLS private key file")]
    pub key: Option<PathBuf>,
}

impl ServeCommand {
    pub fn validate(&self) -> crate::Result<()> {
        if !self.dir.exists() {
            return Err(crate::ServerError::InvalidPath(
                format!("Directory does not exist: {}", self.dir.display())
            ));
        }

        if !self.dir.is_dir() {
            return Err(crate::ServerError::InvalidPath(
                format!("Path is not a directory: {}", self.dir.display())
            ));
        }

        match (&self.cert, &self.key) {
            (Some(cert), Some(key)) => {
                if !cert.exists() {
                    return Err(crate::ServerError::TlsConfiguration(
                        format!("Certificate file does not exist: {}", cert.display())
                    ));
                }
                if !key.exists() {
                    return Err(crate::ServerError::TlsConfiguration(
                        format!("Key file does not exist: {}", key.display())
                    ));
                }
            }
            (Some(_), None) => {
                return Err(crate::ServerError::TlsConfiguration(
                    "Certificate provided but no key file specified (use --key)".to_string()
                ));
            }
            (None, Some(_)) => {
                return Err(crate::ServerError::TlsConfiguration(
                    "Key provided but no certificate file specified (use --cert)".to_string()
                ));
            }
            (None, None) => {
                return Err(crate::ServerError::TlsConfiguration(
                    "GURT protocol requires TLS encryption. Please provide --cert and --key parameters.".to_string()
                ));
            }
        }

        Ok(())
    }
}
