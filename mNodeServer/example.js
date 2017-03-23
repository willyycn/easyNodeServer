/**
 * Created by willyy on 2017/2/25.
 */
var faker = require('faker');
var libs = process.cwd() + '/libs/';
var log = require(libs + 'log')(module);
var db = require(libs + 'db/mongoose');
var config = require(libs + 'config');
var User = require(libs + 'model/user');
User.remove({}, function(err) {
    var user = new User({
        username: config.get("user:username"),
        password: config.get("user:password"),
        authcode: config.get('user:authcode')
    });

    user.save(function(err, user) {
        if(!err) {
            log.info("New user - %s:%s:%s", user.username, user.password, user.authcode);
        }else {
            return log.error(err);
        }
    });

});

setTimeout(function() {
    db.disconnect();
}, 1000);