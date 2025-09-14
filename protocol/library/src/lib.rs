pub mod protocol;
pub mod crypto;
pub mod server;
pub mod client;
pub mod error;
pub mod message;

pub use error::{GurtError, Result};
pub use message::{GurtMessage, GurtRequest, GurtResponse, GurtMethod};
pub use protocol::{GurtStatusCode, GURT_VERSION, DEFAULT_PORT};
pub use crypto::{CryptoManager, TlsConfig, GURT_ALPN, TLS_VERSION};
pub use server::{GurtServer, GurtHandler, ServerContext, Route};
pub use client::{GurtClient, GurtClientConfig};

pub mod prelude {
    pub use crate::{
        GurtError, Result,
        GurtMessage, GurtRequest, GurtResponse,
        GURT_VERSION, DEFAULT_PORT,
        CryptoManager, TlsConfig, GURT_ALPN, TLS_VERSION,
        GurtServer, GurtHandler, ServerContext, Route,
        GurtClient, GurtClientConfig,
    };
}