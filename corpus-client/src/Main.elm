module Main exposing (..)

import Browser

import Html as H
import Html exposing (Html, div, text, select, option, node)
import Html.Attributes exposing (class, type_)
import Html.Events exposing (onClick)

import Http

import Json.Decode exposing (Decoder, field, list, map3, string)



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
  | Success (List Email)


type alias Email =
  { from : String
  , datetime : String
  , subject : String
  }


init : () -> (Model, Cmd Msg)
init _ =
  (Loading, getEmails)



-- UPDATE


type Msg
  = FetchEmails
  | GotEmails (Result Http.Error (List Email))


update msg model =
  case msg of
    FetchEmails ->
      (Loading, getEmails)

    GotEmails result ->
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


{-
  A bulma message with 'danger' colours.

  The messages's header is the given title.

  The message's body is filled with the given contents.

  See: https://bulma.io/documentation/components/message/
-}
bulmaDangerMessage title contents =
  let
    messageHeader =
      H.div
        [class "message-header"]
        [H.p [] [text title]]
    messageBody =
      H.div
       [class "message-body"]
       contents
  in
    H.article
      [class "message", class "is-danger"]
      [messageHeader, messageBody]



{-
  See: https://bulma.io/documentation/layout/container/
-}
bulmaCentered html =
  div [class "container"] html


viewErrorMessage message =
  let
    bulmaMessage =
      bulmaDangerMessage
        "Error"
        [text (String.concat ["There was an error: ", message])]
  in
  div [class "error"] [bulmaMessage]


{-
  Modal displaying "loading" above a blank client.

  Used when a GET request is loading.
-}
viewLoading =
  let
    blankPage = viewPage []
    loadingModal =
      div
        [class "modal", class "is-active"]
        [ div [class "modal-background"] []
        , div
            [class "modal-content"]
            [ div
               [class "loading", class "is-size-1", class "has-text-light"]
               [text "Loading"]
            ]
        ]
  in
  div [] [loadingModal, blankPage]


viewSelectEmails emails =
   let
     option_from_email = \{ from, datetime, subject } ->
       option [] [text (datetime ++ " " ++ from ++ ": " ++ subject)]
     options = List.map option_from_email emails
   in
   div [class "select"] [ select [] options]


viewPage emails =
  bulmaCentered [viewSelectEmails emails]


-- HTTP


getEmails : Cmd Msg
getEmails =
  Http.get
    { url = "http://localhost:8901/emails"
    , expect = Http.expectJson GotEmails emailsDecoder
    }

{-
  e.g. of response:
    {
      "status": "success",
      emails: [
        {
          from: "foo1@bar.com",
          date: "2019-01-01T12:00:00+0000",
          subject: "Foo Bar",
        },
      ]
    }
-}
emailsDecoder : Decoder (List Email)
emailsDecoder =
  field "emails" (list emailDecoder)

emailDecoder : Decoder Email
emailDecoder =
  map3 Email
      (field "from" string)
      (field "datetime" string)
      (field "subject" string)
