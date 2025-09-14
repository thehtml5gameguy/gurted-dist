-- Fix record types to remove MX and ensure NS is supported
ALTER TABLE dns_records DROP CONSTRAINT IF EXISTS dns_records_record_type_check;
ALTER TABLE dns_records ADD CONSTRAINT dns_records_record_type_check 
    CHECK (record_type IN ('A', 'AAAA', 'CNAME', 'TXT', 'NS'));

-- Add indexes for efficient DNS lookups if they don't exist
CREATE INDEX IF NOT EXISTS idx_dns_records_ns_lookup ON dns_records(record_type, name) WHERE record_type = 'NS';
CREATE INDEX IF NOT EXISTS idx_dns_records_subdomain_lookup ON dns_records(domain_id, name, record_type);