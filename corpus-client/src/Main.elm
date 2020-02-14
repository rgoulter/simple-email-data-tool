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
      in
      case (Ui.Email.getFailure emailModel, Ui.Email.getEmail emailModel) of
        -- I think this assumes that the model.failure was related to Email,
        -- and not due to other components.
        (Nothing, Nothing) ->
          ( { model
            | email = emailModel
            , failure = Nothing
            }
          , Cmd.map (\c -> EmailMsg index c) emailCmd
          )

        (Nothing, Just updatedEmail) ->
          let
            updatedSelection =
              Ui.EmailSelection.updateEmail model.selection index updatedEmail
          in
          ( { model
            | email = emailModel
            , selection = updatedSelection
            , failure = Nothing
            }
          , Cmd.map (\c -> EmailMsg index c) emailCmd
          )

        (emailFailure, _) ->
          ( { model
            | email = emailModel
            , failure = emailFailure
            }
          , Cmd.map (\c -> EmailMsg index c) emailCmd
          )


    EmailSelectionMsg selectionMsg ->
      let
        (emailSelectionModel, selectionCmd) = Ui.EmailSelection.update selectionMsg model.selection
      in
        case ( Ui.EmailSelection.getFailure emailSelectionModel
             , Ui.EmailSelection.getSelection emailSelectionModel
             ) of
          (Nothing, Just (index, email)) ->
            ( { model
              | email = Ui.Email.setEmail model.email (Just email)
              , selection = emailSelectionModel
              , failure = Nothing
              }
            , Cmd.none
            )

          (Nothing, Nothing) ->
            ( { model
              | selection = emailSelectionModel
              , failure = Nothing
              }
            , Cmd.map EmailSelectionMsg selectionCmd
            )

          (selectionFailure, _) ->
            ( { model
              | selection = emailSelectionModel
              , failure = selectionFailure
              }
            , Cmd.map EmailSelectionMsg selectionCmd
            )

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
  in
    case Ui.EmailSelection.getSelection model.selection of
      Nothing ->
        bulmaCentered ([Html.map EmailSelectionMsg selection] ++
                       (List.map (\e -> Html.map (\_ -> Noop) e) email) ++
                       [summary])
      Just (index, _) ->
        bulmaCentered ([Html.map EmailSelectionMsg selection] ++
                       (List.map (\e -> Html.map (\msg -> EmailMsg index msg) e) email) ++
                       [summary])
