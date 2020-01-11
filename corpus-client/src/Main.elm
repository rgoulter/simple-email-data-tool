module Main exposing (..)

import Browser

import Html exposing (Html, div, text, select, option, node)
import Html.Attributes exposing (class, type_)
import Html.Events exposing (onClick)



-- MAIN


main =
  Browser.sandbox { init = 0, update = update, view = view }



-- UPDATE


type Msg = Never



update msg model =
  model



-- VIEW


withStyle html =
  div []
  [ node "style" [type_ "text/css"]
    [text "@import url(https://cdn.jsdelivr.net/npm/bulma@0.8.0/css/bulma.min.css)"]
  , html
  ]



view model =
  div
   []
   [ div [class "select"]
      [ select [] [ option [] [text "foo"]
                  , option [] [text "bar"]
                  , option [] [text "baz"]
                  ]
      ]
   ]
  |> withStyle
