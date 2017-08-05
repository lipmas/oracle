//Run this file within the truffle execution environment:
// truffle exec <filename>.js

var oracle, client;
module.exports = function(callback) {
    //import truffle contract abstractions
    Oracle = artifacts.require("Oracle");
    SimpleOracleClient = artifacts.require("SimpleOracleClient");
    console.log("oracle is at: ", Oracle.address)
    console.log("client is at: ", SimpleOracleClient.address)

    //filterForCurrentBalance();
    Oracle.deployed().then(function(instance){
	oracle = instance;
	//setup filters to watch
	return SimpleOracleClient.deployed();
    }).then(function(instance){
	client = instance;
	setupFilters();
	test();
    });
}

function test(){
    var oracleFee;
    oracle.fee.call().then(function(fee){
	oracleFee = fee.toNumber();
	client.getPrice("IBM", {value: oracleFee}).then(function(trxObj) {
	    console.log(trxObj);
	    /*
	    //return oracle.priceReply(1, test_price);
	    }).then(function(trxObj) {
	    return client.thePrice.call();
	    }).then(function(price) {
	    */
	}).catch(function(err){
	    console.log(err);
	});
    });
}
			  
function setupFilters(){
    //getPreviousPriceRequests(oracle, 0);
    watchForPriceRequests(oracle);
}

//gets all previous price requests from startBlock
function getPreviousPriceRequests(oracle, startBlock){
    newPriceRequestFilter = oracle.NewPriceRequest({}, {fromBlock: startBlock, toBlock: 'latest'});
    newPriceRequestFilter.get(function(error, logs){
	//console.log(logs);
	if(!error){	    
	    for(var i=0; i<logs.length; ++i){
		logPriceRequest(logs[i]);
	    }
	}
    });
}

//watches for new price requests events
function watchForPriceRequests(oracle){
    newPriceRequestFilter = oracle.NewPriceRequest();
    newPriceRequestFilter.watch(function(error, result){
	if(!error){
	    logPriceRequest(result);
	}
	else{
	    console.log(error);
	}
    });
}

function logPriceRequest(req){
    var ticker = web3.toAscii(req.args.ticker);	    
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

function filterForCurrentBalance(){
    var a1 = web3.eth.accounts[0];
    var originalBalance = web3.eth.getBalance(a1);
    console.log(originalBalance);
    web3.eth.filter('latest').watch(function() {
	var currentBalance = web3.eth.getBalance(a1).toNumber();
	console.log("Current Balance is:", currentBalance);
    });
}
