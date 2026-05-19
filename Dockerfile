FROM alpine:latest

# Cài đặt các tools cần thiết
RUN apk add --no-cache \
    bash \
    curl \
    wget \
    git \
    go \
    ca-certificates \
    bind-tools \
    jq

# Cài đặt Subfinder
RUN go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest

# Cài đặt Assetfinder
RUN go install -v github.com/tomnomnom/assetfinder@latest

# Cài đặt Httpx
RUN go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest

# Cài đặt DNSx
RUN go install -v github.com/projectdiscovery/dnsx/cmd/dnsx@latest

# Cài đặt Amass (tùy chọn)
RUN go install -v github.com/OWASP/Amass/v3/...@master

# Copy scripts
COPY scripts/ /scripts/
RUN chmod +x /scripts/*.sh

WORKDIR /workspace

ENTRYPOINT ["/scripts/run_pipeline.sh"]