# Universal LAS to 3D Tiles Converter
# Builds gocesiumtiler from source for better flexibility

FROM python:3.11-slim

# Install build and runtime dependencies
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    build-essential \
    cmake \
    pkg-config \
    git \
    wget \
    curl \
    libsqlite3-dev \
    libtiff-dev \
    libproj-dev \
    proj-data \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Go
RUN wget -O go.tar.gz https://go.dev/dl/go1.23.2.linux-$(dpkg --print-architecture).tar.gz \
    && tar -C /usr/local -xzf go.tar.gz \
    && rm go.tar.gz
ENV PATH="/usr/local/go/bin:${PATH}"

# Create non-root user to avoid permission issues
RUN groupadd -r converter && useradd -r -g converter converter

# Clone and build gocesiumtiler from source
WORKDIR /tmp/gocesiumtiler
RUN git clone --depth 1 --branch v2 https://github.com/mfbonfigli/gocesiumtiler.git . \
    && CGO_ENABLED=1 go build -o /usr/local/bin/gocesiumtiler ./cmd/main.go \
    && chmod +x /usr/local/bin/gocesiumtiler \
    && cd / && rm -rf /tmp/gocesiumtiler

# Set PROJ environment variable (uses system PROJ data)
ENV PROJ_LIB=/usr/share/proj

# Create directories with proper ownership
RUN mkdir -p /input /output && \
    chown -R converter:converter /input /output && \
    chmod 777 /input /output

# Don't switch to non-root user to avoid permission issues with volume mounts
# USER converter
WORKDIR /

# Default command
ENTRYPOINT ["gocesiumtiler"]
CMD ["--help"]