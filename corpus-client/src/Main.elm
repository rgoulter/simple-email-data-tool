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

        Err error ->
          let
            errorMessage =
              case error of
                Http.BadUrl url -> String.concat ["Bad Url: ", url]
                Http.Timeout -> "Request timed out"
                Http.NetworkError -> "Network error"
                Http.BadStatus statusCode -> String.concat ["Bad status code: ", String.fromInt statusCode]
                Http.BadBody message -> String.concat ["Bad body:", message]
          in
          (Failure (String.concat ["GET /email-addresses failed: ", errorMessage]), Cmd.none)



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.none



-- VIEW


withStyle html =
  div []
  [ node "style" [type_ "text/css"]
    [text "@import url(https://cdn.jsdelivr.net/npm/bulma@0.8.0/css/bulma.min.css)"]
  , html
  ]


view : Model -> Html Msg
view model =
  withStyle (styledView model)


styledView : Model -> Html Msg
styledView model =
  case model of
    Failure message -> viewErrorMessage message

    Loading -> viewLoading

    Success emails ->
      div [] [viewSelectEmails emails]


viewErrorMessage message =
  div [class "error"] [text (String.concat ["There was an error:", message])]


viewLoading =
  div [class "loading"] [text "Loading..."]


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
