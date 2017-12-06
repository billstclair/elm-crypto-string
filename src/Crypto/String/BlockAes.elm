----------------------------------------------------------------------
--
-- BlockAes.elm
-- Connect Crypto.AES to Crypto.String.Crypt
-- Copyright (c) 2017 Bill St. Clair <billstclair@gmail.com>
-- Some rights reserved.
-- Distributed under the MIT License
-- See LICENSE.txt
--
----------------------------------------------------------------------


module Crypto.String.BlockAes exposing (Key, encryption)

{-| Connect Crypto.AES to Crypto.String.Crypt


# Types

@docs Key


# Functions

@docs encryption

-}

import Array exposing (Array)
import Crypto.AES as AES
import Crypto.String.Types exposing (Block, Encryption, KeyExpander)


{-| AES key type
-}
type alias Key =
    AES.Keys


{-| AES encryption.
-}
encryption : Encryption AES.Keys
encryption =
    { name = "AES"
    , blockSize = 16
    , keyExpander = keyExpander
    , encryptor = encrypt
    , decryptor = decrypt
    }


keyExpander : KeyExpander AES.Keys
keyExpander =
    { keySize = 32
    , expander = AES.expandKey
    }



-- TODO: setKeySize : Int -> KeyExpander AES.Keys -> KeyExpander AES.Keys


encrypt : AES.Keys -> Block -> Block
encrypt keys block =
    AES.encrypt keys block


decrypt : AES.Keys -> Block -> Block
decrypt keys block =
    AES.decrypt keys block
