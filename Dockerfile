FROM alpine:latest

RUN apk add --no-cache \
    bash \
    curl \
    wget \
    git \
    go \
    ca-certificates \
    bind-tools \
    jq

# Add Go bin to PATH so installed tools are found
ENV PATH="/root/go/bin:${PATH}"
ENV GOPATH="/root/go"

RUN go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
RUN go install -v github.com/tomnomnom/assetfinder@latest
RUN go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest
RUN go install -v github.com/projectdiscovery/dnsx/cmd/dnsx@latest
RUN go install -v github.com/owasp-amass/amass/v4/...@master

COPY scripts/ /scripts/
RUN chmod +x /scripts/*.sh

WORKDIR /workspace

# Use CMD (not ENTRYPOINT) so docker-compose `command:` can fully override it
CMD ["/scripts/run_pipeline.sh"]
