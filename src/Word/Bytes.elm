module Word.Bytes exposing (ByteCount, fromInt, fromUTF8)

{-| Helper functions for creating lists of bytes.

    import Word.Hex as Hex

@docs ByteCount, fromInt, fromUTF8

-}

import Bitwise
import Char


{-| Total number of bytes
-}
type alias ByteCount =
    Int


{-| Convert a character into a list of bytes

    fromUTF8 "a" |> Hex.fromByteList
    --> "61"

    fromUTF8 "I ❤ cheese"
    --> [ 73, 32,
    -->   226, 157, 164,
    -->   32, 99, 104, 101, 101, 115, 101 ]

    fromUTF8 "dѐf"
    --> [ 100, 209, 144, 102 ]

-}
fromUTF8 : String -> List Int
fromUTF8 =
    String.toList
        >> List.foldl
            (\char acc ->
                List.append acc (char |> Char.toCode |> splitUtf8)
            )
            []


splitUtf8 : Int -> List Int
splitUtf8 x =
    if x < 128 then
        [ x ]

    else if x < 2048 then
        [ x |> Bitwise.and 0x07C0 |> Bitwise.shiftRightZfBy 6 |> Bitwise.or 0xC0
        , x |> Bitwise.and 0x3F |> Bitwise.or 0x80
        ]

    else
        [ x |> Bitwise.and 0xF000 |> Bitwise.shiftRightZfBy 12 |> Bitwise.or 0xE0
        , x |> Bitwise.and 0x0FC0 |> Bitwise.shiftRightZfBy 6 |> Bitwise.or 0x80
        , x |> Bitwise.and 0x3F |> Bitwise.or 0x80
        ]


{-| Split an integer value into a list of bytes with the given length.

    fromInt 4 0 |> Hex.fromByteList
    --> "00000000"

    fromInt 4 1 |> Hex.fromByteList
    --> "00000001"

    fromInt 2 2 |> Hex.fromByteList
    --> "0002"

    fromInt 1 255 |> Hex.fromByteList
    --> "ff"

    fromInt 4 256 |> Hex.fromByteList
    --> "00000100"

    fromInt 4 65537 |> Hex.fromByteList
    --> "00010001"

    fromInt 4 16777216 |> Hex.fromByteList
    --> "01000000"

    fromInt 8 344 |> Hex.fromByteList
    --> "0000000000000158"

    fromInt 16 344 |> Hex.fromByteList
    --> "00000000000000000000000000000158"

-}
fromInt : ByteCount -> Int -> List Int
fromInt byteCount value =
    if byteCount > 4 then
        List.append
            (fromInt (byteCount - 4) (value // 2 ^ 32))
            (fromInt 4 (Bitwise.and 0xFFFFFFFF value))

    else
        List.map
            (\i ->
                value
                    |> Bitwise.shiftRightZfBy ((byteCount - i) * 2 ^ 3)
                    |> Bitwise.and 0xFF
            )
            (List.range 1 byteCount)


fixLength : Int -> Int -> List Int -> List Int
fixLength byteCount val list =
    case compare (List.length list) byteCount of
        EQ ->
            list

        LT ->
            List.append
                (List.repeat (byteCount - List.length list) val)
                list

        GT ->
            List.take byteCount list
