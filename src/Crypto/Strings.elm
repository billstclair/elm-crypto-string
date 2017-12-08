----------------------------------------------------------------------
--
-- Strings.elm
-- Top-level default string functions for elm-crypto-string.
-- Copyright (c) 2017 Bill St. Clair <billstclair@gmail.com>
-- Some rights reserved.
-- Distributed under the MIT License
-- See LICENSE.txt
--
----------------------------------------------------------------------


module Crypto.Strings
    exposing
        ( decrypt
        , encrypt
        , justEncrypt
        )

{-| Block chaining and string encryption for use with any block cipher.


# Functions

@docs encrypt, justEncrypt, decrypt

-}

import Array
import Crypto.Strings.BlockAes as Aes
import Crypto.Strings.Chaining as Chaining
import Crypto.Strings.Crypt as Crypt
import Crypto.Strings.Encoding as Encoding
import Crypto.Strings.Types as Types
import Random exposing (Seed)


{-| This matches Crypt.defaultConfig
-}
config : Types.Config Aes.Key Chaining.CtrState randomState
config =
    { encryption = Aes.encryption
    , keyEncoding = Encoding.foldedSha256KeyEncoding
    , chaining = Chaining.ctrChaining
    , encoding = Encoding.base64Encoding 60
    }


{-| Encrypt a string. Encode the output as Base64 with 80-character lines.

The `Seed` parameter is a `Random.Seed`, as created by `Random.initialSeed`

See `Crypto.Strings.Crypt.encrypt` for more options.

This shouldn't ever return an error, but since the key generation can possibly do so, it returns a `Result` instead of just `(Ciphertext, randomState)`.

-}
encrypt : Seed -> Types.Passphrase -> Types.Plaintext -> Result String ( Types.Ciphertext, Seed )
encrypt seed passphrase plaintext =
    case Crypt.expandKeyString config passphrase of
        Err msg ->
            Err msg

        Ok key ->
            Ok <| Crypt.encrypt config (Crypt.seedGenerator seed) key plaintext


{-| Testing function. Just returns the result with no random generator update.
-}
justEncrypt : Seed -> Types.Passphrase -> Types.Plaintext -> Types.Ciphertext
justEncrypt seed passphrase plaintext =
    case Crypt.expandKeyString config passphrase of
        Err msg ->
            ""

        Ok key ->
            Crypt.encrypt config (Crypt.seedGenerator seed) key plaintext
                |> Tuple.first


{-| Decrypt a string created with `encrypt`.

See `Crypto.Strings.Crypt.decrypt` for more options.

This can get errors if the ciphertext you pass in decrypts to something that isn't a UTF-8 string.

-}
decrypt : Types.Passphrase -> Types.Ciphertext -> Result String Types.Plaintext
decrypt passphrase ciphertext =
    case Crypt.expandKeyString config passphrase of
        Err msg ->
            Err msg

        Ok key ->
            Crypt.decrypt config key ciphertext
