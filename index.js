var http = require('http');
var express = require('express');
var app = express();

var config = {port:1337};

app.get('/', function (req, res) {
    res.sendFile(__dirname + '/launchtoken.html');
});

app.get('/ico', function (req, res) {
    res.sendFile(__dirname + '/example_ico.html');
});

app.get('/node_modules/web3/dist/web3.min.js', function (req, res) {
    res.sendFile(__dirname + '/node_modules/web3/dist/web3.min.js');
});

//app.use("/", express.static(__dirname + '/public'));

var http_port = process.env.PORT || config.port;

var server = http.createServer(app);

server.listen(http_port, function () {
    var host = server.address().address;
    var port = server.address().port;

    console.log('Evtend app listening at http://%s:%s', host, port);
});
