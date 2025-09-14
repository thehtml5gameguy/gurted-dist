-- Re-add NS record support and extend record types
ALTER TABLE dns_records DROP CONSTRAINT IF EXISTS dns_records_record_type_check;
ALTER TABLE dns_records ADD CONSTRAINT dns_records_record_type_check 
    CHECK (record_type IN ('A', 'AAAA', 'CNAME', 'TXT', 'NS', 'MX'));

-- Add index for efficient NS record lookups during delegation
CREATE INDEX IF NOT EXISTS idx_dns_records_ns_lookup ON dns_records(record_type, name) WHERE record_type = 'NS';

-- Add index for subdomain resolution optimization
CREATE INDEX IF NOT EXISTS idx_dns_records_subdomain_lookup ON dns_records(domain_id, name, record_type);