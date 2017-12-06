----------------------------------------------------------------------
--
-- Chaining.elm
-- General purpose string encryption functions.
-- Copyright (c) 2017 Bill St. Clair <billstclair@gmail.com>
-- Some rights reserved.
-- Distributed under the MIT License
-- See LICENSE.txt
--
----------------------------------------------------------------------


module Crypto.String.Chaining
    exposing
        ( EcbState
        , ecbChainer
        )

{-| Block chaining for block ciphers.

Algorithm descriptions: <https://en.wikipedia.org/wiki/Block_cipher_mode_of_operation>


# Classes

@docs EcbState


# Functions

@docs ecbChainer

-}

import Array exposing (Array)
import Crypto.String.Types
    exposing
        ( Block
        , Chainer
        )


{-| Electronic Codebook state
-}
type alias EcbState =
    String


{-| Electronic Codebook chainer
-}
ecbChainer : Chainer k EcbState
ecbChainer state encryptor key block =
    ( state, encryptor key block )
