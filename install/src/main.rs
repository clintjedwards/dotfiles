use anyhow::{Context, Result};
use polyfmt::{error, println, success};
use std::io::{BufRead, BufReader, Write};
use std::process::{Command, Stdio};

/// Run a command with "ephemeral logs" (like docker build).
pub fn run_stage(name: &str, cmd: &str, args: &[&str]) -> Result<()> {
    println!("{name}...");

    // spawn
    let mut child = Command::new(cmd)
        .args(args)
        .stdout(Stdio::piped())
        .stderr(Stdio::piped())
        .spawn()
        .with_context(|| format!("failed to spawn {cmd}"))?;

    let stdout = child.stdout.take().unwrap();
    let stderr = child.stderr.take().unwrap();

    // merge stdout+stderr lines into one stream
    let mut out_reader = BufReader::new(stdout);
    let mut err_reader = BufReader::new(stderr);

    // threads to stream + buffer output
    let t_out = std::thread::spawn({
        let mut buf = Vec::new();
        move || {
            let mut line = String::new();
            while out_reader.read_line(&mut line).unwrap() > 0 {
                print!("{}", line);
                std::io::stdout().flush().unwrap();
                buf.push(line.clone());
                line.clear();
            }
            buf
        }
    });
    let t_err = std::thread::spawn({
        let mut buf = Vec::new();
        move || {
            let mut line = String::new();
            while err_reader.read_line(&mut line).unwrap() > 0 {
                eprint!("{}", line);
                std::io::stderr().flush().unwrap();
                buf.push(line.clone());
                line.clear();
            }
            buf
        }
    });

    let status = child.wait()?;
    let mut logs = t_out.join().unwrap();
    logs.extend(t_err.join().unwrap());

    if status.success() {
        // clear output
        // (ANSI: move cursor up N lines and clear them)
        let lines_count = logs.len() + 1; // Plus the heading.
        for _ in 0..lines_count {
            print!("\x1B[1A\x1B[2K"); // up + clear line
        }
        success!("{name} succeeded");
        Ok(())
    } else {
        error!("{name} failed (exit code {:?})", status.code());
        Err(anyhow::anyhow!("{name} failed"))
    }
}

fn main() -> anyhow::Result<()> {
    run_stage(
        "counting",
        "bash",
        &[
            "-c",
            r#"
        for i in {1..5}; do
            echo "Step $i"
            sleep 1
        done
    "#,
        ],
    )?;

    run_stage(
        "failing stage",
        "bash",
        &[
            "-c",
            r#"
        for i in {1..3}; do
            echo "Working $i"
            sleep 1
        done
        echo "Something went wrong" >&2
        exit 1
    "#,
        ],
    )?;

    Ok(())
}
