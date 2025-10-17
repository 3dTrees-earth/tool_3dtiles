# Universal LAS to 3D Tiles Converter
# Builds gocesiumtiler from source for better flexibility

FROM debian:trixie-slim

# Install build and runtime dependencies (including LAStools dependencies)
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
    liblaszip-dev \
    libjpeg62-turbo \
    libpng-dev \
    libjpeg-dev \
    zlib1g-dev \
    liblzma-dev \
    libjbig-dev \
    libzstd-dev \
    libgeotiff-dev \
    libwebp-dev \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Go
RUN wget -O go.tar.gz https://go.dev/dl/go1.23.2.linux-$(dpkg --print-architecture).tar.gz \
    && tar -C /usr/local -xzf go.tar.gz \
    && rm go.tar.gz
ENV PATH="/usr/local/go/bin:${PATH}"

# Build and install LASzip library (needed for gocesiumtiler)
WORKDIR /tmp/laszip
RUN git clone https://github.com/LASzip/LASzip.git . \
    && mkdir build && cd build \
    && cmake .. \
    && make -j$(nproc) \
    && make install \
    && ldconfig \
    && cd / && rm -rf /tmp/laszip

# Download and install LAStools (includes laszip CLI)
WORKDIR /usr/local/lastools
RUN wget https://downloads.rapidlasso.de/LAStools.tar.gz \
    && tar xzf LAStools.tar.gz --strip-components=1 \
    && rm LAStools.tar.gz \
    && chmod +x laszip64

# Set library path for LAStools and add to PATH
ENV LD_LIBRARY_PATH=/usr/local/lastools/lib
ENV PATH="/usr/local/lastools:${PATH}"

# Create symlink for laszip command
RUN ln -s /usr/local/lastools/laszip64 /usr/local/bin/laszip

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

# Copy wrapper script
COPY converter-wrapper.sh /usr/local/bin/converter-wrapper.sh
RUN chmod +x /usr/local/bin/converter-wrapper.sh

# Create directories with proper ownership
RUN mkdir -p /input /output && \
    chown -R converter:converter /input /output

# Switch to non-root user
USER converter
WORKDIR /

# Default command - use wrapper instead of direct gocesiumtiler  
# Note: Don't use ENTRYPOINT here because Galaxy needs to override the command
CMD ["/usr/local/bin/converter-wrapper.sh", "--help"]