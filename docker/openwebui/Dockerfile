# Use a lightweight Python base
FROM python:3.12-slim

# Copy uv binaries directly from the official image
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

# Set environment variables
ENV PYTHONUNBUFFERED=1 \
    UV_CACHE_DIR=/tmp/.uv_cache

# Expose the MCP port
EXPOSE 8000

# Run the MCP server
ENTRYPOINT ["uvx", "--with", "minimax-coding-plan-mcp", "minimax-coding-plan-mcp", "--transport", "sse", "--host", "0.0.0.0", "--port", "8000"]