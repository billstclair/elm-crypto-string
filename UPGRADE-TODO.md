# Things to do to upgrade to 0.19.

* Make billstclair/elm-word and billstclair/elm-crypto from ktonon's versions. He appears to be gone. No commits since June. No work on elm projects since 2017.

* Accept ccapndave's [pull request](https://github.com/billstclair/elm-crypto-string/pull/6). He's done most of the conversion work.

* Replace `src/Word` and `src/Crypto` with `billstclair/elm-word` and `billstclair/elm-crypto` dependencies, as before.

* Make the tests work.

# Compatibility

The package as is works, but isn't compatible with anything. Build `Encoding` and `Chaining` functions to be compatible with the Node.js [Crypto package](https://nodejs.org/api/crypto.html).

ccapndave's example:

```
var crypto = require('crypto');

var AESCrypt = {};

AESCrypt.decrypt = function(cryptkey, iv, encryptdata) {
    encryptdata = new Buffer(encryptdata, 'base64').toString('binary');

    var decipher = crypto.createDecipheriv('aes-256-cbc', cryptkey, iv),
        decoded  = decipher.update(encryptdata);

    decoded += decipher.final();
    return decoded;
}

AESCrypt.encrypt = function(cryptkey, iv, cleardata) {
    var encipher = crypto.createCipheriv('aes-256-cbc', cryptkey, iv),
        encryptdata  = encipher.update(cleardata);

    encryptdata += encipher.final();
    encode_encryptdata = new Buffer(encryptdata, 'binary').toString('base64');
    return encode_encryptdata;
}

var cryptkey   = crypto.createHash('sha256').update('Nixnogen').digest(),
    iv         = 'a2xhcgAAAAAAAAAA',
    buf        = "Here is some data for the encrypt", // 32 chars
    enc        = AESCrypt.encrypt(cryptkey, iv, buf);
var dec        = AESCrypt.decrypt(cryptkey, iv, enc);

console.warn("encrypt length: ", enc.length);
console.warn("encrypt in Base64:", enc);
console.warn("decrypt all: " + dec);
```
