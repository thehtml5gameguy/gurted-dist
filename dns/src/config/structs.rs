use serde::{Deserialize, Serialize};

#[derive(Clone, Debug, Deserialize, Serialize)]
pub struct Config {
    #[serde(skip)]
    pub config_path: String,
    pub(crate) server: Server,
    pub(crate) settings: Settings,
    pub(crate) discord: Discord,
    pub(crate) auth: Auth,
}

#[derive(Clone, Debug, Deserialize, Serialize)]
pub struct Server {
    pub(crate) address: String,
    pub(crate) port: u64,
    pub(crate) database: Database,
    pub(crate) cert_path: String,
    pub(crate) key_path: String,
}

#[derive(Clone, Debug, Deserialize, Serialize)]
pub struct Database {
    pub(crate) url: String,
    pub(crate) max_connections: u32,
}

#[derive(Clone, Debug, Deserialize, Serialize)]
pub struct Settings {
    pub(crate) tld_list: Vec<String>,
    pub(crate) offensive_words: Vec<String>,
}

#[derive(Clone, Debug, Deserialize, Serialize)]
pub struct Discord {
    pub(crate) bot_token: String,
    pub(crate) channel_id: u64,
}

#[derive(Clone, Debug, Deserialize, Serialize)]
pub struct Auth {
    pub(crate) jwt_secret: String,
}
