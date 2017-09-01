pragma solidity ^0.4.13;

//truffle
import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";

//helper test contracts
import "./ThrowProxy.sol";

//contracts
import "../contracts/Oracle.sol";
import "../contracts/OptionCallContract.sol";

contract TestOptionCallContract {
  uint public initialBalance = 10 ether;

  uint defaultOracleFee = 100 wei;
  uint defaultOracleTimeout = 10;
  uint defaultMaxGas = 100000;
  

  Oracle oracle1;
  OptionCallContract callContract1;
  
  function testCreate(){
    oracle1 = new Oracle(defaultOracleFee, defaultMaxGas, defaultOracleTimeout);

    bytes4 ticker = "ABCD";
    uint32 optionPrice = 10;
    uint32 strikePrice = 100;
    uint32 numContracts = 100;
    uint expireTime =  now;
    uint collateral = 100;
      
    callContract1 = new OptionCallContract(address(oracle1), ticker, optionPrice, strikePrice, numContracts, expireTime, collateral);

    bool r;
    ThrowProxy proxy_buyer  = new ThrowProxy(address(callContract1));
    ThrowProxy proxy_seller = new ThrowProxy(address(callContract1));

    //buy for less than optionPrice
    OptionCallContract(address(proxy_buyer)).buy.value(5);
    r = proxy_buyer.execute(); 
    Assert.isFalse(r, "calling buy with not enough ether should throw");

    //buy for option price and verify state
    OptionCallContract(address(proxy_buyer)).buy.value(optionPrice + defaultOracleFee/2 + 500);
    r = proxy_buyer.execute();
    Assert.isTrue(r, "calling buy with enough ether should not throw");
    
    Assert.equal(callContract1.buyer(), address(proxy_buyer), "buyer should be registered in contract");

    /*
    //cannnot buy once already bought
    OptionCallContract(address(proxy_buyer)).buy.value(optionPrice + defaultOracleFee /2);
    r = proxy_buyer.execute();
    Assert.isFalse(r, "calling buy after there is already a buyer should throw");
    */
  }
}
