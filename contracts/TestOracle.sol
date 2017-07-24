pragma solidity ^0.4.11;

import "./Oracle.sol";

contract TestOracle{
  
  Oracle public oracle;
  uint32 public thePrice;

  function TestOracle(address _oracleAddr){
   oracle = Oracle(_oracleAddr);
   
  }

  function getPrice(bytes4 _ticker) payable{
    oracle.makePriceRequest.value(msg.value)(_ticker, this.getPriceCallback);
  }

  function getPriceCallback(bool success, uint32 _price) payable{
    require(msg.sender == address(oracle));

    if(success){
      //success code path
      thePrice = _price;
    }
    else{
      //error or timeout occurred
      //msg.value has the returned fee
    }
  }
}
