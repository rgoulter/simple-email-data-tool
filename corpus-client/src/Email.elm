module Email exposing (..)

import Array exposing (Array)

import Json.Decode as Decode
import Json.Decode exposing (Decoder, array, field, int, string)


-- MODEL


type alias Email =
  { from : String
  , datetime : String
  , subject : String
  , timestamp : Int
  , note : String
  }




-- JSON DECODE


{-
  e.g. of response:
    {
      "status": "success",
      emails: [
        {
          from: "foo1@bar.com",
          timestamp: 1546344060,
          datetime: "2019-01-01T12:00:00+0000",
          subject: "Foo Bar",
          plain: true,
          html: false,
          note: "",
        },
      ]
    }
-}
emailsDecoder : Decoder (Array Email)
emailsDecoder =
  field "emails" (array emailDecoder)


emailDecoder : Decoder Email
emailDecoder =
  let
    -- Simpler to duplicate Email than to
    -- depend on the positional arguments of Email
    mkEmail from datetime subject timestamp note =
      { from = from
      , datetime = datetime
      , subject = subject
      , timestamp = timestamp
      , note = note
      }
  in
  Decode.map5
    mkEmail
    (field "from" string)
    (field "datetime" string)
    (field "subject" string)
    (field "timestamp" int)
    (field "note" string)
