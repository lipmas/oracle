pragma solidity ^0.4.11;

import "./Oracle.sol";

//implements simple mutex to prevent reentrant calls when needed
//no longer needed because transfer and send limit gas to 2300?
contract Mutex {
  bool locked;
  function Mutex(){
    locked = false;
  }
  modifier lock(){
    require(!locked);
    locked = true;
    _;
    locked = false;
  }
}

contract OptionCallContract is Mutex {
  Oracle public oracle;
  
  address public buyer;
  address public seller;
  uint public collateralPaid;
  
  bytes4 public ticker;
  uint32 public optionPrice;
  uint32 public strikePrice;
  uint32 public numberContracts;
  uint public startTime;
  uint public expiryTime;
  
  //cap the amount of money that can be lost by the seller
  uint public collateralRequired;

  modifier isPaid(){ require(msg.value >= optionPrice); _; }
  modifier isCollateralized(){ require(msg.value >= collateralRequired); collateralPaid += msg.value; _; }
  modifier onlyOracle(){ require(msg.sender == address(oracle)); _; }
  modifier onlyBuyer(){ require(msg.sender == buyer); _; }
  modifier onlySeller(){ require(msg.sender == seller); _; }
  modifier onlyLockedIn(){ require(buyer != address(0x0) && seller != address(0x0)); _; }
  modifier onlyBeforeExpiry(){ require(now <= expiryTime); _; }
  modifier onlyAfterExpiry(){ require(now > expiryTime); _; }

  function max(uint a, uint b) private returns (uint) {
    return a > b ? a : b;
  }
  
  function OptionCallContract(address oracleAddr, bytes4 _ticker, uint32 _optionPrice, uint32 _strikePrice,
			      uint32 _numberContracts, uint _expiryTime, uint _collateralRequired){
    oracle = Oracle(oracleAddr);
    ticker = _ticker;
    optionPrice = _optionPrice;
    strikePrice =  _strikePrice;
    numberContracts = _numberContracts;
    expiryTime = _expiryTime;
    collateralRequired = _collateralRequired;
    
    startTime = now;
  }

  function buy() payable isPaid{
    require(buyer == address(0x0));
    buyer = msg.sender;
  }

  function sell() payable isCollateralized {
    require(seller == address(0x0));
    seller = msg.sender;
  }

  function execute() onlyLockedIn onlyBuyer onlyBeforeExpiry {
    oracle.makePriceRequest(ticker, this.executeCallback);
  }

  function executeCallback(bool _success, uint32 _price) onlyOracle lock{
    if(!_success){
      //error refund both participants
      errorRefund();
    }
    else{
      if(_price < strikePrice){
	uint diff = strikePrice - _price;
	uint payAmount = max(diff*numberContracts, collateralRequired);
	
	//pay the buyer
	buyer.transfer(payAmount);
	
	//pay the seller and refund unused collateral
	seller.transfer(collateralPaid - payAmount + optionPrice);
      }
    }
  }

  function timeoutRefund() onlySeller onlyAfterExpiry lock{
    seller.transfer(collateralPaid + optionPrice);
  }
  
  function errorRefund() internal lock{
    buyer.transfer(optionPrice);
    seller.transfer(collateralPaid);
  }
}
