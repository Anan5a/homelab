FROM python:3.12-slim

# Install system dependencies (needed for some MCP packages to build)
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Get the latest uv binaries
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

# Set the working directory
WORKDIR /app

# Enable uv's global cache to avoid permission issues in /root
ENV UV_PROJECT_ENVIRONMENT=/app/.venv \
    UV_CACHE_DIR=/app/.uv_cache \
    PYTHONUNBUFFERED=1

# Expose the port
EXPOSE 8000

# Explicitly run uvx
ENTRYPOINT ["uvx", "minimax-coding-plan-mcp", "-y"]