----------------------------------------------------------------------
--
-- Crypt.elm
-- General purpose string encryption functions.
-- Copyright (c) 2017 Bill St. Clair <billstclair@gmail.com>
-- Some rights reserved.
-- Distributed under the MIT License
-- See LICENSE.txt
--
----------------------------------------------------------------------


module Crypto.String.Crypt
    exposing
        ( DefaultKey
        , decrypt
        , defaultConfig
        , encrypt
        , expandKeyString
        )

{-| Block chaining and string encryption for use with any block cipher.


# Types

@docs DefaultKey


# Functions

@docs expandKeyString, defaultConfig, encrypt, decrypt

-}

import Array exposing (Array)
import Crypto.String.BlockAes as BlockAes
import Crypto.String.Chaining as Chaining
import Crypto.String.Types
    exposing
        ( Config
        , Decryptor
        , Encoding
        , Encryptor
        , Key(..)
        , KeyExpander
        )


{-| TODO
-}
processKey : KeyExpander k -> String -> Array Int
processKey expander string =
    Array.empty


defaultEncoding : Encoding String
defaultEncoding =
    { name = "dummy"
    , parameters = "nothing"
    , encoder = \_ -> ""
    , decoder = \_ -> []
    }


{-| Default key type.
-}
type alias DefaultKey =
    Key BlockAes.Key


{-| Default configuration.
-}
defaultConfig : Config BlockAes.Key Chaining.EcbState String
defaultConfig =
    { encryption = BlockAes.encryption
    , chaining = Chaining.ecbChaining
    , encoding = defaultEncoding
    }


{-| Expand a key preparing it for use with `encrypt` or `decrypt`.
-}
expandKeyString : Config k state p -> String -> Result String (Key k)
expandKeyString config string =
    let
        expander =
            config.encryption.keyExpander
    in
    case expander.expander (processKey expander string) of
        Err msg ->
            Err msg

        Ok key ->
            Ok <| Key key


{-| Encrypt a string. Encode the output as Base64 with 80-character lines.
-}
encrypt : Config k state p -> Key k -> String -> String
encrypt config key string =
    --This will use the blockchain algorithm and block encoder
    string


{-| Decrypt a string created with `encrypt`.
-}
decrypt : Config k state p -> Key k -> String -> String
decrypt config key string =
    --This will use the blockchain algorithm and block encoder
    string
