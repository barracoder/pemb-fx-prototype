FROM mcr.microsoft.com/dotnet/sdk:8.0 AS ralph-base

# Install system dependencies + Node.js LTS + Claude CLI (single cached layer)
RUN apt-get update && apt-get install -y --no-install-recommends \
    jq git curl ca-certificates gnupg \
  && curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
  && apt-get install -y --no-install-recommends nodejs \
  && npm install -g @anthropic-ai/claude-code \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace

COPY scripts/ralph/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["entrypoint.sh"]
