module Traveller.FreightTraffic exposing
    ( FreightTrafficResult
    , LotTypeResult
    , LotTypes
    , Modifier
    , RollDetail
    , SystemInfo
    , freightTrafficResultDecoder
    , systemInfoDecoder
    , systemQuery
    , trafficQuery
    )

{-| Types and JSON decoders for the Freight Traffic tool, mirroring
`Api::FreightTrafficController#calculate`'s JSON shape. This module holds
data only - the form/modal lives in `Traveller.FreightTrafficForm`.
-}

import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline exposing (required)
import Traveller.RoutePlan exposing (RoutePlanEndpoint, routePlanEndpointDecoder)
import Url.Builder


type alias Modifier =
    { label : String
    , value : Int
    }


modifierDecoder : Decoder Modifier
modifierDecoder =
    Decode.succeed Modifier
        |> required "label" Decode.string
        |> required "value" Decode.int


{-| A single logged roll - one `DiceRoller#roll` call. `dice`/`sides` describe
the dice code (e.g. 3D6), `dm` the modifier applied to that specific roll,
`rolls` the individual die values, and `total` the resulting sum. `tons` is
only present on per-lot size rolls.
-}
type alias RollDetail =
    { dice : Int
    , sides : Int
    , dm : Int
    , rolls : List Int
    , total : Int
    , tons : Maybe Int
    }


rollDetailDecoder : Decoder RollDetail
rollDetailDecoder =
    Decode.succeed RollDetail
        |> required "dice" Decode.int
        |> required "sides" Decode.int
        |> required "dm" Decode.int
        |> required "rolls" (Decode.list Decode.int)
        |> required "total" Decode.int
        |> Json.Decode.Pipeline.optional "tons" (Decode.map Just Decode.int) Nothing


{-| `lotsRoll` is `Nothing` when the qualifying roll landed on "1 or less" -
no lots of this type are available, so no dice-code roll was made.
-}
type alias LotTypeResult =
    { lots : Int
    , totalTons : Int
    , modifiers : List Modifier
    , qualifyingRoll : RollDetail
    , lotsRoll : Maybe RollDetail
    , lotSizeRolls : List RollDetail
    }


lotTypeResultDecoder : Decoder LotTypeResult
lotTypeResultDecoder =
    Decode.succeed LotTypeResult
        |> required "lots" Decode.int
        |> required "total_tons" Decode.int
        |> required "modifiers" (Decode.list modifierDecoder)
        |> required "qualifying_roll" rollDetailDecoder
        |> required "lots_roll" (Decode.nullable rollDetailDecoder)
        |> required "lot_size_rolls" (Decode.list rollDetailDecoder)


type alias LotTypes =
    { incidental : LotTypeResult
    , minor : LotTypeResult
    , major : LotTypeResult
    }


lotTypesDecoder : Decoder LotTypes
lotTypesDecoder =
    Decode.succeed LotTypes
        |> required "incidental" lotTypeResultDecoder
        |> required "minor" lotTypeResultDecoder
        |> required "major" lotTypeResultDecoder


type alias FreightTrafficResult =
    { from : RoutePlanEndpoint
    , to : RoutePlanEndpoint
    , parsecDistance : Int
    , brokerEffect : Int
    , refereeModifier : Int
    , sharedModifiers : List Modifier
    , lotTypes : LotTypes
    }


freightTrafficResultDecoder : Decoder FreightTrafficResult
freightTrafficResultDecoder =
    Decode.succeed FreightTrafficResult
        |> required "from" routePlanEndpointDecoder
        |> required "to" routePlanEndpointDecoder
        |> required "parsec_distance" Decode.int
        |> required "broker_effect" Decode.int
        |> required "referee_modifier" Decode.int
        |> required "shared_modifiers" (Decode.list modifierDecoder)
        |> required "lot_types" lotTypesDecoder


{-| Query params for `GET api/freight_traffic`.
-}
trafficQuery :
    { fromId : Int
    , toId : Int
    , brokerEffect : Int
    , refereeModifier : Int
    }
    -> List Url.Builder.QueryParameter
trafficQuery { fromId, toId, brokerEffect, refereeModifier } =
    [ Url.Builder.int "from_id" fromId
    , Url.Builder.int "to_id" toId
    , Url.Builder.int "broker_effect" brokerEffect
    , Url.Builder.int "referee_modifier" refereeModifier
    ]


{-| UWP + trade codes + travel zone for a single system, from
`GET api/freight_traffic/system` - shared across tabs the same way the
Rails-rendered Commerce page reuses this endpoint for its From/To display,
regardless of which tab is active.
-}
type alias SystemInfo =
    { uwp : Maybe String
    , tradeCodes : List String
    , travelZone : Maybe String
    }


systemInfoDecoder : Decoder SystemInfo
systemInfoDecoder =
    Decode.succeed SystemInfo
        |> required "uwp" (Decode.nullable Decode.string)
        |> required "trade_codes" (Decode.list Decode.string)
        |> required "travel_zone" (Decode.nullable Decode.string)


{-| Query params for `GET api/freight_traffic/system`.
-}
systemQuery : { id : Int } -> List Url.Builder.QueryParameter
systemQuery { id } =
    [ Url.Builder.int "id" id ]
