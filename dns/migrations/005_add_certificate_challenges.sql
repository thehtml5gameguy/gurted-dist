-- Add certificate challenges table for CA functionality
CREATE TABLE IF NOT EXISTS certificate_challenges (
    id SERIAL PRIMARY KEY,
    token VARCHAR(255) UNIQUE NOT NULL,
    domain VARCHAR(255) NOT NULL,
    challenge_type VARCHAR(20) NOT NULL CHECK (challenge_type IN ('dns')),
    verification_data VARCHAR(500) NOT NULL,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'valid', 'invalid', 'expired')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    expires_at TIMESTAMPTZ NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_certificate_challenges_token ON certificate_challenges(token);
CREATE INDEX IF NOT EXISTS idx_certificate_challenges_domain ON certificate_challenges(domain);
CREATE INDEX IF NOT EXISTS idx_certificate_challenges_expires_at ON certificate_challenges(expires_at);

-- Add table to store issued certificates
CREATE TABLE IF NOT EXISTS issued_certificates (
    id SERIAL PRIMARY KEY,
    domain VARCHAR(255) NOT NULL,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    certificate_pem TEXT NOT NULL,
    private_key_pem TEXT NOT NULL,
    issued_at TIMESTAMPTZ DEFAULT NOW(),
    expires_at TIMESTAMPTZ NOT NULL,
    revoked_at TIMESTAMPTZ,
    serial_number VARCHAR(255) UNIQUE NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_issued_certificates_domain ON issued_certificates(domain);
CREATE INDEX IF NOT EXISTS idx_issued_certificates_user_id ON issued_certificates(user_id);
CREATE INDEX IF NOT EXISTS idx_issued_certificates_serial ON issued_certificates(serial_number);
CREATE INDEX IF NOT EXISTS idx_issued_certificates_expires_at ON issued_certificates(expires_at);