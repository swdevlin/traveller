module Traveller.PassengerTraffic exposing
    ( Modifier
    , PassengerTrafficResult
    , PassengerTypeResult
    , PassengerTypes
    , RollDetail
    , passengerTrafficResultDecoder
    , trafficQuery
    )

{-| Types and JSON decoders for the Passenger Traffic tool, mirroring
`Api::PassengerTrafficController#calculate`'s JSON shape. This module holds
data only - the form/modal lives in `Traveller.PassengerTrafficForm`.
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
`rolls` the individual die values, and `total` the resulting sum.
-}
type alias RollDetail =
    { dice : Int
    , sides : Int
    , dm : Int
    , rolls : List Int
    , total : Int
    }


rollDetailDecoder : Decoder RollDetail
rollDetailDecoder =
    Decode.succeed RollDetail
        |> required "dice" Decode.int
        |> required "sides" Decode.int
        |> required "dm" Decode.int
        |> required "rolls" (Decode.list Decode.int)
        |> required "total" Decode.int


{-| `countRoll` is `Nothing` when the qualifying roll landed on "1 or less" -
no passengers are seeking passage of this type, so no dice-code roll was
made.
-}
type alias PassengerTypeResult =
    { passengers : Int
    , modifiers : List Modifier
    , qualifyingRoll : RollDetail
    , countRoll : Maybe RollDetail
    }


passengerTypeResultDecoder : Decoder PassengerTypeResult
passengerTypeResultDecoder =
    Decode.succeed PassengerTypeResult
        |> required "passengers" Decode.int
        |> required "modifiers" (Decode.list modifierDecoder)
        |> required "qualifying_roll" rollDetailDecoder
        |> required "count_roll" (Decode.nullable rollDetailDecoder)


type alias PassengerTypes =
    { low : PassengerTypeResult
    , basic : PassengerTypeResult
    , middle : PassengerTypeResult
    , high : PassengerTypeResult
    }


passengerTypesDecoder : Decoder PassengerTypes
passengerTypesDecoder =
    Decode.succeed PassengerTypes
        |> required "low" passengerTypeResultDecoder
        |> required "basic" passengerTypeResultDecoder
        |> required "middle" passengerTypeResultDecoder
        |> required "high" passengerTypeResultDecoder


type alias PassengerTrafficResult =
    { from : RoutePlanEndpoint
    , to : RoutePlanEndpoint
    , parsecDistance : Int
    , brokerEffect : Int
    , chiefStewardSkill : Int
    , refereeModifier : Int
    , sharedModifiers : List Modifier
    , passengerTypes : PassengerTypes
    }


passengerTrafficResultDecoder : Decoder PassengerTrafficResult
passengerTrafficResultDecoder =
    Decode.succeed PassengerTrafficResult
        |> required "from" routePlanEndpointDecoder
        |> required "to" routePlanEndpointDecoder
        |> required "parsec_distance" Decode.int
        |> required "broker_effect" Decode.int
        |> required "chief_steward_skill" Decode.int
        |> required "referee_modifier" Decode.int
        |> required "shared_modifiers" (Decode.list modifierDecoder)
        |> required "passenger_types" passengerTypesDecoder


{-| Query params for `GET api/passenger_traffic`.
-}
trafficQuery :
    { fromId : Int
    , toId : Int
    , brokerEffect : Int
    , chiefStewardSkill : Int
    , refereeModifier : Int
    }
    -> List Url.Builder.QueryParameter
trafficQuery { fromId, toId, brokerEffect, chiefStewardSkill, refereeModifier } =
    [ Url.Builder.int "from_id" fromId
    , Url.Builder.int "to_id" toId
    , Url.Builder.int "broker_effect" brokerEffect
    , Url.Builder.int "chief_steward_skill" chiefStewardSkill
    , Url.Builder.int "referee_modifier" refereeModifier
    ]
