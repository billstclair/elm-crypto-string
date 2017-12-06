module Tests exposing (all)

import Crypto.String exposing (Key, decrypt, encrypt, expandKeyString)
import Expect exposing (Expectation)
import Test exposing (..)


{-| This runs all of your tests.

Each line is for a different result type.

-}
all : Test
all =
    Test.concat <|
        List.concat
            [ List.map doTest <|
                case key of
                    Ok k ->
                        stringData k

                    Err msg ->
                        [ ( "badkey", "The key was bad:", msg ) ]
            ]


key : Result String Key
key =
    expandKeyString
        "000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f"


log =
    Debug.log


{-| change to True to log JSON input & output results
-}
enableLogging : Bool
enableLogging =
    False


maybeLog : String -> a -> a
maybeLog label value =
    if enableLogging then
        log label value
    else
        value


expectResult : Result err a -> Result err a -> Expectation
expectResult sb was =
    case maybeLog "  result" was of
        Err err ->
            case sb of
                Err _ ->
                    Expect.true "You shouldn't ever see this." True

                Ok _ ->
                    Expect.false (toString err) True

        Ok wasv ->
            case sb of
                Err _ ->
                    Expect.false "Expected an error but didn't get one." True

                Ok sbv ->
                    Expect.equal sbv wasv


doTest : ( String, a, a ) -> Test
doTest ( name, was, sb ) =
    test name
        (\_ ->
            expectResult (Ok sb) (Ok was)
        )


doResultTest : ( String, Result String a, Result String a ) -> Test
doResultTest ( name, was, sb ) =
    test name
        (\_ ->
            expectResult sb was
        )


{-| Tests that return integers
-}
stringData : Key -> List ( String, String, String )
stringData key =
    [ ( "encrypt", encrypt key "foo", "foo" )
    ]
