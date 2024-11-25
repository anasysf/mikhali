use std::io::Write;
use std::path::PathBuf;
use std::fs::OpenOptions;
use tiberius::Client;
use futures_util::{TryStreamExt, AsyncRead, AsyncWrite};

#[derive(Debug, clap::Subcommand)]
pub enum Command {
    Gather {
        #[clap(long, short)]
        like: String,

        #[clap(long, short)]
        to: PathBuf,
    }
}

pub async fn gather<S: AsyncRead + AsyncWrite + Unpin + Send>(client: &mut Client<S>, database: &str, like: &str, to: &PathBuf) -> Result<(), Box<dyn std::error::Error>> {
    let query: String = format!("SELECT OBJECT_NAME(object_id) AS Name, definition AS Content FROM sys.sql_modules WHERE OBJECT_NAME(object_id) LIKE '%{like}%'");

    let mut row_stream = client.simple_query(query).await?.into_row_stream();

    let mut output_file = OpenOptions::new()
        .truncate(true)
        .write(true)
        .open(to)?;

    if let None = row_stream.try_next().await? {
        println!("CITYYY");
    }

    writeln!(output_file, "{}", format!("USE [{database}]"))?;
    writeln!(output_file, "GO")?;

    while let Some(row) = row_stream.try_next().await? {
        let name = row.get::<&str, &str>("Name").expect("no name.");
        println!("ADDING SCRIPT FOR: {name}");
        let content = row.get::<&str, &str>("Content").expect("no content.");
        writeln!(output_file, "-------------------------------------------- {name} --------------------------------------------")?;
        writeln!(output_file, "{content}")?;
        writeln!(output_file, "GO")?;
    }

    println!("DONE");

    Ok(())
}
