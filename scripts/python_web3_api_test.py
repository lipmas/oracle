import sys, time, io
import json
from web3 import Web3, KeepAliveRPCProvider, EthereumTesterProvider

abi_filename = "interface/oracle_abi.json"
oracle_abi = json.load(io.open(abi_filename, 'r'))

oracle_addr_filename = "interface/oracle_addr";
oracle_addr = io.open(oracle_addr_filename, 'r').readline()

#print(oracle_abi);
#print(oracle_addr);

#web3 = Web3(EthereumTesterProvider())
web3 = Web3(KeepAliveRPCProvider(host='localhost', port='8545'))

print("Deployer is: {0}".format(web3.eth.coinbase))

def new_block_callback(block_hash):
    sys.stdout.write("New Block: {0}\n".format(block_hash))
    sys.stdout.flush()

def new_price_request_callback(price_request):
    sys.stdout.write("got a price request:")
    sys.stdout.write(str(price_request))

def wait_for_filters():
    #new block filter
    block_filter = web3.eth.filter('latest')
    block_filter.watch(new_block_callback)
    
    oracle = web3.eth.contract(contract_name='oracle', abi=oracle_abi, address=oracle_addr)
    #price_request_filter = oracle.on('NewPriceRequest', {'filter': {'id': 2}})
    filter_params = {
        'filter': {
            #'id': [1,2,3,4,5,6,7,8,9]
        }
    }
    price_request_filter = oracle.on('NewPriceRequest', filter_params)
    price_request_filter.watch(new_price_request_callback)
    
    while 1:
        time.sleep(5)


def get_oracle_info():
    oracle = web3.eth.contract(contract_name='oracle', abi=oracle_abi, address=oracle_addr)
    owner = oracle.call().owner()

    currId = oracle.call().currId()

    print("Oracle address is: {0}".format(oracle.address))
    print("Oracle owner is: {0}".format(owner))
    print("Oracle currId is: {0}".format(currId))

    print_oracle_request(oracle, currId)

def print_oracle_request(oracle, id):
    (ticker, timestamp, timeout, requestor) = oracle.call().getPriceRequest(id)
    
    print("Price Request\n"
          "---------------\n"
          "ticker: {0}\n"
          "timestamp: {1}\n"
          "timeout: {2}\n"
          "requestor: {3}\n"
          "---------------".format(ticker, timestamp, timeout, requestor))

def main():
    #get_oracle_info()
    wait_for_filters()
    
if __name__ == "__main__":
    main()
