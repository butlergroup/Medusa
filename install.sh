#!/bin/bash
set -e

# --- System prep ---
sudo apt-get update
sudo apt-get install -y \
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
  mediainfo

# --- Download and build Python from source ---
cd /usr/src
sudo wget https://www.python.org/ftp/python/3.12.12/Python-3.12.12.tgz
sudo tar xzf Python-3.12.12.tgz
cd Python-3.12.12

# Configure and compile with optimizations for best performance
sudo ./configure --enable-optimizations --with-ensurepip=install
sudo make -j"$(nproc)"
sudo make altinstall  # installs as /usr/local/bin/python3.12 and pip3.12

# Verify installation
/usr/local/bin/python3.12 --version
/usr/local/bin/pip3.12 --version

# --- Create Medusa user and directories ---
sudo addgroup --system medusa || true
sudo adduser --disabled-password --system --home /var/lib/medusa --gecos "Medusa" --ingroup medusa medusa || true
sudo mkdir -p /opt/medusa && sudo chown medusa:medusa /opt/medusa

# --- Clone Medusa repo ---
sudo git clone https://github.com/butlergroup/Medusa.git /opt/medusa || true
sudo chown -R medusa:medusa /opt/medusa

# --- Install Medusa service ---
sudo cp -v /opt/medusa/runscripts/init.systemd /etc/systemd/system/medusa.service
sudo chown root:root /etc/systemd/system/medusa.service
sudo chmod 644 /etc/systemd/system/medusa.service
sudo systemctl enable medusa.service

# --- Create virtual environment using the newly built Python ---
cd /opt/medusa
sudo rm -rf /opt/medusa/venv
sudo -u medusa /usr/local/bin/python3.12 -m venv venv

# --- Activate and install dependencies ---
sudo -u medusa bash -c "source /opt/medusa/venv/bin/activate && pip install --upgrade pip"
sudo -u medusa bash -c "source /opt/medusa/venv/bin/activate && pip install --upgrade guessit rebulk importlib_resources packaging"

# --- Start Medusa ---
sudo systemctl start medusa
sudo systemctl status medusa
