#!/bin/bash

# Step 1: Update and Upgrade VPS
echo "Updating and upgrading VPS..."
sudo apt update && sudo apt upgrade -y

# Step 2: Install Go
echo "Installing Go..."
cd $HOME
ver="1.22.0"
wget "https://go.dev/dl/go$ver.linux-amd64.tar.gz"
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf "go$ver.linux-amd64.tar.gz"
rm "go$ver.linux-amd64.tar.gz"
echo "export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin" >> ~/.bash_profile
source ~/.bash_profile
go version

# Step 3: Download and Install Story-Geth Binary
echo "Downloading and installing Story-Geth binary..."
wget -q https://story-geth-binaries.s3.us-west-1.amazonaws.com/geth-public/geth-linux-amd64-0.9.2-ea9f0d2.tar.gz -O /tmp/geth-linux-amd64-0.9.2-ea9f0d2.tar.gz
tar -xzf /tmp/geth-linux-amd64-0.9.2-ea9f0d2.tar.gz -C /tmp
[ ! -d "$HOME/go/bin" ] && mkdir -p $HOME/go/bin
sudo cp /tmp/geth-linux-amd64-0.9.2-ea9f0d2/geth $HOME/go/bin/story-geth

# Step 4: Download and Install Story Binary
echo "Downloading and installing Story binary..."
wget -q https://story-geth-binaries.s3.us-west-1.amazonaws.com/story-public/story-linux-amd64-0.9.11-2a25df1.tar.gz -O /tmp/story-linux-amd64-0.9.11-2a25df1.tar.gz
tar -xzf /tmp/story-linux-amd64-0.9.11-2a25df1.tar.gz -C /tmp
sudo cp /tmp/story-linux-amd64-0.9.11-2a25df1/story $HOME/go/bin/story

# Step 5: Initialize the Iliad Network Node
echo "Initializing Iliad network node..."
$HOME/go/bin/story init --network iliad

# Step 6: Create and Configure systemd Service for Story-Geth
echo "Creating systemd service for Story-Geth..."
sudo tee /etc/systemd/system/story-geth.service > /dev/null <<EOF
[Unit]
Description=Story Geth Client
After=network.target

[Service]
User=root
ExecStart=$HOME/go/bin/story-geth --iliad --syncmode full
Restart=on-failure
RestartSec=3
LimitNOFILE=4096

[Install]
WantedBy=multi-user.target
EOF

# Step 7: Create and Configure systemd Service for Story
echo "Creating systemd service for Story..."
sudo tee /etc/systemd/system/story.service > /dev/null <<EOF
[Unit]
Description=Story Consensus Client
After=network.target

[Service]
User=root
ExecStart=$HOME/go/bin/story run
Restart=on-failure
RestartSec=3
LimitNOFILE=4096

[Install]
WantedBy=multi-user.target
EOF

# Step 8: Ask for Moniker and Update config.toml
echo "Please enter the moniker for your node (e.g., your node's name):"
read -r moniker

# Step 9: Update Ports in config.toml Based on User Input
echo "Please enter the starting port number (between 11 and 64). Default is 26:"
read -r start_port

# Default value check for port
if [ -z "$start_port" ]; then
  start_port=26
elif ! [[ "$start_port" =~ ^[0-9]+$ ]] || [ "$start_port" -lt 11 ] || [ "$start_port" -gt 64 ]; then
  echo "Invalid input. Please enter a number between 11 and 64."
  exit 1
fi

# Calculate new ports based on start_port
rpc_port=$((start_port * 1000 + 657))
p2p_port=$((start_port * 1000 + 656))
proxy_app_port=$((start_port * 1000 + 658))
prometheus_port=$((start_port * 1000 + 660))

# Update config.toml with new port values and moniker
config_path="/root/.story/story/config/config.toml"

# Update ports
sed -i "s|laddr = \"tcp://127.0.0.1:26657\"|laddr = \"tcp://127.0.0.1:$rpc_port\"|g" "$config_path"
sed -i "s|laddr = \"tcp://0.0.0.0:26656\"|laddr = \"tcp://0.0.0.0:$p2p_port\"|g" "$config_path"
sed -i "s|proxy_app = \"tcp://127.0.0.1:26658\"|proxy_app = \"tcp://127.0.0.1:$proxy_app_port\"|g" "$config_path"
sed -i "s|prometheus_listen_addr = \":26660\"|prometheus_listen_addr = \":$prometheus_port\"|g" "$config_path"

# Update moniker
sed -i "s|moniker = \"[^\"]*\"|moniker = \"$moniker\"|g" "$config_path"

echo "Configuration updated successfully in config.toml:"
echo "Moniker: $moniker"
echo "RPC Port: $rpc_port"
echo "P2P Port: $p2p_port"
echo "Proxy App Port: $proxy_app_port"
echo "Prometheus Port: $prometheus_port"

# Step 10: Update Persistent Peers in config.toml
echo "Fetching peers and updating persistent_peers in config.toml..."
URL="https://story-testnet-rpc.coinsspor.com/net_info"
response=$(curl -s $URL)
PEERS=$(echo $response | jq -r '.result.peers[] | "\(.node_info.id)@\(.remote_ip):" + (.node_info.listen_addr | capture("(?<ip>.+):(?<port>[0-9]+)$").port)' | paste -sd "," -)
echo "PEERS=\"$PEERS\""

# Update the persistent_peers in the config.toml file
sed -i 's|^persistent_peers *=.*|persistent_peers = "'$PEERS'"|' $CONFIG_PATH

echo "Persistent peers updated in $CONFIG_PATH."


# Step 11: Reload systemd, Enable, and Start Services
echo "Reloading systemd, enabling, and starting Story-Geth and Story services..."
sudo systemctl daemon-reload
sudo systemctl enable story-geth story
sudo systemctl start story-geth story

