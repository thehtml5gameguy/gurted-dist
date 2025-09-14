mod config;
mod indexer;
mod crawler;
mod scheduler;
mod server;
mod models;

use anyhow::Result;
use clap::{Parser, Subcommand};
use config::Config;
use tracing::info;
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt};

#[derive(Parser)]
#[command(name = "gurted-search-engine")]
#[command(about = "Crawl and index registered GURT domains")]
#[command(version = "0.1.0")]
struct Cli {
    #[command(subcommand)]
    command: Commands,

    #[arg(long, default_value = "config.toml")]
    config: String,

    #[arg(short, long, action = clap::ArgAction::Count)]
    verbose: u8,
}

#[derive(Subcommand)]
enum Commands {
    Server,
    Crawl,
    RebuildIndex,
    Search {
        query: String,
        #[arg(short, long, default_value = "10")]
        limit: usize,
    },
    Stats,
}

#[tokio::main]
async fn main() -> Result<()> {
    let cli = Cli::parse();

    init_logging(&cli)?;

    let config = Config::load_from_file(&cli.config).unwrap();

    info!("Starting Gurted Search Engine v{}", env!("CARGO_PKG_VERSION"));
    info!("Configuration loaded from: {}", cli.config);

    match cli.command {
        Commands::Server => {
            info!("Starting search engine server on {}", config.server_bind_address());
            server::run_server(config).await?;
        }
        Commands::Crawl => {
            info!("Starting one-time crawl of all registered domains");
            crawler::run_crawl_all(config).await?;
        }
        Commands::RebuildIndex => {
            info!("Rebuilding search index from scratch");
            indexer::rebuild_index(config).await?;
        }
        Commands::Search { query, limit } => {
            info!("Testing search with query: '{}'", query);
            test_search(config, query, limit).await?;
        }
        Commands::Stats => {
            info!("Displaying search index statistics");
            show_stats(config).await?;
        }
    }

    Ok(())
}

fn init_logging(cli: &Cli) -> Result<()> {
    let log_level = match cli.verbose {
        0 => "info",
        1 => "debug",
        _ => "trace",
    };

    tracing_subscriber::registry()
        .with(
            tracing_subscriber::EnvFilter::try_from_default_env()
                .unwrap_or_else(|_| format!("gurted_search_engine={}", log_level).into()),
        )
        .with(tracing_subscriber::fmt::layer())
        .init();

    Ok(())
}

async fn test_search(config: Config, query: String, limit: usize) -> Result<()> {
    let search_engine = indexer::SearchEngine::new(config)?;
    let results = search_engine.search(&query, limit).await?;
    
    println!("Search results for '{}' (showing {} results):", 
             query, results.len());
    
    for (i, result) in results.iter().enumerate() {
        println!("{}. {} - {}", i + 1, result.title, result.url);
        println!("   {}", result.preview);
        println!();
    }
    
    Ok(())
}

async fn show_stats(config: Config) -> Result<()> {
    let search_engine = indexer::SearchEngine::new(config)?;
    let stats = search_engine.get_stats().await?;
    
    println!("Search Index Statistics:");
    println!("  Total documents: {}", stats.total_documents);
    println!("  Total domains: {}", stats.total_domains);
    println!("  Index size: {} MB", stats.index_size_mb);
    println!("  Last updated: {}", stats.last_updated);
    
    Ok(())
}