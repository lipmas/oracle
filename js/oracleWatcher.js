//Run this file within the truffle execution environment:
// truffle exec <filename>.js
var gdaxApi = require("./gdax.js");

var oracle, client;
var oracleFee;

module.exports = function(callback) {
    //import truffle contract abstractions
    Oracle = artifacts.require("Oracle");
    SimpleOracleClient = artifacts.require("SimpleOracleClient");
    console.log("oracle is at:", Oracle.address)
    console.log("client is at:", SimpleOracleClient.address)
    console.log("current block is:", web3.eth.blockNumber);
    
    //filterForCurrentBalance();
    Oracle.deployed().then(function(instance){
	oracle = instance;
	return SimpleOracleClient.deployed();
    }).then(function(instance){
	client = instance;
	//setup the filters
	setupFilters();
	//get the oracle fee
	return oracle.fee();
    }).then(function(fee) {
	oracleFee = fee.toNumber();
	console.log("Using oracleFee as: ", oracleFee);
    }).then(function(){
	//do tests
	//test();
	test_gdax();
    });
}

function setupFilters(){
    //getPreviousPriceRequests(oracle, 0);
    watchForPriceRequests();
    watchForClientPriceReturned();
}

function test_gdax(){
    client.getPrice('BTC', {value: oracleFee});
    client.getPrice('ETH', {value: oracleFee});
}

function test(){
    var test_price = Math.random()*100;
    return client.getPrice("IBM", {value: oracleFee}).then(function(trxObj) {
	//console.log(trxObj);
	return oracle.currId.call();
    }).then(function(id){
	let currId = id.toNumber();
	console.log(currId);
	return oracle.priceReply(currId, test_price);
    }).then(function(trxObj) {
	//console.log(trxObj);
	return client.thePrice.call();
    }).then(function(price) {
	//console.log("Price returned from oracle is: ", price.toNumber());
	return true;
    });
}

//watches for new price requests events
function watchForPriceRequests(){
    newPriceRequestFilter = oracle.NewPriceRequest();
    newPriceRequestFilter.watch(function(error, result){
	if(!error){
	    logPriceRequest(result);
	    handlePriceRequest(result);
	}
	else{
	    console.log(error);
	}
    });
}

function handlePriceRequest(req){
    var ticker = web3.toUtf8(req.args.ticker);	    
    //convert from seconds to ms for js date object
    var id = req.args.id.toNumber();
    var timestamp_unix_time = req.args.timestamp.toNumber()*1000;
    var timestamp = new Date(timestamp_unix_time);	    
    var timeout = req.args.timeout.toNumber();

    
    //if this ticker is supported by gdax api
    if(gdaxApi.supportedProducts.includes(ticker)){
	console.log("Getting price for " + ticker + " from gdax api...");
	var price = gdaxApi.getLastPrice(ticker).then(function(price){
	    console.log("Replying with price: ", price);
	    oracle.priceReply(id, price );
	});
    }
}

function logPriceRequest(req){
    var ticker = web3.toUtf8(req.args.ticker);	    
    //convert from seconds to ms for js date object
    var id = req.args.id.toNumber();
    var timestamp_unix_time = req.args.timestamp.toNumber()*1000;
    var timestamp = new Date(timestamp_unix_time);	    
    var timeout = req.args.timeout.toNumber();
    console.log("Id is: ", id);
    console.log("Ticker is: ", ticker);
    console.log("Timestamp is: ", timestamp.toString());
    console.log("Timeout is: ", timeout);
}

function watchForClientPriceReturned(){
    priceReturnedFilter = client.PriceReturned();
    priceReturnedFilter.watch(function(error, result){
	if(!error){
	    console.log("Got price returned event");
	    var price = result.args.price.toNumber();
	    console.log("Price returned from oracle is: ", price);
	}
	else{
	    console.log(error);
	}
    });
}

/*
//gets all previous price requests from startBlock
function getPreviousPriceRequests(oracle, startBlock){
    newPriceRequestFilter = oracle.NewPriceRequest({}, {fromBlock: startBlock, toBlock: 'latest'});
    newPriceRequestFilter.get(function(error, logs){
	//console.log(logs);
	if(!error){	    
	    for(var i=0; i<logs.length; ++i){
		//logPriceRequest(logs[i]);
	    }
	}
    });
}

function filterForCurrentBalance(){
    var a1 = web3.eth.accounts[0];
    var originalBalance = web3.eth.getBalance(a1);
    console.log(originalBalance);
    web3.eth.filter('latest').watch(function() {
	var currentBalance = web3.eth.getBalance(a1).toNumber();
	console.log("Current Balance is:", currentBalance);
    });
}

*/
