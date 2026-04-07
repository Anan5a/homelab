FROM python:3.12-slim

# Install curl for healthchecks and networking tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl && rm -rf /var/lib/apt/lists/*

# Get the uv binary for fast installation
COPY --from=ghcr.io/astral-sh/uv:latest /uv /bin/

WORKDIR /app

# Install the package globally in the container
RUN uv pip install --system minimax-coding-plan-mcp

# Set essential environment variables
ENV PYTHONUNBUFFERED=1

# Use the direct module path. 
# This ensures we see the traceback if it crashes.
ENTRYPOINT ["python", "-m", "minimax_mcp.server"]
CMD ["--transport", "sse", "--host", "0.0.0.0", "--port", "8000"]