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
        , Config
        , Decoder
        , Decryptor
        , Encoder
        , Encryptor
        , Key(..)
        , KeyExpander
        )

{-| Shared types used by all the Crypto.String modules.


# Types

@docs KeyExpander, Key, Config, Block
@docs Encryptor, Decryptor, Chainer, Encoder, Decoder

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


{-| A string encoding algorithm
-}
type alias Encoder =
    List Block -> String


{-| A string decoding algorithm
-}
type alias Decoder =
    String -> List Block


{-| Configuration for the block chaining and string encoding
-}
type alias Config k state =
    { keyExpander : KeyExpander k
    , encryptor : Encryptor k
    , decryptor : Encryptor k
    , chainer : Chainer k state
    , encoder : Encoder
    , decoder : Decoder
    }
