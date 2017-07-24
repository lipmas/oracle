var Oracle   = artifacts.require("./Oracle.sol");
var TestOracle = artifacts.require("./TestOracle.sol");

module.exports = function(deployer, network, accounts) {

    if(network == "development"){
	var fee = 0;
	var maxGas = 100000;
	var timeOut = 60*5; //5 min
	
	deployer.deploy(Oracle, fee, maxGas, timeOut).then(function() {
	    return deployer.deploy(TestOracle, Oracle.address);
	});
    }
};
