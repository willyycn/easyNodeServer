/**
 * Created by willyy on 2017/3/23.
 */
var redis = require('redis'),
    client = redis.createClient(6379,'127.0.0.1',{})
var libs = process.cwd() + '/libs/',
    log = require(libs + 'log')(module),
    config = require(libs + 'config');
client.on("error", function (err) {
    log.info("redis Error " + err);
});

exports.setRedis = function (stringKey,stringValue) {
    client.set(stringKey,stringValue);
    client.expire(stringKey,config.get("security:tokenLife"))
};
exports.hsetRedis = function (hashKey,stringValue) {
    client.hset(hashKey,stringValue);
};
exports.getRedis = function (stringKey,callBack) {
    client.get(stringKey, function (err, reply) {
        callBack(err,reply);
    });
};
exports.hgetRedis = function (hashKey,callBack) {
    client.hget(hashKey, function (err, reply) {
        callBack(err,reply);
    });
};
exports.quitRedis = function () {
    client.quit();
};