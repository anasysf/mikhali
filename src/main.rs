use std::path::PathBuf;
use clap::Parser;
use tiberius::{Config, AuthMethod, Client};
use tokio::net::TcpStream;
use tokio_util::compat::TokioAsyncWriteCompatExt;

mod args;
mod gather;

use args::Args;
use gather::Command;

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    /* let cmd = clap::Command::new("mikhali")
        .subcommand(gather::gather_cli()); */

    let Args { server_name, port, ref database, login, password, command } = Args::parse();

    let mut config = Config::new();

    config.host(server_name);
    config.port(port);
    config.authentication(AuthMethod::sql_server(login, password));
    config.database(database);
    config.trust_cert();

    let tcp = TcpStream::connect(config.get_addr()).await?;
    tcp.set_nodelay(true)?;

    let mut client = Client::connect(config, tcp.compat_write()).await?;

    match command {
        Command::Gather { ref like, ref to } => {
            gather::gather(&mut client, database, like, to).await?;
        },
    }

    Ok(())
}
