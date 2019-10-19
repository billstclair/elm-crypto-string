----------------------------------------------------------------------
--
-- example.elm
-- Example of using the billstclair/elm-crypto-string
-- Copyright (c) 2017-2019 Bill St. Clair <billstclair@gmail.com>
-- Some rights reserved.
-- Distributed under the MIT License
-- See LICENSE.txt
--
----------------------------------------------------------------------


module Main exposing (Model, Msg(..), b, br, btext, decrypt, encrypt, init, main, update, view)

import Browser
import Crypto.Strings as Strings
import Debug exposing (log)
import Html
    exposing
        ( Attribute
        , Html
        , a
        , br
        , button
        , div
        , h2
        , input
        , option
        , p
        , select
        , span
        , table
        , td
        , text
        , textarea
        , th
        , tr
        )
import Html.Attributes
    exposing
        ( checked
        , cols
        , disabled
        , href
        , name
        , rows
        , selected
        , size
        , style
        , target
        , type_
        , value
        )
import Html.Events exposing (on, onClick, onInput, targetValue)
import List.Extra as LE
import Random exposing (Seed, initialSeed)
import Task
import Time exposing (Posix)


main =
    Browser.element
        { init = \() -> init
        , view = view
        , update = update
        , subscriptions = \_ -> Sub.none
        }


type alias Model =
    { passphrase : String
    , plaintext : String
    , ciphertext : String
    , seed : Seed
    }


type Msg
    = InitializeSeed Posix
    | SetPassphrase String
    | SetPlaintext String
    | SetCiphertext String
    | Encrypt ()
    | Decrypt


init : ( Model, Cmd Msg )
init =
    ( { passphrase = "23 Skidoo!"
      , plaintext = "Four score and seven years ago, they lived happily ever after."
      , ciphertext = ""
      , seed = initialSeed 0
      }
    , Task.perform InitializeSeed Time.now
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        InitializeSeed posix ->
            ( { model | seed = initialSeed <| Time.posixToMillis posix }
            , Task.perform Encrypt <| Task.succeed ()
            )

        SetPassphrase passphrase ->
            ( { model | passphrase = passphrase }
            , Cmd.none
            )

        SetPlaintext plaintext ->
            ( { model | plaintext = plaintext }
            , Cmd.none
            )

        SetCiphertext ciphertext ->
            ( { model | ciphertext = ciphertext }
            , Cmd.none
            )

        Encrypt _ ->
            ( encrypt model
            , Cmd.none
            )

        Decrypt ->
            ( decrypt model
            , Cmd.none
            )


encrypt : Model -> Model
encrypt model =
    let
        passphrase =
            model.passphrase

        plaintext =
            model.plaintext

        ( ciphertext, seed ) =
            case Strings.encrypt model.seed passphrase plaintext of
                Err msg ->
                    ( "Error: " ++ msg, model.seed )

                Ok textAndSeed ->
                    textAndSeed
    in
    { model
        | ciphertext = ciphertext
        , seed = seed
    }


decrypt : Model -> Model
decrypt model =
    let
        passphrase =
            model.passphrase

        ciphertext =
            model.ciphertext

        plaintext =
            case Strings.decrypt passphrase ciphertext of
                Err msg ->
                    "Error: " ++ msg

                Ok text ->
                    text
    in
    { model | plaintext = plaintext }


br : Html Msg
br =
    Html.br [] []


b : List (Html Msg) -> Html Msg
b elements =
    Html.b [] elements


btext : String -> Html Msg
btext str =
    b [ text str ]


view : Model -> Html Msg
view model =
    div
        [ style "margin-left" "3em"
        ]
        [ h2 [] [ text "Elm.Crypto.Strings Example" ]
        , p []
            [ text "This is an example of AES encryption written in pure Elm." ]
        , p []
            [ btext "Passphrase: "
            , input
                [ type_ "text"
                , value model.passphrase
                , size 30
                , onInput SetPassphrase
                ]
                []
            ]
        , p []
            [ btext "Plaintext:"
            , br
            , textarea
                [ cols 80
                , rows 10
                , value model.plaintext
                , onInput SetPlaintext
                ]
                []
            , br
            , button [ onClick <| Encrypt () ]
                [ text "Encrypt" ]
            ]
        , p []
            [ btext "Ciphertext:"
            , br
            , textarea
                [ cols 80
                , rows 10
                , value model.ciphertext
                , onInput SetCiphertext
                , style "font-family" "monospace"
                ]
                []
            , br
            , button [ onClick Decrypt ]
                [ text "Decrypt" ]
            ]
        , p []
            [ a [ href "http://elm-lang.org" ]
                [ text "Elm" ]
            , text " "
            , a [ href "https://github.com/billstclair/elm-crypto-string" ]
                [ text "GitHub" ]
            ]
        ]
