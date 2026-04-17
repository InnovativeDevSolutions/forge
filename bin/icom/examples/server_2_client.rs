use forge_icom::client::IComClient;
use serde_json::json;

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    println!("Server 2 - ICOM Client");
    println!("Connecting to ICOM server...\n");

    // Connect to ICOM as server_2
    let client = IComClient::connect("127.0.0.1:9090", "server_2".to_string()).await?;

    println!("\nSending messages to server_1...\n");

    // Wait a moment for server_2 to be ready
    tokio::time::sleep(tokio::time::Duration::from_secs(2)).await;

    // Example: Supply drop event
    println!("Sending supply drop event...");
    match client
        .send_event(
            "server_1",
            "supply_drop",
            json!({
                "coords": [1234.5, 5678.9, 0.0],
                "supplies": ["ammo_box", "medical_supplies"]
            }),
        )
        .await
    {
        Ok(_) => println!("Supply drop event sent\n"),
        Err(e) => println!("Supply drop failed: {}\n", e),
    }

    tokio::time::sleep(tokio::time::Duration::from_secs(1)).await;

    // Example: Mission spawn event
    println!("Sending mission spawn event...");
    match client
        .send_event(
            "server_1",
            "spawn_mission",
            json!({
                "mission_type": "convoy_ambush",
                "difficulty": "hard",
                "location": [1234, 5678, 0]
            }),
        )
        .await
    {
        Ok(_) => println!("Mission spawn event sent\n"),
        Err(e) => println!("Mission spawn failed: {}\n", e),
    }

    tokio::time::sleep(tokio::time::Duration::from_secs(1)).await;

    // Example: Broadcast event
    println!("Broadcasting event...");
    match client
        .broadcast(
            "global_alert",
            json!({
                "message": "Nuclear strike incoming!",
                "severity": "critical"
            }),
        )
        .await
    {
        Ok(_) => println!("Broadcast sent\n"),
        Err(e) => println!("Broadcast failed: {}\n", e),
    }

    println!("All messages sent (check above for any failures)!");
    println!("Press Ctrl+C to exit");

    // Keep running to receive any responses
    tokio::time::sleep(tokio::time::Duration::from_secs(3)).await;

    Ok(())
}
