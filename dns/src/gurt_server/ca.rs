use crate::crypto;
use anyhow::Result;
use sqlx::PgPool;

pub struct CaCertificate {
    pub ca_cert_pem: String,
    pub ca_key_pem: String,
}

pub async fn get_or_create_ca(db: &PgPool) -> Result<CaCertificate> {
    if let Some(ca_cert) = get_active_ca(db).await? {
        return Ok(ca_cert);
    }

    log::info!("Generating new CA certificate...");
    let (ca_key_pem, ca_cert_pem) = crypto::generate_ca_cert()?;

    sqlx::query(
        "INSERT INTO ca_certificates (ca_cert_pem, ca_key_pem, is_active) VALUES ($1, $2, TRUE)"
    )
    .bind(&ca_cert_pem)
    .bind(&ca_key_pem)
    .execute(db)
    .await?;

    log::info!("CA certificate generated and stored");
    
    Ok(CaCertificate {
        ca_cert_pem,
        ca_key_pem,
    })
}

async fn get_active_ca(db: &PgPool) -> Result<Option<CaCertificate>> {
    let result: Option<(String, String)> = sqlx::query_as(
        "SELECT ca_cert_pem, ca_key_pem FROM ca_certificates WHERE is_active = TRUE ORDER BY created_at DESC LIMIT 1"
    )
    .fetch_optional(db)
    .await?;

    Ok(result.map(|(ca_cert_pem, ca_key_pem)| CaCertificate {
        ca_cert_pem,
        ca_key_pem,
    }))
}
