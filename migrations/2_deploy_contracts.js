var Oracle   = artifacts.require("./Oracle.sol");
var SimpleOracleClient = artifacts.require("./SimpleOracleClient.sol");

module.exports = function(deployer, network, accounts) {

    if(network == "development"){
	var fee = 100;
	var maxGas = 100000;
	var timeOut = 5; //5 blocks
	
	deployer.deploy(Oracle, fee, maxGas, timeOut).then(function() {
	    return deployer.deploy(SimpleOracleClient, Oracle.address);
	});
    }
};
