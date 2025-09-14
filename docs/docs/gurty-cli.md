---
sidebar_position: 5
---

# Gurty CLI Tool

**Gurty** is a command-line interface tool for setting up and managing GURT protocol servers. It provides an easy way to deploy GURT servers with proper TLS configuration for both development and production environments.

## Installation

To begin, [install Gurty here](https://gurted.com/download).

## Configuration

Gurty supports configuration through TOML files. Use the provided template to get started:

```bash
cd protocol/cli
cp gurty.template.toml gurty.toml
```

### Configuration File Structure

The configuration file includes the following sections:

#### Server Settings
```toml
[server]
host = "127.0.0.1"
port = 4878
protocol_version = "1.0.0"
alpn_identifier = "GURT/1.0"
max_connections = 10
max_message_size = "10MB"

[server.timeouts]
handshake = 5
request = 30
connection = 10
pool_idle = 300
```

#### TLS Configuration
```toml
[tls]
certificate = "localhost+2.pem"
private_key = "localhost+2-key.pem"
```

#### Logging Options
```toml
[logging]
level = "info"
log_requests = true
log_responses = false
access_log = "/var/log/gurty/access.log"
error_log = "/var/log/gurty/error.log"
```

#### Security Settings
```toml
[security]
deny_files = ["*.env", "*.config", ".git/*", "*.key", "*.pem"]
allowed_methods = ["GET", "POST", "PUT", "DELETE", "HEAD", "OPTIONS", "PATCH"]
rate_limit_requests = 100
rate_limit_connections = 1000
```

#### Error Pages and Headers
```toml
# Custom error page files
[error_pages]
"404" = "/errors/404.html"
"500" = "/errors/500.html"

# Default inline error pages
[error_pages.default]
"400" = '''<!DOCTYPE html>
<html><head><title>400 Bad Request</title></head>
<body><h1>400 - Bad Request</h1><p>The request could not be understood by the server.</p></body></html>'''

# Custom HTTP headers
[headers]
server = "GURT/1.0.0"
"x-frame-options" = "SAMEORIGIN"
"x-content-type-options" = "nosniff"
```

## Quick Start

### Development Setup

1. **Install mkcert** for development certificates:
   ```bash
   # Windows (with Chocolatey)
   choco install mkcert
   
   # macOS (with Homebrew)
   brew install mkcert
   
   # Or download from: https://github.com/FiloSottile/mkcert/releases
   ```

2. **Install local CA** in your system:
   ```bash
   mkcert -install
   ```

3. **Generate localhost certificates**:
   ```bash
   cd protocol/cli
   mkcert localhost 127.0.0.1 ::1
   ```
   This creates:
   - `localhost+2.pem` (certificate)
   - `localhost+2-key.pem` (private key)

4. **Set up configuration** (optional but recommended):
   ```bash
   cd protocol/cli
   cp gurty.template.toml gurty.toml
   ```
   Edit `gurty.toml` to customize settings for development.

5. **Start GURT server**:
   ```bash
   cargo run --release serve --config gurty.toml
   ```
   Or specify certificates explicitly:
   ```bash
   cargo run --release serve --cert localhost+2.pem --key localhost+2-key.pem
   ```

### Production Setup

1. **Generate production certificates** with OpenSSL:
   ```bash
   # Generate private key
   openssl genpkey -algorithm RSA -out gurt-server.key -pkcs8
   
   # Generate certificate signing request
   openssl req -new -key gurt-server.key -out gurt-server.csr
   
   # Generate self-signed certificate (valid for 365 days)
   openssl x509 -req -days 365 -in gurt-server.csr -signkey gurt-server.key -out gurt-server.crt
   
   # Or generate both in one step
   openssl req -x509 -newkey rsa:4096 -keyout gurt-server.key -out gurt-server.crt -days 365 -nodes
   ```

2. **Set up configuration**:
   ```bash
   cp gurty.template.toml gurty.toml
   # Edit gurty.toml for production:
   # - Update certificate paths
   # - Set host to "0.0.0.0" for external access
   # - Configure logging and security settings
   ```

3. **Deploy with production certificates**:
   ```bash
   cargo run --release serve --config gurty.toml
   ```
   Or specify certificates explicitly:
   ```bash
   cargo run --release serve --cert gurt-server.crt --key gurt-server.key --config gurty.toml
   ```

## Commands

### `serve` Command

Start a GURT server with TLS certificates.

```bash
gurty serve [OPTIONS]
```

#### Options

| Option | Description | Default |
|--------|-------------|---------|
| `--cert <FILE>` | Path to TLS certificate file | Required* |
| `--key <FILE>` | Path to TLS private key file | Required* |
| `--config <FILE>` | Path to configuration file | None |
| `--host <HOST>` | Host address to bind to | `127.0.0.1` |
| `--port <PORT>` | Port number to listen on | `4878` |
| `--dir <DIR>` | Directory to serve files from | None |
| `--log-level <LEVEL>` | Logging level (error, warn, info, debug, trace) | `info` |

*Required unless specified in configuration file

#### Examples

**Using configuration file:**
```bash
gurty serve --config gurty.toml
```

**Explicit certificates with configuration:**
```bash
gurty serve --cert localhost+2.pem --key localhost+2-key.pem --config gurty.toml
```

**Manual setup without configuration file:**
```bash
gurty serve --cert localhost+2.pem --key localhost+2-key.pem --dir ./public
```

**Debug mode with configuration:**
```bash
gurty serve --config gurty.toml --log-level debug
```
