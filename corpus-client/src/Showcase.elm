{-
  "Showcases" the components used by this Elm client,
  to facilitate component testing and development.
-}
module Showcase exposing (..)

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

import Main exposing
  ( Email
  , bulmaCentered
  , viewErrorMessage
  , viewLoading
  , viewSelectEmails
  , withStyle
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


type Msg = UrlChanged
         | UrlRequested


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


viewComponent component =
  case component of
    "error" -> bulmaCentered [viewErrorMessage "example error"]
    "emails" ->
      bulmaCentered [viewSelectEmails [ { from = "foo@bar.com", datetime = "2020-01-01", subject = "foo" }
                                      , { from = "bar@baz.com", datetime = "2020-01-01", subject = "foo" }
                                      , { from = "baz@foo.com", datetime = "2020-01-01", subject = "foo" }
                                      ]]
    "loading" -> viewLoading
    _ -> div [] [text (String.concat ["Unknown component: ", component])]
