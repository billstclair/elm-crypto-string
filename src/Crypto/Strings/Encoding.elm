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


module Crypto.Strings.Encoding
    exposing
        ( base64Decoder
        , base64Encoder
        , base64Encoding
        , fold
        , foldedSha256KeyEncoder
        , foldedSha256KeyEncoding
        , hexDecoder
        , hexEncoder
        , hexEncoding
        , plainTextDecoder
        , plainTextEncoder
        )

{-| Encoders and decoders from and to strings and blocks.


# `Config` elements


## Key Encodings

@docs foldedSha256KeyEncoding


## Encodings

@docs base64Encoding, hexEncoding


# Translate between strings and byte lists.

@docs plainTextDecoder, plainTextEncoder


# Implementations of the `Config` elements

@docs foldedSha256KeyEncoder, fold
@docs base64Encoder, base64Decoder
@docs hexEncoder, hexDecoder

-}

import Array exposing (fromList)
import Base64
import Bitwise
import Char
import Crypto.Hash exposing (sha256)
import Crypto.Strings.Types
    exposing
        ( Block
        , BlockSize
        , Decoder
        , Encoder
        , Encoding
        , KeyEncoding
        )
import Hex
import List.Extra as LE
import Recovered.UTF8


{-| Hash and fold a passphrase to turn it into a raw key array.
-}
foldedSha256KeyEncoder : BlockSize -> String -> Block
foldedSha256KeyEncoder blockSize string =
    sha256 string
        |> hexDecoder 2
        --The default will never happen. At least I hope it doesn't. :)
        |> Result.withDefault
            [ 102, 117, 99, 107, 32, 109, 101, 32, 104, 97, 114, 100, 101, 114 ]
        |> fold blockSize
        |> Array.fromList


{-| A KeyEncoding for foldedSha256KeyEncoder
-}
foldedSha256KeyEncoding : KeyEncoding
foldedSha256KeyEncoding =
    { name = "Folded SHA256 Key Encoding"
    , encoder = foldedSha256KeyEncoder
    }


{-| Fold a list of integers to a specified size.

Actually XORs too-long pieces together to not lose any entropy.

Worth the effort? I don't know. Hashing probably does enough.

-}
fold : Int -> List Int -> List Int
fold size list =
    let
        len =
            List.length list
    in
    if len == size then
        list
    else if len < size then
        List.append list list
            |> fold size
    else if len > size * 2 then
        let
            l =
                if isOdd len then
                    0 :: list
                else
                    list

            ln =
                (len + 1) // 2
        in
        List.map2 Bitwise.xor (List.take ln l) (List.drop ln l)
            |> fold size
    else
        let
            left =
                List.take size list

            r =
                List.drop size list

            diff =
                len - size

            right =
                List.append r <| List.repeat diff 0
        in
        List.map2 Bitwise.xor left right


isOdd : Int -> Bool
isOdd x =
    x /= (x // 2) * 2


{-| Encode a string as UTF-8 bytes
-}
plainTextEncoder : String -> List Int
plainTextEncoder string =
    Recovered.UTF8.toSingleByte string
        |> String.toList
        |> List.map Char.toCode


{-| Decode UTF-8 bytes into a string.
-}
plainTextDecoder : List Int -> String
plainTextDecoder list =
    List.map Char.fromCode list
        |> String.fromList
        |> Recovered.UTF8.toMultiByte


{-| How to encode/decode strings to/from hex.
-}
hexEncoding : Encoding
hexEncoding =
    { name = "Hex Encoding"
    , encoder = hexEncoder
    , decoder = hexDecoder 2
    }


{-| Convert bytes to hex.
-}
hexEncoder : List Int -> String
hexEncoder list =
    List.map Hex.toString list
        |> List.map String.toUpper
        |> List.map (String.padLeft 2 '0')
        |> String.concat


{-| Convert a hex string to bytes. Sometimes the string is malformed.
-}
hexDecoder : Int -> String -> Result String (List Int)
hexDecoder groupSize string =
    if String.length string % groupSize /= 0 then
        Err <| "String length not a multiple of " ++ toString groupSize
    else
        let
            res =
                String.toList string
                    |> LE.greedyGroupsOf groupSize
                    |> List.map String.fromList
                    |> List.map String.toLower
                    |> List.map Hex.fromString
                    |> List.map (Result.withDefault -1)
        in
        if List.member -1 res then
            Err <| "Invalid hexadecimal string: " ++ string
        else
            Ok res


{-| How to encode/decode strings to/from Base64

The Int parameter is the line length for encoding to a string.

-}
base64Encoding : Int -> Encoding
base64Encoding lineLength =
    { name = "Base64 Encoding"
    , encoder = base64Encoder lineLength
    , decoder = base64Decoder
    }


splitLines : Int -> String -> String
splitLines lineLength string =
    if lineLength <= 0 then
        string
    else
        let
            loop : String -> List String -> String
            loop =
                \tail res ->
                    if String.length tail <= lineLength then
                        (tail :: res)
                            |> List.reverse
                            |> String.join "\n"
                    else
                        loop (String.dropLeft lineLength tail) <|
                            String.left lineLength tail
                                :: res
        in
        loop string []


{-| Convert bytes to Base64.
-}
base64Encoder : Int -> List Int -> String
base64Encoder lineLength list =
    Base64.encode list
        |> splitLines lineLength


{-| Convert a Base64 string to bytes. Sometimes the string is malformed.
-}
base64Decoder : String -> Result String (List Int)
base64Decoder string =
    String.words string
        |> String.concat
        |> Base64.decode
