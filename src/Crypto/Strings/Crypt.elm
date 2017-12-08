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


module Crypto.Strings.Crypt
    exposing
        ( DefaultKey
        , blocksToList
        , decrypt
        , defaultConfig
        , encrypt
        , expandKeyString
        , listToBlocks
        , padLastBlock
        , seedGenerator
        , stripTrailingZeroes
        , unpadLastBlock
        )

{-| Block chaining and string encryption for use with any block cipher.


# Types

@docs DefaultKey


# Functions

@docs expandKeyString, defaultConfig, encrypt, decrypt, seedGenerator


# Low-level functions

@docs listToBlocks, blocksToList
@docs padLastBlock, unpadLastBlock, stripTrailingZeroes

-}

import Array exposing (Array)
import Crypto.Strings.BlockAes as Aes
import Crypto.Strings.Chaining as Chaining
import Crypto.Strings.Encoding as Encoding
import Crypto.Strings.Types
    exposing
        ( Block
        , BlockSize
        , Ciphertext
        , Config
        , Decryptor
        , Encoding
        , Encryptor
        , Key(..)
        , KeyEncoding
        , KeyExpander
        , Passphrase
        , Plaintext
        , RandomGenerator
        )
import List.Extra as LE
import Random


{-| TODO
-}
processKey : Config key state randomState -> String -> Result String key
processKey config string =
    let
        expander =
            config.encryption.keyExpander

        keyEncoder =
            config.keyEncoding.encoder
    in
    keyEncoder expander.keySize string
        |> expander.expander


defaultEncoding =
    Encoding.base64Encoding 60


{-| Default key type.
-}
type alias DefaultKey =
    Key Aes.Key


{-| Default configuration.
-}
defaultConfig : Config Aes.Key Chaining.CtrState randomState
defaultConfig =
    { keyEncoding = Encoding.foldedSha256KeyEncoding
    , encryption = Aes.encryption
    , chaining = Chaining.ctrChaining
    , encoding = defaultEncoding
    }


{-| Expand a key preparing it for use with `encrypt` or `decrypt`.
-}
expandKeyString : Config key state randomState -> Passphrase -> Result String (Key key)
expandKeyString config passphrase =
    case processKey config passphrase of
        Err msg ->
            Err msg

        Ok key ->
            Ok <| Key key


{-| A random generator that takes and returns a standard Elm Seed.
-}
seedGenerator : Random.Seed -> RandomGenerator Random.Seed
seedGenerator seed blockSize =
    let
        gen =
            Random.list blockSize <| Random.int 0 255

        ( list, sd ) =
            Random.step gen seed
    in
    ( Array.fromList list, sd )


{-| Encrypt a list of blocks.
-}
encryptList : Config key state randomState -> RandomGenerator randomState -> Key key -> List Int -> ( List Int, randomState )
encryptList config generator (Key key) list =
    let
        chaining =
            config.chaining

        encryption =
            config.encryption

        chainer =
            chaining.encryptor

        pair =
            ( encryption.encryptor, encryption.decryptor )

        ( state, randomState ) =
            chaining.initializer generator encryption.blockSize

        step : Block -> ( List Block, state ) -> ( List Block, state )
        step =
            \block ( blocks, state ) ->
                let
                    ( outBlock, outState ) =
                        chainer state pair key block
                in
                ( outBlock :: blocks, outState )

        ( cipherBlocks, finalState ) =
            listToBlocks encryption.blockSize list
                |> List.foldl step ( [], state )
    in
    ( List.reverse cipherBlocks
        |> blocksToList
        |> chaining.adjoiner finalState
    , randomState
    )


