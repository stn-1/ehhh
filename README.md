# Auto Recon Pipeline

Automated subdomain reconnaissance pipeline using Docker.  
Runs Subfinder + Assetfinder → deduplicates → DNS resolves → HTTP probes.

---

## Requirements

- Docker Desktop (already installed)
- That's it. All tools run inside the container.

---

## Quick Setup (do this once)

```bash
# 1. Copy the example env file
cp .env.example .env

# 2. Edit .env — at minimum set your target domain
#    DOMAIN=example.com
#    Everything else has working defaults.
notepad .env
```

> **Optional:** Add API keys to `config/provider-config.yaml` to get more subdomain results from paid sources (Shodan, Censys, etc.). The pipeline works without them.

---

## Scan a Single Domain

```bash
# Scan one domain defined in .env (DOMAIN=example.com)
docker-compose up --build

# Or pass the domain directly without editing .env
DOMAIN=example.com docker-compose up --build

# On Windows PowerShell:
$env:DOMAIN="example.com"; docker-compose up --build
```

Results are saved to `./outputs/` on your machine.

---

## Scan Multiple Domains in Parallel

```bash
# 1. Edit inputs/domains.txt — one domain per line
notepad inputs\domains.txt

# 2. Run the parallel pipeline
docker-compose -f docker-compose-full.yml up --build
```

This runs up to 3 domains at the same time (set `MAX_PARALLEL` in `.env` to change).

---

## View Results in a Browser

When using `docker-compose-full.yml`, a web server starts automatically:

```
http://localhost:8080
```

You'll see all output files listed. Click any file to view it.

---

## Output Files

For each scanned domain (e.g. `example.com`) you get:

| File | Contents |
|------|----------|
| `example.com_subfinder.txt` | Subdomains found by Subfinder |
| `example.com_assetfinder.txt` | Subdomains found by Assetfinder |
| `example.com_all_subdomains.txt` | Merged, deduplicated list |
| `example.com_alive.txt` | Subdomains that resolved via DNS |
| `example.com_websites.txt` | Live web services (status, title, tech) |
| `example.com_summary.txt` | Count summary |
| `recon_YYYYMMDD_HHMMSS.log` | Full run log |

---

## Monitor a Running Scan

Open a second terminal while the container is running:

```bash
# Windows PowerShell
docker exec recon-worker bash config/monitor.sh

# Or watch the live log
docker logs -f recon-automation
```

---

## Environment Variables (`.env`)

| Variable | Default | Description |
|----------|---------|-------------|
| `DOMAIN` | *(required)* | Target domain for single-domain scan |
| `THREADS` | `50` | Thread count passed to tools |
| `RUN_HTTPX` | `true` | Probe alive subdomains for web services |
| `MAX_PARALLEL` | `3` | Max domains scanned simultaneously |
| `WEBHOOK_URL` | *(empty)* | Slack/Discord webhook for notifications |

---

## Add API Keys (Optional)

Edit `config/provider-config.yaml` and replace placeholder values:

```yaml
shodan:
  - YOUR_SHODAN_KEY

virustotal:
  - YOUR_VIRUSTOTAL_KEY
```

Free keys available at:
- Shodan: https://account.shodan.io
- Chaos (ProjectDiscovery): https://chaos.projectdiscovery.io
- VirusTotal: https://www.virustotal.com
- Censys: https://censys.io/register

---

## Rebuild After Code Changes

```bash
docker-compose up --build
```

The `--build` flag rebuilds the Docker image. You can skip it on subsequent runs if nothing changed.

---

## Troubleshooting

**"No domain provided" error**
→ Make sure `.env` exists and has `DOMAIN=yourtarget.com`

**Empty results**
→ Add API keys to `config/provider-config.yaml` for more sources

**Container exits immediately**
→ Check the log: `docker logs recon-automation`

**Permission denied on scripts**
→ The Dockerfile already runs `chmod +x` on scripts. Rebuild: `docker-compose build --no-cache`
