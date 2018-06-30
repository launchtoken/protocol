var Web3 = require('web3');


var http = require('http');
var express = require('express');
var app = express();
const Tx = require('ethereumjs-tx');

var config = {port:1337};

var env = process.env.NODE_ENV || 'dev';

var kyc_config = null;
if(env == 'dev') {
    kyc_config = require('./kyc_config');
}else{
    kyc_config = {
        private_key: process.env.KYC_PRIVATE_KEY,
        public_key: process.env.KYC_PUBLIC_KEY,
        contract_address: process.env.KYC_CONTRACT_ADDRESS,
        ethereum_node: process.env.ETHEREUM_NODE
    }
}

var web3 = new Web3(new Web3.providers.HttpProvider(kyc_config.ethereum_node));

app.use(function(req, res, next) {
    res.header("Access-Control-Allow-Origin", "*");
    res.header("Access-Control-Allow-Headers", "Origin, X-Requested-With, Content-Type, Accept");
    next();
});

app.get('/', function (req, res) {
    res.sendFile(__dirname + '/launchtoken.html');
});

app.get('/ico', function (req, res) {
    res.sendFile(__dirname + '/example_ico.html');
});

app.get('/node_modules/web3/dist/web3.min.js', function (req, res) {
    res.sendFile(__dirname + '/node_modules/web3/dist/web3.min.js');
});


app.get('/kyc', function(req, resp) {
    var accountToSignWith = null;
    var contract_address = null;
    var localnet = false;

    //use local rpc
    if( process.argv.indexOf('local') < 0 ){
        console.log('ROPSTEN request');
        contract_address = kyc_config.contract_address;
    } else { //!process.env.web3provider
        web3.setProvider(new web3.providers.HttpProvider('http://localhost:8545'));
        accountToSignWith = web3.eth.accounts[1];
        contract_address = '0x3e78bfbd336845f18912edaae026fca163e5e0d6';
        localnet = true;
    }

    var registry = web3.eth.contract(require('./abi/KYCRegistry')).at(contract_address);

    var user = req.query.user;

    verifyKYC({}, function(hash) {
        //var hash = "0xjajajaja"

        if (localnet) {
            registry.register(user, hash, {from: accountToSignWith}, function (err, res) {
                resp.send(err || res)
            })
        } else {
            callSolidityFunction(
                contract_address,
                registry.register.getData(user, hash),
                kyc_config.public_key,
                kyc_config.private_key,
                function(err, res){
                    resp.send(res);
                }
            );
        }
    })

    //registry.owner.call(function(err, res){
    //    resp.send(res);
    //})

})

function callSolidityFunction(address, data, public_key, private_key, cb){
    web3.eth.getTransactionCount(public_key, function(err, nonce) {
        console.log("TX COUNT", nonce)

        var account = public_key;
        var key = new Buffer(private_key, 'hex')

        const gasPrice = web3.eth.gasPrice;

        //console.log("gas price", gasPrice)

        const gasPriceHex = web3.toHex(gasPrice.mul(20));
        const gasLimitHex = web3.toHex(3000000);

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

function verifyKYC(data, cb){
    setTimeout(function(){
        cb("0xHASH" + (new Date()).getTime());
    }, 10000);
}

//app.use("/", express.static(__dirname + '/public'));

var http_port = process.env.PORT || config.port;

var server = http.createServer(app);

server.listen(http_port, function () {
    var host = server.address().address;
    var port = server.address().port;

    console.log('LaunchToken server listening at http://%s:%s', host, port);
    console.log("ENV:", env);
});