{-| Encrypt a string.
-}
encrypt : Config key state randomState -> RandomGenerator randomState -> Key key -> Plaintext -> ( Ciphertext, randomState )
encrypt config generator key plaintext =
    Encoding.plainTextEncoder plaintext
        |> encryptList config generator key
        |> (\( cipherList, randomState ) ->
                ( config.encoding.encoder cipherList
                , randomState
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


marker : Int
marker =
    0x80


{-| Put a 0x80 at the end of the last block, and pad with zeroes.

No padding is done if the last block is of the blockSize, and does NOT already end with 0 or 0x80.

-}
padLastBlock : Int -> List Block -> List Block
padLastBlock blockSize blocks =
    let
        loop : List Block -> List Block -> List Block
        loop =
            \blocks res ->
                case blocks of
                    [] ->
                        []

                    [ blk ] ->
                        let
                            block =
                                stripTrailingZeroes blk

                            len =
                                Array.length block

                            last =
                                Maybe.withDefault 0 <|
                                    Array.get (len - 1) block

                            ( b, bs, ln ) =
                                if len == blockSize && (last == 0 || last == marker) then
                                    ( Array.fromList [ marker ]
                                    , [ block ]
                                    , 1
                                    )
                                else if len < blockSize then
                                    ( Array.push marker block
                                    , []
                                    , len + 1
                                    )
                                else
                                    ( block
                                    , []
                                    , len
                                    )

                            b2 =
                                if ln < blockSize then
                                    Array.append b <|
                                        Array.repeat (blockSize - ln) 0
                                else
                                    b
                        in
                        (b2 :: List.append bs res)
                            |> List.reverse

                    head :: tail ->
                        loop tail <| head :: res
    in
    loop blocks []


{-| Remove the padding added by `padLastBlock` from the last block in a list.
-}
unpadLastBlock : List Block -> List Block
unpadLastBlock blocks =
    let
        loop : List Block -> List Block -> List Block
        loop =
            \blocks res ->
                case blocks of
                    [] ->
                        []

                    [ blk ] ->
                        let
                            block =
                                stripTrailingZeroes blk

                            len =
                                Array.length block

                            last =
                                Maybe.withDefault 1 <| Array.get (len - 1) block

                            b =
                                if last == marker then
                                    Array.slice 0 -1 block
                                else
                                    block
                        in
                        (b :: res)
                            |> List.reverse

                    head :: tail ->
                        loop tail (head :: res)
    in
    loop blocks []


{-| Strip the trailing zeroes from a block.
-}
stripTrailingZeroes : Block -> Block
stripTrailingZeroes block =
    let
        len =
            Array.length block

        loop : Int -> Block
        loop =
            \idx ->
                if idx < 0 then
                    block
                else
                    case Array.get idx block of
                        Nothing ->
                            --can't happen
                            block

                        Just x ->
                            if x /= 0 then
                                Array.slice 0 (1 + idx) block
                            else
                                loop (idx - 1)
    in
    loop (len - 1)


{-| Convert a list of integers into a list of blocks.

The end of the last block will always be #x80 plus zeroes. If all the
blocks are full, and the last byte is NOT zero or #x80, then no
padding is added.

-}
listToBlocks : Int -> List Int -> List Block
listToBlocks blockSize list =
    LE.greedyGroupsOf blockSize list
        |> List.map (extendArray blockSize 0 << Array.fromList)
        |> padLastBlock blockSize


{-| Convert a list of blocks into a list of integers.
-}
blocksToList : List Block -> List Int
blocksToList blocks =
    unpadLastBlock blocks
        |> List.map Array.toList
        |> List.concat


{-| Decrypt a list of integers.
-}
decryptList : Config key state randomState -> Key key -> List Int -> List Int
decryptList config (Key key) list =
    let
        chaining =
            config.chaining

        encryption =
            config.encryption

        chainer =
            chaining.decryptor

        pair =
            ( encryption.encryptor, encryption.decryptor )

        ( cipherList, state ) =
            chaining.separator encryption.blockSize list

        cipherBlocks =
            listToBlocks encryption.blockSize cipherList

        step : Block -> ( List Block, state ) -> ( List Block, state )
        step =
            \block ( blocks, state ) ->
                let
                    ( outBlock, state2 ) =
                        chainer state pair key block
                in
                ( outBlock :: blocks, state2 )

        ( plainBlocks, _ ) =
            List.foldl step ( [], state ) cipherBlocks
    in
    List.reverse plainBlocks
        |> blocksToList


{-| Decrypt a string created with `encrypt`.
-}
decrypt : Config key state randomState -> Key key -> Ciphertext -> Result Plaintext String
decrypt config key string =
    --This will use the blockchain algorithm and block encoder
    case config.encoding.decoder string of
        Err msg ->
            Err msg

        Ok list ->
            decryptList config key list
                |> Encoding.plainTextDecoder
                |> Ok
