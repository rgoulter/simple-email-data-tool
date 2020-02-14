{-
  "Showcases" the components used by this Elm client,
  to facilitate component testing and development.
-}
module Showcase exposing (..)

import Array exposing (Array)

import Browser
import Browser.Navigation as Nav

import Html exposing (Html, div, text, select, option, node)
import Html.Attributes exposing (class, type_)
import Html.Events exposing (onClick)

import Http

import Json.Decode exposing (Decoder, field, list, string)

import Url
import Url.Parser exposing ((<?>), (</>))
import Url.Parser as Url
import Url.Parser.Query as Query

import Email exposing (Email, sampleEmails)
import Ui.Bulma exposing (bulmaCentered, withStyle)
import Ui.EmailSelection
import Main exposing
  ( viewErrorMessage
  , viewLoading
  )



-- MAIN


main =
  Browser.application
    { init = init
    , view = view
    , update = update
    , subscriptions = subscriptions
    , onUrlChange = \_ -> UrlChanged
    , onUrlRequest = \_ -> UrlRequested
    }



-- MODEL


type Model
  = ShowComponents (List String)


componentsFromQuery : Url.Url -> List String
componentsFromQuery url =
  let
    componentsStr = Query.map (Maybe.withDefault "") (Query.string "components")

    components = Query.map (String.split ",") componentsStr

    -- QUESTION: Can we avoid hardcoding this fragment parsing?
    reactorRoute = Url.s "src" </> Url.s "Showcase.elm"
    maybeComponents = Url.parse (reactorRoute <?> components) url
  in
    Maybe.withDefault [] maybeComponents


init : () -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init _ url key =
  let
    components = componentsFromQuery url
  in
  (ShowComponents components, Cmd.none)


-- UPDATE


type Msg
  = UrlChanged
  | UrlRequested
  | EmailSelectionMsg Ui.EmailSelection.Msg
  | MainMsg Main.Msg


update msg model = (model, Cmd.none)



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.none



-- VIEW


view model =
  { title = "Component Showcase"
  , body = [withStyle (styledView model)]
  }


styledView : Model -> Html Msg
styledView model =
  case model of
    ShowComponents components ->
      viewComponents components


viewHelpText = div [] [text "No components given. Use components parameter."]


viewComponents components =
  case components of
    [] -> viewHelpText
    component::_ -> viewComponent component

viewSelectEmails : Array Email -> Html Msg
viewSelectEmails emails =
  Ui.EmailSelection.modelFromEmails 1 emails
    |> Ui.EmailSelection.view
    |> Html.map EmailSelectionMsg


viewComponent component =
  case component of
    "error" -> bulmaCentered [viewErrorMessage "example error"]
    "emails" ->
      bulmaCentered [viewSelectEmails sampleEmails]
    "loading" -> Html.map MainMsg viewLoading
    _ -> div [] [text (String.concat ["Unknown component: ", component])]
