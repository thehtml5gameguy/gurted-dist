use anyhow::Result;
use crate::client::{Challenge, GurtCAClient};

pub async fn complete_dns_challenge(challenge: &Challenge, client: &GurtCAClient) -> Result<()> {
    println!("Please add this TXT record to your domain:");
    println!("   1. Go to gurt://dns.web (or your DNS server)");
    println!("   2. Login and navigate to your domain: {}", challenge.domain);
    println!("   3. Add TXT record:");
    println!("      Name: _gurtca-challenge");
    println!("      Value: {}", challenge.verification_data);
    println!("   4. Press Enter when ready...");
    
    let mut input = String::new();
    std::io::stdin().read_line(&mut input)?;
    
    println!("🔍 Verifying DNS record...");
    
    if verify_dns_txt_record(&challenge.domain, &challenge.verification_data, client).await? {
        println!("✅ DNS challenge completed successfully!");
        Ok(())
    } else {
        anyhow::bail!("❌ DNS verification failed. Make sure the TXT record is correctly set.");
    }
}

async fn verify_dns_txt_record(domain: &str, expected_value: &str, client: &GurtCAClient) -> Result<bool> {
    let request = serde_json::json!({
        "domain": format!("_gurtca-challenge.{}", domain),
        "record_type": "TXT"
    });
    
    let response = client
        .post_json("gurt://dns.web/resolve-full", &request)
        .await?;
    
    if response.is_success() {
        let dns_response: serde_json::Value = serde_json::from_slice(&response.body)?;
        
        if let Some(records) = dns_response["records"].as_array() {
            for record in records {
                if record["type"] == "TXT" && record["value"] == expected_value {
                    return Ok(true);
                }
            }
        }
    }
    
    Ok(false)
}