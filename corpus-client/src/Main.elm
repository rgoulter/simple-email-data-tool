module Main exposing (..)

import Browser

import Html exposing (Html, div, text, select, option, node)
import Html.Attributes exposing (class, type_)
import Html.Events exposing (onClick)

import Http

import Json.Decode exposing (Decoder, field, list, string)



-- MAIN


main =
  Browser.element
    { init = init
    , update = update
    , subscriptions = subscriptions
    , view = view
    }


-- MODEL


type Model
  = Failure String
  | Loading
  | Success (List String)


init : () -> (Model, Cmd Msg)
init _ =
  (Loading, getEmailAddresses)



-- UPDATE


type Msg
  = FetchEmailAddresses
  | GotEmailAddresses (Result Http.Error (List String))


update msg model =
  case msg of
    FetchEmailAddresses ->
      (Loading, getEmailAddresses)

    GotEmailAddresses result ->
      case result of
        Ok emails ->
          (Success emails, Cmd.none)

        Err _ ->
          (Failure "An error occurred", Cmd.none)



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.none



-- VIEW


view : Model -> Html Msg
view model =
  div []
  [ node "style" [type_ "text/css"]
    [text "@import url(https://cdn.jsdelivr.net/npm/bulma@0.8.0/css/bulma.min.css)"]
  , (styledView model)
  ]


styledView : Model -> Html Msg
styledView model =
  case model of
    Failure message ->
      div [] [text (String.concat ["There was an error:", message])]

    Loading ->
      text "Loading..."

    Success emails ->
      div [] [viewSelectEmails emails]


viewSelectEmails emails =
   let
     options = List.map (\e -> option [] [text e]) emails
   in
   div [class "select"] [ select [] options]



-- HTTP


getEmailAddresses : Cmd Msg
getEmailAddresses =
  Http.get
    { url = "http://localhost:8901/email-addresses"
    , expect = Http.expectJson GotEmailAddresses emailsDecoder
    }

{-
  e.g. of response:
    {
      "status": "success",
      "emails": [
        "foo1@bar.com",
        "foo2@bar.com",
        "foo3@baz.com"
      ]
    }
-}
emailsDecoder : Decoder (List String)
emailsDecoder =
  field "emails" (list string)
