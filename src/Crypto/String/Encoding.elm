----------------------------------------------------------------------
--
-- Encoding.elm
-- String encoding/decoding.
-- Copyright (c) 2017 Bill St. Clair <billstclair@gmail.com>
-- Some rights reserved.
-- Distributed under the MIT License
-- See LICENSE.txt
--
----------------------------------------------------------------------


module Crypto.String.Encoding
    exposing
        ( base64Decoder
        , base64Encoder
        , base64Encoding
        , hexDecoder
        , hexEncoder
        , hexEncoding
        , keyEncoder
        , plainTextDecoder
        , plainTextEncoder
        )

{-| Encoders and decoders from and to strings and blocks.


# Functions

@docs keyEncoder
@docs plainTextDecoder, plainTextEncoder
@docs base64Encoding, base64Encoder, base64Decoder
@docs hexEncoding, hexEncoder, hexDecoder

-}

import Array exposing (fromList)
import Crypto.String.Types exposing (Block, BlockSize, Decoder, Encoder, Encoding)


{-| Hash and fold a passphrase to turn it into a raw key array.
-}
keyEncoder : BlockSize -> String -> Block
keyEncoder blockSize string =
    fromList []


{-| Encode a string as UTF-8 bytes
-}
plainTextEncoder : String -> List Block
plainTextEncoder string =
    []


{-| Decode UTF-8 bytes into a string. Sometimes this is not possible.
-}
plainTextDecoder : List Block -> Result String String
plainTextDecoder blocks =
    Err "plainTextDecoder is not yet implemented."


{-| How to encode/decode strings to/from hex.
-}
hexEncoding : Encoding
hexEncoding =
    { name = "Hex Encoding"
    , encoder = hexEncoder
    , decoder = hexDecoder
    }


{-| Convert bytes to hex.
-}
hexEncoder : List Block -> String
hexEncoder blocks =
    ""


{-| Convert a hex string to bytes. Sometimes the string is malformed.
-}
hexDecoder : String -> Result String (List Block)
hexDecoder string =
    Err "hexDecoder is not yet implemented."


{-| How to encode/decode strings to/from Base64

The Int parameter is the line length for encoding to a string.

-}
base64Encoding : Int -> Encoding
base64Encoding lineLength =
    { name = "Base64 Encoding"
    , encoder = base64Encoder lineLength
    , decoder = base64Decoder
    }


{-| Convert bytes to Base64.
-}
base64Encoder : Int -> List Block -> String
base64Encoder lineLength blocks =
    ""


{-| Convert a Base64 string to bytes. Sometimes the string is malformed.
-}
base64Decoder : String -> Result String (List Block)
base64Decoder string =
    Err "base64Decider is not yet implemented."
