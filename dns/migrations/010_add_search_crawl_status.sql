-- Search engine domain crawl status tracking
CREATE TABLE IF NOT EXISTS domain_crawl_status (
    domain_id INTEGER PRIMARY KEY REFERENCES domains(id) ON DELETE CASCADE,
    last_crawled_at TIMESTAMPTZ,
    next_crawl_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    crawl_status VARCHAR(20) DEFAULT 'pending' CHECK (crawl_status IN ('pending', 'crawling', 'completed', 'failed', 'disabled')),
    error_message TEXT,
    pages_found INTEGER DEFAULT 0,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_domain_crawl_status_next_crawl ON domain_crawl_status(next_crawl_at);
CREATE INDEX IF NOT EXISTS idx_domain_crawl_status_status ON domain_crawl_status(crawl_status);

-- Function to update the updated_at column
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for updated_at
DROP TRIGGER IF EXISTS update_domain_crawl_status_updated_at ON domain_crawl_status;
CREATE TRIGGER update_domain_crawl_status_updated_at
    BEFORE UPDATE ON domain_crawl_status
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();