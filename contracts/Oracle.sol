pragma solidity ^0.4.11;

/*
 TODO: 
 -make gas stipend required as part of fee and possible allow calling contract to specify
 an amount of gas (and somehow determine ahead of time gas price) needed for subcall, refund unused stipend
*/

contract Owned {
  address public owner;

  function Owned(){
    owner = msg.sender;
  }
  
  modifier onlyOwner(){
    require(msg.sender == owner);
    _;
  }
}

contract Oracle is Owned {
  /* type definitions */
  struct PriceRequest{
    bytes4 ticker;
    uint timestamp;
    uint timeOut;
    address requestor;
    function (bool success, uint32 price) external payable callback;
  }

  /* state */
  
  //constant
  uint public fee;
  uint public timeOut;
  uint public maxGas;
  
  //mutable
  uint public currId;
  mapping(uint => PriceRequest) public priceRequests;
  mapping(uint => bool) public priceRequestsPending;
  
  /* Modifiers */
  modifier isPaid() {
    require(msg.value >= fee);
    _;
  }

  modifier onlyPast(uint timestamp) {
    require(timestamp <= now);
    _;
  }

  modifier onlyFuture(uint timestamp) {
    require(timestamp > now);
    _;
  }
  
  /* Events */
  event NewPriceRequest(uint id, bytes4 ticker, uint timestamp, uint timeout);
  
  /* Functions */
  
  //constructor
  /* @param _timeout: time out in blocks */
  function Oracle(uint _fee, uint _maxGas, uint _timeOut){
    currId = 0;
    fee = _fee;
    maxGas = _maxGas;
    timeOut = _timeOut;
  }

  function makePriceRequest(bytes4 _ticker, uint timestamp, function(bool, uint32) external payable _callback) payable isPaid onlyPast(timestamp) returns (uint currId) {
    currId++;
    priceRequests[currId] = PriceRequest(_ticker, timestamp, block.number + timeOut, msg.sender, _callback);
    priceRequestsPending[currId] = true;
    NewPriceRequest(currId, _ticker, timestamp, block.number + timeOut);
  }

  /*
  function makeFuturePriceRequest(bytes4 _ticker, uint timestamp, function(bool, uint32) external payable _callback) payable isPaid onlyFuture(timestamp) returns (uint currId){
    currId++;
    //timeout clock doesnt start until timestamp is reached
    priceRequests[currId] = PriceRequest(_ticker, timestamp,  timestamp + timeOut, msg.sender, _callback);
    priceRequestsPending[currId] = true;
    NewPriceRequest(currId, _ticker, timestamp, block.number + timeOut);
  }
  */
  
  function priceReply(uint _requestId, uint32 _price) onlyOwner {
    //check that id exists and hasnt been processed yet
    require(priceRequestsPending[_requestId]);
    
    PriceRequest request = priceRequests[_requestId];
    
    //must be before timeout
    require(block.number < request.timeOut);

    //guard against reentracy
    priceRequestsPending[_requestId] = false;
    
    //call the provided callback function with success
    //but limit gas used in subcall to maxGas
    request.callback.gas(maxGas)(true, _price);

    //clean up request
    //delete priceRequestsPending[_requestId];
    //delete priceRequests[_requestId];
  }

    function timeoutRefund(uint _requestId) {
    //check that id exists and hasnt been processed yet
    require(priceRequestsPending[_requestId]);
    
    PriceRequest request = priceRequests[_requestId];
    
    //only after timeout
    require(block.number >= request.timeOut);

    //guard against reentracy
    priceRequestsPending[_requestId] = false;

    //call the provided callback function
    //return failure and send back fee
    //but limit gas used in subcall to maxGas
    request.callback.gas(maxGas).value(fee)(false, 0);

    //clean up request
    //delete priceRequestsPending[_requestId];
    //delete priceRequests[_requestId];
  }

}
