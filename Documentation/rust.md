# Rust

# HashMap entry

```rust
pub async fn subscribe(
    &self,
    kind: gofer_models::EventKind,
) -> Result<Subscription<'_>, EventError> {
    let mut event_channel_map = match self.event_channel_map.write() {
        Ok(v) => v,
        Err(e) => {
            error!("could not subscribe to event"; "error" => e.to_string());
            return Err(EventError::Unknown(e.to_string()));
        }
    };

    let subscription_map = event_channel_map
        .entry(mem::discriminant(&kind))
        .or_insert(HashMap::new());

    let (sender, receiver) = channel::unbounded::<gofer_models::Event>();
    let new_subscription = Subscription {
        id: nanoid!(10),
        kind: kind.clone(),
        event_bus: self,
        receiver,
    };

    subscription_map.insert(new_subscription.id.clone(), sender);

    Ok(new_subscription)
}
```
