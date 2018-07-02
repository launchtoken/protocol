const Tx = require('ethereumjs-tx');

function callSolidityFunction(web3, address, data, public_key, private_key, cb){
    web3.eth.getTransactionCount(public_key, function(err, nonce) {
        console.log("TX COUNT", nonce)

        var account = public_key;
        var key = new Buffer(private_key, 'hex')

        const gasPrice = web3.eth.gasPrice;

        //console.log("gas price", gasPrice)

        const gasPriceHex = web3.toHex(gasPrice.mul(20));
        const gasLimitHex = web3.toHex(300000);

        var tra = {
            gasPrice: gasPriceHex,
            gasLimit: gasLimitHex,
            data: data,
            from: account,
            to: address,
            nonce: nonce,
            chainId: 3,
        };

        var tx = new Tx(tra);
        tx.sign(key);

        var stx = tx.serialize();
        web3.eth.sendRawTransaction('0x' + stx.toString('hex'), function (err, hash) {
            if (err) {
                if(cb) cb(err);
                console.log(err);
                return;
            }
            console.log('tx: ' + hash);
            if(cb) cb(null, hash);
        });
    });
}

module.exports = callSolidityFunction;