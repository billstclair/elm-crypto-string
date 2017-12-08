[![elm-package](https://img.shields.io/badge/elm-1.0.0-blue.svg)](http://package.elm-lang.org/packages/billstclair/elm-crypto-strings/latest)
[![Build Status](https://travis-ci.org/billstclair/elm-crypto-strings.svg?branch=master)](https://travis-ci.org/billstclair/elm-crypto-strings)

`billstclair/elm-crypto-strings` does block chaining and string conversion for encrypting strings. It is designed to plug in to any low-level, block-based encryption module that can be made to follow its protocol. It ships knowing how to talk to [`billstclair/elm-crypto-aes`](http://package.elm-lang.org/packages/billstclair/elm-crypto-aes/latest), a pure Elm rendering of the Advanced Encryption Standard.

# Default Configuration

The default encryption algorithm uses a standard Elm random number generator, for which you need to supply a seed integer, and, if you plan to encrypt more than once, save the returned seed for use the next time around.

It uses [Counter Block Chaining] (https://en.wikipedia.org/wiki/Block_cipher_mode_of_operation#Counter_(CTR)) (CTR) and [Advanced Encryption Standard](https://en.wikipedia.org/wiki/Advanced_Encryption_Standard) (AES) encryption. It hashes the keystring you give it to a 32-byte (256 bit) AES key.

It encodes cipherstrings in Base64 with 60-character lines.

# Example

    module Crypto.Strings.Example exposing (doDecrypt, doEncrypt)
    
    import Crypto.Strings exposing (decrypt, encrypt)
    import Random exposing (Seed, initialSeed)
    
    {-| In a real app,
    you would get the time and initialize this in your update function.
    And you would save the `Seed` resulting from a call to `doEncrypt`
    for the next one.
    -}
    time : Int
    time =
        0
    
    {-| In a real app, this would be user input
    -}
    passphrase : String
    passphrase =
        "My mother's maiden name."
    
    doEncrypt : Int -> String -> Result String ( String, Seed )
    doEncrypt time plaintext =
        encrypt (initialSeed time) passphrase plaintext
    
    doDecrypt : String -> Result String String
    doDecrypt ciphertext =
        decrypt passphrase ciphertext

This example is part of the distribution. You can run it as follows:

    $ git clone https://github.com/billstclair/elm-crypto-strings.git
    $ cd elm-crypt-strings
    $ elm repl
    ---- elm-repl 0.18.0 -----------------------------------------------------------
     :help for help, :exit to exit, more at <https://github.com/elm-lang/elm-repl>
    --------------------------------------------------------------------------------
    > import Crypto.Strings.Example exposing (..)
    > doEncrypt 0 "foo"
    Ok ("rYcxCPIdEyvT4C/AJlb4h9gqRRMIVFHaBA7YCkwSZBk=",Seed { state = State 2124954851 1554910725, next = <function>, split = <function>, range = <function> })
        : Result.Result String ( String, Random.Seed )
    > doDecrypt "rYcxCPIdEyvT4C/AJlb4h9gqRRMIVFHaBA7YCkwSZBk="
    Ok "foo" : Result.Result String String
    > doEncrypt 1 "foo"
    Ok ("UaC72fT1tLW2Ur+DRI1Sv4/qaUdv0Xz6tcY/2raM5C4=",Seed { state = State 2102426139 1554910725, next = <function>, split = <function>, range = <function> })
        : Result.Result String ( String, Random.Seed )
    > doDecrypt "UaC72fT1tLW2Ur+DRI1Sv4/qaUdv0Xz6tcY/2raM5C4="
    Ok "foo" : Result.Result String String

# Advanced Usage

Currently, ther
