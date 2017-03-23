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
    privateKey = fs.readFileSync(certs+config.get("rsa:private"),'utf8'), //jwt private key
    publicKey = fs.readFileSync(certs+config.get("rsa:public"),'utf8'); //jwt public key
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

exports.rsaEncrypt = function (plain) {
    plain = plain || "";
    return rsaEncrypt(plain);
};

exports.rsaDecrypt = function(cipher){
    cipher = cipher || "";
    return rsaDecrypt(cipher);
};

exports.aesEncrypt = function (plain,key) {
    plain = plain || "";
    return aesEncrypt(plain,key);
};

exports.aesDecrypt = function(cipher,key){
    cipher = cipher || "";
    return aesDecrypt(cipher,key);
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

// function aesEncrypt(plainStr,ckey) {
//     ckey = crypto.createHash('sha384').update(ckey).digest('hex');
//     var key = ckey.substring(0,64),
//         iv = ckey.substring(64,96);
//
//     var keyBuf = new Buffer(key,'hex'),
//         ivBuf = new Buffer(iv,'hex');
//
//     var clearEncoding = 'utf8';
//     var cipherEncoding = 'ascii';
//     var cipher = crypto.createCipheriv('aes-256-cbc', keyBuf, ivBuf);
//     cipher.setAutoPadding(true);
//     var buff = new Buffer(plainStr, clearEncoding);
//     var re = Buffer.concat([cipher.update(buff), cipher.final()]);
//     return new Buffer(re).toString(cipherEncoding);
// }
function customPadding(str) {
    str = new Buffer(str,"utf8").toString("hex");
    var bitLength = str.length*8;

    if(bitLength < 256) {
        for(i=bitLength;i<256;i+=8) {
            str += 0x0;
        }
    } else if(bitLength > 256) {
        while((str.length*8)%256 != 0) {
            str+= 0x0;
        }
    }
    return new Buffer(str,"hex").toString("utf8");
}

function aesEncrypt(plainStr,ckey) {
    // ckey = crypto.createHash('sha384').update(ckey).digest('hex');
    // var key = ckey.substring(0,64),
    //     iv = ckey.substring(64,96);
    //
    // var keyBuf = new Buffer(key,'hex'),
    //     ivBuf = new Buffer(iv,'hex');

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

function aesDecrypt(cipherStr,ckey) {
    var key = ckey.substring(0,32),
        iv = ckey.substring(32,48);

    if (!cipherStr) {
        return "";
    }
    iv = iv || "";
    var clearEncoding = 'utf8';
    var cipherEncoding = 'base64';
    var cipherChunks = [];
    var decipher = crypto.createDecipheriv('aes-256-cbc', key, iv);
    decipher.setAutoPadding(false);
    cipherChunks.push(decipher.update(cipherStr, cipherEncoding, clearEncoding));
    cipherChunks.push(decipher.final(clearEncoding));
    return cipherChunks.join('');
}

function rsaEncrypt(plainStr) {
    var buf = new Buffer(plainStr,'utf-8');
    var start = 0,
        end = maxBit;
    var result = '';
    var bufSize = buf.length;

    while(start < bufSize){
        var tmp  = buf.slice(start, end);

        var encrypt =crypto.publicEncrypt({
            key:publicKey,
            padding:padding
        },tmp);
        var enStr = encrypt.toString('base64');

        result += enStr;
        start += realBit;
        end += realBit;
    }
    result = base64url.fromBase64(result);
    return result;
}

function rsaDecrypt(cipherStr) {
    cipherStr = base64url.toBase64(cipherStr);
    var buf = new Buffer(cipherStr,'base64');
    var start = 0,
        end = maxBit;
    var result = '';
    var bufSize = buf.length;
    while(start < bufSize){
        var tmp  = buf.slice(start, end);    //请注意slice函数的用法
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

