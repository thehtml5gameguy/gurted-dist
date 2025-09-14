use clap::{Parser, Subcommand};
use anyhow::Result;

mod challenges;
mod crypto;
mod client;

#[derive(Parser)]
#[command(name = "gurtca")]
#[command(about = "Gurted Certificate Authority CLI - Get TLS certificates for your domains")]
struct Cli {
    #[command(subcommand)]
    command: Commands,
    
    #[arg(long, default_value = "gurt://dns.web")]
    ca_url: String,
}

#[derive(Subcommand)]
enum Commands {
    Request {
        domain: String,
        
        #[arg(long, default_value = "./certs")]
        output: String,
    },
    GetCa {
        #[arg(long, default_value = "./ca.crt")]
        output: String,
    },
}

#[tokio::main]
async fn main() -> Result<()> {
    let cli = Cli::parse();
    
    let client = client::GurtCAClient::new_with_ca_discovery(cli.ca_url).await?;
    
    match cli.command {
        Commands::Request { domain, output } => {
            println!("🔐 Requesting certificate for: {}", domain);
            request_certificate(&client, &domain, &output).await?;
        },
        Commands::GetCa { output } => {
            println!("📋 Fetching CA certificate from server...");
            get_ca_certificate(&client, &output).await?;
        },
    }
    
    Ok(())
}

async fn request_certificate(
    client: &client::GurtCAClient, 
    domain: &str, 
    output_dir: &str
) -> Result<()> {
    println!("🔍 Verifying domain exists...");
    if !client.verify_domain_exists(domain).await? {
        anyhow::bail!("❌ Domain does not exist or is not approved: {}", domain);
    }
    
    println!("🔑 Generating key pair...");
    let (private_key, csr) = crypto::generate_key_and_csr(domain)?;
    
    println!("📝 Submitting certificate request...");
    let challenge = client.request_certificate(domain, &csr).await?;
    
    println!("🧩 Completing DNS challenge...");
    challenges::complete_dns_challenge(&challenge, client).await?;
    
    println!("⏳ Waiting for certificate issuance...");
    let certificate = client.poll_certificate(&challenge.token).await?;
    
    println!("💾 Saving certificate files...");
    std::fs::create_dir_all(output_dir)?;
    
    std::fs::write(
        format!("{}/{}.crt", output_dir, domain),
        certificate.cert_pem
    )?;
    
    std::fs::write(
        format!("{}/{}.key", output_dir, domain),
        private_key
    )?;
    
    println!("✅ Certificate successfully issued for: {}", domain);
    println!("📁 Files saved to: {}", output_dir);
    println!("   - Certificate: {}/{}.crt", output_dir, domain);
    println!("   - Private Key: {}/{}.key", output_dir, domain);
    
    Ok(())
}

async fn get_ca_certificate(
    client: &client::GurtCAClient,
    output_path: &str
) -> Result<()> {
    let ca_cert = client.fetch_ca_certificate().await?;
    
    std::fs::write(output_path, &ca_cert)?;
    
    println!("✅ CA certificate saved to: {}", output_path);
    Ok(())
}