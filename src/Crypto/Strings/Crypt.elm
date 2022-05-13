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


module Crypto.Strings.Crypt exposing
    ( DefaultKey
    , expandKeyString, defaultConfig, encrypt, decrypt, seedGenerator
    , listToBlocks, blocksToList
    , padLastBlock, unpadLastBlock, stripTrailingZeroes
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
import Random


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
            \block ( blocks, state_ ) ->
                let
                    ( outBlock, outState ) =
                        chainer state_ pair key block
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


padLastBlockLoop : Int -> List Block -> List Block -> List Block
padLastBlockLoop blockSize =
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
                padLastBlockLoop blockSize tail <| head :: res


{-| Put a 0x80 at the end of the last block, and pad with zeroes.

No padding is done if the last block is of the blockSize, and does NOT already end with 0 or 0x80.

-}
padLastBlock : Int -> List Block -> List Block
padLastBlock blockSize blocks =
    padLastBlockLoop blockSize blocks []


unpadLastBlockLoop : List Block -> List Block -> List Block
unpadLastBlockLoop =
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
                unpadLastBlockLoop tail (head :: res)


{-| Remove the padding added by `padLastBlock` from the last block in a list.
-}
unpadLastBlock : List Block -> List Block
unpadLastBlock blocks =
    unpadLastBlockLoop blocks []


stripTrailingZeroesLoop : Block -> Int -> Block
stripTrailingZeroesLoop block =
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
                        stripTrailingZeroesLoop block (idx - 1)


{-| Strip the trailing zeroes from a block.
-}
stripTrailingZeroes : Block -> Block
stripTrailingZeroes block =
    let
        len =
            Array.length block
    in
    stripTrailingZeroesLoop block (len - 1)


{-| Convert a list of integers into a list of blocks.

The end of the last block will always be #x80 plus zeroes. If all the
blocks are full, and the last byte is NOT zero or #x80, then no
padding is added.

-}
listToBlocks : Int -> List Int -> List Block
listToBlocks blockSize list =
    greedyGroupsOfTailRec blockSize list
        |> List.map (extendArray blockSize 0 << Array.fromList)
        |> padLastBlock blockSize



{- Fully tail recursive version of greedyGroupsOf.  Modified from the source of
   elm-community/list-extra which carries the following copywrite notice:

   The MIT License (MIT)

   Copyright (c) 2016 CircuitHub Inc., Elm Community members

   Permission is hereby granted, free of charge, to any person obtaining a copy
   of this software and associated documentation files (the "Software"), to deal
   in the Software without restriction, including without limitation the rights
   to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
   copies of the Software, and to permit persons to whom the Software is
   furnished to do so, subject to the following conditions:

   The above copyright notice and this permission notice shall be included in all
   copies or substantial portions of the Software.

   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
   OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
   SOFTWARE.

-}


greedyGroupsOfTailRec : Int -> List a -> List (List a)
greedyGroupsOfTailRec size xs =
    greedyGroupsOfWithStepTailRec size size xs


greedyGroupsOfWithStepTailRec : Int -> Int -> List a -> List (List a)
greedyGroupsOfWithStepTailRec size step list =
    if size <= 0 || step <= 0 then
        []

    else
        let
            go : List a -> List (List a) -> List (List a)
            go xs acc =
                if List.isEmpty xs then
                    List.reverse acc

                else
                    go
                        (List.drop step xs)
                        (takeTailRec size xs :: acc)
        in
        go list []



{- List.take starts out non-tail-recursive and switches to a tail-recursive
   implementation after the first 1000 iterations.  For functions which are themselves
   recursive and use List.take on each call (e.g. List.Extra.groupsOf), this can result
   in potential call stack overflow from the successive accumulation of 1000-long
   non-recursive List.take calls.  Here we provide an always tail recursive version of
   List.take to avoid this problem.  The code is taken directly from the implementation
   of elm/core and carries the following copywrite:

   Copyright 2014-present Evan Czaplicki

   Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

   1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

   2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

   3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
-}


takeTailRec : Int -> List a -> List a
takeTailRec n list =
    List.reverse (takeReverse n list [])


takeReverse : Int -> List a -> List a -> List a
takeReverse n list kept =
    if n <= 0 then
        kept

    else
        case list of
            [] ->
                kept

            x :: xs ->
                takeReverse (n - 1) xs (x :: kept)


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
            \block ( blocks, state_ ) ->
                let
                    ( outBlock, state2 ) =
                        chainer state_ pair key block
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
