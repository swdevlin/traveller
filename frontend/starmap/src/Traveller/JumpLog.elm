module Traveller.JumpLog exposing
    ( Draft
    , JumpLog
    , LastJump
    , ParsecOption
    , SectorOption
    , ShipOption
    , addDays
    , compareNewestFirst
    , daysBetween
    , daysPerYear
    , defaultJumpRange
    , defaultTravelDays
    , encodeDraft
    , errorsDecoder
    , formatDate
    , hexDistance
    , jumpDecoder
    , lastJumpDecoder
    , minimumTravelDays
    , parsecDecoder
    , previousArrival
    , sectorDecoder
    , sectorInRange
    , shipDecoder
    )

{-| Data types, decoders and pure helpers for the starmap jump log table and
its referee-only add/edit form. The HTTP round trips and view live in
`Traveller.JumpLogPanel`; everything here is pure so it can be unit tested.

The endpoints are served by `Api::JumpLogsController` (`GET/POST /jumps`,
`PATCH /jumps/:id`), `Api::ShipsController`, `Api::SectorsController` and
`Api::ParsecsController`.

-}

import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline exposing (optional, required)
import Json.Encode as Encode


{-| The jump rating assumed for a ship without one, as in the Rails form.
-}
defaultJumpRange : Int
defaultJumpRange =
    4


{-| A jump takes at least this long unless it is a misjump. Matches
`JumpLog::MINIMUM_TRAVEL_DAYS` in Rails, which enforces it.
-}
minimumTravelDays : Int
minimumTravelDays =
    6


daysPerYear : Int
daysPerYear =
    365


{-| The number of days a typical jump takes. The Rails form pre-fills the
arrival date this far after departure.
-}
defaultTravelDays : Int
defaultTravelDays =
    7


type alias JumpLog =
    { id : Int
    , sequence : Int
    , shipId : Int
    , shipName : String
    , departYear : Int
    , departDay : Int
    , arriveYear : Int
    , arriveDay : Int
    , fromParsecId : Int
    , fromSectorName : String
    , fromHex : String
    , toParsecId : Int
    , toSectorName : String
    , toHex : String
    , misjump : Bool
    , notes : String
    }


type alias ShipOption =
    { id : Int
    , name : String
    , jumpDrive : Maybe Int
    }


type alias SectorOption =
    { id : Int
    , name : String
    , x : Int
    , y : Int
    }


type alias ParsecOption =
    { id : Int
    , hexCode : String
    , x : Int
    , y : Int
    , systemName : Maybe String
    }


type alias LastJump =
    { parsecId : Int
    , sectorId : Int
    , arriveYear : Int
    , arriveDay : Int
    }


{-| The editable fields, as sent to the API.
-}
type alias Draft =
    { shipId : Int
    , fromParsecId : Int
    , toParsecId : Int
    , departYear : Int
    , departDay : Int
    , arriveYear : Int
    , arriveDay : Int
    , misjump : Bool
    , notes : String
    }



-- DECODERS


jumpDecoder : Decoder JumpLog
jumpDecoder =
    Decode.succeed JumpLog
        |> required "id" Decode.int
        |> optional "sequence" Decode.int 0
        |> required "ship_id" Decode.int
        |> optional "ship_name" Decode.string ""
        |> required "depart_year" Decode.int
        |> required "depart_day" Decode.int
        |> required "arrive_year" Decode.int
        |> required "arrive_day" Decode.int
        |> required "from_parsec_id" Decode.int
        |> required "from_sector_name" Decode.string
        |> required "from_hex_code" Decode.string
        |> required "to_parsec_id" Decode.int
        |> required "to_sector_name" Decode.string
        |> required "to_hex_code" Decode.string
        |> required "misjump" Decode.bool
        |> optional "notes" nullableString ""


nullableString : Decoder String
nullableString =
    Decode.nullable Decode.string
        |> Decode.map (Maybe.withDefault "")


shipDecoder : Decoder ShipOption
shipDecoder =
    Decode.map3 ShipOption
        (Decode.field "id" Decode.int)
        (Decode.field "name" Decode.string)
        (Decode.field "jump_drive" (Decode.nullable Decode.int))


sectorDecoder : Decoder SectorOption
sectorDecoder =
    Decode.map4 SectorOption
        (Decode.field "id" Decode.int)
        (Decode.field "name" Decode.string)
        (Decode.field "x" Decode.int)
        (Decode.field "y" Decode.int)


parsecDecoder : Decoder ParsecOption
parsecDecoder =
    Decode.map5 ParsecOption
        (Decode.field "id" Decode.int)
        (Decode.field "hex_code" Decode.string)
        (Decode.field "x" Decode.int)
        (Decode.field "y" Decode.int)
        (Decode.field "system_name" (Decode.nullable Decode.string))


