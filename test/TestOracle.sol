pragma solidity ^0.4.11;

//truffle
import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";

//helper test contracts
import "./ThrowProxy.sol";

//contracts
import "../contracts/Oracle.sol";
import "../contracts/SimpleOracleClient.sol";

contract TestOracle {
  //truffle test will fund this contract after deployed
  uint public initialBalance = 10 ether;

  uint defaultOracleFee = 100 wei;
  uint defaultOracleTimeout = 10;
  uint defaultMaxGas = 100000;
  
  uint startTime;
  uint startBlockNumber;

  uint currTime;

  Oracle deployedOracle;
  
  Oracle oracle1;  
  SimpleOracleClient client1;
  
  function beforeAll(){
    //Assert.equal(true, false, "This gets called when:");
    startTime = now;
    startBlockNumber = block.number;

    //reference to our deployed oracle
    deployedOracle = Oracle(DeployedAddresses.Oracle());
  }


  function beforeEach(){    
    //each trx increments testrpc by 1 block
    //Assert.equal(startTime, now, "time after one trx is:");
    //Assert.equal(startBlockNumber, block.number, "block number after one trx is:");

    if(block.number - startBlockNumber == 1){
    }
  }
  
  function testSimpleCallOracle(){
    Oracle oracle = new Oracle(defaultOracleFee, defaultMaxGas, defaultOracleTimeout);
    SimpleOracleClient client = new SimpleOracleClient(address(oracle));
    
    var id = client.getPrice.value(defaultOracleFee)("AAPL");
    Assert.equal(id, 1, "First request should have id of 1");
    Assert.equal(oracle.priceRequestsPending(id), true, "Request should be pending");

    var(ticker, timestamp, timeout, requestor, cb) = oracle.priceRequests(id);
    Assert.equal(ticker, "AAPL", "Ticker should be AAPL");
    Assert.equal(timestamp, now, "Timestamp should be now");
    Assert.equal(timeout, block.number + defaultOracleTimeout, "Timeout set incorrect");
    Assert.equal(requestor, address(client), "Requestor should be client");
    //Assert.equal(cb, client.getPriceCallback, "cb should be getPriceCallback");

    Assert.equal(oracle.owner(), this, "is owner");
    //oracle should invoke the callback function
    oracle.priceReply(id, 100);

    var price = client.thePrice();

    //must type cast price to uint256 because Assert library only handles uint256 right now
    Assert.equal(uint(price), 100, "Price should be 100 in client's state"); 
  }

  //prepare the oracle timeout test with an oracle with timeout of 1 block
  function testOracleTimeoutSetup() {
    uint timeout = 1;  
    oracle1 = new Oracle(defaultOracleFee, defaultMaxGas, timeout);
    client1 = new SimpleOracleClient(address(oracle1));
    
    client1.getPrice.value(defaultOracleFee)("AAPL");
  }
  
  function testOracleTimeout(){
    uint id = 1;

    var(ticker, timestamp, timeout, requestor, cb) = oracle1.priceRequests(id);
    Assert.isAtMost(timeout, block.number, "Timeout is now"); 

    ThrowProxy throwProxy = new ThrowProxy(address(oracle1));
    //prime the call
    Oracle(address(throwProxy)).priceReply(id, 123);
    bool r = throwProxy.execute.gas(defaultMaxGas)();
    Assert.isFalse(r, "calling price reply after timeout should throw");
    
    //should not throw
    oracle1.timeoutRefund(id);
    Assert.equal(client1.errorStatus(), true, "Oracle should return an error to client");
    Assert.equal(address(client1).balance, defaultOracleFee, "Fee should have been refunded to client");    
  }
}
