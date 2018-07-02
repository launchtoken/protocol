var crypto = require("crypto");

function encrypt(toEncrypt, publicKey) {
    var buffer = new Buffer(toEncrypt);
    var encrypted = crypto.publicEncrypt(publicKey, buffer);
    return encrypted.toString("base64");
};

function decrypt(toDecrypt, privateKey) {
    var buffer = new Buffer(toDecrypt, "base64");
    var decrypted = crypto.privateDecrypt(privateKey, buffer);
    return decrypted.toString("utf8");
};

function encrypt_large(toEncrypt, publicKey){
    var chunkSize = 470;

    var chunks = [];

    if(typeof toEncrypt != "string") toEncrypt = JSON.stringify(toEncrypt)

    for(var i = 0; i < toEncrypt.length; i+= chunkSize){
        var substring = toEncrypt.substr(i, chunkSize);
        var encrypted = encrypt(substring, publicKey);
        chunks.push(encrypted);
    }

    return JSON.stringify(chunks);
}

function decrypt_large(toDecrypt, privateKey){
    if(typeof toDecrypt == "string") toDecrypt = JSON.parse(toDecrypt);
    var chunks = toDecrypt;

    var result = "";

    for(var i = 0; i<chunks.length; i++){
        var decrypted = decrypt(chunks[i], privateKey);

        result += decrypted;
    }

    return result;
}

module.exports = {
    encrypt: encrypt,
    decrypt: decrypt,
    encrypt_large: encrypt_large,
    decrypt_large: decrypt_large,
}