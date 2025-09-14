# Gurty - a CLI tool to setup your GURT Protocol server

Gurty is a command-line interface tool for setting up and managing GURT protocol servers.

## Configuration

Gurty uses a TOML configuration file to manage server settings. The `gurty.template.toml` file provides a complete configuration template with all available options:

### Sections

- **Server**: Basic server settings (host, port, protocol version, connection limits)
- **TLS**: Certificate and private key configuration for secure connections
- **Logging**: Logging levels, request/response logging, and log file paths
- **Security**: File access restrictions, allowed HTTP methods, and rate limiting
- **Error Pages**: Custom error page templates and default error responses
- **Headers**: Custom HTTP headers for security and server identification

### Using Configuration Files

1. **Copy the configuration template:**
   ```bash
   cp gurty.template.toml gurty.toml
   ```

2. **Edit the configuration** to match your environment. (optional)

3. **Use the configuration file:**
   ```bash
   gurty serve --config gurty.toml
   ```

## Setup for Production

For production deployments, you can use the Gurted Certificate Authority to get proper TLS certificates:

1. **Install the Gurted CA CLI:**
   
   🔗 https://gurted.com/download

2. **Request a certificate for your domain:**
   ```bash
   gurtca request yourdomain.web --output ./certs
   ```

3. **Follow the DNS challenge instructions:**
   When prompted, add the TXT record to your domain:
   - Go to gurt://dns.web (or your DNS server)
   - Login and navigate to your domain
   - Add a TXT record with:
     - Name: `_gurtca-challenge`
     - Value: (provided by the CLI tool)
   - Press Enter to continue verification

4. **Copy the configuration template and customize:**
   ```bash
   cp gurty.template.toml gurty.toml
   ```

5. **Deploy with CA-issued certificates:**
   ```bash
   gurty serve --cert ./certs/yourdomain.web.crt --key ./certs/yourdomain.web.key --config gurty.toml
   ```

## Development Environment Setup

To set up a development environment for GURT, follow these steps:

1. **Install mkcert:**
   ```bash
   # Windows (with Chocolatey)
   choco install mkcert
   
   # Or download from: https://github.com/FiloSottile/mkcert/releases
   ```

2. **Install local CA in system:**
   ```bash
   mkcert -install
   ```
   This installs a local CA in your **system certificate store**.

3. **Generate localhost certificates:**
   ```bash
   cd gurted/protocol/cli
   mkcert localhost 127.0.0.1 ::1
   ```
   This creates:
   - `localhost+2.pem` (certificate)
   - `localhost+2-key.pem` (private key)

4. **Copy the configuration template and customize:**
   ```bash
   cp gurty.template.toml gurty.toml
   ```

5. **Start GURT server with certificates and configuration:**
   ```bash
   gurty serve --config gurty.toml
   ```
   Or specify certificates explicitly:
   ```bash
   gurty serve --cert localhost+2.pem --key localhost+2-key.pem --config gurty.toml
   ```