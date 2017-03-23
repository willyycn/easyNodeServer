# easyNodeServer


非常容易使用的NodeServer, 同时兼顾安全性和易用性, 包括了iOS和Android客户端

Server端使用:
安装mongodb, 安装redis, 命令行打开mNodeServer根目录, 运行"npm install", 运行"node example.js". example.js向mongodb导入了示例用户.
启动server. 其他配置请看config.json

iOS端使用:
修改GlobalTools.m中的ServerUrl为Server端地址.

Android端使用:
修改GlobalUtil.java中的ServerUrl为Server端地址.

安全设计:
使用RSA交换临时AES秘钥, 使用AES加密JWT签名秘钥, 使用JWT作为token凭证.

易用设计:
服务端除获取和重新获取token的接口外, 其他接口都使用中间件进行操作, 下层业务接口不用关心用户操作, 只用关心业务逻辑.
客户端的加密层负责所有token相关的加解密操作, 网络服务层封装了相关数据, 下层业务接口不用关心用户管理操作, 只用关心业务逻辑.

Very easy used NodeServer  Also consider security.  include iOS and Android Client

Sever use:
Install mongodb, install redis, open the mNodeServer root directory using commandline , run "npm install", run "node example.js". Example.js import example user account to mongodb.
Start the server. Other configuration check config.json

iOS client:
modify GlobalTools.m, change ServerUrl to server address.

Android client:
modify 修改GlobalUtil.java, change ServerUrl to server address.

security issue:
use RSA exchange temporary AES key, use AES encrypt JWT signature key, use JWT as user token.

