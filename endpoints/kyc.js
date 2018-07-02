var env = process.env.NODE_ENV || 'dev';
var Web3 = require('web3');
var rsa = require('../util/rsa_encryption');

var kyc_config = null;
var endpoint_config = null;
var rsa_config = null;
if(env == 'dev') {
    kyc_config = require('../conf/kyc_config');
    endpoint_config = require('../conf/endpoint_config');
    rsa_config = require('../conf/rsa_config');
}else{
    kyc_config = {
        private_key: process.env.KYC_PRIVATE_KEY,
        public_key: process.env.KYC_PUBLIC_KEY,
        contract_address: process.env.KYC_CONTRACT_ADDRESS,
    };
    endpoint_config = {
        ethereum_node: process.env.ETHEREUM_NODE,
        ipfs_endpoint: process.env.IPFS_ENDPOINT,
    };
    rsa_config = {
        public_key: process.env.RSA_PUBLIC_KEY,
    };
}

console.log(rsa_config.public_key)

var web3 = new Web3(new Web3.providers.HttpProvider(endpoint_config.ethereum_node));
var callSolidityFunction = require('../util/raw_transaction')

const IPFS = require('ipfs-mini');

var ipfs_endpoint_info = endpoint_config.ipfs_endpoint.split('://');
const ipfs = new IPFS({host: ipfs_endpoint_info[1], port: 5001, protocol: ipfs_endpoint_info[0]});

function endpoint(req, resp) {
    var body = req.body;
    var image_data = req.body.image_data;
    //delete body.image_data;

    //testCrypto(image_data);
    //return;

    //console.log("BODY", body);

    //const randomData = "8803cf48b8805198dbf85b2e0d514320"; // random bytes for testing

    var accountToSignWith = null;
    var contract_address = null;
    var localnet = false;

    var user = req.query.user;

    //use local rpc
    if( process.argv.indexOf('local') < 0 ){
        contract_address = kyc_config.contract_address;
    } else { //!process.env.web3provider
        web3.setProvider(new web3.providers.HttpProvider('http://localhost:8545'));
        accountToSignWith = web3.eth.accounts[1];
        contract_address = '0x3e78bfbd336845f18912edaae026fca163e5e0d6';
        localnet = true;
    }

    console.log('KYC request:', user);

    var registry = web3.eth.contract(require('../abi/KYCRegistry')).at(contract_address);

    verifyKYC(body, function(err, hash) {
        //var hash = "0xjajajaja"

        if (localnet) {
            registry.register(user, hash, {from: accountToSignWith}, function (err, res) {
                resp.send(err || res)
            })
        } else {
            callSolidityFunction(
                web3,
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

}

function verifyKYC(data, cb){
    setTimeout(function(){
        var encrypted = rsa.encrypt_large(JSON.stringify(data), rsa_config.public_key);

        //console.log("encrypted", encrypted, encrypted.length / 1000, "KB");

        ipfs.add(encrypted, function(err, hash) {
            if (err) {
                return console.log(err);
            }

            console.log("HASH:", hash);
            cb(null, hash);
        });
        //cb("0xHASH" + (new Date()).getTime());
    }, 10000);
}

function testCrypto(){
    //var input = "hello";
    var input = "";
    for(var i = 0; i<512; i++){
        input += "a";
    }

    console.log("input length", input.length)

    var encrypted = rsa.encrypt_large(input, rsa_config.public_key)

    var decrypted = rsa.decrypt_large(encrypted, rsa_config.private_key);

    console.log(encrypted)
    console.log(input, "==", decrypted, input == decrypted)
    console.log("input length", input.length)
    console.log("decrypted length", decrypted.length);

    return encrypted;
}

//testCrypto();

module.exports = endpoint;