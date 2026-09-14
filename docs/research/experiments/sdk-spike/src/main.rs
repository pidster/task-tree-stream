// DISPOSABLE EXPERIMENT — not product code.
// Written only to verify claims in docs/research/2026-09-14-rust-sdk-embedded-vs-remote.md.
// Never referenced from product code.

use surrealdb::engine::any::connect;
use surrealdb::opt::auth::Root;
use surrealdb::types::SurrealValue;

#[derive(Debug, SurrealValue)]
struct Task {
    status: String,
}

#[tokio::main]
async fn main() -> surrealdb::Result<()> {
    // --- Embedded, in-memory ---
    println!("=== embedded mem:// ===");
    let db = connect("mem://").await?;
    db.use_ns("spike").use_db("spike").await?;
    let created: Option<Task> = db
        .create(("task", "e1"))
        .content(Task {
            status: "embedded-created".into(),
        })
        .await?;
    println!("embedded create result: {:?}", created);
    let fetched: Option<Task> = db.select(("task", "e1")).await?;
    println!("embedded select result: {:?}", fetched);

    // --- Embedded, rocksdb file-backed ---
    println!("=== embedded rocksdb:// ===");
    let path = "/tmp/sdk-spike-rocksdb-data";
    let _ = std::fs::remove_dir_all(path);
    let db2 = connect(format!("rocksdb://{path}")).await?;
    db2.use_ns("spike").use_db("spike").await?;
    let created2: Option<Task> = db2
        .create(("task", "r1"))
        .content(Task {
            status: "rocksdb-created".into(),
        })
        .await?;
    println!("rocksdb create result: {:?}", created2);

    // --- Remote, against a locally started `surreal start` server ---
    println!("=== remote ws:// ===");
    match connect("ws://127.0.0.1:8901").await {
        Ok(db3) => {
            db3.signin(Root {
                username: "root".to_string(),
                password: "root".to_string(),
            })
            .await?;
            db3.use_ns("spike").use_db("spike").await?;
            let created3: Option<Task> = db3
                .create(("task", "m1"))
                .content(Task {
                    status: "remote-created".into(),
                })
                .await?;
            println!("remote create result: {:?}", created3);
            let fetched3: Option<Task> = db3.select(("task", "m1")).await?;
            println!("remote select result: {:?}", fetched3);
        }
        Err(e) => {
            println!("remote connect FAILED: {:?}", e);
        }
    }

    println!("=== done ===");
    Ok(())
}
