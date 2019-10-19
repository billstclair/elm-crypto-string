[![elm-package](https://img.shields.io/badge/elm-3.0.1-blue.svg)](http://package.elm-lang.org/packages/billstclair/elm-crypto-string/latest)
[![Build Status](https://travis-ci.org/billstclair/elm-crypto-string.svg?branch=master)](https://travis-ci.org/billstclair/elm-crypto-string)

`billstclair/elm-crypto-string` does block chaining and string conversion for encrypting strings. It is designed to plug in to any low-level, block-based encryption module that can be made to follow its protocol. It ships knowing how to talk to [`billstclair/elm-crypto-aes`](http://package.elm-lang.org/packages/billstclair/elm-crypto-aes/latest), a pure Elm rendering of the Advanced Encryption Standard.

The application in the `example` directory in the distribution is live at https://lisplog.org/elm-crypto-string

# Default Configuration

The default encryption algorithm uses a standard Elm random number generator, for which you need to supply a seed integer, and, if you plan to encrypt more than once, save the returned seed for use the next time around.

It uses Counter [Block Chaining](https://en.wikipedia.org/wiki/Block_cipher_mode_of_operation) (CTR) and [Advanced Encryption Standard](https://en.wikipedia.org/wiki/Advanced_Encryption_Standard) (AES) encryption. It hashes the keystring you give it to a 32-byte (256 bit) AES key.

It encodes cipherstrings in Base64 with 60-character lines.

# Example

    module Crypto.Strings.Example exposing (doDecrypt, doEncrypt)
    
    import Crypto.Strings exposing (decrypt, encrypt)
    import Crypto.Types exposing (Passphrase, Plaintext, Ciphertext)
    import Random exposing (Seed, initialSeed)
    
    {-| In real code, you'd pass in a seed created from a time, not a time.
    -}
    doEncrypt : Int -> Passphrase -> Plaintext -> Result String ( Ciphertext, Seed )
    doEncrypt time passphrase plaintext =
        encrypt (initialSeed time) passphrase plaintext
    
    doDecrypt : Passphrase -> Ciphertext -> Result String Plaintext
    doDecrypt passphrase ciphertext =
        decrypt passphrase ciphertext

This example is part of the distribution. You can run it as follows:

    $ git clone https://github.com/billstclair/elm-crypto-string.git
    $ cd elm-crypto-string
    $ elm repl
    ---- elm-repl 0.18.0 -----------------------------------------------------------
     :help for help, :exit to exit, more at <https://github.com/elm-lang/elm-repl>
    --------------------------------------------------------------------------------
    > import Crypto.Strings.Example exposing (..)
    > doEncrypt 0 "foo" "bar"
    Ok ("rYcxCPIdEyvT4C/AJlb4hzZUJr/izK+q/C0LPbqKSfI=",Seed { state = State 2124954851 1554910725, next = <function>, split = <function>, range = <function> })
        : Result.Result
            String ( Crypto.Strings.Types.Ciphertext, Random.Seed )
    > doDecrypt "foo" "rYcxCPIdEyvT4C/AJlb4hzZUJr/izK+q/C0LPbqKSfI="
    Ok "bar" : Result.Result String Crypto.Strings.Types.Plaintext
    > doEncrypt 1 "foo" "bar"
    Ok ("UaC72fT1tLW2Ur+DRI1Sv+AiAGSnNT06NGzHS80tmz0=",Seed { state = State 2102426139 1554910725, next = <function>, split = <function>, range = <function> })
        : Result.Result
            String ( Crypto.Strings.Types.Ciphertext, Random.Seed )
    > doDecrypt "foo" "UaC72fT1tLW2Ur+DRI1Sv+AiAGSnNT06NGzHS80tmz0="
    Ok "bar" : Result.Result String Crypto.Strings.Types.Plaintext

# Advanced Usage

Currently, you can also configure encryption using Electronic Codebook block chaining, which is not recommended for real applications, and you can encode the ciphertext as Hex instead of Base64. `Crypto.Strings.Example` contains a simple example of this. See `ecbConfig`. Once you grok the types, you can pretty easily create your own encoders and block chaining mechanisms, and you can plug in other block ciphers.

Here's an example of running the ECB example code. Note that the time input makes no difference here. ECB uses no chaining and no initialization vector.

    > ecbEncrypt 0 "foo" "bar"
    Ok "64610C0C571DB560F005C8B0BC8283DB"
        : Result.Result String String
    > ecbEncrypt 1 "foo" "bar"
    Ok "64610C0C571DB560F005C8B0BC8283DB"
        : Result.Result String String
    > ecbDecrypt "foo" "64610C0C571DB560F005C8B0BC8283DB"
    Ok "bar" : Result.Result String String

