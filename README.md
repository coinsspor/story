## Story
Story is the World’s IP Blockchain, onramping Programmable IP to power the next generation of AI, DeFi, and consumer applications.

**DİSCORD : https://discord.gg/storyprotocol**

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


```
### Step-2 Synchronization Check

xx ,The 2-digit part number you entered in step 1.
```
curl localhost:xx657/status | jq
```
Make sure catching_up = false

### Step-3 Export wallet

```
story validator export --export-evm-key

```

### Step-4  Get wallet key and import to Metamask wallet

```
sudo nano ~/.story/story/config/private_key.txt

```
### Step-5  Import wallet to Metamask and faucet

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

### Step-6  Register validator
```
story validator create --stake 1000000000000000000 --private-key "your_private_key"
```
