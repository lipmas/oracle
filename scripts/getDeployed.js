var fs = require('fs');
var solc = require('solc');

module.exports = function(callback) {
    //import truffle contract abstractions
    Oracle = artifacts.require("Oracle");
    SimpleOracleClient = artifacts.require("SimpleOracleClient");
    
    console.log("oracle is at: ", Oracle.address)
    console.log("client is at: ", SimpleOracleClient.address)

    let oracleSource = fs.readFileSync('../contracts/Oracle.sol', 'utf8');
    let compiledOracle = solc.compile(oracleSource, 1);
    let oracleAbi = JSON.parse(compiledOracle.contracts[':Oracle'].interface);

    fs.writeFile('interface/oracle_addr', Oracle.address, (err) => {
	if(err){
	    console.error("Could not open file");
	}
    });
    fs.writeFile('interface/oracle_abi.json', JSON.stringify(oracleAbi), (err) => {
	if(err){
	    console.error("Could not open file");
	}
    });
}
