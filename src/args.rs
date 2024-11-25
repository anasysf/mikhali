use clap::Parser;
use crate::gather;

#[derive(Parser, Debug)]
pub struct Args {
    #[arg(short, long)]
    pub database: String,

    #[arg(short, long)]
    pub server_name: String,

    #[arg(long, default_value_t = 1433)]
    pub port: u16,

    #[arg(short, long)]
    pub login: String,

    #[arg(short, long)]
    pub password: String,
    
    #[clap(subcommand)]
    pub command: gather::Command,
}
