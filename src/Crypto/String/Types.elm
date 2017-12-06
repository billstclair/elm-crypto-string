----------------------------------------------------------------------
--
-- Types.elm
-- Types for the string encryption packge.
-- Copyright (c) 2017 Bill St. Clair <billstclair@gmail.com>
-- Some rights reserved.
-- Distributed under the MIT License
-- See LICENSE.txt
--
----------------------------------------------------------------------


module Crypto.String.Types
    exposing
        ( Block
        , Chainer
        , Chaining
        , ChainingStateAdjoiner
        , ChainingStateRemover
        , Config
        , Decoder
        , Decryptor
        , Encoder
        , Encoding
        , Encryption
        , Encryptor
        , Key(..)
        , KeyExpander
        )

{-| Shared types used by all the Crypto.String modules.


# Types

@docs KeyExpander, Key, Config, Block
@docs Encryption, Encryptor, Decryptor
@docs Encoding, Encoder, Decoder
@docs Chaining, Chainer, ChainingStateAdjoiner, ChainingStateRemover

-}

import Array exposing (Array)


{-| A portable name for block encryption algorithm specific keys.
-}
type Key k
    = Key k


{-| Describe key expansion for a particular block encryption algorithm.

`keySize` is the number of bytes in a raw key.

`expander` is a function to turn an array of that size into a key.

-}
type alias KeyExpander k =
    { keySize : Int
    , expander : Array Int -> Result String k
    }


{-| One block for a block encryption algorithm.
-}
type alias Block =
    Array Int


{-| An encryption function for a particular low-level block algorithm.
-}
type alias Encryptor k =
    k -> Block -> Block


{-| A decryption function for a particular low-level block algorithm.
-}
type alias Decryptor k =
    k -> Block -> Block


{-| A block chaining algorithm.
-}
type alias Chainer k state =
    state -> Encryptor k -> k -> Block -> ( state, Block )


{-| Adjoin chaining state to a list of ciphertext blocks.
-}
type alias ChainingStateAdjoiner state =
    state -> List Block -> List Block


{-| Remove the adjoined state from a list of cipher blocks and turn it into a state.
-}
type alias ChainingStateRemover state =
    List Block -> ( state, List Block )


{-| Package up all the information needed to do block chaining.
-}
type alias Chaining k state =
    { name : String
    , encryptor : Chainer k state
    , decryptor : Chainer k state
    , adjoiner : ChainingStateAdjoiner state
    , remover : ChainingStateRemover state
    }


{-| A string encoding algorithm
-}
type alias Encoder =
    List Block -> String


{-| A string decoding algorithm
-}
type alias Decoder =
    String -> List Block


{-| Encoder and decoder for translating between strings and blocks.
-}
type alias Encoding p =
    { name : String
    , parameters : p
    , encoder : Encoder
    , decoder : Decoder
    }


{-| Package up information about a block encryption algorithm.
-}
type alias Encryption k =
    { name : String
    , keyExpander : KeyExpander k
    , encryptor : Encryptor k
    , decryptor : Decryptor k
    }


{-| Configuration for the block chaining and string encoding
-}
type alias Config k state p =
    { encryption : Encryption k
    , chaining : Chaining k state
    , encoding : Encoding p
    }
