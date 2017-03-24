/**
 * Created by willyy on 2017/2/25.
 */
var libs = process.cwd() + '/libs/',
    config = require(libs + 'config');
var mongoose = require('mongoose'),
    crypto = require('crypto'),
    Schema = mongoose.Schema,
    User = new Schema({
        username: {
            type: String,
            unique: true,
            required: true
        },
        authcode: {
            type: String,
            required: false,
            default: ""
        },
        hashedPassword: {
            type: String,
            required: true
        },
        salt: {
            type: String,
            required: true
        },
        accessKey:{
            type: String,
            required: false
        },
        accessKeyExpireDate:{
            type: String,
            required: false
        },
        created: {
            type: Date,
            default: Date.now()
        },
        update: {
            type: String,
            default: new Date(Date.now()).getTime()
        }
    });
User.methods.encryptPassword = function(password) {
    return crypto.createHmac('sha256', this.salt).update(password).digest('hex');
};

User.virtual('userId')
    .get(function () {
        return this.id;
    });

User.virtual('password')
    .set(function(password) {
        this._plainPassword = password;
        this.salt = crypto.randomBytes(32).toString('hex');
        this.hashedPassword = this.encryptPassword(password);
    })
    .get(function() { return this._plainPassword; });

User.methods.checkPassword = function(password) {
    return this.encryptPassword(password) === this.hashedPassword;
};

User.methods.checkAuthCode = function (authcode) {
    if (this.authcode === "")
    {
        return false;
    }
    return this.authcode === authcode;
};

User.methods.setAuthCode = function (authcode) {
    this.authcode = authcode;
}

User.methods.getUserid = function () {
    return this._id.toString();
};

User.methods.setAccessKey = function (key) {
    this.accessKey = key;
    this.update = new Date(Date.now()).getTime();
    this.accessKeyExpireDate = new Date(Date.now()).getTime() + config.get("security:tokenLife") *1000;
};

User.methods.checkAccessKey = function (accessKey) {
    if (this.accessKey === "")
    {
        return false;
    }
    return this.accessKey === accessKey;
};

module.exports = mongoose.model('User', User);