-- Add table to store CA certificate and key
CREATE TABLE IF NOT EXISTS ca_certificates (
    id SERIAL PRIMARY KEY,
    ca_cert_pem TEXT NOT NULL,
    ca_key_pem TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_active BOOLEAN DEFAULT TRUE
);