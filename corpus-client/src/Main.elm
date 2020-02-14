module Main exposing (..)

import Browser

import Html exposing (Html, div, text)
import Html.Attributes exposing (class)

import Ui.Bulma exposing (bulmaCentered, bulmaDangerMessage, withStyle)
import Ui.Email
import Ui.EmailSelection
import Ui.Summary exposing (viewSummary)




-- MAIN


main =
  Browser.element
    { init = init
    , update = update
    , subscriptions = subscriptions
    , view = view
    }




-- MODEL


type alias Model
  = { failure : Maybe String
    , selection : Ui.EmailSelection.Model
    , email : Ui.Email.Model
    }


init : () -> (Model, Cmd Msg)
init _ =
  let
    (initSelection, initCmd) = Ui.EmailSelection.init ()
    (initEmail, _) = Ui.Email.init ()
  in
  ( { failure = Nothing, selection = initSelection, email = initEmail }
  , Cmd.map EmailSelectionMsg initCmd
  )




-- UPDATE


type Msg
  = EmailSelectionMsg Ui.EmailSelection.Msg
  | EmailMsg Int Ui.Email.Msg
  | Noop


update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    EmailMsg index emailMsg ->
      let
        (emailModel, emailCmd) = Ui.Email.update emailMsg model.email
        mainCmd = Cmd.map (\c -> EmailMsg index c) emailCmd
        emailFailure = Ui.Email.getFailure emailModel
        -- Lift the failure from Ui.Email into the main Model
        updatedModel = { model | email = emailModel, failure = emailFailure }
      in
      case Ui.Email.getEmail emailModel of
        -- Email.Msg might indicate that the Ui.Email widget updated the
        -- Email, so the Ui.EmailSelection model needs to be updated.
        Just updatedEmail ->
          ( { updatedModel
            | selection = Ui.EmailSelection.setSelection model.selection index updatedEmail
            }
          , mainCmd
          )

        -- Since the Ui.Email widget doesn't have an email selected,
        --  the update to the Model is straightforward.
        Nothing -> (updatedModel, mainCmd)


    EmailSelectionMsg selectionMsg ->
      let
        (emailSelectionModel, selectionCmd) = Ui.EmailSelection.update selectionMsg model.selection
        selectionFailure = Ui.EmailSelection.getFailure emailSelectionModel
        mainCmd = Cmd.map EmailSelectionMsg selectionCmd
        updatedModel =
          { model
          | selection = emailSelectionModel
          , failure = selectionFailure
          }
      in
      case Ui.EmailSelection.getSelection emailSelectionModel of
        -- EmailSelectionMsg with a selection might indicate that the
        -- selected Email changed, so update the Ui.Email widget
        Just (index, email) ->
          ( { updatedModel
            | email = Ui.Email.setEmail model.email email
            }
          , mainCmd
          )

        -- Since the Ui.EmailSelection widget doesn't have a selected
        --  Email, the update to the model is straightforward.
        Nothing -> (updatedModel, mainCmd)


    Noop -> (model, Cmd.none)




-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.none




-- VIEW


view : Model -> Html Msg
view model =
  withStyle (styledView model)


styledView : Model -> Html Msg
styledView model =
  if Ui.EmailSelection.isLoading model.selection then
   viewLoading
  else
    case model.failure of
      Just message -> viewErrorMessage message
      Nothing -> viewNonLoadingNonFailing model


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
    blankPage = viewNonLoadingNonFailing { failure = Nothing
                                         , selection = Ui.EmailSelection.empty
                                         , email = Ui.Email.empty
                                         }
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


viewNonLoadingNonFailing model =
  let
    selection = Ui.EmailSelection.view model.selection
    email = Ui.Email.view model.email
    summary = viewSummary (Ui.EmailSelection.getEmails model.selection)
    emailMsgToMsg =
      case Ui.EmailSelection.getSelection model.selection of
        Nothing -> \e -> Html.map (\_ -> Noop) e
        Just (index, _) -> \e -> Html.map (\msg -> EmailMsg index msg) e
  in
    bulmaCentered ([Html.map EmailSelectionMsg selection] ++
                   (List.map emailMsgToMsg email) ++
                   [summary])
