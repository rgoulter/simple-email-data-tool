module Ui.Bulma exposing (..)

import Html as H
import Html.Attributes as A
import Html exposing (Html, div, text, node)
import Html.Attributes exposing (class, type_)




-- VIEW


{-
  See: https://bulma.io/documentation/layout/container/
-}
bulmaCentered : List (Html msg) -> Html msg
bulmaCentered html =
  H.section [class "section"] [div [class "content"] html]


{-
  A bulma message with 'danger' colours.

  The messages's header is the given title.

  The message's body is filled with the given contents.

  See: https://bulma.io/documentation/components/message/
-}
bulmaDangerMessage : String -> List (Html msg) -> Html msg
bulmaDangerMessage title contents =
  let
    messageHeader =
      H.div
        [class "message-header"]
        [H.p [] [text title]]
    messageBody =
      H.div
       [class "message-body"]
       contents
  in
    H.article
      [class "message", class "is-danger"]
      [messageHeader, messageBody]


withStyle : Html msg -> Html msg
withStyle html =
  div []
  [ node "style" [type_ "text/css"]
    [ text "@import url(https://cdn.jsdelivr.net/npm/bulma@0.8.0/css/bulma.min.css);"
    , text "@import url(https://allo-media.github.io/elm-daterange-picker/style.css);"
    ]
  , html
  ]
