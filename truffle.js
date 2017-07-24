//var web3 = require("./node_modules/web3");
//web3.setProvider(new web3.providers.HttpProvider('http://localhost:8545'));
//var web3 = new Web3(new Web3.providers.HttpProvider("http://localhost:8545"));

module.exports = {
    networks: {
	development: {
	    host: "localhost",
	    port: 8545,
	    network_id: "*",
	    //default trx parameters
	    from: "0x2d2804cfdb2674f3184896fa8538237588699bad"
	},
    }
};
