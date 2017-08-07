const request = require('request');
var apiURI = "https://api.gdax.com";

function addHeaders(obj){
    obj.headers = {
        'User-Agent': 'gdax-node-client',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
    }
}

const supportedProducts =  ['BTC' ,'ETH'];

function getLastPrice(id){
    var fullId = id + '-USD';    
    var req = {
	method: "GET",
	uri: apiURI + "/" + 'products' + '/' +  fullId + '/' + 'stats',	
    }
    addHeaders(req);
    console.log(req);

    const p = new Promise( (resolve,reject) => {
	request(req, function(err, response, data){
	    if(err){
		reject(err);
	    }
	    let res = JSON.parse(data);
	    //console.log(res);
	    let price = res['last'];
	    resolve(price);
	})
    });
    return p;
}

//exports
exports.supportedProducts = supportedProducts;
exports.getLastPrice = getLastPrice;

//getLastPrice("BTC").then(function(p) { console.log(p); });
