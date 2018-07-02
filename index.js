var http = require('http');
var express = require('express');
var app = express();
var bodyParser = require('body-parser')
app.use(bodyParser.json({ limit: '1mb' }))

var config = {port:1337};

app.use(function(req, res, next) {
    res.header("Access-Control-Allow-Origin", "*");
    res.header("Access-Control-Allow-Headers", "Origin, X-Requested-With, Content-Type, Accept");
    next();
});

app.get('/', function (req, res) {
    res.sendFile(__dirname + '/public/launchtoken.html');
});

app.get('/ico', function (req, res) {
    res.sendFile(__dirname + '/public/example_ico.html');
});

app.get('/node_modules/web3/dist/web3.min.js', function (req, res) {
    res.sendFile(__dirname + '/node_modules/web3/dist/web3.min.js');
});


var kyc_endpoint = require('./endpoints/kyc');
app.get('/kyc', kyc_endpoint)
app.post('/kyc', kyc_endpoint)

//app.use("/", express.static(__dirname + '/public'));

var http_port = process.env.PORT || config.port;

var server = http.createServer(app);

server.listen(http_port, function () {
    var host = server.address().address;
    var port = server.address().port;

    console.log('LaunchToken server listening at http://%s:%s', host, port);
    //console.log("ENV:", process.env);
});
