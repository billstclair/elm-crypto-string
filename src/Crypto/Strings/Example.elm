----------------------------------------------------------------------
--
-- Example.elm
-- Example of using billstclair/elm-crypto-strings
-- Copyright (c) 2017 Bill St. Clair <billstclair@gmail.com>
-- Some rights reserved.
-- Distributed under the MIT License
-- See LICENSE.txt
--
----------------------------------------------------------------------


module Crypto.Strings.Example exposing
    ( doDecrypt
    , doEncrypt
    , ecbDecrypt
    , ecbEncrypt
    )

import Crypto.Strings exposing (decrypt, encrypt)
import Crypto.Strings.BlockAes as Aes
import Crypto.Strings.Chaining as Chaining
import Crypto.Strings.Crypt as Crypt
import Crypto.Strings.Encoding as Encoding
import Crypto.Strings.Types exposing (..)
import Random exposing (Seed, initialSeed)


{-| In real code, you'd pass in a seed created from a time, not a time.
-}
doEncrypt : Int -> Passphrase -> Plaintext -> Result String ( Ciphertext, Seed )
doEncrypt time passphrase plaintext =
    encrypt (initialSeed time) passphrase plaintext


doDecrypt : Passphrase -> Ciphertext -> Result String Plaintext
doDecrypt passphrase ciphertext =
    decrypt passphrase ciphertext


{-| This tests that ECB chaining and Hex encoding work.
-}
ecbConfig : Config Aes.Key Chaining.EcbState randomState
ecbConfig =
    { encryption = Aes.encryption
    , keyEncoding = Encoding.foldedSha256KeyEncoding
    , chaining = Chaining.ecbChaining
    , encoding = Encoding.hexEncoding
    }


seedGenerator : Int -> RandomGenerator Random.Seed
seedGenerator time =
    Crypt.seedGenerator <| initialSeed time


{-| In real code, you'd pass in a seed created from a time, not a time.
-}
ecbEncrypt : Int -> Passphrase -> Plaintext -> Result String Ciphertext
ecbEncrypt time passphrase plaintext =
    case Crypt.expandKeyString ecbConfig passphrase of
        Err msg ->
            Err msg

        Ok key ->
            let
                ( res, _ ) =
                    Crypt.encrypt ecbConfig (seedGenerator time) key plaintext
            in
            Ok res


ecbDecrypt : Passphrase -> Ciphertext -> Result String Plaintext
ecbDecrypt passphrase ciphertext =
    case Crypt.expandKeyString ecbConfig passphrase of
        Err msg ->
            Err msg

        Ok key ->
            Crypt.decrypt ecbConfig key ciphertext
