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
	console.log("Oracle Fee is: ", oracleFee);
    }).then(function(){
	testHook();
    });
}

function testHook(){
    simpleTest();
    //testGdax();    
}

function setupFilters(){
    //getPreviousPriceRequests(oracle, 0);
    watchForPriceRequests();
    watchForClientPriceReturned();
}

function testGdax(){
    client.getPrice('BTC', {value: oracleFee});
    client.getPrice('ETH', {value: oracleFee});
    client.getPrice('LTC', {value: oracleFee});
}

function simpleTest(){
    console.log("Running simple test");
    var test_price = Math.random()*100;
    console.log("Sending price request to oracle");
    return client.getPrice("IBM", {value: oracleFee}).then(function(trxObj) {
	//console.log(trxObj);
	return oracle.currId.call();
    }).then(function(id){
	let currId = id.toNumber();
	console.log("ID of the request is: ", currId);
	console.log("Sending price reply to oracle: ", test_price);
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
    newPriceRequestFilter = oracle.NewPriceRequest({fromBlock: 'latest'});
    newPriceRequestFilter.watch(function(error, result){
	if(!error){
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

    logPriceRequest(id, ticker, timestamp, timeout);
    
    //if this ticker is supported by gdax api
    if(gdaxApi.supportedProducts.includes(ticker)){
	console.log("Getting price for " + ticker + " from gdax api...");
	var price = gdaxApi.getLastPrice(ticker).then(function(price){
	    console.log("Replying with price: ", price);
	    oracle.priceReply(id, price );
	});
    }

    //TODO:
    //add http request to oracle service here
}

function logPriceRequest(id, ticker, timestamp, timeout){
    console.log("-----NEW PRICE REQUEST-----");
    console.log("Id is: ", id);
    console.log("Ticker is: ", ticker);
    console.log("Timestamp is: ", timestamp.toString());
    console.log("Timeout is: ", timeout);
    console.log("---------------------------");
}

function watchForClientPriceReturned(){
    priceReturnedFilter = client.PriceReturned({fromBlock: 'latest'});
    priceReturnedFilter.watch(function(error, result){
	if(!error){
	    console.log("-----NEW PRICE RETURNED-----");
	    var price = result.args.price.toNumber();
	    console.log("Price returned from oracle is: ", price);
	    console.log("----------------------------");
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
		handlePriceRequest(logs[i]));
	    }
	}
    });
}
*/
