# Dockerfile for FastMCP Server with Auth0 Integration
# Deploy to Google Cloud Run

FROM python:3.13-slim

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install Poetry
ENV POETRY_HOME=/opt/poetry
ENV POETRY_VERSION=2.1.4
RUN curl -sSL https://install.python-poetry.org | python3 - && \
    ln -s /opt/poetry/bin/poetry /usr/local/bin/poetry

# Configure Poetry to not create virtual environments (use system Python in container)
RUN poetry config virtualenvs.create false

# Copy dependency files
COPY pyproject.toml poetry.lock ./

# Install dependencies (production only)
RUN poetry install --only main --no-interaction --no-ansi --no-root

# Copy application code
COPY src ./src

# Create non-root user for security
RUN useradd -m -u 1000 appuser && \
    chown -R appuser:appuser /app

USER appuser

# Expose the MCP server port
EXPOSE 3001

# Health check endpoint
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:3001/.well-known/oauth-protected-resource').read()" || exit 1

# Run the MCP server in production mode
CMD ["python", "-m", "src.server"]
