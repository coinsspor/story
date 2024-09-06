## Story
Story is the World’s IP Blockchain, onramping Programmable IP to power the next generation of AI, DeFi, and consumer applications.

### System Requirements

| Hardware   | Minimum Requirement |
|------------|---------------------|
| CPU        | 4 Cores             |
| RAM        | 8 GB                |
| Disk       | 200 GB              |
| Bandwidth  | 10 MBit/s           |

### Step-1 Auto Install ( u must select port and moniker name)

```
source <(curl -s https://raw.githubusercontent.com/coinsspor/story/main/story.sh)
```
### Step-2 Snapshot

```
sudo apt-get install wget lz4 -y

wget -O geth_snapshot.lz4 https://snapshots.mandragora.io/geth_snapshot.lz4
wget -O story_snapshot.lz4 https://snapshots.mandragora.io/story_snapshot.lz4

sudo systemctl stop story-geth
sudo systemctl stop story

sudo cp $HOME/.story/story/data/priv_validator_state.json $HOME/.story/priv_validator_state.json.backup

sudo rm -rf $HOME/.story/geth/iliad/geth/chaindata
sudo rm -rf $HOME/.story/story/data

lz4 -c -d geth_snapshot.lz4 | tar -x -C $HOME/.story/geth/iliad/geth
lz4 -c -d story_snapshot.lz4 | tar -x -C $HOME/.story/story

sudo rm -v geth_snapshot.lz4
sudo rm -v story_snapshot.lz4

sudo cp $HOME/.story/priv_validator_state.json.backup $HOME/.story/story/data/priv_validator_state.json

sudo systemctl start story-geth
sudo systemctl start story

```
### Step-3 Synchronization Check

xx ,The 2-digit part number you entered in step 1.
```
curl localhost:xx657/status | jq
```
Make sure catching_up = false

### Step-4 Export wallet

```
story validator export --export-evm-key

```

### Step-5  Get wallet key and import to Metamask wallet

```
sudo nano ~/.story/story/config/private_key.txt

```
### Step-6  Import wallet to Metamask and faucet

1-
```
 https://faucet.story.foundation/
```
2-
```
https://thirdweb.com/story-iliad-testnet
```
3-
```
 https://faucet.quicknode.com/story 
```
**You need at least have 1 IP on wallet before go to last step**

### Step-7  Register validator
```
story validator create --stake 1000000000000000000 --private-key "your_private_key"
```
### BACK UP FILE

1-Wallet private key:
```sudo nano ~/.story/story/config/private_key.txt```

2-Validator key:
```sudo nano ~/.story/story/config/priv_validator_key.json```