{-| `GET ships/:id/last_jump` renders JSON `null` for a ship with no jumps.
-}
lastJumpDecoder : Decoder (Maybe LastJump)
lastJumpDecoder =
    Decode.nullable
        (Decode.map4 LastJump
            (Decode.field "parsec_id" Decode.int)
            (Decode.field "sector_id" Decode.int)
            (Decode.field "arrive_year" Decode.int)
            (Decode.field "arrive_day" Decode.int)
        )


{-| The `{ "errors": [ ... ] }` body of a 422 response.
-}
errorsDecoder : Decoder (List String)
errorsDecoder =
    Decode.field "errors" (Decode.list Decode.string)



-- ENCODERS


encodeDraft : Draft -> Encode.Value
encodeDraft draft =
    Encode.object
        [ ( "jump_log"
          , Encode.object
                [ ( "ship_id", Encode.int draft.shipId )
                , ( "from_parsec_id", Encode.int draft.fromParsecId )
                , ( "to_parsec_id", Encode.int draft.toParsecId )
                , ( "depart_year", Encode.int draft.departYear )
                , ( "depart_day", Encode.int draft.departDay )
                , ( "arrive_year", Encode.int draft.arriveYear )
                , ( "arrive_day", Encode.int draft.arriveDay )
                , ( "misjump", Encode.bool draft.misjump )
                , ( "notes", Encode.string draft.notes )
                ]
          )
        ]



-- HELPERS


{-| `1105.007` - year, then the day zero-padded to three digits.
-}
formatDate : Int -> Int -> String
formatDate year day =
    String.fromInt year ++ "." ++ String.padLeft 3 '0' (String.fromInt day)


{-| Add days to a year/day date, rolling over on a 365 day year.
-}
addDays : Int -> ( Int, Int ) -> ( Int, Int )
addDays days ( year, day ) =
    let
        total =
            year * daysPerYear + (day - 1) + days
    in
    ( total // daysPerYear, modBy daysPerYear total + 1 )


{-| Newest first, by arrival date then sequence.
-}
compareNewestFirst : JumpLog -> JumpLog -> Order
compareNewestFirst a b =
    compare
        ( b.arriveYear * 1000 + b.arriveDay, b.sequence, b.id )
        ( a.arriveYear * 1000 + a.arriveDay, a.sequence, a.id )


{-| Distance in parsecs between two universal hex coordinates. Mirrors
`HexDistance#hex_distance` in Rails, including its flooring integer division.
-}
hexDistance : ( Int, Int ) -> ( Int, Int ) -> Int
hexDistance a b =
    let
        toCube ( x, y ) =
            let
                z =
                    -y - floor (toFloat x / 2)
            in
            ( x, -x - z, z )

        ( ax, ay, az ) =
            toCube a

        ( bx, by, bz ) =
            toCube b
    in
    (abs (ax - bx) + abs (ay - by) + abs (az - bz)) // 2


{-| Whether any hex of the sector could lie within `range` parsecs of the
universal coordinate. A bounding box test, so it can include a sector whose
nearest hex is just out of reach at a corner, but never excludes one that holds
a reachable hex. Sectors are 32 hexes across and 40 tall, with universal y
running down the page (see `Parsec.hex_address_from_coords`).
-}
sectorInRange : Int -> ( Int, Int ) -> SectorOption -> Bool
sectorInRange range ( x, y ) sector =
    let
        minX =
            sector.x * 32

        maxX =
            minX + 31

        maxY =
            sector.y * 40

        minY =
            maxY - 39
    in
    x >= minX - range && x <= maxX + range && y >= minY - range && y <= maxY + range


{-| Days from the first date to the second, negative if the second is earlier.
-}
daysBetween : ( Int, Int ) -> ( Int, Int ) -> Int
daysBetween ( fromYear, fromDay ) ( toYear, toDay ) =
    (toYear * daysPerYear + toDay) - (fromYear * daysPerYear + fromDay)


{-| The arrival a new or edited jump of the ship has to follow. For a new jump
that is the ship's latest arrival. When editing, it is the latest arrival that
is no later than the edited jump's original departure, so that jump and those
after it do not count. Mirrors `JumpLog#previous_arrival_total` in Rails.
-}
previousArrival : List JumpLog -> Int -> Maybe Int -> Maybe ( Int, Int )
previousArrival jumps shipId editingId =
    let
        others =
            List.filter (\j -> j.shipId == shipId && Just j.id /= editingId) jumps

        edited =
            editingId
                |> Maybe.andThen (\id -> List.filter (\j -> j.id == id) jumps |> List.head)

        candidates =
            case edited of
                Just jump ->
                    if jump.shipId == shipId then
                        List.filter
                            (\j -> ( j.arriveYear, j.arriveDay ) <= ( jump.departYear, jump.departDay ))
                            others

                    else
                        others

                Nothing ->
                    others
    in
    candidates
        |> List.map (\j -> ( j.arriveYear, j.arriveDay ))
        |> List.maximum
