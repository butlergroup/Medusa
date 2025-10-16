# Build script created to deploy Medusa with custom-built Python in a container
# --- Base image ---
FROM ubuntu:24.04

# --- Metadata ---
LABEL maintainer="The Butler Group <support@butlergroup.net>" \
      description="Medusa test container with Python 3.12.12 built from source"

# --- Environment variables ---
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHON_VERSION=3.12.12

# --- Install build tools and dependencies ---
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libssl-dev \
    zlib1g-dev \
    libncurses5-dev \
    libncursesw5-dev \
    libreadline-dev \
    libsqlite3-dev \
    libgdbm-dev \
    libdb5.3-dev \
    libbz2-dev \
    libexpat1-dev \
    liblzma-dev \
    tk-dev \
    libffi-dev \
    wget \
    curl \
    ca-certificates \
    unrar \
    git \
    openssl \
    mediainfo \
 && rm -rf /var/lib/apt/lists/*

# --- Build and install Python from source ---
WORKDIR /usr/src
RUN wget https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz && \
    tar -xzf Python-${PYTHON_VERSION}.tgz && \
    cd Python-${PYTHON_VERSION} && \
    ./configure --enable-optimizations --with-ensurepip=install && \
    make -j"$(nproc)" && \
    make altinstall && \
    ln -sf /usr/local/bin/python3.12 /usr/bin/python3 && \
    ln -sf /usr/local/bin/pip3.12 /usr/bin/pip3 && \
    cd / && rm -rf /usr/src/Python-${PYTHON_VERSION}*

# --- Verify installation ---
RUN bash -c "/usr/local/bin/python3.12 --version && \
    /usr/local/bin/pip3.12 --version && \
    python3 --version && \
    pip3 --version"

# --- Create Medusa user and directory ---
RUN groupadd --system medusa && \
    useradd --system --create-home --home-dir /var/lib/medusa --gid medusa medusa && \
    mkdir -p /opt/medusa && chown medusa:medusa /opt/medusa

# --- Clone Medusa repository ---
RUN git clone https://github.com/butlergroup/Medusa.git /opt/medusa && \
    chown -R medusa:medusa /opt/medusa

WORKDIR /opt/medusa

# --- Create virtual environment using newly built Python ---
RUN rm -rf /opt/medusa/venv && \
    python3 -m venv /opt/medusa/venv

# --- Install Python dependencies ---
RUN bash -c "source /opt/medusa/venv/bin/activate && \
    pip install --upgrade pip && \
    pip install --upgrade guessit rebulk importlib_resources packaging"

# --- Container run configuration ---
EXPOSE 8081
USER medusa
ENV PATH="/opt/medusa/venv/bin:$PATH"

# --- Default command (runs Medusa directly for testing) ---
CMD ["python3", "/opt/medusa/Medusa.py"]
