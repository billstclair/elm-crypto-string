module Word.Helpers exposing (lowMask, rotatedLowBits, safeShiftRightZfBy)

{-| Helpers functions.

    import Array
    import Word.Hex as Hex

-}

import Bitwise


{-| Rotate the low `n` bits of a 32 bit value and adds as high bits to another.

    rotatedLowBits 2 0xFFFFFFFF 0xBEEF |> Hex.fromInt 8
    --> "c000beef"

    rotatedLowBits 2 0x03 0xBEEF |> Hex.fromInt 8
    --> "c000beef"

    rotatedLowBits 28 0xFFFFFFFF 7 |> Hex.fromInt 8
    --> "fffffff7"

-}
rotatedLowBits : Int -> Int -> Int -> Int
rotatedLowBits n val =
    (+)
        (val
            |> Bitwise.and (lowMask n)
            |> Bitwise.shiftLeftBy (32 - n)
        )


safeShiftRightZfBy : Int -> Int -> Int
safeShiftRightZfBy n val =
    if n >= 32 then
        -- `shiftRightZfBy 32 0xffff` returns `65535`
        0

    else
        Bitwise.shiftRightZfBy n val


{-| A bitmask for the lower `n` bits.
-}
lowMask : Int -> Int
lowMask n =
    case n of
        0 ->
            0x00

        1 ->
            0x01

        2 ->
            0x03

        3 ->
            0x07

        4 ->
            0x0F

        5 ->
            0x1F

        6 ->
            0x3F

        7 ->
            0x7F

        8 ->
            0xFF

        9 ->
            0x01FF

        10 ->
            0x03FF

        11 ->
            0x07FF

        12 ->
            0x0FFF

        13 ->
            0x1FFF

        14 ->
            0x3FFF

        15 ->
            0x7FFF

        16 ->
            0xFFFF

        17 ->
            0x0001FFFF

        18 ->
            0x0003FFFF

        19 ->
            0x0007FFFF

        20 ->
            0x000FFFFF

        21 ->
            0x001FFFFF

        22 ->
            0x003FFFFF

        23 ->
            0x007FFFFF

        24 ->
            0x00FFFFFF

        25 ->
            0x01FFFFFF

        26 ->
            0x03FFFFFF

        27 ->
            0x07FFFFFF

        28 ->
            0x0FFFFFFF

        29 ->
            0x1FFFFFFF

        30 ->
            0x3FFFFFFF

        31 ->
            0x7FFFFFFF

        _ ->
            0xFFFFFFFF
