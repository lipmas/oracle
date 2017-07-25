pragma solidity ^0.4.11;

import "./Oracle.sol";

contract SimpleOracleClient{
  
  Oracle public oracle;
  uint32 public thePrice;

  function SimpleOracleClient(address _oracleAddr){
   oracle = Oracle(_oracleAddr);
   
  }

  function getPrice(bytes4 _ticker) payable returns (uint id) {
    return oracle.makePriceRequest.value(msg.value)(_ticker, now, this.getPriceCallback);
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

  //fallback payable function
  function () payable{}
}
