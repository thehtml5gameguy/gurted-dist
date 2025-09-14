# Ringle

The official Gurted search engine.

## Configuration
```sh
cp config.template.toml config.toml
```
### Values
```toml
[database]
url = "postgres://..." # A valid postgres database url
max_connections = 5 # The maximum amount of simultaneous connections to the database
```
```toml
[server]
address = "127.0.0.1" # The binding adress the server will listen to
port = 4879 # The port the server will listen on
cert_path = "certs/t.crt" # A path to the certificate
key_path = "certs/t.key" # A path to the key for the certificate
```

```toml
[search]
index_path = "./search_indexes" # The path where the indexed pages will be saved to
crawl_interval_hours = 2 # How frequently should the search engine crawl (in hours)
max_pages_per_domain = 1000 # Maximum amount of pages indexed per domain
crawler_timeout_seconds = 30 # The maximum amount of seconds before a page times out and is skipped
crawler_user_agent = "RingleBot/1.0" # The user agent the crawler should use
max_concurrent_crawls = 5 # How many pages should the bot crawl concurrently
content_size_limit_mb = 10 # The maximum amount of data a page can be
index_rebuild_interval_hours = 48 # How often (in hours) should the index be rebuilt
search_results_per_page = 20 # How many search results should be displayed per page
max_search_results = 1000 # The maximum amount of results displayed

allowed_extensions = [ # Extensions allowed to be indexed
    "html", "htm", "txt", "md", "json", "xml", "rss", "atom"
]

blocked_extensions = [ # Extension that should not be indexed
    "exe", "zip", "rar", "tar", "gz", "7z", "iso", "dmg",
    "pdf", "doc", "docx", "xls", "xlsx", "ppt", "pptx",
    "jpg", "jpeg", "png", "gif", "bmp", "svg", "webp",
    "mp3", "mp4", "avi", "mov", "wmv", "flv", "webm",
    "css", "js", "woff", "woff2", "ttf", "eot"
]
```

```toml
[crawler]
clanker_txt = true # Wheter or not should the crawler respect clanker.txt
crawl_delay_ms = 1000 # The delay between each page crawl
max_redirects = 5 # The maximum amount of redirects the crawler shoul follow
follow_external_links = false # Crawl external links found in the page?
max_depth = 10 # The maximum amount of nested pages

request_headers = [ # The headers the crawler will include in the request while crawling
    ["Accept", "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"],
    ["Accept-Language", "en-US,en;q=0.5"],
    ["Accept-Encoding", "gzip, deflate"],
    ["DNT", "1"],
]
```

```toml
[logging]
level = "info" # How much should the search engine log, can be info, debug or trace
format = "compact" # The format for the logs
```

## Running
Run with:
```sh
cargo run
```