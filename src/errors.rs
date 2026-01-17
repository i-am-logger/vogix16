use std::io;
use std::path::PathBuf;

#[derive(Debug)]
pub enum VogixError {
    Io(io::Error),
    ConfigNotFound(PathBuf),
    ParseError(String),
    InvalidTheme(String),
    ThemeNotFound(String),
    SymlinkError(String),
    ReloadError(String),
}

impl std::fmt::Display for VogixError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            VogixError::Io(err) => write!(f, "IO error: {}", err),
            VogixError::ConfigNotFound(path) => {
                write!(f, "Config file not found: {}", path.display())
            }
            VogixError::ParseError(msg) => write!(f, "Parse error: {}", msg),
            VogixError::InvalidTheme(msg) => write!(f, "Invalid theme: {}", msg),
            VogixError::ThemeNotFound(name) => write!(f, "Theme not found: {}", name),
            VogixError::SymlinkError(msg) => write!(f, "Symlink error: {}", msg),
            VogixError::ReloadError(msg) => write!(f, "Reload error: {}", msg),
        }
    }
}

impl std::error::Error for VogixError {}

impl From<io::Error> for VogixError {
    fn from(err: io::Error) -> Self {
        VogixError::Io(err)
    }
}

pub type Result<T> = std::result::Result<T, VogixError>;
