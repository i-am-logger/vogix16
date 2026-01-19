//! Shell completions command.

use crate::cli::{Cli, CompletionShell};
use crate::errors::Result;
use clap::CommandFactory;
use clap_complete::{generate, shells};
use std::io;

/// Handle the `completions` command - generate shell completions
pub fn handle_completions(shell: CompletionShell) -> Result<()> {
    let mut cmd = Cli::command();
    let bin_name = "vogix";

    match shell {
        CompletionShell::Bash => generate(shells::Bash, &mut cmd, bin_name, &mut io::stdout()),
        CompletionShell::Zsh => generate(shells::Zsh, &mut cmd, bin_name, &mut io::stdout()),
        CompletionShell::Fish => generate(shells::Fish, &mut cmd, bin_name, &mut io::stdout()),
        CompletionShell::Pwsh => {
            generate(shells::PowerShell, &mut cmd, bin_name, &mut io::stdout())
        }
        CompletionShell::Elvish => generate(shells::Elvish, &mut cmd, bin_name, &mut io::stdout()),
    }

    Ok(())
}
