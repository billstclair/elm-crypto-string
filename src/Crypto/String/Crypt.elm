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
encryptBlocks : Config key randomState state -> RandomGenerator randomState -> Key key -> List Block -> ( randomState, List Block )
encryptBlocks config generator (Key key) blocks =
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
                    ( state2, outBlock ) =
                        chainer state encryptor key block
                in
                ( state2, outBlock :: blocks )

        ( finalState, cipherBlocks ) =
            List.foldl step ( state, [] ) blocks
    in
    ( randomState
    , chaining.adjoiner finalState <|
        List.reverse cipherBlocks
    )


{-| Encrypt a string.
-}
encrypt : Config key randomState state -> RandomGenerator randomState -> Key key -> String -> ( randomState, String )
encrypt config generator key plaintext =
    Encoding.plainTextEncoder plaintext
        |> encryptBlocks config generator key
        |> (\( randomState, cipherBlocks ) ->
                ( randomState
                , config.encoding.encoder cipherBlocks
                )
           )


{-| Decrypt a list of blocks.
-}
decryptBlocks : Config key randomState state -> Key key -> List Block -> List Block
decryptBlocks config (Key key) rawBlocks =
    let
        chaining =
            config.chaining

        encryption =
            config.encryption

        chainer =
            chaining.decryptor

        decryptor =
            encryption.decryptor

        ( state, cipherBlocks ) =
            chaining.remover encryption.blockSize rawBlocks

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


{-| Decrypt a string created with `encrypt`.
-}
decrypt : Config key randomState state -> Key key -> String -> Result String String
decrypt config key string =
    --This will use the blockchain algorithm and block encoder
    case config.encoding.decoder string of
        Err msg ->
            Err msg

        Ok cipherBlocks ->
            decryptBlocks config key cipherBlocks
                |> Encoding.plainTextDecoder
