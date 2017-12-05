module Tests exposing (all)

import Expect exposing (Expectation)
import Test exposing (..)


{-| This runs all of your tests.

Each line is for a different result type.

-}
all : Test
all =
    Test.concat <|
        List.concat
            [ List.map doTest intData
            , List.map doTest intResultData
            ]


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
intData : List ( String, Int, Int )
intData =
    [ ( "1+1", 1 + 1, 2 )
    ]


{-| Tests that return Results with integers.
-}
intResultData : List ( String, Result String Int, Result String Int )
intResultData =
    [ ( "Error foo", Err "foo", Err "foo" )
    , ( "Ok 1+1", Ok (1 + 1), Ok 2 )
    ]
