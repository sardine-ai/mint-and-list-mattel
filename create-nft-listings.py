import json
import re
import subprocess
from subprocess import Popen, PIPE, STDOUT

subprocess.run("flow transactions send ./cadence/transactions/mint_and_list_nfts.cdc -n testnet --signer testnet --save storefront-listings.json --output json", shell=True)
with open('./storefront-listings.json', 'r') as file:
    result = []
    data = json.load(file)
    for event in data['events']:
        if 'ListingAvailable' in event['type']:
            listing_data = event['values']['value']['fields']
            result.append({
                'contractAddress': listing_data[0]['value']['value'],
                'nftId': listing_data[1]['value']['value'],
                'token': listing_data[5]['value']['value']['staticType']['typeID'].split('.')[2],
                'cost': listing_data[6]['value']['value']
            })
    print(result)

cmd = 'flow scripts execute ./cadence/scripts/get_pair_info.cdc A.7e60df042a9c0868.FlowToken A.0898fa4896d73752.USDCFlow -n testnet'
p = Popen(cmd, shell=True, stdin=PIPE, stdout=PIPE, stderr=STDOUT, close_fds=True)
output = str(p.stdout.read())
flow_pool_balance = float(re.findall(r'\[(.*?)\]', output)[0].split(',')[2])
usdc_pool_balance = float(re.findall(r'\[(.*?)\]', output)[0].split(',')[3])
print(f'\nCurrently 1 FLOW = {usdc_pool_balance / flow_pool_balance} USDC on Flow Testnet')