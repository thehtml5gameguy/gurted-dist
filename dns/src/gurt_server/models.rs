use super::helpers::deserialize_lowercase;
use serde::{Deserialize, Serialize};
use sqlx::{FromRow, types::chrono::{DateTime, Utc}};

#[derive(Clone, Debug, Deserialize, Serialize, FromRow)]
pub struct Domain {
    #[serde(skip_deserializing)]
    pub(crate) id: Option<i32>,
    #[serde(deserialize_with = "deserialize_lowercase")]
    pub(crate) name: String,
    #[serde(deserialize_with = "deserialize_lowercase")]
    pub(crate) tld: String,
    #[serde(skip_deserializing)]
    pub(crate) ip: Option<String>,
    #[serde(skip_deserializing)]
    pub(crate) user_id: Option<i32>,
    #[serde(skip_deserializing)]
    pub(crate) status: Option<String>,
    #[serde(skip_deserializing)]
    pub(crate) denial_reason: Option<String>,
    #[serde(skip_deserializing)]
    pub(crate) created_at: Option<DateTime<Utc>>,
}

#[derive(Clone, Debug, Deserialize, Serialize, FromRow)]
pub struct DnsRecord {
    #[serde(skip_deserializing)]
    pub(crate) id: Option<i32>,
    pub(crate) domain_id: i32,
    #[serde(deserialize_with = "deserialize_lowercase")]
    pub(crate) record_type: String, // A, AAAA, CNAME, TXT, MX, NS
    #[serde(deserialize_with = "deserialize_lowercase")]
    pub(crate) name: String,        // subdomain or @ for root
    pub(crate) value: String,       // IP, domain, text value, etc.
    pub(crate) ttl: Option<i32>,    // Time to live in seconds
    pub(crate) priority: Option<i32>, // For MX records
    #[serde(skip_deserializing)]
    pub(crate) created_at: Option<DateTime<Utc>>,
}

#[derive(Clone, Debug, Deserialize, Serialize, FromRow)]
pub struct User {
    pub(crate) id: i32,
    pub(crate) username: String,
    pub(crate) password_hash: String,
    pub(crate) registrations_remaining: i32,
    pub(crate) domain_invite_codes: i32,
    pub(crate) created_at: DateTime<Utc>,
}

#[derive(Clone, Debug, Deserialize, Serialize, FromRow)]
pub struct InviteCode {
    pub(crate) id: i32,
    pub(crate) code: String,
    pub(crate) created_by: Option<i32>,
    pub(crate) used_by: Option<i32>,
    pub(crate) created_at: DateTime<Utc>,
    pub(crate) used_at: Option<DateTime<Utc>>,
}

#[derive(Clone, Debug, Deserialize, Serialize, FromRow)]
pub struct DomainInviteCode {
    pub(crate) id: i32,
    pub(crate) code: String,
    pub(crate) created_by: Option<i32>,
    pub(crate) used_by: Option<i32>,
    pub(crate) created_at: DateTime<Utc>,
    pub(crate) used_at: Option<DateTime<Utc>>,
}

#[derive(Debug, Serialize)]
pub(crate) struct ResponseDomain {
    pub(crate) tld: String,
    pub(crate) name: String,
    pub(crate) records: Option<Vec<ResponseDnsRecord>>,
}

#[derive(Debug, Serialize)]
pub(crate) struct ResponseDnsRecord {
    pub(crate) id: i32,
    #[serde(rename = "type")]
    pub(crate) record_type: String,
    pub(crate) name: String,
    pub(crate) value: String,
    pub(crate) ttl: Option<i32>,
    pub(crate) priority: Option<i32>,
}

#[derive(Debug, Serialize, Deserialize)]
pub(crate) struct DnsResolutionRequest {
    pub(crate) name: String,
    pub(crate) tld: String,
}

#[derive(Debug, Serialize)]
pub(crate) struct DnsResolutionResponse {
    pub(crate) name: String,
    pub(crate) tld: String,
    pub(crate) records: Vec<ResponseDnsRecord>,
}

#[derive(Serialize)]
pub(crate) struct PaginationResponse {
    pub(crate) domains: Vec<ResponseDomain>,
    pub(crate) page: u32,
    pub(crate) limit: u32,
}

#[derive(Serialize)]
pub(crate) struct DomainList {
    pub(crate) domain: String,
    pub(crate) taken: bool,
}

#[derive(Debug, Serialize)]
pub(crate) struct UserDomain {
    pub(crate) name: String,
    pub(crate) tld: String,
    pub(crate) status: String,
    pub(crate) denial_reason: Option<String>,
}

#[derive(Serialize)]
pub(crate) struct UserDomainResponse {
    pub(crate) domains: Vec<UserDomain>,
    pub(crate) page: u32,
    pub(crate) limit: u32,
}

#[derive(Debug, Deserialize)]
pub(crate) struct CreateDnsRecord {
    #[serde(rename = "type")]
    pub(crate) record_type: String,
    pub(crate) name: Option<String>,
    pub(crate) value: String,
    #[serde(deserialize_with = "deserialize_ttl")]
    pub(crate) ttl: Option<i32>,
    pub(crate) priority: Option<i32>,
}

fn deserialize_ttl<'de, D>(deserializer: D) -> Result<Option<i32>, D::Error>
where
    D: serde::Deserializer<'de>,
{
    use serde::Deserialize;
    
    let value: Option<serde_json::Value> = Option::deserialize(deserializer)?;
    match value {
        Some(serde_json::Value::Number(n)) => {
            if let Some(f) = n.as_f64() {
                Ok(Some(f as i32))
            } else if let Some(i) = n.as_i64() {
                Ok(Some(i as i32))
            } else {
                Ok(None)
            }
        }
        Some(_) => Ok(None),
        None => Ok(None),
    }
}

#[derive(Debug, Serialize)]
pub(crate) struct DomainDetail {
    pub(crate) name: String,
    pub(crate) tld: String,
    pub(crate) status: Option<String>,
}
