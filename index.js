var Web3 = require('web3');
var web3 = new Web3();

var http = require('http');
var express = require('express');
var app = express();

var config = {port:1337};

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


app.get('/kyc', function(req, resp){
    var accountToSignWith = null;

    //use local rpc
    if(!process.env.web3provider) {
        web3.setProvider(new web3.providers.HttpProvider('http://localhost:8545'));
        accountToSignWith = web3.eth.accounts[1];
    }

    //web3.personal.importRawKey

    var registry = web3.eth.contract(require('./abi/KYCRegistry')).at('0x3e78bfbd336845f18912edaae026fca163e5e0d6');

    var user = req.query.user;
    var hash = "0xlololol"

    //registry.

    setTimeout(function(){
        registry.register(user, hash, {from:accountToSignWith}, function(err,res){
            resp.send(err || res)
        })
    }, 10000)

    /*registry.owner.call(function(err, res){
        resp.send(res);
    })*/

})

//app.use("/", express.static(__dirname + '/public'));

var http_port = process.env.PORT || config.port;

var server = http.createServer(app);

server.listen(http_port, function () {
    var host = server.address().address;
    var port = server.address().port;

    console.log('Evtend app listening at http://%s:%s', host, port);
});
