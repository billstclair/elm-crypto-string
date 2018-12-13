module Recovered.UTF8 exposing
    ( toMultiByte
    , toSingleByte
    )

{-| Library to encode / decode between multi-byte Unicode characters and UTF-8
multiple single-byte character encoding. Ported from: (c) [Chris
Veness](http://www.movable-type.co.uk).


# UTF-8 to Unicode

@docs toMultiByte


# Unicode to UTF-8

@docs toSingleByte

-}

--LIBS

import Array exposing (Array, fromList, get)
import Bitwise exposing (and, or, shiftLeftBy, shiftRightBy)
import Regex
import String exposing (fromChar, toList)


{-| Encode multi-byte Unicode string into utf-8 multiple single-byte characters
(BMP / basic multilingual plane only).

Chars in range U+0080 - U+07FF are encoded in 2 chars, U+0800 - U+FFFF in 3
chars.

    toMultiByte "Ã¦ Ã¸ Ã¥ Ã±"
        == "æ ø å ñ"

-}
toMultiByte : String -> String
toMultiByte str =
    let
        three =
            -- 3-byte chars
            "[\\u00e0-\\u00ef][\\u0080-\\u00bf][\\u0080-\\u00bf]"

        two =
            -- 2-byte chars
            "[\\u00c0-\\u00df][\\u0080-\\u00bf]"
    in
    str
        |> escape three threeSingleToMulti
        |> escape two twoSingleToMulti


{-| Decode utf-8 encoded string back into multi-byte Unicode characters.

    toSingleByte "æ ø å ñ"
        == "Ã¦ Ã¸ Ã¥ Ã±"

-}
toSingleByte : String -> String
toSingleByte str =
    let
        two =
            -- U+0080 - U+07FF => 2 bytes 110yyyyy, 10zzzzzz
            "[\\u0080-\\u07ff]"

        three =
            -- U+0800 - U+FFFF => 3 bytes 1110xxxx, 10yyyyyy, 10zzzzzz
            "[\\u0800-\\uffff]"
    in
    str
        |> unescape two twoMultiToSingle
        |> unescape three threeMultiToSingle



-- HELPERS


escape : String -> (String -> String) -> String -> String
escape pattern replacement str =
    Regex.replace
        (Regex.fromString pattern |> Maybe.withDefault Regex.never)
        (\{ match } -> replacement match)
        str


unescape : String -> (Char -> String) -> String -> String
unescape pattern replacement str =
    Regex.replace
        (Regex.fromString pattern |> Maybe.withDefault Regex.never)
        (\{ match } ->
            match
                |> String.toList
                |> List.map replacement
                |> List.foldl (\c a -> a ++ c) ""
        )
        str


stringify : KeyCode -> String
stringify =
    fromCode >> fromChar


threeSingleToMulti : String -> String
threeSingleToMulti three =
    let
        xs =
            strToCharArray three

        t1 =
            getKeyCode 0 xs
                |> Bitwise.and 0x0F
                |> Bitwise.shiftLeftBy 12

        t2 =
            getKeyCode 1 xs
                |> Bitwise.and 0x3F
                |> Bitwise.shiftLeftBy 6

        t3 =
            getKeyCode 2 xs
                |> Bitwise.and 0x3F
    in
    t1
        |> Bitwise.or t2
        |> Bitwise.or t3
        |> stringify


twoSingleToMulti : String -> String
twoSingleToMulti two =
    let
        xs =
            strToCharArray two

        t1 =
            getKeyCode 0 xs
                |> Bitwise.and 0x1F
                |> Bitwise.shiftLeftBy 6

        t2 =
            getKeyCode 1 xs
                |> Bitwise.and 0x3F
    in
    t1
        |> Bitwise.or t2
        |> stringify


strToCharArray : String -> Array Char
strToCharArray =
    String.toList >> Array.fromList


getKeyCode : Int -> Array Char -> KeyCode
getKeyCode i xs =
    case Array.get i xs of
        Just c ->
            c |> toCode

        Nothing ->
            0


twoMultiToSingle : Char -> String
twoMultiToSingle c =
    let
        cc =
            c |> toCode

        t1 =
            cc
                |> Bitwise.shiftRightBy 6
                |> Bitwise.or 0xC0
                |> stringify

        t2 =
            cc
                |> Bitwise.and 0x3F
                |> Bitwise.or 0x80
                |> stringify
    in
    t1 ++ t2


threeMultiToSingle : Char -> String
threeMultiToSingle c =
    let
        cc =
            c |> toCode

        t1 =
            cc
                |> Bitwise.shiftRightBy 12
                |> Bitwise.or 0xE0
                |> stringify

        t2 =
            cc
                |> Bitwise.shiftRightBy 6
                |> Bitwise.and 0x3F
                |> Bitwise.or 0x80
                |> stringify

        t3 =
            cc
                |> Bitwise.and 0x3F
                |> Bitwise.or 0x80
                |> stringify
    in
    t1 ++ t2 ++ t3


type alias KeyCode =
    Int


toCode : Char -> KeyCode
toCode =
    Char.toCode


fromCode : KeyCode -> Char
fromCode =
    Char.fromCode
