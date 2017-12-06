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
        ( decrypt
        , defaultConfig
        , encrypt
        , expandKeyString
        )

{-| Block chaining and string encryption for use with any block cipher.


# High-level functions

@doc expandKeyString, defaultConfig, encrypt, decrypt

-}

import Array exposing (Array)
import Crypto.String.Types
    exposing
        ( Config
        , Decryptor
        , Encryptor
        , Key(..)
        , KeyExpander
        )


{-| TODO
-}
processKey : KeyExpander k -> String -> Array Int
processKey expander string =
    Array.empty


{-| Expand a key preparing it for use with `encrypt` or `decrypt`.
-}
expandKeyString : KeyExpander k -> String -> Result String (Key k)
expandKeyString expander string =
    case expander.expander (processKey expander string) of
        Err msg ->
            Err msg

        Ok key ->
            Ok <| Key key


{-| Default configuration.
-}
defaultConfig : Config
defaultConfig =
    "Default"


{-| Encrypt a string. Encode the output as Base64 with 80-character lines.
-}
encrypt : Config -> Encryptor k -> Key k -> String -> String
encrypt config encryptor key string =
    --This will use the blockchain algorithm and block encoder
    string


{-| Decrypt a string created with `encrypt`.
-}
decrypt : Config -> Decryptor k -> Key k -> String -> String
decrypt config decryptor key string =
    --This will use the blockchain algorithm and block encoder
    string
