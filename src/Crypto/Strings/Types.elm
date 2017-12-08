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


module Crypto.Strings.Types
    exposing
        ( Block
        , BlockSize
        , Chainer
        , Chaining
        , ChainingInitializer
        , ChainingStateAdjoiner
        , ChainingStateSeparator
        , Ciphertext
        , Config
        , Decoder
        , Decryptor
        , Encoder
        , Encoding
        , Encryption
        , Encryptor
        , Key(..)
        , KeyEncoder
        , KeyEncoding
        , KeyExpander
        , Passphrase
        , Plaintext
        , RandomGenerator
        )

{-| Shared types used by all the Crypto.Strings modules.


# Types

@docs Passphrase, Plaintext, Ciphertext
@docs KeyExpander, Key, Config, BlockSize, Block
@docs Encryption, Encryptor, Decryptor, RandomGenerator
@docs KeyEncoding, KeyEncoder
@docs Encoding, Encoder, Decoder
@docs Chaining, ChainingInitializer, Chainer
@docs ChainingStateAdjoiner, ChainingStateSeparator

-}

import Array exposing (Array)


{-| Another name for `String`, to aid in documentation.
-}
type alias Passphrase =
    String


{-| Another name for `String`, to aid in documentation.
-}
type alias Plaintext =
    String


{-| Another name for `String`, to aid in documentation.
-}
type alias Ciphertext =
    String


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
    state -> ( Encryptor key, Decryptor key ) -> key -> Block -> ( Block, state )


{-| Adjoin chaining state to a list of ciphertext blocks.
-}
type alias ChainingStateAdjoiner state =
    state -> List Int -> List Int


{-| Remove the adjoined state from a list of cipher blocks and turn it into a state.
-}
type alias ChainingStateSeparator state =
    BlockSize -> List Int -> ( List Int, state )


{-| Create a random byte array of a given length
-}
type alias RandomGenerator randomState =
    BlockSize -> ( Block, randomState )


{-| Create an initial chaining state for encryption.
-}
type alias ChainingInitializer state randomState =
    RandomGenerator randomState -> BlockSize -> ( state, randomState )


{-| Package up all the information needed to do block chaining.
-}
type alias Chaining key state randomState =
    { name : String
    , initializer : ChainingInitializer state randomState
    , encryptor : Chainer key state
    , decryptor : Chainer key state
    , adjoiner : ChainingStateAdjoiner state
    , separator : ChainingStateSeparator state
    }


{-| Turn a passphrase into an IV.
-}
type alias KeyEncoder =
    BlockSize -> Passphrase -> Block


{-| Describe a `KeyEncoder` for a `Config`.

Not all `KeyEncodings` will be compatible with all block `Encryption` types.

-}
type alias KeyEncoding =
    { name : String
    , encoder : KeyEncoder
    }


{-| A string encoding algorithm.
-}
type alias Encoder =
    List Int -> String


{-| A string decoding algorithm.
-}
type alias Decoder =
    String -> Result String (List Int)


{-| Encoder and decoder for translating between strings and blocks.
-}
type alias Encoding =
    { name : String
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
type alias Config key state randomState =
    { encryption : Encryption key
    , keyEncoding : KeyEncoding
    , chaining : Chaining key state randomState
    , encoding : Encoding
    }
