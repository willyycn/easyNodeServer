/**
 * Created by willyy on 2017/3/2.
 */
var crypto = require('crypto');
var base64url = require('base64url');
var jwt = require('jsonwebtoken');
var libs = process.cwd() + '/libs/';
var config = require(libs + 'config'),
    debug = config.get('debug');
var fs = require('fs'),
    certs = process.cwd() + '/certs/',
    privateKey = fs.readFileSync(certs+config.get("rsa:private"),'utf8'),
    publicKey = fs.readFileSync(certs+config.get("rsa:public"),'utf8');
var maxBit = 2048/8,
    realBit = maxBit - 11,
    padding = crypto.constants.RSA_PKCS1_PADDING;

exports.getJwtDefault = function (jwtData) {
    return jwt.sign({ token: jwtData }, privateKey, {algorithm: 'RS256',expiresIn: config.get("security:exKeyLife")});
}

exports.verifyJwt = function (jwtData,accessKey,callback) {
    jwt.verify(jwtData, accessKey, { algorithms: ['HS256'] }, function (err, payload) {
        if (err){
            err = debug === 1 ? err : {status:8899};
        }
        callback (err,payload);
    });
}

exports.decodeJwt = function (jwtData,callback) {
    var decoded = jwt.decode(jwtData);
    callback (decoded);
}

exports.randomKey = function (keySize) {
    return getRandomKey(keySize);
}

exports.rsaDecrypt = function(cipher){
    cipher = cipher || "";
    return rsaDecrypt(cipher);
};

exports.aesEncrypt = function (plain,key) {
    plain = plain || "";
    return aesEncrypt(plain,key);
};

function getRandomKey(keySize) {
    var sourceString = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ";
    var resultStr = "";
    for (var i = 0; i < keySize; i++){
        var ran = Math.floor(Math.random()*100)%36;
        resultStr += sourceString.substr(ran,1);
    }
    return resultStr;
}

function aesEncrypt(plainStr,ckey) {
    var key = ckey.substring(0,32),
        iv = ckey.substring(32,48);

    var clearEncoding = 'utf8';
    var cipherEncoding = 'base64';
    var cipherChunks = [];
    var cipher = crypto.createCipheriv('aes-256-cbc', key, iv);
    cipher.setAutoPadding(true);

    cipherChunks.push(cipher.update(plainStr, clearEncoding, cipherEncoding));
    cipherChunks.push(cipher.final(cipherEncoding));
    return cipherChunks.join('');
}

function rsaDecrypt(cipherStr) {
    cipherStr = base64url.toBase64(cipherStr);
    var buf = new Buffer(cipherStr,'base64');
    var start = 0,
        end = maxBit;
    var result = '';
    var bufSize = buf.length;
    while(start < bufSize){
        var tmp  = buf.slice(start, end);
        var decrypt =crypto.privateDecrypt({
            key:privateKey,
            padding:padding
        },tmp);
        var deStr = decrypt.toString('utf-8')
        result += deStr;
        start += maxBit;
        end += maxBit;
    }
    return result;
}

