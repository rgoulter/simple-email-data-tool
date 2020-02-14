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
import Ui.DateFilter
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


type alias Model
  = { dateFilter : Ui.DateFilter.Model
    , components : (List String)
    }


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
    (dateFilter, dateFilterCmd) = Ui.DateFilter.init ()
  in
  ( { dateFilter = dateFilter, components = components }
  , Cmd.map DateFilterMsg dateFilterCmd
  )


-- UPDATE


type Msg
  = UrlChanged
  | UrlRequested
  | EmailSelectionMsg Ui.EmailSelection.Msg
  | MainMsg Main.Msg
  | DateFilterMsg Ui.DateFilter.Msg


update msg model =
  case msg of
    DateFilterMsg dateFilterMsg ->
      let
        (dateFilter, dateFilterCmd) =
          Ui.DateFilter.update dateFilterMsg model.dateFilter
      in
      ({ model | dateFilter = dateFilter}, Cmd.map DateFilterMsg dateFilterCmd)

    _ -> (model, Cmd.none)



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
  viewComponents model


viewHelpText = div [] [text "No components given. Use components parameter."]


viewComponents { components, dateFilter } =
  case components of
    [] -> viewHelpText
    "datefilter"::_ -> viewDateFilter dateFilter
    component::_ -> viewComponent component

viewSelectEmails : Array Email -> Html Msg
viewSelectEmails emails =
  Ui.EmailSelection.modelFromEmails 1 emails
    |> Ui.EmailSelection.view
    |> Html.map EmailSelectionMsg



viewDateFilter : Ui.DateFilter.Model -> Html Msg
viewDateFilter dateFilter =
  Html.map DateFilterMsg <| Ui.DateFilter.view dateFilter


viewComponent component =
  case component of
    "error" -> bulmaCentered [viewErrorMessage "example error"]
    "emails" ->
      bulmaCentered [viewSelectEmails sampleEmails]
    "loading" -> Html.map MainMsg viewLoading
    _ -> div [] [text (String.concat ["Unknown component: ", component])]
