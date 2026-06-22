# Hosting

Crown & Cinder uses direct peer hosting.

## LAN

1. Host starts a direct game.
2. Guests enter the host computer's local IP address.
3. Guests enter the invite code shown in the lobby.

## Internet

The host usually needs to forward UDP port `37172` to the host computer. The host then shares:

- public IP or VPN IP,
- port `37172`,
- invite code.

## Security model

The host is authoritative. Guests submit secret orders to the host, and the host resolves turns and broadcasts the new state. This keeps the project simple and self-hostable without dedicated servers.
