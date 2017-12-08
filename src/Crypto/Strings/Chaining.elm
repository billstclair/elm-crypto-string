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


module Crypto.Strings.Chaining
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
import Crypto.Strings.Types
    exposing
        ( Block
        , BlockSize
        , Chainer
        , Chaining
        , ChainingInitializer
        , ChainingStateAdjoiner
        , ChainingStateSeparator
        )


{-| The state for ECB chaining
-}
type alias EcbState =
    ()


emptyStateInitializer : ChainingInitializer () randomState
emptyStateInitializer generator _ =
    let
        ( _, state ) =
            generator 0
    in
    ( (), state )


{-| Electronic Codebook chaining
-}
ecbChaining : Chaining key EcbState randomState
ecbChaining =
    { name = "ECB Chaining"
    , initializer = emptyStateInitializer
    , encryptor = ecbChainer
    , decryptor = ecbChainer
    , adjoiner = identityAdjoiner
    , separator = identitySeparator ()
    }


identityAdjoiner : state -> List Int -> List Int
identityAdjoiner _ list =
    list


identitySeparator : state -> BlockSize -> List Int -> ( state, List Int )
identitySeparator state _ blocks =
    ( state, blocks )


ecbChainer : Chainer key EcbState
ecbChainer state encryptor key block =
    ( state, encryptor key block )
