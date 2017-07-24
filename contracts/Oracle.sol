pragma solidity ^0.4.11;

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
    uint timeOut;
    address requestor;
    function (uint32 price) external callback;
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
  
  /* Events */
  event NewPriceRequest(uint id, bytes4 ticker, uint timestamp);
  
  /* Functions */
  
  //constructor
  function Oracle(uint _fee, uint _maxGas, uint _timeOut){
    currId = 0;
    fee = _fee;
    maxGas = _maxGas;
    timeOut = _timeOut;
  }
  
  function makePriceRequest(bytes4 _ticker, function(uint32 price) external _callback) payable isPaid{
    currId++;
    priceRequests[currId] = PriceRequest(_ticker, now + timeOut, msg.sender, _callback);
    priceRequestsPending[currId] = true;
    NewPriceRequest(currId, _ticker, now);
  }

  function refund(uint _requestId) {
    //check that id exists and hasnt been processed yet
    require(priceRequestsPending[_requestId]);
    
    PriceRequest request = priceRequests[_requestId];
    //only after timeout
    require(now >= request.timeOut);
    //send refund to requestor
    require(request.requestor.send(fee));

    //clean up request
    delete priceRequestsPending[_requestId];
    delete priceRequests[_requestId];
  }
  
  function priceReply(uint _requestId, uint32 _price) onlyOwner {
    //check that id exists and hasnt been processed yet
    require(priceRequestsPending[_requestId]);
    
    PriceRequest request = priceRequests[_requestId];
    //must be before timeout
    require(now < request.timeOut);

    //call the provided callback function
    //but limit gas used in subcall to maxGas
    request.callback.gas(maxGas)(_price);

    //clean up request
    delete priceRequestsPending[_requestId];
    delete priceRequests[_requestId];
  }
}
