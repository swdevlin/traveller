module Traveller.MailTraffic exposing
    ( MailResult
    , MailTrafficResult
    , Modifier
    , RollDetail
    , mailTrafficResultDecoder
    , trafficQuery
    )

{-| Types and JSON decoders for the Mail tool, mirroring
`Api::MailTrafficController#calculate`'s JSON shape. This module holds data
only - the form/modal lives in `Traveller.CommerceForm`.
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
the dice code (e.g. 2D6), `dm` the modifier applied to that specific roll,
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


{-| `containersRoll` is `Nothing` when the qualifying roll landed below 12 -
no mail is available, so no container count roll was made.
-}
type alias MailResult =
    { available : Bool
    , containers : Int
    , totalTons : Int
    , totalPayment : Int
    , qualifyingRoll : RollDetail
    , containersRoll : Maybe RollDetail
    }


mailResultDecoder : Decoder MailResult
mailResultDecoder =
    Decode.succeed MailResult
        |> required "available" Decode.bool
        |> required "containers" Decode.int
        |> required "total_tons" Decode.int
        |> required "total_payment" Decode.int
        |> required "qualifying_roll" rollDetailDecoder
        |> required "containers_roll" (Decode.nullable rollDetailDecoder)


type alias MailTrafficResult =
    { from : RoutePlanEndpoint
    , to : RoutePlanEndpoint
    , parsecDistance : Int
    , freightTrafficDm : Int
    , shipArmed : Bool
    , navalOrScoutRank : Int
    , socDm : Int
    , refereeModifier : Int
    , modifiers : List Modifier
    , result : MailResult
    }


mailTrafficResultDecoder : Decoder MailTrafficResult
mailTrafficResultDecoder =
    Decode.succeed MailTrafficResult
        |> required "from" routePlanEndpointDecoder
        |> required "to" routePlanEndpointDecoder
        |> required "parsec_distance" Decode.int
        |> required "freight_traffic_dm" Decode.int
        |> required "ship_armed" Decode.bool
        |> required "naval_or_scout_rank" Decode.int
        |> required "soc_dm" Decode.int
        |> required "referee_modifier" Decode.int
        |> required "modifiers" (Decode.list modifierDecoder)
        |> required "result" mailResultDecoder


{-| Query params for `GET api/mail_traffic`.
-}
trafficQuery :
    { fromId : Int
    , toId : Int
    , shipArmed : Bool
    , navalOrScoutRank : Int
    , socDm : Int
    , refereeModifier : Int
    }
    -> List Url.Builder.QueryParameter
trafficQuery { fromId, toId, shipArmed, navalOrScoutRank, socDm, refereeModifier } =
    [ Url.Builder.int "from_id" fromId
    , Url.Builder.int "to_id" toId
    , Url.Builder.string "ship_armed"
        (if shipArmed then
            "1"

         else
            "0"
        )
    , Url.Builder.int "naval_or_scout_rank" navalOrScoutRank
    , Url.Builder.int "soc_dm" socDm
    , Url.Builder.int "referee_modifier" refereeModifier
    ]
