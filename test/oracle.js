var Oracle = artifacts.require("./Oracle.sol");
var SimpleOracleClient = artifacts.require("./SimpleOracleClient.sol");

contract('Oracle', function(accounts) {
    var a1 = accounts[0];
    var a2 = accounts[1];
    
    it("Simple client calls the oracle", function() {
	var oracle, client;
	var test_ticker = "AAPL";
	var test_price = 100;
	
	return Oracle.deployed().then(function(instance) {
	    oracle = instance;
	    return SimpleOracleClient.deployed();
	}).then(function(instance) {
	    client = instance;
	    return client.getPrice(test_ticker);
	}).then(function(trxObj) {
	    //console.log(trxObj);
	    return oracle.priceReply(1, test_price);
	}).then(function(trxObj) {
	    return client.thePrice.call();
	}).then(function(price) {
	    assert.equal(price, test_price, "Price should be in client's state");
	    return;
	});
    });    
});
