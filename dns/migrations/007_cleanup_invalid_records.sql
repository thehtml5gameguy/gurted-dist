-- Remove invalid record types before applying constraint
DELETE FROM dns_records WHERE record_type NOT IN ('A', 'AAAA', 'CNAME', 'TXT');

-- Now apply the constraint
ALTER TABLE dns_records DROP CONSTRAINT IF EXISTS dns_records_record_type_check;
ALTER TABLE dns_records ADD CONSTRAINT dns_records_record_type_check 
    CHECK (record_type IN ('A', 'AAAA', 'CNAME', 'TXT'));