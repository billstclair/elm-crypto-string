module Word.Hex exposing
    ( CharCount, fromInt, fromByte, fromWord, fromByteList, fromWordArray
    , toByteList, toWordArray
    )

{-| Convert to and from strings of hexadecimal characters.

Examples assume the following:

    import Array
    import Word exposing (Size(..), Word(..))


## From Other to Hex

@docs CharCount, fromInt, fromByte, fromWord, fromByteList, fromWordArray


## From Hex to Other

@docs toByteList, toWordArray

-}

import Array exposing (Array)
import Bitwise
import Char
import Word exposing (Word(..))


{-| When converting from integers, the number characters in the hex string.
-}
type alias CharCount =
    Int


{-| Convert an integer to a string of hexadecimal characters.

    fromInt 1 10
    --> "a"

    fromInt 8 0x42BEEF
    --> "0042beef"

-}
fromInt : CharCount -> Int -> String
fromInt charCount value =
    List.foldl
        (\i ->
            value
                |> Bitwise.shiftRightZfBy (i * 2 ^ 2)
                |> Bitwise.and 0x0F
                |> fromIntAccumulator
        )
        ""
        (List.range 0 (charCount - 1))


fromIntAccumulator : Int -> String -> String
fromIntAccumulator x =
    String.cons <|
        Char.fromCode
            (if x < 10 then
                x + 48

             else
                x + 97 - 10
            )


{-| Convert a byte to a hex string of length 2.

    fromByte 0x7B
    --> "7b"

-}
fromByte : Int -> String
fromByte =
    fromInt 2


{-| Convert a list of words to a string of hexadecimal characters.

    W 16 |> fromWord
    --> "00000010"

    D 0xDEADBEEF 0x00112233 |> fromWord
    --> "deadbeef00112233"

-}
fromWord : Word -> String
fromWord word =
    case word of
        W x ->
            fromInt 8 x

        D h l ->
            (++)
                (fromInt 8 h)
                (fromInt 8 l)

        _ ->
            "M"


{-| Convert a list of bytes to a string of hexadecimal characters.

    fromByteList [ 0xde, 0xad, 0xbe, 0xef ]
    --> "deadbeef"

-}
fromByteList : List Int -> String
fromByteList =
    fromList fromByte


{-| Convert an array of words to a string of hexadecimal characters.

    Word.fromUTF8 Bit32 "I ❤ UTF strings!" |> fromWordArray
    --> "4920e29da42055544620737472696e6773210000"

-}
fromWordArray : Array Word -> String
fromWordArray =
    fromArray fromWord


{-| Convert a string of hexadecimal values to a list of bytes.

Fails for non-hex strings.

    toByteList "not hex"
    --> []

Each byte requires 2 characters, so odd length strings fail

    toByteList "000"
    --> []

Some passing examples

    toByteList "00"
    --> [ 0x00 ]

    toByteList "010203040506DEADbeef"
    --> [ 0x01, 0x02, 0x03, 0x04
    --> , 0x05, 0x06, 0xDE, 0xAD
    --> , 0xBE, 0xEF
    --> ]

-}
toByteList : String -> List Int
toByteList hex =
    accHex2 (String.toList hex) []


{-| Convert a string of hexadecimal values to a list of bytes.
-}
toIntList : String -> List Int
toIntList hex =
    accHex2 (String.toList hex) []


{-| Convert a string of hexadecimal values to an array of words.

    toWordArray Word.Bit32 "DEADBEEFdeadbeef" |> fromWordArray
    --> "deadbeefdeadbeef"

-}
toWordArray : Word.Size -> String -> Array Word
toWordArray wordSize hex =
    case wordSize of
        Word.Bit32 ->
            accHex8 (String.toList hex) Array.empty

        Word.Bit64 ->
            accHex16 (String.toList hex) Array.empty



-- HELPERS


accHex2 : List Char -> List Int -> List Int
accHex2 chars acc =
    case chars of
        h :: l :: rest ->
            let
                ( x1, x0 ) =
                    ( hexFromChar h, hexFromChar l )

                acc2 =
                    ((x1 * 2 ^ 4) + x0)
                        |> (\byte -> List.append acc [ byte ])
            in
            accHex2 rest acc2

        [] ->
            acc

        _ ->
            []


type EightNibs
    = EightNibs Int Int Int Int Int Int Int Int


accHex8 : List Char -> Array Word -> Array Word
accHex8 chars acc =
    case chars of
        x7 :: x6 :: x5 :: x4 :: x3 :: x2 :: x1 :: x0 :: rest ->
            let
                acc2 =
                    acc
                        |> Array.push
                            (W
                                (toInt32
                                    (EightNibs
                                        (hexFromChar x7)
                                        (hexFromChar x6)
                                        (hexFromChar x5)
                                        (hexFromChar x4)
                                        (hexFromChar x3)
                                        (hexFromChar x2)
                                        (hexFromChar x1)
                                        (hexFromChar x0)
                                    )
                                )
                            )
            in
            accHex8 rest acc2

        [] ->
            acc

        _ ->
            Array.empty


accHex16 : List Char -> Array Word -> Array Word
accHex16 chars acc =
    case chars of
        x15 :: x14 :: x13 :: x12 :: x11 :: x10 :: x9 :: x8 :: x7 :: x6 :: x5 :: x4 :: x3 :: x2 :: x1 :: x0 :: rest ->
            let
                acc2 =
                    acc
                        |> Array.push
                            (D
                                (toInt32
                                    (EightNibs
                                        (hexFromChar x15)
                                        (hexFromChar x14)
                                        (hexFromChar x13)
                                        (hexFromChar x12)
                                        (hexFromChar x11)
                                        (hexFromChar x10)
                                        (hexFromChar x9)
                                        (hexFromChar x8)
                                    )
                                )
                                (toInt32
                                    (EightNibs
                                        (hexFromChar x7)
                                        (hexFromChar x6)
                                        (hexFromChar x5)
                                        (hexFromChar x4)
                                        (hexFromChar x3)
                                        (hexFromChar x2)
                                        (hexFromChar x1)
                                        (hexFromChar x0)
                                    )
                                )
                            )
            in
            accHex16 rest acc2

        [] ->
            acc

        _ ->
            Array.empty


hexFromChar : Char -> Int
hexFromChar char =
    let
        x =
            Char.toCode char
    in
    if x < 65 then
        -- assume valid 48 - 57 ('0' - '9')
        x - 48

    else if x > 70 then
        -- assume valid 97 - 102 ('a' - 'f')
        x - 87

    else
        x - 55


fromList : (a -> String) -> List a -> String
fromList toHex =
    List.foldl
        (\val acc -> acc ++ toHex val)
        ""


fromArray : (a -> String) -> Array a -> String
fromArray toHex =
    Array.foldl
        (\val acc -> acc ++ toHex val)
        ""


toInt32 : EightNibs -> Int
toInt32 (EightNibs x7 x6 x5 x4 x3 x2 x1 x0) =
    x0
        + (x1 * 2 ^ 4)
        + (x2 * 2 ^ 8)
        + (x3 * 2 ^ 12)
        + (x4 * 2 ^ 16)
        + (x5 * 2 ^ 20)
        + (x6 * 2 ^ 24)
        + (x7 * 2 ^ 28)
