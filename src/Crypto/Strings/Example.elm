----------------------------------------------------------------------
--
-- Example.elm
-- Example of using billstclair/elm-crypto-strings
-- Copyright (c) 2017 Bill St. Clair <billstclair@gmail.com>
-- Some rights reserved.
-- Distributed under the MIT License
-- See LICENSE.txt
--
----------------------------------------------------------------------


module Crypto.Strings.Example exposing (doDecrypt, doEncrypt)

import Crypto.Strings exposing (decrypt, encrypt)
import Random exposing (Seed, initialSeed)


{-| In a real app,
you would get the time and initialize this in your update function.
And you would save the `Seed` resulting from a call to `doEncrypt`
for the next one.
-}
time : Int
time =
    0


{-| In a real app, this would be user input
-}
passphrase : String
passphrase =
    "My mother's maiden name."


doEncrypt : Int -> String -> Result String ( String, Seed )
doEncrypt time plaintext =
    encrypt (initialSeed time) passphrase plaintext


doDecrypt : String -> Result String String
doDecrypt ciphertext =
    decrypt passphrase ciphertext
