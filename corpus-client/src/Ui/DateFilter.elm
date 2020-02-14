{-
  UI for the Date Filter
-}
module Ui.DateFilter exposing
  ( Model
  , Msg
  , empty
  , getRange
  , init
  , update
  , view
  )

import DateRangePicker as Picker
import DateRangePicker.Range as Range

import Html as H
import Html.Attributes as A
import Html exposing (Html, div, text)
import Html.Events as E

import Time

import Ui.Bulma exposing (bulmaCentered)




-- MODEL


type alias Model
  = { picker : Picker.State }


init : () -> (Model, Cmd Msg)
init _ =
  let
    defConfig = Picker.defaultConfig
    config = { defConfig
             | inputClass = "input"
             , noRangeCaption = "Click to Filter by Date"
             }
    picker =
      Picker.init config Nothing
  in
  ( { picker = picker }
  , Picker.now PickerChanged picker
  )


empty : Model
empty =
  let
    picker = Picker.init Picker.defaultConfig Nothing
  in
    { picker = picker }


getRange : Model -> Maybe (Time.Posix, Time.Posix)
getRange model =
  let
    range = Picker.getRange model.picker
  in
    Maybe.map (\r -> (Range.beginsAt r, Range.endsAt r)) range




-- UPDATE


type Msg
  = PickerChanged Picker.State


update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    PickerChanged state ->
      ({ model | picker = state }, Cmd.none)



-- VIEW


view : Model -> Html Msg
view model =
  Picker.view PickerChanged model.picker
