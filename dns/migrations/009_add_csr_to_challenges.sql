-- Add CSR field to certificate challenges
ALTER TABLE certificate_challenges ADD COLUMN IF NOT EXISTS csr_pem TEXT;