use forge_icom::{Message, client::IComClient};

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    println!("Server 1 - ICOM Client");
    println!("Connecting to ICOM server...\n");

    // Connect to ICOM as server_1
    let client = IComClient::connect("127.0.0.1:9090", "server_1".to_string()).await?;
    println!("Registered as 'server_1'.");

    println!("Listening for incoming messages...\n");

    // Listen for incoming messages indefinitely
    client
        .listen_for_events(|msg| {
            match msg {
                Message::Event {
                    event_name, data, ..
                } => {
                    println!("EVENT: {}", event_name);
                    println!("Data: {:#?}", data);
                    println!();
                }
                Message::Ack { .. } => {
                    // Ignore acks in listener mode
                }
                Message::Error { message } => {
                    eprintln!("Error: {}", message);
                }
                _ => {
                    println!("Received: {:?}", msg);
                    println!();
                }
            }
            Ok(())
        })
        .await?;

    Ok(())
}
