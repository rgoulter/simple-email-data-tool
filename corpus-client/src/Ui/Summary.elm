module Ui.Summary exposing (..)

import Array exposing (Array)
import Array

import Email exposing (Email)

import Html as H
import Html.Attributes as A
import Html exposing (Html, div, text)

import List.Extra exposing (gatherEqualsBy)

import Time




-- VIEW


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


timeOfEmail : Email -> Time.Posix
timeOfEmail email =
  Time.millisToPosix (email.timestamp * 1000)


dateStringOfEmail : Email -> String
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


viewSummary : Array Email -> Html msg
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
