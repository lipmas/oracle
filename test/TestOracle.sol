pragma solidity ^0.4.11;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/Oracle.sol";
import "../contracts/SimpleOracleClient.sol";

contract TestOracle {
  //truffle test will fund this contract after deployed
  uint public initialBalance = 50 ether;
  
  uint oracleFee = 100;
  uint oracleTimeout = 5 minutes;
  uint maxGas = 100000;
  
  function testSimpleCallOracle(){
    Oracle oracle = new Oracle(oracleFee, maxGas, oracleTimeout);
    SimpleOracleClient client = new SimpleOracleClient(address(oracle));

    var id = client.getPrice.value(100)("AAPL");
    Assert.equal(id, 1, "First request should have id of 1");
    Assert.equal(oracle.priceRequestsPending(id), true, "Request should be pending");
    
    var(ticker, timestamp, timeout, requestor, cb) = oracle.priceRequests(id);
    Assert.equal(ticker, "AAPL", "Ticker should be AAPL");
    Assert.equal(timestamp, now, "Timestamp should be now");
    Assert.equal(timeout, now + oracleTimeout, "Timeout incorrect");
    Assert.equal(requestor, address(client), "Requestor should be client");
    //Assert.equal(cb, client.getPriceCallback, "cb should be getPriceCallback");

    Assert.equal(oracle.owner(), this, "is owner");
    //oracle should invoke the callback function
    oracle.priceReply(id, 100);

    var price = client.thePrice();

    //must type cast price to uint256 because Assert library only handles uint256 right now
    Assert.equal(uint(price), 100, "Price should be 100 in client's state"); 
  }
}
