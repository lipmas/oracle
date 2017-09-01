pragma solidity ^0.4.13;

import "./Oracle.sol";

contract SimpleOracleClient{
  
  Oracle public oracle;
  uint32 public thePrice;
  bool   public errorStatus;  

  event PriceReturned(uint32 price);
  
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
      errorStatus = false;
      thePrice = _price;
      PriceReturned(_price);
    }
    else{
      //error or timeout occurred
      //msg.value has the returned fee
      errorStatus = true;
    }
  }

  //fallback payable function
  function () payable{}
}
