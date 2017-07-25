pragma solidity ^0.4.11;

import "./Oracle.sol";

contract OptionCallContract {
  Oracle public oracle;
  
  address public buyer;
  address public seller;
  uint public collateralPaid;
  uint public oracleFee;
  
  bytes4 public ticker;
  uint32 public optionPrice;
  uint32 public strikePrice;
  uint32 public numberContracts;
  uint public startTime;
  uint public expiryTime;
  
  //cap the amount of money that can be lost by the seller
  uint public collateralRequired;

  modifier buyerPaid(){ require(msg.value >= optionPrice + oracleFee/2); _; }
  modifier sellerPaid(){ require(msg.value >= collateralRequired + oracleFee/2); collateralPaid += msg.value; _; }
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
    oracleFee = oracle.fee();
    ticker = _ticker;
    optionPrice = _optionPrice;
    strikePrice =  _strikePrice;
    numberContracts = _numberContracts;
    expiryTime = _expiryTime;
    collateralRequired = _collateralRequired;
    startTime = now;
  }

  function buy() payable buyerPaid {
    require(buyer == address(0x0));
    buyer = msg.sender;
  }

  function sell() payable sellerPaid {
    require(seller == address(0x0));
    seller = msg.sender;
  }

  function execute() onlyLockedIn onlyBuyer onlyBeforeExpiry {
    //call the oracle with fee
    oracle.makePriceRequest.value(oracleFee)(ticker, now, this.executeCallback);
  }

  function executeCallback(bool _success, uint32 _price) onlyOracle {
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

  function optionExpiredRefund() onlySeller onlyAfterExpiry {
    seller.transfer(collateralPaid + optionPrice);
  }
  
  function errorRefund() internal {
    buyer.transfer(optionPrice);
    seller.transfer(collateralPaid);
  }
}
