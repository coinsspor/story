# --------------------------------
# Upgrade Parameters
# --------------------------------
UPGRADE_BLOCK=858000 # Block height for the upgrade
REPO_URL="https://github.com/piplabs/story" # Story GitHub repository
RELEASE_VERSION="v0.13.0" # Target version
PROJECT_HOME="/root/.story/story" # Corrected project home directory
CONFIG_FILE="$PROJECT_HOME/config/config.toml" # Path to config.toml
OLD_BIN_PATH="/root/go/bin/story" # Path of the current binary
NEW_BIN_DIR="$HOME/story_upgrade" # Temporary directory for the new binary
NEW_BIN_PATH="$NEW_BIN_DIR/story" # Path of the new binary

# --------------------------------
# Automatically detect RPC port
# --------------------------------
echo -e "${CYAN}Detecting RPC port...${NC}"
RPC_PORT=$(grep -m 1 -oP '^laddr = "tcp://[^:]+:\K[0-9]+' "$CONFIG_FILE")
if [[ -z "$RPC_PORT" ]]; then
  echo -e "${RED}Failed to detect RPC port. Please check your configuration.${NC}"
  exit 1
fi
echo -e "${GREEN}Detected RPC port: ${RPC_PORT}${NC}"

# --------------------------------
# Install Required Software
# --------------------------------
echo -e "${CYAN}Checking and installing required software...${NC}"
sudo apt update && sudo apt install -y curl jq screen git build-essential
if ! command -v go &> /dev/null; then
  echo -e "${YELLOW}Installing Go...${NC}"
  wget https://golang.org/dl/go1.20.5.linux-amd64.tar.gz -O go.tar.gz
  sudo tar -C /usr/local -xzf go.tar.gz
  echo "export PATH=$PATH:/usr/local/go/bin" >> ~/.bashrc
  source ~/.bashrc
fi
echo -e "${GREEN}All required software installed successfully.${NC}"

# --------------------------------
# Start Screen Session
# --------------------------------
echo -e "${CYAN}Starting a screen session for the upgrade process...${NC}"
screen -S story-upgrade -dm bash -c "
  echo -e '${RED}${BOLD}========================================================${NC}'
  echo -e '${YELLOW}${BOLD} YOU ARE NOW INSIDE A SCREEN SESSION!${NC}'
  echo -e '${CYAN}${BOLD} TO EXIT THE SCREEN SESSION, PRESS: CTRL + A + D${NC}'
  echo -e '${RED}${BOLD}========================================================${NC}'
  echo -e '${PURPLE}${BOLD} WARNING:${NC}'
  echo -e '${RED}${BOLD} IF YOU DO NOT EXIT USING CTRL + A + D, THE UPGRADE WILL NOT COMPLETE!${NC}'
  echo -e '${GREEN}${BOLD} PLEASE PRESS CTRL + A + D TO ALLOW AUTOMATIC UPGRADE TO FINISH.${NC}'
  echo -e '${RED}${BOLD}========================================================${NC}'
  sleep 10

  echo -e '${CYAN}Preparing the new binary...${NC}'
  rm -rf $NEW_BIN_DIR
  git clone $REPO_URL $NEW_BIN_DIR
  cd $NEW_BIN_DIR
  git checkout $RELEASE_VERSION
  go build -o story ./client
  if [[ ! -f $NEW_BIN_PATH ]]; then
    echo -e '${RED}Failed to build the new binary. Exiting.${NC}'
    exit 1
  fi
  echo -e '${GREEN}New binary built successfully.${NC}'

  echo -e '${PURPLE}Monitoring block height. Upgrade will occur at block: ${UPGRADE_BLOCK}${NC}'
  while true; do
    CURRENT_BLOCK=\$(curl -s http://localhost:$RPC_PORT/status | jq -r '.result.sync_info.latest_block_height')
    echo -e '${CYAN}Current Block: '\$CURRENT_BLOCK' | Target Block: ${UPGRADE_BLOCK}${NC}'
    if [[ \"\$CURRENT_BLOCK\" -ge \"$UPGRADE_BLOCK\" ]]; then
      echo -e '${YELLOW}Target block reached! Starting the upgrade...${NC}'
      sudo systemctl stop story
      sudo mv $NEW_BIN_PATH $OLD_BIN_PATH
      sudo systemctl start story
      echo -e '${GREEN}Upgrade completed successfully!${NC}'
      break
    fi
    sleep 5
  done
"

if screen -list | grep -q "story-upgrade"; then
  echo -e "${GREEN}The screen session 'story-upgrade' has been successfully created.${NC}"
  echo -e "${YELLOW}You can monitor it with: screen -r story-upgrade${NC}"
else
  echo -e "${RED}Failed to create the screen session. Please check your script.${NC}"
fi
