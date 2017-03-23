/**
 * Created by willyy on 2017/1/18.
 */
var express = require('express');
var router = express.Router();


router.get('/',function (req,res) {
    res.render('index',{title:"GDYY App"})
});

module.exports = router;