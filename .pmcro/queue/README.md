# Durable PMCR-O message queue

This queue is a transport adapter. Protocol authority remains in `.pmcro/protocol`. Delivery is at-least-once, so consumers must be idempotent. Envelopes are immutable; mutable transport state is stored separately in `state/`. Claiming uses atomic moves. ACK creates an immutable receipt. NACK retries with bounded exponential backoff and dead-letters at `maxAttempts`. Leases are recovered after expiry.
