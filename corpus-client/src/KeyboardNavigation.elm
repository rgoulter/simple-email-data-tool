module KeyboardNavigation exposing (..)

import Json.Decode as Decode




type Direction
  = Previous
  | Next


keyDecoder : (Direction -> msg) -> Decode.Decoder msg
keyDecoder msgForDirection =
  let
    maybeDirection =
      Decode.map2
      (\key isAltDown ->
         case (key, isAltDown) of
           ("j", True) -> Just Next
           ("k", True) -> Just Previous
           _ -> Nothing)
      (Decode.field "key" Decode.string)
      (Decode.field "altKey" Decode.bool)
    msg maybeDir =
      case maybeDir of
        Nothing -> Decode.fail "not alt+j or alt+k"
        Just direction -> Decode.succeed (msgForDirection direction)
  in
    maybeDirection |> Decode.andThen msg
