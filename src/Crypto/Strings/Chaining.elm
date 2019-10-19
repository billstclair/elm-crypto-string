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


module Crypto.Strings.Chaining exposing
    ( EcbState, CtrState
    , ecbChaining, ctrChaining
    )

{-| Block chaining for block ciphers.

Algorithm descriptions: <https://en.wikipedia.org/wiki/Block_cipher_mode_of_operation>


# Classes

@docs EcbState, CtrState


# Functions

@docs ecbChaining, ctrChaining

-}

import Array exposing (Array)
import Array.Extra as AE
import Bitwise
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
        ( _, randomState ) =
            generator 0
    in
    ( (), randomState )


{-| Electronic Codebook chaining
-}
ecbChaining : Chaining key EcbState randomState
ecbChaining =
    { name = "Electronic Cookbook Chaining"
    , initializer = emptyStateInitializer
    , encryptor = ecbEncryptor
    , decryptor = ecbDecryptor
    , adjoiner = identityAdjoiner
    , separator = identitySeparator ()
    }


identityAdjoiner : state -> List Int -> List Int
identityAdjoiner _ list =
    list


identitySeparator : state -> BlockSize -> List Int -> ( List Int, state )
identitySeparator state _ blocks =
    ( blocks, state )


ecbEncryptor : Chainer key EcbState
ecbEncryptor state ( encryptor, _ ) key block =
    ( encryptor key block, state )


ecbDecryptor : Chainer key EcbState
ecbDecryptor state ( _, decryptor ) key block =
    ( decryptor key block, state )


{-| The state for Counter chaining
-}
type alias CtrState =
    { nonce : Block
    , counter : Block
    }


ctrInitializer : ChainingInitializer CtrState randomState
ctrInitializer generator blockSize =
    let
        ( nonce, randomState ) =
            generator blockSize
    in
    ( { nonce = nonce
      , counter = Array.repeat blockSize 0
      }
    , randomState
    )


ctrChainer : Chainer key CtrState
ctrChainer state ( encryptor, _ ) key block =
    let
        counter =
            state.counter

        input =
            AE.map2 Bitwise.xor state.nonce counter

        output =
            encryptor key input

        ciphertext =
            AE.map2 Bitwise.xor output block
    in
    ( ciphertext
    , { state
        | counter = incrementBlock counter
      }
    )


loop : Int -> Block -> Block
loop =
    \idx block_ ->
        case Array.get idx block_ of
            Nothing ->
                block_

            Just x ->
                if x == 255 then
                    loop (idx + 1) <| Array.set idx 0 block_

                else
                    Array.set idx (1 + x) block_


incrementBlock : Block -> Block
incrementBlock block =
    loop 0 block


ctrAdjoiner : ChainingStateAdjoiner CtrState
ctrAdjoiner state list =
    List.append (Array.toList state.nonce) list


ctrSeparator : ChainingStateSeparator CtrState
ctrSeparator blockSize list =
    ( List.drop blockSize list
    , { nonce = Array.fromList <| List.take blockSize list
      , counter = Array.repeat blockSize 0
      }
    )


{-| Counter Chaining

Uses the encryptor for both encryption and decryption.

-}
ctrChaining : Chaining key CtrState randomState
ctrChaining =
    { name = "Counter Chaining"
    , initializer = ctrInitializer
    , encryptor = ctrChainer
    , decryptor = ctrChainer
    , adjoiner = ctrAdjoiner
    , separator = ctrSeparator
    }
