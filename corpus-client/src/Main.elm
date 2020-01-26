module Main exposing (..)

import Array exposing (Array)
import Array

import Browser

import Html as H
import Html.Attributes as A
import Html exposing (Html, div, text, select, option, node)
import Html.Attributes exposing (class, type_)
import Html.Events exposing (onClick, onInput)
import Html.Events.Extra exposing (onChange)

import Http

import Json.Decode as Decode
import Json.Decode exposing (Decoder, array, field, int, string)
import Json.Encode as Encode

import List.Extra exposing (gatherEqualsBy)

import Time



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
  , loadingEmail : Bool
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
  , note : String
  }


init : () -> (Model, Cmd Msg)
init _ =
  (Loading, getEmails)




-- UPDATE


type Msg
  = FetchEmails
  | GotEmails (Result Http.Error (Array Email))
  | GotUpdatedEmail (Result Http.Error (Int, Email))
  | Noop
  | SelectEmail Int
  | UpdateEmailNote Int String


update msg model =
  case msg of
    FetchEmails ->
      (Loading, getEmails)

    GotEmails result ->
      case result of
        Ok emails ->
          -- n.b. unhandled case if emails is empty!
          (Success { selected = 0, emails = emails, loadingEmail = False }, Cmd.none)

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

    GotUpdatedEmail result ->
      case result of
        Ok (index, email) ->
          case model of
            Success emails ->
              ( Success
                { emails
                | emails = Array.set index email emails.emails
                , loadingEmail = False
                }
              , Cmd.none
              )
            _ -> (model, Cmd.none)

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
          (Failure (String.concat ["PATCH /email/<from>/<timestamp>/ failed: ", errorMessage]), Cmd.none)

    Noop -> (model, Cmd.none)

    SelectEmail index ->
      case model of
        Success emails -> (Success { emails | selected = index }, Cmd.none)
        _ -> (model, Cmd.none)

    UpdateEmailNote index note ->
      case model of
        Success emails ->
          case Array.get index emails.emails of
            Nothing -> (model, Cmd.none)
            Just email ->
              (Success {emails | loadingEmail = True}, updateEmailNote index email note)
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
     humanFriendlyEmailString datetime from subject =
       datetime ++ " " ++ from ++ ": " ++ subject
     option_from_email = \index { from, datetime, subject } ->
       option [A.value (String.fromInt index)]
              [text (humanFriendlyEmailString datetime from subject)]
     options = Array.toList (Array.indexedMap option_from_email emails)
     handleInput msg =
       case String.toInt msg of
         Nothing -> Noop
         Just index -> SelectEmail index
   in
   div [class "select"]
       [select [A.id "emails", onChange handleInput] options]


viewEmailContent email =
  let
    base_uri = "http://localhost:8901"
    from = email.from
    timestamp = String.fromInt email.timestamp
    email_uri =  (base_uri ++ "/email/" ++ from ++ "/" ++ timestamp ++ "/plain")
  in
  H.iframe [A.src email_uri, A.id "email_content"] []


viewNote index email =
  let
    handleChange note =
      UpdateEmailNote index note
  in
  H.input [ A.placeholder "Make a note about the email"
          , A.id "note"
          , A.value email.note
          , onChange handleChange
          ]
          []



toDateString : Time.Posix -> String
toDateString time =
  let
    -- Hardcoded for convenience
    tz = Time.customZone 7 []
    toMM month =
      case month of
        Time.Jan -> "01"
        Time.Feb -> "02"
        Time.Mar -> "03"
        Time.Apr -> "04"
        Time.May -> "05"
        Time.Jun -> "06"
        Time.Jul -> "07"
        Time.Aug -> "08"
        Time.Sep -> "09"
        Time.Oct -> "10"
        Time.Nov -> "11"
        Time.Dec -> "12"
  in
  String.fromInt (Time.toYear tz time)
  ++ "-" ++
  toMM (Time.toMonth tz time)
  ++ "-" ++
  String.padLeft 2 '0' (String.fromInt (Time.toDay tz time))


timeOfEmail email =
  Time.millisToPosix (email.timestamp * 1000)


dateStringOfEmail email =
  toDateString (timeOfEmail email)


groupEmailsByDate : Array Email -> List (String, (List Email))
groupEmailsByDate emails =
   let
     emailsList = Array.toList emails
     gatheredByDateString = gatherEqualsBy dateStringOfEmail emailsList
   in
     -- This isn't quite as pretty as I'd like
     List.map (\(e, es) -> (dateStringOfEmail e, e :: es)) gatheredByDateString


viewSummary : Array Email -> Html Msg
viewSummary emails =
  let
    humanFriendlyEmailString from subject =
      from ++ ": " ++ subject
    emailsWithNotes = Array.filter (\e -> not (String.isEmpty e.note)) emails
    noteFromEmail email =
      email.note ++
      "\n# " ++
      (humanFriendlyEmailString email.from email.subject)
    notesPerDate (dateString, emailsOnDate) =
      dateString ++ "\n" ++ (String.join "\n" (List.map noteFromEmail emailsOnDate))
    summary = String.join "\n\n" (List.map notesPerDate (groupEmailsByDate emailsWithNotes))
  in
  div [A.id "summary"] [H.pre [] [text summary]]


viewPage { selected, emails } =
  case Array.get selected emails of
    Nothing ->
      bulmaCentered [ viewSelectEmails emails
                    , text "bad index"
                    ]
    Just selectedEmail ->
      bulmaCentered [ viewSelectEmails emails
                    , viewEmailContent selectedEmail
                    , viewNote selected selectedEmail
                    , viewSummary emails
                    ]




-- HTTP


getEmails : Cmd Msg
getEmails =
  Http.get
    { url = "http://localhost:8901/emails"
    , expect = Http.expectJson GotEmails emailsDecoder
    }


updateEmailNote index email note =
  let
    url =
      String.concat
        [ "http://localhost:8901/email/"
        , email.from
        , "/"
        , String.fromInt email.timestamp
        ]
    patchJson = Encode.object [("note", Encode.string note)]
  in
  Http.request
    { method = "PATCH"
    , headers = []
    , url = url
    , body = Http.jsonBody patchJson
    , expect =  Http.expectJson GotUpdatedEmail (patchedEmailDecoder index)
    , timeout = Nothing
    , tracker = Nothing
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


patchedEmailDecoder : Int -> Decoder (Int, Email)
patchedEmailDecoder index =
  Decode.map (\email -> (index, email)) emailDecoder


emailDecoder : Decoder Email
emailDecoder =
  let
    -- Simpler to duplicate Email than to
    -- depend on the positional arguments of Email
    mkEmail from datetime subject timestamp note =
      { from = from
      , datetime = datetime
      , subject = subject
      , timestamp = timestamp
      , note = note
      }
  in
  Decode.map5
    mkEmail
    (field "from" string)
    (field "datetime" string)
    (field "subject" string)
    (field "timestamp" int)
    (field "note" string)
