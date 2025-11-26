FROM ghcr.io/astral-sh/uv:python3.12-bookworm-slim

# Set working directory
WORKDIR /app

# Install dependencies using uv
# --system: Install packages into the system python environment (acceptable in containers)
# --no-cache: Skip caching to keep the image layer small
RUN uv pip install --system --no-cache fastapi uvicorn

# Copy the application code
COPY app /app/

# We don't copy the data here. We will mount it via volume in docker-compose.
# This keeps the image small and the build fast.

# Command to run the server
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]