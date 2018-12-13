----------------------------------------------------------------------
--
-- BlockAes.elm
-- Connect Crypto.AES to Crypto.Strings.Crypt
-- Copyright (c) 2017 Bill St. Clair <billstclair@gmail.com>
-- Some rights reserved.
-- Distributed under the MIT License
-- See LICENSE.txt
--
----------------------------------------------------------------------


module Crypto.Strings.BlockAes exposing
    ( Key, KeySize(..)
    , encryption, setKeySize
    )

{-| Connect Crypto.AES to Crypto.Strings.Crypt


# Types

@docs Key, KeySize


# Functions

@docs encryption, setKeySize

-}

import Array exposing (Array)
import Crypto.AES as AES
import Crypto.Strings.Types exposing (Block, Encryption, KeyExpander)


{-| AES key type
-}
type alias Key =
    AES.Keys


{-| AES encryption. 32-byte key size. Use `setKeySize` to change it.
-}
encryption : Encryption Key
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


{-| An AES key size. 16, 24, or 32 bytes.
-}
type KeySize
    = KeySize16
    | KeySize24
    | KeySize32


keySizeToInt : KeySize -> Int
keySizeToInt keySize =
    case keySize of
        KeySize16 ->
            16

        KeySize24 ->
            24

        KeySize32 ->
            32


{-| Change the key size of the keyExpander inside an AES Encryption spec.
-}
setKeySize : KeySize -> Encryption Key -> Encryption Key
setKeySize keySize encryption_ =
    let
        expander =
            encryption_.keyExpander
    in
    { encryption_
        | keyExpander = { expander | keySize = keySizeToInt keySize }
    }


encrypt : AES.Keys -> Block -> Block
encrypt keys block =
    AES.encrypt keys block


decrypt : AES.Keys -> Block -> Block
decrypt keys block =
    AES.decrypt keys block
