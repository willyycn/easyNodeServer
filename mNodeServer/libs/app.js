var express = require('express');
var path = require('path');
var favicon = require('serve-favicon');
var cookieParser = require('cookie-parser');
var csrf = require('csurf')
var bodyParser = require('body-parser');
var methodOverride = require('method-override');

var libs = process.cwd() + '/libs/';
var config = require(libs + 'config');
var log = require(libs + 'log')(module);

// ==================api===================
var libController = libs + 'controller/';
//set api controller
var api = require(libController + 'api');
// ==================web===================
var webController = process.cwd() + '/site/controller/';
var webView = process.cwd() + '/site/views/';
var webPublic = process.cwd() + '/site/public/';
//set website controller
var index = require(webController + 'index');

var app = express();

app.set('views', webView);
app.set('view engine', 'ejs');
app.use(express.static(webPublic));

app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: false }));
app.use(cookieParser());
app.use(methodOverride());

app.use('/', index);
app.use('/api',api);

// catch 404 and forward to error handler
app.use(function(req, res, next) {
  var err = new Error('Not Found');
  err.status = 404;
  next(err);
});

app.set('env',config.get('debug'));
// error handler
app.use(function(err, req, res, next) {
  // set locals, only providing error in development
  res.locals.message = err.message;
  res.locals.error = req.app.get('env') === 1 ? err : {};
  // render the error page
  res.status(err.status || 500);
  res.render('error');
    // res.render('error',{error:err,message:err.message});
});

module.exports = app;
