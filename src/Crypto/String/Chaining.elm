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
        , ecbChaining
        )

{-| Block chaining for block ciphers.

Algorithm descriptions: <https://en.wikipedia.org/wiki/Block_cipher_mode_of_operation>


# Classes

#docs EcbState


# Functions

@docs ecbChaining

-}

import Array exposing (Array)
import Crypto.String.Types
    exposing
        ( Block
        , Chainer
        , Chaining
        , ChainingStateAdjoiner
        , ChainingStateRemover
        )


{-| The state for ECB chaining
-}
type alias EcbState =
    String


{-| Electronic Codebook state
-}
ecbChaining : Chaining key EcbState
ecbChaining =
    { name = "ECB Chaining"
    , initializer = \_ -> "EcbState"
    , encryptor = ecbChainer
    , decryptor = ecbChainer
    , adjoiner = identityAdjoiner
    , remover = identityRemover "EcbState"
    }


identityAdjoiner : state -> List Block -> List Block
identityAdjoiner _ blocks =
    blocks


identityRemover : state -> List Block -> ( state, List Block )
identityRemover state blocks =
    ( state, blocks )


ecbChainer : Chainer key EcbState
ecbChainer state encryptor key block =
    ( state, encryptor key block )
