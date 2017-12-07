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

@docs EcbState


# Functions

@docs ecbChaining

-}

import Array exposing (Array)
import Crypto.String.Types
    exposing
        ( Block
        , BlockSize
        , Chainer
        , Chaining
        , ChainingInitializer
        , ChainingStateAdjoiner
        , ChainingStateRemover
        )


{-| The state for ECB chaining
-}
type alias EcbState =
    ()


emptyStateInitializer : ChainingInitializer randomState ()
emptyStateInitializer generator _ =
    let
        ( state, _ ) =
            generator 0
    in
    ( state, () )


{-| Electronic Codebook chaining
-}
ecbChaining : Chaining key randomState EcbState
ecbChaining =
    { name = "ECB Chaining"
    , initializer = emptyStateInitializer
    , encryptor = ecbChainer
    , decryptor = ecbChainer
    , adjoiner = identityAdjoiner
    , remover = identityRemover ()
    }


identityAdjoiner : state -> List Int -> List Int
identityAdjoiner _ list =
    list


identityRemover : state -> BlockSize -> List Int -> ( state, List Int )
identityRemover state _ blocks =
    ( state, blocks )


ecbChainer : Chainer key EcbState
ecbChainer state encryptor key block =
    ( state, encryptor key block )
