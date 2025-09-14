-- Make IP column optional for domains
ALTER TABLE domains ALTER COLUMN ip DROP NOT NULL;

-- Update DNS records constraint to only allow A, AAAA, CNAME, TXT
ALTER TABLE dns_records DROP CONSTRAINT IF EXISTS dns_records_record_type_check;
ALTER TABLE dns_records ADD CONSTRAINT dns_records_record_type_check 
    CHECK (record_type IN ('A', 'AAAA', 'CNAME', 'TXT'));