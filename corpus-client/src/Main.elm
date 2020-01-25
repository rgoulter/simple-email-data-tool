module Main exposing (..)

import Array exposing (Array)
import Array

import Browser

import Html as H
import Html.Attributes as A
import Html exposing (Html, div, text, select, option, node)
import Html.Attributes exposing (class, type_)
import Html.Events exposing (onClick, onInput)

import Http

import Json.Decode as Decode
import Json.Decode exposing (Decoder, array, field, int, map4, string)



-- MAIN


main =
  Browser.element
    { init = init
    , update = update
    , subscriptions = subscriptions
    , view = view
    }




-- MODEL


type alias Emails =
  { selected : Int
  , emails : Array Email
  }


type Model
  = Failure String
  | Loading
  | Success Emails


type alias Email =
  { from : String
  , datetime : String
  , subject : String
  , timestamp : Int
  }


init : () -> (Model, Cmd Msg)
init _ =
  (Loading, getEmails)




-- UPDATE


type Msg
  = FetchEmails
  | GotEmails (Result Http.Error (Array Email))
  | Noop
  | SelectEmail Int


update msg model =
  case msg of
    FetchEmails ->
      (Loading, getEmails)

    GotEmails result ->
      case result of
        Ok emails ->
          -- n.b. unhandled case if emails is empty!
          (Success { selected = 0, emails = emails }, Cmd.none)

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

    Noop -> (model, Cmd.none)

    SelectEmail index ->
      case model of
        Success emails -> (Success { emails | selected = index }, Cmd.none)
        _ -> (model, Cmd.none)




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
      viewPage emails


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
  H.section [class "section"] [div [class "content"] html]


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
    blankPage = viewPage { selected = 0, emails = Array.empty }
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
     option_from_email = \index { from, datetime, subject } ->
       option [A.value (String.fromInt index)]
              [text (datetime ++ " " ++ from ++ ": " ++ subject)]
     options = Array.toList (Array.indexedMap option_from_email emails)
     handleInput msg =
       case String.toInt msg of
         Nothing -> Noop
         Just index -> SelectEmail index
   in
   div [class "select"]
       [select [A.id "emails", onInput handleInput] options]


viewEmailContent email =
  let
    base_uri = "http://localhost:8901"
    from = email.from
    timestamp = String.fromInt email.timestamp
    email_uri =  (base_uri ++ "/email/" ++ from ++ "/" ++ timestamp ++ "/plain")
  in
  H.iframe [A.src email_uri, A.id "email_content"] []


viewPage { selected, emails } =
  bulmaCentered [ viewSelectEmails emails
                , let
                    maybeEmail = Array.get selected emails
                  in
                  Maybe.withDefault (text "bad index")
                                    (Maybe.map viewEmailContent maybeEmail)
                ]




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
          timestamp: 1546344060,
          datetime: "2019-01-01T12:00:00+0000",
          subject: "Foo Bar",
          plain: true,
          html: false,
          note: "",
        },
      ]
    }
-}
emailsDecoder : Decoder (Array Email)
emailsDecoder =
  field "emails" (array emailDecoder)


emailDecoder : Decoder Email
emailDecoder =
  map4 Email
      (field "from" string)
      (field "datetime" string)
      (field "subject" string)
      (field "timestamp" int)
