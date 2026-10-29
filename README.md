# Qwen3.8 on a Local 4090

## Metrics

Run [nvidia_gpu_exporter](https://github.com/utkuozdemir/nvidia_gpu_exporter/blob/main/docs/INSTALL.md)
as a separate service inside WSL. Its standard build requires a working
`nvidia-smi`. The existing systemd service listens on port 9835; mprocs does
not start a second exporter. Manage exporter updates using your chosen
installation method.

Alloy scrapes the GPU exporter at `127.0.0.1:9835/metrics` and cloudflared at
`127.0.0.1:60123/metrics`, then forwards both to the existing remote-write
endpoint. Cloudflared listens on loopback; the existing GPU exporter service
listens on all interfaces, so restrict it separately if necessary. After
starting mprocs, check those endpoints with curl and check Alloy's scrape
health and Grafana for the `nvidia_gpu` and `cloudflared` jobs.

## Cloudflare Tunnel (remote access)

The existing `mprocs.yaml` runs `cloudflared` alongside Qwen and Alloy:

```text
https://ai.scetrov.live → Cloudflare Tunnel → http://127.0.0.1:9931
```

The tunnel runs inside WSL, so remote access needs no Windows port forwarding
or inbound firewall rule. Existing LAN access and llama-server API-key
authentication remain unchanged. Cloudflare terminates public HTTPS; the local
loopback connection uses HTTP.

### One-time configuration

1. Install the current stable `cloudflared` package **inside WSL** using
   [Cloudflare's installation instructions](https://developers.cloudflare.com/cloudflare-one/networks/connectors/cloudflare-tunnel/downloads/).
   Version 2025.4.0 or later is required for `--token-file`. Verify with
   `cloudflared --version`. Updates are managed manually/by your package manager.
2. Ensure `scetrov.live` is an active Cloudflare DNS zone and its edge
   certificate covers `ai.scetrov.live` (normally covered by Universal SSL).
3. In Cloudflare **Networking → Tunnels**, create a remotely managed
   **Cloudflared** tunnel, for example `qwen-local`.
   Copy only the connector token from the installation command; do not install
   a second system service, since mprocs manages this connector.
4. Save that token locally without putting it in shell history:

   ```bash
   mkdir -p secrets
   (umask 077; touch secrets/cloudflare-tunnel-token.txt)
   chmod 600 secrets/cloudflare-tunnel-token.txt
   ${EDITOR:-nano} secrets/cloudflare-tunnel-token.txt
   ```

   Paste the token as a single line. The `secrets/` directory is gitignored.
   Keep this token private; it is separate from the llama-server API key.
5. Add a **Published application** route to the tunnel:
   - Hostname: **ai.scetrov.live**
   - Service type: **HTTP**
   - Service URL: **127.0.0.1:9931**
   - Leave the path empty to forward all paths unchanged, including `/v1`.

   Allow Cloudflare to create the DNS record; resolve any conflicting record
   first. No local tunnel UUID, credentials JSON, or ingress YAML is needed.
6. Start `mprocs` from this repository and check that the connector is healthy.
   Complete the token setup first to avoid an autorestart loop. The tunnel
   makes outbound connections; allow outbound TCP/UDP port 7844 if filtered.

### Remote Pi client

Use the existing provider/model configuration below, replacing only:

```json
"baseUrl": "https://ai.scetrov.live/v1"
```

Keep the existing llama-server API key and model ID `qwen3.8-27b`.
No CORS change is needed for Pi or other non-browser API clients.

### Verification and security

- Request `https://ai.scetrov.live/v1/models` without an API key and confirm
  it is rejected; repeat with your existing Bearer API key and confirm the
  model is listed.
- Test a streaming completion through your client and check for disconnects
  or timeouts. Cloudflare request limits still apply.
- This publishes the origin to the Internet; Tunnel is not an authorization
  layer. The existing API key protects API requests, but do not assume it
  protects every llama-server route (for example health/metrics).
- For private-only access or protection of all routes, configure Cloudflare
  Access before publishing. Machine clients need compatible service-token
  headers; that extra authentication is not configured here.
- LAN forwarding described below is optional for Tunnel users. Remove it
  separately if you no longer need direct LAN access.
- Stop the `cloudflared` process in mprocs to stop this connector. Delete the
  published route/DNS record in Cloudflare to retire the hostname.

## Setup Instructions (direct LAN access)

### WSL

Gather the following information:

1. Host IP address via Powershell (`$HOST_IP`): `(Get-NetRoute -DestinationPrefix '0.0.0.0/0' | Get-NetIPAddress -AddressFamily IPv4).IPAddress`
2. WSL Guest IP address via WSL ($GUEST_IP): `hostname -I`
3. Get the API Key (`$API_KEY`) from `./secrets/llama-api-key.txt`

### Host Setup

Forward the port:

```powershell
netsh interface portproxy add v4tov4 listenport=9931 listenaddress=0.0.0.0 connectport=9931 connectaddress=$GUEST_IP
```

Open Firewall Port:

```powershell
New-NetFirewallRule -DisplayName "llama-server 9931" -Direction Inbound -LocalPort 9931 -Protocol TCP -Action Allow
```

### Pi Coding Agent Setup

In `~/.pi/agent/models.json`

```json
{
  "providers": {
   "local-rig": {
      "baseUrl": "http://10.229.2.10:9931/v1",
      "api": "openai-completions",
      "apiKey": "qwen-EcT4wdVhqi4gpUj7ohGj",
      "models": [
        {
          "id": "qwen3.8-27b",
          "name": "Qwen-3.8-27B",
          "input": ["text"],
          "reasoning": true,
          "contextWindow": 131072,
          "maxTokens": 32768
        }
      ]
    }
  }
}
```

