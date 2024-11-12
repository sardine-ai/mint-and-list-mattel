# mint-and-list-mattel

## Setup Steps
- download the flow cli at: https://developers.flow.com/tools/flow-cli/install
- create a testnet keypair with: `flow accounts create -n testnet -o testnet.json`
  - You will be prompted to name it. Name it testnet
  - You will be prompted to select a chain. Select Testnet
  - The private key will automatically be added to the gitignore
- Copy the account address and airdrop flow to it at: https://testnet-faucet.onflow.org/fund-account
- Deploy The ExampleNFT contract with `flow accounts add-contract ./cadence/contracts/ExampleNFT.cdc -n testnet --signer testnet`
- In your flow.json update the ExampleNFT object with your account address.
  - for instance if your account address is `0x3e9bb56b5f645ec4` make the testnet key: `3e9bb56b5f645ec4`
  ```
  "ExampleNFT": {
    "source": "./cadence/contracts/ExampleNFT.cdc",
    "aliases": {
      "testing": "0000000000000008",
      "testnet": "3e9bb56b5f645ec4"
    }
  }
  ```
- Now you should be goog to run `python3 create-nft-listings.py`. The output will look like this:
```
💾 result saved to: storefront-listings.json 
[{'contractAddress': '0x3e9bb56b5f645ec4', 'nftId': '10995116371178', 'token': 'FlowToken', 'cost': '0.00001000'}, {'contractAddress': '0x3e9bb56b5f645ec4', 'nftId': '10995116371180', 'token': 'FlowToken', 'cost': '0.00002000'}, {'contractAddress': '0x3e9bb56b5f645ec4', 'nftId': '10995116371182', 'token': 'FlowToken', 'cost': '0.00003000'}, {'contractAddress': '0x3e9bb56b5f645ec4', 'nftId': '10995116371184', 'token': 'FlowToken', 'cost': '0.00004000'}, {'contractAddress': '0x3e9bb56b5f645ec4', 'nftId': '10995116371186', 'token': 'FlowToken', 'cost': '0.00005000'}, {'contractAddress': '0x3e9bb56b5f645ec4', 'nftId': '10995116371188', 'token': 'FlowToken', 'cost': '0.00006000'}, {'contractAddress': '0x3e9bb56b5f645ec4', 'nftId': '10995116371190', 'token': 'FlowToken', 'cost': '0.00007000'}, {'contractAddress': '0x3e9bb56b5f645ec4', 'nftId': '10995116371192', 'token': 'FlowToken', 'cost': '0.00008000'}, {'contractAddress': '0x3e9bb56b5f645ec4', 'nftId': '10995116371194', 'token': 'FlowToken', 'cost': '0.00009000'}, {'contractAddress': '0x3e9bb56b5f645ec4', 'nftId': '10995116371196', 'token': 'FlowToken', 'cost': '0.00010000'}]

Currently 1 FLOW = 1.0000000801500033 USDC on Flow Testnet
```
- each object contains the contract address and nft id which you can use to test
- Congrats, you have just minted an nft and listed it on mattels marketplace 

## Using Sardine Checkout
- With a contract address and nft you can now call the following endpoint to obtain a session key
```
curl --location 'https://api.sandbox.sardine.ai/v1/auth/client-tokens' \
--header 'Content-Type: application/json' \
--header 'Authorization: Basic YOUR_ATHORIZATION_CODE' \ <---- FILL THIS OUT
--data-raw '
{
	"referenceId": "test-0.9790479wedwedwed3007148",
	"expiresIn": 3600,
	"identityPrefill": {
		"firstName": "fname",
		"lastName": "lname",
		"dateOfBirth": "2000-01-01",
		"emailAddress": "foobar-low-risk@sardine.ai",
		"phone": "+19254485826",
		"address": {
			"street1": "123 main st",
			"street2": "",
			"city": "irvine",
			"regionCode": "CA",
			"postalCode": "02747",
			"countryCode": "US"
		}
	},
	"paymentMethodTypeConfig": {
		"enabled": [
			"us_debit",
			"us_credit",
			"international_debit",
			"international_credit",
			"ach"
		],
		"default": "us_debit"
	},
    "nft": {
        "name": "Hot wheels <> Sardine",
        "imageUrl": "https://cdn.shopify.com/s/files/1/0568/1132/3597/files/HWNFT_S4_modular-grid_584x800b.jpg?v=1669157307",
        "network": "flow",
        "recipientAddress": "THE_ACCOUNT_ADDRESS_YOU_CREATED", <---- FILL THIS OUT
        "platform": "mattel",
        "type": "nft_secondary",
        "blockchainNftId": "A_BLOCKCHAIN_NFT_ID", <---- FILL THIS OUT
        "contractAddress": "A_CONTRACT_ADDRESS" <---- FILL THIS OUT
    }
}'
```
- Use the client token in the following url: `https://crypto.sandbox.sardine.ai/?client_token=CLIENT_TOKEN&show_features=true`
- YEEEEE