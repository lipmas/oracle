pragma solidity ^0.4.11;

import "./Oracle.sol";

contract TestOracle{
  
  Oracle public oracle;
  uint32 public thePrice;

  function TestOracle(address _oracleAddr){
   oracle = Oracle(_oracleAddr);
   
  }

  function getPrice(bytes4 _ticker){
    oracle.makePriceRequest(_ticker, this.getPriceCallback);
  }

  function getPriceCallback(uint32 _price) {
    require(msg.sender == address(oracle));
    thePrice = _price;
  }
}
