{-
  UI for the Email: content, and note, summary?.
-}
module Ui.Email exposing (..)

import Email exposing (Email, emailDecoder)

import Html as H
import Html.Attributes as A
import Html exposing (Html, div, text)
import Html.Events.Extra exposing (onChange)

import Http

import Json.Encode as Encode

import Ui.Bulma exposing (bulmaCentered)




-- MODEL


type Model
  = Failure String
  | NoEmail
  | HasEmail { email : Email, loading : Bool }


init : () -> (Model, Cmd Msg)
init _ =
  (NoEmail, Cmd.none)


empty : Model
empty = NoEmail


getFailure : Model -> Maybe String
getFailure model =
  case model of
    Failure message -> Just message
    _ -> Nothing


getEmail : Model -> Maybe Email
getEmail model =
  case model of
    HasEmail { email } -> Just email
    _ -> Nothing


setEmail : Model -> Maybe Email -> Model
setEmail model maybeEmail =
  -- Unhandled race condition: 'loading' an email, but set a new one
  case maybeEmail of
    Just email -> HasEmail { email = email, loading = False }
    Nothing -> NoEmail




-- UPDATE


type Msg
  = GotUpdatedEmail (Result Http.Error Email)
  | UpdateEmailNote String


update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    GotUpdatedEmail result ->
      case result of
        Ok updatedEmail ->
          case model of
            HasEmail { email, loading } ->
              (HasEmail { email = updatedEmail, loading = False } , Cmd.none)
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

    UpdateEmailNote note ->
      case model of
        HasEmail { email, loading } ->
          (HasEmail { email = email, loading = True }, updateEmailNote email note)
        _ -> (model, Cmd.none)




-- VIEW


viewEmailContent : Email -> Html msg
viewEmailContent email =
  let
    base_uri = "/api"
    from = email.from
    timestamp = String.fromInt email.timestamp
    email_uri =  (base_uri ++ "/email/" ++ from ++ "/" ++ timestamp ++ "/plain")
  in
  H.iframe [A.src email_uri, A.id "email_content"] []


viewNote : Email -> Html Msg
viewNote email =
  let
    handleChange note =
      UpdateEmailNote note
  in
  H.input [ A.placeholder "Make a note about the email"
          , A.id "note"
          , A.value email.note
          , onChange handleChange
          ]
          []


view : Model -> List (Html Msg)
view model =
  case model of
    HasEmail { email, loading } ->
      [viewEmailContent email, viewNote email]

    -- ASSUMEs that Failure case is handled higher up.
    _ ->
      [text "no email selected"]




-- HTTP


updateEmailNote : Email -> String -> Cmd Msg
updateEmailNote email note =
  let
    url =
      String.concat
        [ "/api/email/"
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
    , expect =  Http.expectJson GotUpdatedEmail emailDecoder
    , timeout = Nothing
    , tracker = Nothing
    }
