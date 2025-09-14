use clap::Parser;
use gurty::{
    cli::{Cli, Commands},
    command_handler::{CommandHandler, CommandHandlerBuilder},
    Result,
};

#[tokio::main]
async fn main() -> Result<()> {
    let cli = Cli::parse();
    
    match cli.command {
        Commands::Serve(serve_cmd) => {
            let handler = CommandHandlerBuilder::new()
                .with_logging(serve_cmd.verbose)
                .initialize_logging()
                .build_serve_handler(serve_cmd);
            
            handler.execute().await
        }
    }
}

