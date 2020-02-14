{-
  UI for the Email: content, and note, summary.
-}
module Ui.Email exposing
  ( Model
  , Msg
  , empty
  , init
  , getEmail
  , getFailure
  , setEmail
  , update
  , view
  )

import Email exposing (Email, emailDecoder)

import Html as H
import Html.Attributes as A
import Html exposing (Html, div, text)
import Html.Events exposing (onClick)
import Html.Events.Extra exposing (onChange)

import Http

import Json.Encode as Encode

import Ui.Bulma exposing (bulmaCentered)




-- MODEL


type Content
  = Plain
  | Html


type Model
  = Failure String
  | NoEmail
  | HasEmail { email : Email, loading : Bool, content : Maybe Content }


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
    Just email -> HasEmail { email = email
                           , loading = False
                           , content = defaultContentForEmail email
                           }
    Nothing -> NoEmail




-- UPDATE


type Msg
  = GotUpdatedEmail (Result Http.Error Email)
  | UpdateEmailNote String
  | ShowContent Content


update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    GotUpdatedEmail result ->
      case result of
        Ok updatedEmail ->
          case model of
            HasEmail { email, loading, content } ->
              (HasEmail { email = updatedEmail, loading = False, content = content } , Cmd.none)
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

    ShowContent content ->
      case model of
        HasEmail email -> (HasEmail { email | content = Just content }, Cmd.none)
        _ -> (model, Cmd.none)


    UpdateEmailNote note ->
      case model of
        HasEmail { email, loading, content } ->
          (HasEmail { email = email, loading = True, content = content }, updateEmailNote email note)
        _ -> (model, Cmd.none)




-- VIEW


viewEmailContentTabs : Email -> Maybe Content -> Html Msg
viewEmailContentTabs email selection =
  let
    plainClasses =
      List.map A.class
      <|
      ["tab"] ++
      (if not email.plain then ["disabled"] else []) ++
      (if selection == Just Plain then ["is-active"] else [])
    htmlClasses =
      List.map A.class
      <|
      ["tab"] ++
      (if not email.html then ["disabled"] else []) ++
      (if selection == Just Html then ["is-active"] else [])
    plainTab =
      H.li (plainClasses ++ [onClick (ShowContent Plain)])
           [H.a [] [text "plain"]]
    htmlTab =
      H.li (htmlClasses ++ [onClick (ShowContent Html)])
           [H.a [] [text "html"]]
  in
  div [A.class "tabs"] [H.ul [] [plainTab, htmlTab]]


viewNote : Email -> Html Msg
viewNote email =
  let
    handleChange note =
      UpdateEmailNote note
  in
  H.input [ A.placeholder "Make a note about the email"
          , A.id "note"
          , A.value email.note
          , A.class "input"
          , A.class "is-medium"
          , onChange handleChange
          ]
          []


defaultContentForEmail : Email -> Maybe Content
defaultContentForEmail email =
  case (email.plain, email.html) of
    (False, False) -> Nothing
    (False, True) -> Just Html
    (True, False) -> Just Plain
    (True, True) -> Just Html


viewEmailContent : Email -> Maybe Content -> Html Msg
viewEmailContent email selected =
  let
    baseUri = "/api"
    from = email.from
    timestamp = String.fromInt email.timestamp
    uriForContent contentType =
      (baseUri ++ "/email/" ++ from ++ "/" ++ timestamp ++ "/" ++ contentType)
    defaultSelected = defaultContentForEmail email
    contentToShow =
      case selected of
        Nothing -> defaultSelected
        _ -> selected
    emailUri =
      case contentToShow of
        Nothing -> "about:blank"
        Just Plain -> uriForContent "plain"
        Just Html -> uriForContent "html"
  in
  div [A.class "content"]
      [ viewEmailContentTabs email contentToShow
      , H.iframe [A.src emailUri, A.id "email_content"] []
      ]



view : Model -> List (Html Msg)
view model =
  case model of
    HasEmail { email, loading, content } ->
      [viewEmailContent email content, viewNote email]

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
