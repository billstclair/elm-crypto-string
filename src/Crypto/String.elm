----------------------------------------------------------------------
--
-- String.elm
-- Top-level default string functions for elm-crypto-string.
-- Copyright (c) 2017 Bill St. Clair <billstclair@gmail.com>
-- Some rights reserved.
-- Distributed under the MIT License
-- See LICENSE.txt
--
----------------------------------------------------------------------


module Crypto.String
    exposing
        ( RandomGenerator
        , decrypt
        , dummyGenerator
        , encrypt
        )

{-| Block chaining and string encryption for use with any block cipher.


# Types

@docs RandomGenerator


# Functions

@docs encrypt, decrypt, dummyGenerator

-}

import Array
import Crypto.String.Crypt as Crypt
import Crypto.String.Types as Types


config =
    Crypt.defaultConfig


{-| A function to generate randomState and an Array of bytes.
-}
type alias RandomGenerator randomState =
    Types.RandomGenerator randomState


{-| A dummy random generator that isn't random
-}
dummyGenerator : RandomGenerator ()
dummyGenerator blockSize =
    ( (), Array.initialize blockSize identity )


{-| Encrypt a string. Encode the output as Base64 with 80-character lines.

See `Crypto.String.Crypt.encrypt` for more options.

This shouldn't ever return an error, but since the key generation can possibly do so, it returns a Result instead of just (randomState, String).

-}
encrypt : RandomGenerator randomState -> String -> String -> Result String ( randomState, String )
encrypt generator passphrase plaintext =
    case Crypt.expandKeyString config passphrase of
        Err msg ->
            Err msg

        Ok key ->
            Ok <| Crypt.encrypt config generator key plaintext


{-| Decrypt a string created with `encrypt`.

See `Crypto.String.Crypt.decrypt` for more options.

This can get errors if the ciphertext you pass in decrypts to something that isn't a UTF-8 string.

-}
decrypt : String -> String -> Result String String
decrypt passphrase ciphertext =
    case Crypt.expandKeyString config passphrase of
        Err msg ->
            Err msg

        Ok key ->
            Crypt.decrypt config key ciphertext
