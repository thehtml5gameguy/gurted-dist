use anyhow::Result;
use openssl::pkey::PKey;
use openssl::rsa::Rsa;
use openssl::x509::X509Req;
use openssl::x509::X509Name;
use openssl::hash::MessageDigest;

pub fn generate_key_and_csr(domain: &str) -> Result<(String, String)> {
    let rsa = Rsa::generate(2048)?;
    let private_key = PKey::from_rsa(rsa)?;
    
    let mut name_builder = X509Name::builder()?;
    name_builder.append_entry_by_text("C", "US")?;
    name_builder.append_entry_by_text("O", "Gurted Network")?;
    name_builder.append_entry_by_text("CN", domain)?;
    let name = name_builder.build();
    
    let mut req_builder = X509Req::builder()?;
    req_builder.set_subject_name(&name)?;
    req_builder.set_pubkey(&private_key)?;
    req_builder.sign(&private_key, MessageDigest::sha256())?;
    
    let csr = req_builder.build();
    
    let private_key_pem = private_key.private_key_to_pem_pkcs8()?;
    let csr_pem = csr.to_pem()?;
    
    Ok((
        String::from_utf8(private_key_pem)?,
        String::from_utf8(csr_pem)?
    ))
}