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
        , BlockSize
        , Chainer
        , Chaining
        , ChainingInitializer
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

@docs KeyExpander, Key, Config, BlockSize, Block
@docs Encryption, Encryptor, Decryptor
@docs Encoding, Encoder, Decoder
@docs Chaining, ChainingInitializer, Chainer
@docs ChainingStateAdjoiner, ChainingStateRemover

-}

import Array exposing (Array)


{-| A portable name for block encryption algorithm specific keys.
-}
type Key key
    = Key key


{-| Describe key expansion for a particular block encryption algorithm.

`keySize` is the number of bytes in a raw key.

`expander` is a function to turn an array of that size into a key.

-}
type alias KeyExpander key =
    { keySize : Int
    , expander : Array Int -> Result String key
    }


{-| An alternative name for Int to make docs clearer.
-}
type alias BlockSize =
    Int


{-| One block for a block encryption algorithm.
-}
type alias Block =
    Array Int


{-| An encryption function for a particular low-level block algorithm.
-}
type alias Encryptor key =
    key -> Block -> Block


{-| A decryption function for a particular low-level block algorithm.
-}
type alias Decryptor key =
    key -> Block -> Block


{-| A block chaining algorithm.
-}
type alias Chainer key state =
    state -> Encryptor key -> key -> Block -> ( state, Block )


{-| Adjoin chaining state to a list of ciphertext blocks.
-}
type alias ChainingStateAdjoiner state =
    state -> List Block -> List Block


{-| Remove the adjoined state from a list of cipher blocks and turn it into a state.
-}
type alias ChainingStateRemover state =
    List Block -> ( state, List Block )


{-| Create an initial chaining state for encryption.
-}
type alias ChainingInitializer state =
    BlockSize -> state


{-| Package up all the information needed to do block chaining.
-}
type alias Chaining key state =
    { name : String
    , initializer : ChainingInitializer state
    , encryptor : Chainer key state
    , decryptor : Chainer key state
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
type alias Encoding params =
    { name : String
    , parameters : params
    , encoder : Encoder
    , decoder : Decoder
    }


{-| Package up information about a block encryption algorithm.
-}
type alias Encryption key =
    { name : String
    , blockSize : BlockSize
    , keyExpander : KeyExpander key
    , encryptor : Encryptor key
    , decryptor : Decryptor key
    }


{-| Configuration for the block chaining and string encoding
-}
type alias Config key state params =
    { encryption : Encryption key
    , chaining : Chaining key state
    , encoding : Encoding params
    }
