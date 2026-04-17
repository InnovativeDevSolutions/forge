use forge_icom::{Message, client::IComClient};

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    println!("Server 3 - ICOM Client");
    println!("Connecting to ICOM server...\n");

    // Connect to ICOM as server_3
    let client = IComClient::connect("127.0.0.1:9090", "server_3".to_string()).await?;
    println!("Registered as 'server_3'.");

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
