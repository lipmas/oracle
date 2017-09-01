pragma solidity ^0.4.13;

import "./Oracle.sol";

contract OptionCallContract {

  function max(uint a, uint b) private returns (uint) {
    return a > b ? a : b;
  }

  Oracle public oracle;
  
  address public buyer;
  address public seller;
  
  uint    public oracleFee;
  
  bytes4  public ticker;
  uint32  public optionPrice;
  uint32  public strikePrice;
  uint32  public numberContracts;
  uint    public startTime;
  uint    public expiryTime;
  
  //cap the amount of money that can be lost by the seller
  uint    public collateralRequired;

  modifier onlyOracle(){ require(msg.sender == address(oracle)); _; }
  modifier onlyBuyer(){ require(msg.sender == buyer); _; }
  modifier onlySeller(){ require(msg.sender == seller); _; }
  modifier onlyBeforeLockIn() { require(buyer == address(0x0) || seller == address(0x0)); _; }
  modifier onlyLockedIn(){ require(buyer != address(0x0) && seller != address(0x0)); _; }
  modifier onlyBeforeExpiry(){ require(now <= expiryTime); _; }
  modifier onlyAfterExpiry(){ require(now > expiryTime); _; }

  modifier buyerPaid(){
    require(msg.value >= optionPrice + oracleFee/2);
    _;
    var change = msg.value - optionPrice - oracleFee/2;
    if(change > 0){
      msg.sender.transfer(change);
    }
  }
  
  modifier sellerPaid(){
    require(msg.value >= collateralRequired + oracleFee/2);
    var change = msg.value - collateralRequired - oracleFee/2;
    if(change > 0){
      msg.sender.transfer(change);
    }
    _;
  }
  
  function OptionCallContract(address _oracleAddr, bytes4 _ticker, uint32 _optionPrice, uint32 _strikePrice,
			      uint32 _numberContracts, uint _expiryTime, uint _collateralRequired){
    oracle = Oracle(_oracleAddr);
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

  function buyerCancel() onlyBuyer onlyBeforeLockIn {
    refundBuyer();
  }
  
  function sell() payable sellerPaid {
    require(seller == address(0x0));
    seller = msg.sender;
  }

  function sellerCancel() onlySeller onlyBeforeLockIn {
    refundSeller();
  }

  function execute() onlyLockedIn onlyBuyer onlyBeforeExpiry {
    //call the oracle with fee
    oracle.makePriceRequest.value(oracleFee)(ticker, now, this.executeCallback);
  }

  function executeCallback(bool _success, uint32 _price) onlyOracle {
    if(!_success) {
      //error refund both participants
      errorRefund();
    }
    else {
      uint payAmount = 0;
      if(_price < strikePrice) {
	payAmount = max((strikePrice - _price)*numberContracts, collateralRequired);	
	//pay the buyer
	buyer.transfer(payAmount);
      }      
      //pay the seller and refund unused collateral
      seller.transfer(collateralRequired - payAmount + optionPrice);
    }
  }

  function optionExpired() onlySeller onlyAfterExpiry {
    //pay the seller and return full collateral
    seller.transfer(collateralRequired + optionPrice);
  }
  
  function refundBuyer() internal {
    buyer.transfer(optionPrice + oracleFee/2);
  }

  function refundSeller() internal {
    seller.transfer(collateralRequired + oracleFee/2);
  }
  
  function errorRefund() internal {
    refundBuyer();
    refundSeller();
  }
}
