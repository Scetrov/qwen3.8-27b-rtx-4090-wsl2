# Qwen3.8 on a Local 4090

## Setup Instructions

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
      "baseUrl": "http://$HOST_IP:9931/v1",
      "api": "openai-completions",
      "apiKey": "$API_KEY",
      "models": [
        { "id": "qwen3.8-27b", "input": ["text"] }
      ]
    }
  }
}

```

