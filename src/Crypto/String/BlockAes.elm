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


module Crypto.String.BlockAes exposing (Key, decryptor, encryptor, keyExpander)

{-| Connect Crypto.AES to Crypto.String.Crypt


# Types

@docs Key


# Functions

@docs keyExpander, encryptor, decryptor

-}

import Array exposing (Array)
import Crypto.AES as AES
import Crypto.String.Types exposing (Block, KeyExpander)


{-| AES key type
-}
type alias Key =
    AES.Keys


{-| AES key expansion.
-}
keyExpander : KeyExpander AES.Keys
keyExpander =
    { keySize = 32
    , expander = AES.expandKey
    }



-- TODO: setKeySize : Int -> KeyExpander AES.Keys -> KeyExpander AES.Keys


{-| AES encryptor.
-}
encryptor : AES.Keys -> Block -> Block
encryptor keys block =
    AES.encrypt keys block


{-| AES decryptor.
-}
decryptor : AES.Keys -> Block -> Block
decryptor keys block =
    AES.decrypt keys block
