module Traveller.TradeSynergy exposing
    ( Good
    , Partner
    , SystemInfo
    , TradeSynergies
    , cellsWithin
    , hexDistance
    , query
    , tradeSynergiesDecoder
    )

{-| Types and JSON decoder for the Trade Synergies tool, mirroring
`Api::TradeSynergiesController#show`. All scoring happens on the Rails side;
this module holds data only (plus the pure hex-grid maths needed to lay the
partners out on the modal's map). The modal lives in
`Traveller.TradeSynergyPanel`.
-}

import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline exposing (required)
import Url.Builder


{-| A good that flows profitably in one direction. `bonus` is the combined
purchase and sale DM, always above zero.
-}
type alias Good =
    { d66 : Int
    , name : String
    , category : String
    , buyDm : Int
    , sellDm : Int
    , bonus : Int
    }


type alias SystemInfo =
    { id : Int
    , name : Maybe String
    , hex : String
    , sector : String
    , originX : Int
    , originY : Int
    , uwp : Maybe String
    , starport : Maybe String
    , wtn : Maybe Float
    , gasGiant : Bool
    , travelZone : Maybe String
    , tradeCodes : List String
    }


{-| A neighbouring system. "Outbound" is from the origin to this system,
"inbound" is from this system to the origin.
-}
type alias Partner =
    { system : SystemInfo
    , distance : Int
    , outboundCount : Int
    , outboundBonus : Int
    , inboundCount : Int
    , inboundBonus : Int
    , outboundGoods : List Good
    , inboundGoods : List Good
    }


type alias TradeSynergies =
    { jump : Int
    , origin : SystemInfo
    , partners : List Partner
    }


goodDecoder : Decoder Good
goodDecoder =
    Decode.succeed Good
        |> required "d66" Decode.int
        |> required "name" Decode.string
        |> required "category" Decode.string
        |> required "buy_dm" Decode.int
        |> required "sell_dm" Decode.int
        |> required "bonus" Decode.int


systemInfoDecoder : Decoder SystemInfo
systemInfoDecoder =
    Decode.succeed SystemInfo
        |> required "id" Decode.int
        |> required "name" (Decode.nullable Decode.string)
        |> required "hex" Decode.string
        |> required "sector" Decode.string
        |> required "origin_x" Decode.int
        |> required "origin_y" Decode.int
        |> required "uwp" (Decode.nullable Decode.string)
        |> required "starport" (Decode.nullable Decode.string)
        |> required "wtn" (Decode.nullable Decode.float)
        |> required "gas_giant" Decode.bool
        |> required "travel_zone" (Decode.nullable Decode.string)
        |> required "trade_codes" (Decode.list Decode.string)


partnerDecoder : Decoder Partner
partnerDecoder =
    Decode.succeed Partner
        |> Json.Decode.Pipeline.custom systemInfoDecoder
        |> required "distance" Decode.int
        |> required "outbound_count" Decode.int
        |> required "outbound_bonus" Decode.int
        |> required "inbound_count" Decode.int
        |> required "inbound_bonus" Decode.int
        |> required "outbound_goods" (Decode.list goodDecoder)
        |> required "inbound_goods" (Decode.list goodDecoder)


tradeSynergiesDecoder : Decoder TradeSynergies
tradeSynergiesDecoder =
    Decode.succeed TradeSynergies
        |> required "jump" Decode.int
        |> required "origin" systemInfoDecoder
        |> required "partners" (Decode.list partnerDecoder)


query : Int -> List Url.Builder.QueryParameter
query jump =
    [ Url.Builder.int "jump" jump ]


{-| Parsec distance between two universal hex coordinates. Mirrors
`HexDistance#hex_distance` on the Rails side (odd-q layout via cube
coordinates, with floor division so negative columns match Ruby).
-}
hexDistance : ( Int, Int ) -> ( Int, Int ) -> Int
hexDistance ( x1, y1 ) ( x2, y2 ) =
    let
        cube ( x, y ) =
            let
                z =
                    -y - floorHalf x
            in
            ( x, -x - z, z )

        ( ax, ay, az ) =
            cube ( x1, y1 )

        ( bx, by, bz ) =
            cube ( x2, y2 )
    in
    (abs (ax - bx) + abs (ay - by) + abs (az - bz)) // 2


floorHalf : Int -> Int
floorHalf n =
    floor (toFloat n / 2)


{-| Every universal hex within `radius` parsecs of `( ox, oy )`, origin
included. Lays out the map grid.
-}
cellsWithin : Int -> ( Int, Int ) -> List ( Int, Int )
cellsWithin radius ( ox, oy ) =
    List.range (ox - radius) (ox + radius)
        |> List.concatMap
            (\x ->
                List.range (oy - radius - 1) (oy + radius + 1)
                    |> List.filterMap
                        (\y ->
                            if hexDistance ( ox, oy ) ( x, y ) <= radius then
                                Just ( x, y )

                            else
                                Nothing
                        )
            )
