//! Status command - show current theme state.

use crate::errors::Result;
use crate::state::State;

/// Handle the `status` command - display current theme/variant/scheme
pub fn handle_status() -> Result<()> {
    let state = State::load()?;
    state.save()?;

    println!("scheme:  {}", state.current_scheme);
    println!("theme:   {}", state.current_theme);
    println!("variant: {}", state.current_variant);

    if let Some(ref last_applied) = state.last_applied {
        println!("applied: {}", last_applied);
    }

    Ok(())
}
