/**
 * Created by willyy on 2017/3/1.
 */
var express = require('express');
var router = express.Router();

var xss = require('xss');
var libs = process.cwd() + '/libs/',
    mCrypto = require(libs + 'tools/mCrypto');
var log = require(libs + 'log')(module);
var mongo = require(libs + 'db/mongoose'),
    redisClient = require(libs + 'db/redisClient');
var User = require(libs + 'model/user');

router.use(function (req, res, next) {
    log.info('request from : '+ req.baseUrl + ' Time: '+ Date.now());
    if (req.originalUrl === "/api/" && (req.method === 'POST' || req.method === 'GET'))
    {
        next();
    }
    else if (req.originalUrl === "/api/getToken" && req.method === 'POST')
    {
        next();
    }
    else if (req.originalUrl === "/api/regainToken" && req.method === 'POST')
    {
        next();
    }
    else{
        var jwt = req.headers.jwt;
        if (jwt === "")
        {
            res.json({
                status: "jwt Error"
            });
        }
        else {
            var userid = "";
            mCrypto.decodeJwt(jwt,function (payload) {
                userid = payload.iss;
            })

            redisClient.getRedis("userid:"+userid,function (err,reply) {
                if (err){
                    res.json({
                        status:err
                    });
                }
                else if (reply){
                    var accessKey = reply;
                    mCrypto.verifyJwt(jwt,accessKey,function (err, payload) {
                        req.userid = userid;
                        req = fixss(req);
                        if (!err){
                            if (userid === payload.iss)
                            {
                                next();
                            }
                            else{
                                res.json({
                                    status:8899
                                });
                            }
                        }
                        else{
                            res.json({
                                status:8899
                            });
                        }
                    });
                }
                else {
                    res.json({
                        status:4000
                    })
                }
            });
            /*
            使用redis


            User.findOne({_id:userid},function (err,user) {
                if (err){
                    res.json({
                        status:err
                    });
                }
                else if (user === null){
                    res.json({
                        status:4400
                    });
                }
                else{
                    var accessKey = user.checkAccessKeyExpire();
                    if (accessKey){
                        mCrypto.verifyJwt(jwt,accessKey,function (err, payload) {
                            req.userid = userid;
                            req = fixss(req);
                            if (!err){
                                if (userid === payload.iss)
                                {
                                    next();
                                }
                                else{
                                    res.json({
                                        status:8899
                                    });
                                }
                            }
                            else{
                                res.json({
                                    status:8899
                                });
                            }
                        });
                    }
                    else{
                        res.json({
                            status:4000
                        })
                    }
                }
            });
             */
        }
    }
});

router.get('/', function(req, res){
    res.json({
        hello:"hi developer! api services is running!",
    })
});

router.post('/', function(req, res){
    res.json({
        hello:"hi api services is running!",
        method: "post",
        body:req.body
    })
});

router.get('/sayHello', function (req,res) {
    res.json({
        query:req.query,
        userid:req.userid
    });
});

router.post('/sayHello',function (req,res) {
    res.json({
        body:req.body
    })
})

router.post('/regainToken',function (req,res) {
    req = fixss(req);
    var str = req.body.info;
    str = mCrypto.rsaDecrypt(str);
    var json = JSON.parse(str);

    var rkey = json.rk,
        userid = json.userid,
        accessKey = json.accessKey;

    User.findOne({ _id: userid},function (err,user) {
        if (err){
            res.json({
                status:err
            });
        }
        if (accessKey != "" && user && user.checkAccessKey(accessKey)){
            var newAk = mCrypto.randomKey(48);
            user.setAccessKey(newAk);
            user.setAuthCode("");
            user.save();

            redisClient.setRedis("userid:"+userid,newAk);

            var info = {};
            info.userid = userid;
            info.accessKey = newAk;
            var infoStr = JSON.stringify(info);
            var enStr = mCrypto.aesEncrypt(infoStr,rkey);
            var jwt = mCrypto.getJwtDefault(enStr);
            res.json({
                token:jwt
            });
        }
        else {
            res.json({
                status:4001
            });
        }
    });
})

router.post('/getToken',function (req, res) {
    req = fixss(req);
    var str = req.body.info;
    str = mCrypto.rsaDecrypt(str);
    var json = JSON.parse(str);

    var rkey = json.rk,
        username = json.username,
        password = json.password,
        authcode = json.authcode;

    User.findOne({ username: username},function (err,user) {
        if (err){
            res.json({
                status:err
            });
        }
        if (authcode != "" && user && user.checkAuthCode(authcode)){
            var userid = user.getUserid();
            var accessKey = mCrypto.randomKey(48);

            user.setAccessKey(accessKey);
            user.setAuthCode("");
            user.save();

            redisClient.setRedis("userid:"+userid,accessKey);

            var info = {};
            info.userid = userid;
            info.accessKey = accessKey;
            var infoStr = JSON.stringify(info);
            var enStr = mCrypto.aesEncrypt(infoStr,rkey);
            var jwt = mCrypto.getJwtDefault(enStr);
            res.json({
                token:jwt
            });
        }
        else if (password != "" && user && user.checkPassword(password))
        {
            var userid = user.getUserid();
            var accessKey = mCrypto.randomKey(48);

            user.setAccessKey(accessKey);
            user.save();

            var info = {};
            info.userid = userid;
            info.accessKey = accessKey;
            var infoStr = JSON.stringify(info);
            var enStr = mCrypto.aesEncrypt(infoStr,rkey);
            var jwt = mCrypto.getJwtDefault(enStr);
            res.json({
                token:jwt
            });
        }
        else {
            res.json({
                status:4001
            });
        }
    });
});

var mime = function (req) {
    var str = req.headers['content-type'] || '';
    return str.split(';')[0];
}

var fixss = function (req) {
    var query = req.query;
    for(var property in query){
        if(property!==__proto__){
            query[property] = xss(query[property]);
        }
    }
    var body = req.body;
    for(var property in body){
        if(property!==__proto__){
            body[property] = xss(body[property]);
        }
    }
    return req;
}

module.exports = router;