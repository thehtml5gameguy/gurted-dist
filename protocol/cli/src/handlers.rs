use std::path::Path;

pub trait FileHandler: Send + Sync {
    fn can_handle(&self, path: &Path) -> bool;
    fn get_content_type(&self, path: &Path) -> String;
    fn handle_file(&self, path: &Path) -> crate::Result<Vec<u8>>;
}

pub struct DefaultFileHandler;

impl FileHandler for DefaultFileHandler {
    fn can_handle(&self, _path: &Path) -> bool {
        true // Default
    }

    fn get_content_type(&self, path: &Path) -> String {
        match path.extension().and_then(|ext| ext.to_str()) {
            Some("html") | Some("htm") => "text/html".to_string(),
            Some("css") => "text/css".to_string(),
            Some("js") => "application/javascript".to_string(),
            Some("json") => "application/json".to_string(),
            Some("png") => "image/png".to_string(),
            Some("jpg") | Some("jpeg") => "image/jpeg".to_string(),
            Some("gif") => "image/gif".to_string(),
            Some("svg") => "image/svg+xml".to_string(),
            Some("ico") => "image/x-icon".to_string(),
            Some("txt") => "text/plain".to_string(),
            Some("xml") => "application/xml".to_string(),
            Some("pdf") => "application/pdf".to_string(),
            _ => "application/octet-stream".to_string(),
        }
    }

    fn handle_file(&self, path: &Path) -> crate::Result<Vec<u8>> {
        std::fs::read(path).map_err(crate::ServerError::from)
    }
}

pub trait DirectoryHandler: Send + Sync {
    fn handle_directory(&self, path: &Path, request_path: &str) -> crate::Result<String>;
}

pub struct DefaultDirectoryHandler;

impl DirectoryHandler for DefaultDirectoryHandler {
    fn handle_directory(&self, path: &Path, request_path: &str) -> crate::Result<String> {
        let entries = std::fs::read_dir(path)?;
        
        let mut listing = String::from(include_str!("../templates/directory_listing_start.html"));

        if request_path != "/" {
            listing.push_str(include_str!("../templates/directory_parent_link.html"));
        }

        listing.push_str(include_str!("../templates/directory_content_start.html"));

        for entry in entries.flatten() {
            let file_name = entry.file_name();
            let name = file_name.to_string_lossy();
            let is_dir = entry.path().is_dir();
            let display_name = if is_dir { 
                format!("{}/", name) 
            } else { 
                name.to_string() 
            };
            let class = if is_dir { "dir" } else { "file" };
            
            listing.push_str(&format!(
                r#"        <a href="{}" style="{}">{}</a>"#,
                name, class, display_name
            ));
            listing.push('\n');
        }
        
        listing.push_str(include_str!("../templates/directory_listing_end.html"));
        Ok(listing)
    }
}

pub fn get_404_html() -> &'static str {
    include_str!("../templates/404.html")
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::path::Path;

    #[test]
    fn test_default_file_handler_can_handle_any_file() {
        let handler = DefaultFileHandler;
        let path = Path::new("test.txt");
        assert!(handler.can_handle(path));
        
        let path = Path::new("some/random/file");
        assert!(handler.can_handle(path));
    }

    #[test]
    fn test_content_type_detection() {
        let handler = DefaultFileHandler;
        
        assert_eq!(handler.get_content_type(Path::new("index.html")), "text/html");
        assert_eq!(handler.get_content_type(Path::new("style.css")), "text/css");
        assert_eq!(handler.get_content_type(Path::new("script.js")), "application/javascript");
        assert_eq!(handler.get_content_type(Path::new("data.json")), "application/json");
        
        assert_eq!(handler.get_content_type(Path::new("image.png")), "image/png");
        assert_eq!(handler.get_content_type(Path::new("photo.jpg")), "image/jpeg");
        assert_eq!(handler.get_content_type(Path::new("photo.jpeg")), "image/jpeg");
        assert_eq!(handler.get_content_type(Path::new("icon.ico")), "image/x-icon");
        assert_eq!(handler.get_content_type(Path::new("vector.svg")), "image/svg+xml");
        
        assert_eq!(handler.get_content_type(Path::new("readme.txt")), "text/plain");
        assert_eq!(handler.get_content_type(Path::new("data.xml")), "application/xml");
        assert_eq!(handler.get_content_type(Path::new("document.pdf")), "application/pdf");
        
        assert_eq!(handler.get_content_type(Path::new("file.unknown")), "application/octet-stream");
        
        assert_eq!(handler.get_content_type(Path::new("noextension")), "application/octet-stream");
    }

    #[test]
    fn test_directory_handler_generates_valid_html() {
        use std::fs;
        use std::env;
        
        let temp_dir = env::temp_dir().join("gurty_test");
        let _ = fs::create_dir_all(&temp_dir);
        
        let _ = fs::write(temp_dir.join("test.txt"), "test content");
        let _ = fs::create_dir_all(temp_dir.join("subdir"));
        
        let handler = DefaultDirectoryHandler;
        let result = handler.handle_directory(&temp_dir, "/test/");
        
        assert!(result.is_ok());
        let html = result.unwrap();
        
        assert!(html.contains("<!DOCTYPE html>"));
        assert!(html.contains("<title>Directory Listing</title>"));
        assert!(html.contains("← Parent Directory"));
        assert!(html.contains("test.txt"));
        assert!(html.contains("subdir/"));
        
        let _ = fs::remove_dir_all(&temp_dir);
    }

    #[test]
    fn test_directory_handler_root_path() {
        use std::fs;
        use std::env;
        
        let temp_dir = env::temp_dir().join("gurty_test_root");
        let _ = fs::create_dir_all(&temp_dir);
        
        let handler = DefaultDirectoryHandler;
        let result = handler.handle_directory(&temp_dir, "/");
        
        assert!(result.is_ok());
        let html = result.unwrap();
        
        assert!(!html.contains("← Parent Directory"));
        
        let _ = fs::remove_dir_all(&temp_dir);
    }

    #[test]
    fn test_get_404_html_content() {
        let html = get_404_html();
        
        assert!(html.contains("<!DOCTYPE html>"));
        assert!(html.contains("404 Page Not Found"));
        assert!(html.contains("The requested path was not found"));
        assert!(html.contains("Back to home"));
    }

    #[test]
    fn test_directory_handler_with_empty_directory() {
        use std::fs;
        use std::env;
        
        let temp_dir = env::temp_dir().join("gurty_test_empty");
        let _ = fs::create_dir_all(&temp_dir);
        
        let handler = DefaultDirectoryHandler;
        let result = handler.handle_directory(&temp_dir, "/empty/");
        
        assert!(result.is_ok());
        let html = result.unwrap();
        
        assert!(html.contains("<!DOCTYPE html>"));
        assert!(html.contains("Directory Listing"));
        
        let _ = fs::remove_dir_all(&temp_dir);
    }
}
