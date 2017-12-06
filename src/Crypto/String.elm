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


module Crypto.String exposing (Key, decrypt, encrypt, expandKeyString)

{-| Block chaining and string encryption for use with any block cipher.


# Types

@doc Key


# Functions

@doc expandKeyString, encrypt, decrypt

-}

import Crypto.String.BlockAes as Aes
import Crypto.String.Crypt as Crypt
import Crypto.String.Types as Types


{-| Key
-}
type alias Key =
    Types.Key Aes.Key


{-| Expand a key preparing it for use with `encrypt` or `decrypt`.
-}
expandKeyString : String -> Result String Key
expandKeyString string =
    Crypt.expandKeyString Aes.keyExpander string


{-| Encrypt a string. Encode the output as Base64 with 80-character lines.

Use `Crypto.String.Crypt` for more options.

-}
encrypt : Key -> String -> String
encrypt key =
    Crypt.encrypt Crypt.defaultConfig Aes.encryptor key


{-| Decrypt a string created with `encrypt`.

Use `Crypto.String.Crypt` for more options.

-}
decrypt : Key -> String -> String
decrypt key =
    Crypt.decrypt Crypt.defaultConfig Aes.decryptor key
