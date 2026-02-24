use mimalloc::MiMalloc;
use tokio;

#[global_allocator]
static GLOBAL: MiMalloc = MiMalloc;

#[tokio::main]
async fn main() {
    let v: Vec<u32> = vec![1, 2, 3];

    println!("Hello, world from Tokio: {v:?}");
}
