----------------------------------------------------------------------
--
-- Crypt.elm
-- General purpose string encryption functions.
-- Copyright (c) 2017 Bill St. Clair <billstclair@gmail.com>
-- Some rights reserved.
-- Distributed under the MIT License
-- See LICENSE.txt
--
----------------------------------------------------------------------


module Crypto.String.Crypt
    exposing
        ( DefaultKey
        , decrypt
        , defaultConfig
        , encrypt
        , expandKeyString
        )

{-| Block chaining and string encryption for use with any block cipher.


# Types

@docs DefaultKey


# Functions

@docs expandKeyString, defaultConfig, encrypt, decrypt

-}

import Array exposing (Array)
import Crypto.String.BlockAes as Aes
import Crypto.String.Chaining as Chaining
import Crypto.String.Encoding as Encoding
import Crypto.String.Types
    exposing
        ( Block
        , BlockSize
        , Config
        , Decryptor
        , Encoding
        , Encryptor
        , Key(..)
        , KeyExpander
        , RandomGenerator
        )
import List.Extra as LE


{-| TODO
-}
processKey : KeyExpander key -> String -> Result String key
processKey expander string =
    Encoding.keyEncoder expander.keySize string
        |> expander.expander


defaultEncoding =
    Encoding.base64Encoding 60


{-| Default key type.
-}
type alias DefaultKey =
    Key Aes.Key


{-| Default configuration.
-}
defaultConfig : Config Aes.Key randomState Chaining.EcbState
defaultConfig =
    { encryption = Aes.encryption
    , chaining = Chaining.ecbChaining
    , encoding = defaultEncoding
    }


{-| Expand a key preparing it for use with `encrypt` or `decrypt`.
-}
expandKeyString : Config key randomState state -> String -> Result String (Key key)
expandKeyString config string =
    let
        expander =
            config.encryption.keyExpander
    in
    case processKey expander string of
        Err msg ->
            Err msg

        Ok key ->
            Ok <| Key key


{-| Encrypt a list of blocks.
-}
encryptList : Config key randomState state -> RandomGenerator randomState -> Key key -> List Int -> ( randomState, List Int )
encryptList config generator (Key key) list =
    let
        chaining =
            config.chaining

        encryption =
            config.encryption

        chainer =
            chaining.encryptor

        encryptor =
            encryption.encryptor

        ( randomState, state ) =
            chaining.initializer generator encryption.blockSize

        step : Block -> ( state, List Block ) -> ( state, List Block )
        step =
            \block ( state, blocks ) ->
                let
                    ( outState, outBlock ) =
                        chainer state encryptor key block
                in
                ( outState, outBlock :: blocks )

        ( finalState, cipherBlocks ) =
            listToBlocks encryption.blockSize list
                |> List.foldl step ( state, [] )
    in
    ( randomState
    , List.reverse cipherBlocks
        |> blocksToList
        |> chaining.adjoiner finalState
    )


{-| Encrypt a string.
-}
encrypt : Config key randomState state -> RandomGenerator randomState -> Key key -> String -> ( randomState, String )
encrypt config generator key plaintext =
    Encoding.plainTextEncoder plaintext
        |> encryptList config generator key
        |> (\( randomState, cipherList ) ->
                ( randomState
                , config.encoding.encoder cipherList
                )
           )


extendArray : Int -> a -> Array a -> Array a
extendArray size fill array =
    let
        count =
            size - Array.length array
    in
    if count <= 0 then
        array
    else
        Array.append array <| Array.repeat count fill


{-| Convert a list of integers into a list of blocks.

Fill the last one with zeroes, if necessary.

-}
listToBlocks : Int -> List Int -> List Block
listToBlocks blockSize list =
    LE.greedyGroupsOf blockSize list
        |> List.map (extendArray blockSize 0 << Array.fromList)


{-| Convert a list of blocks into a list of integers.
-}
blocksToList : List Block -> List Int
blocksToList blocks =
    List.map Array.toList blocks
        |> List.concat


{-| Decrypt a list of integers.
-}
decryptList : Config key randomState state -> Key key -> List Int -> List Int
decryptList config (Key key) list =
    let
        chaining =
            config.chaining

        encryption =
            config.encryption

        chainer =
            chaining.decryptor

        decryptor =
            encryption.decryptor

        ( state, cipherList ) =
            chaining.separator encryption.blockSize list

        cipherBlocks =
            listToBlocks encryption.blockSize cipherList

        step : Block -> ( state, List Block ) -> ( state, List Block )
        step =
            \block ( state, blocks ) ->
                let
                    ( state2, outBlock ) =
                        chainer state decryptor key block
                in
                ( state2, outBlock :: blocks )

        ( _, plainBlocks ) =
            List.foldl step ( state, [] ) cipherBlocks
    in
    List.reverse plainBlocks
        |> blocksToList


{-| Decrypt a string created with `encrypt`.
-}
decrypt : Config key randomState state -> Key key -> String -> Result String String
decrypt config key string =
    --This will use the blockchain algorithm and block encoder
    case config.encoding.decoder string of
        Err msg ->
            Err msg

        Ok list ->
            decryptList config key list
                |> Encoding.plainTextDecoder
