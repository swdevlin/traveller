module Traveller.TradeGoods exposing
    ( AvailabilityResult
    , Modifier
    , PriceRow
    , PriceResultData
    , PricesResult
    , RollDetail
    , TradeGoodRow
    , availabilityQuery
    , availabilityResultDecoder
    , pricesQuery
    , pricesResultDecoder
    )

{-| Types and JSON decoders for the Speculative Trade tool, mirroring
`Api::TradeGoodsController#availability`/`#prices`'s JSON shape. This module
holds data only - the form/modal lives in `Traveller.CommerceForm`.
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


{-| `tons`/`basePrice` are `Nothing` for Exotics, which has no computable
quantity or price.
-}
type alias TradeGoodRow =
    { d66 : Int
    , name : String
    , category : String
    , guaranteed : Bool
    , tons : Maybe Int
    , basePrice : Maybe Int
    }


tradeGoodRowDecoder : Decoder TradeGoodRow
tradeGoodRowDecoder =
    Decode.succeed TradeGoodRow
        |> required "d66" Decode.int
        |> required "name" Decode.string
        |> required "category" Decode.string
        |> required "guaranteed" Decode.bool
        |> required "tons" (Decode.nullable Decode.int)
        |> required "base_price" (Decode.nullable Decode.int)


type alias AvailabilityResult =
    { system : RoutePlanEndpoint
    , tradeCodes : List String
    , population : Int
    , seed : Int
    , goods : List TradeGoodRow
    }


availabilityResultDecoder : Decoder AvailabilityResult
availabilityResultDecoder =
    Decode.succeed AvailabilityResult
        |> required "system" routePlanEndpointDecoder
        |> required "trade_codes" (Decode.list Decode.string)
        |> required "population" Decode.int
        |> required "seed" Decode.int
        |> required "goods" (Decode.list tradeGoodRowDecoder)


type alias PriceResultData =
    { basePrice : Int
    , percent : Int
    , pricePerTon : Int
    , netPricePerTon : Int
    , feePercentage : Float
    , qualifyingRoll : RollDetail
    }


priceResultDataDecoder : Decoder PriceResultData
priceResultDataDecoder =
    Decode.succeed PriceResultData
        |> required "base_price" Decode.int
        |> required "percent" Decode.int
        |> required "price_per_ton" Decode.int
        |> required "net_price_per_ton" Decode.int
        |> required "fee_percentage" Decode.float
        |> required "qualifying_roll" rollDetailDecoder


type alias PriceRow =
    { d66 : Int
    , name : String
    , modifiers : List Modifier
    , result : PriceResultData
    }


priceRowDecoder : Decoder PriceRow
priceRowDecoder =
    Decode.succeed PriceRow
        |> required "d66" Decode.int
        |> required "name" Decode.string
        |> required "modifiers" (Decode.list modifierDecoder)
        |> required "result" priceResultDataDecoder


{-| `GET api/trade_goods/prices` rolls Purchase or Sale price for every good
requested in a single response - the manual inputs (Skill Effect, Broker
Skill, Other DM) never vary by good, so there is no reason to roll one at a
time.
-}
type alias PricesResult =
    { system : RoutePlanEndpoint
    , direction : String
    , skillEffect : Int
    , counterpartBrokerSkill : Int
    , otherDm : Int
    , results : List PriceRow
    }


pricesResultDecoder : Decoder PricesResult
pricesResultDecoder =
    Decode.succeed PricesResult
        |> required "system" routePlanEndpointDecoder
        |> required "direction" Decode.string
        |> required "skill_effect" Decode.int
        |> required "counterpart_broker_skill" Decode.int
        |> required "other_dm" Decode.int
        |> required "results" (Decode.list priceRowDecoder)


{-| Query params for `GET api/trade_goods/availability`. Pass `seed` as
`Just seed` to re-derive an identical goods list (unused by the Elm client,
which keeps the survey result in memory rather than re-deriving it from a
seed - but the API supports it for the Rails-rendered Commerce page, which has
no persistent client-side state across page loads).
-}
availabilityQuery : { id : Int, seed : Maybe Int } -> List Url.Builder.QueryParameter
availabilityQuery { id, seed } =
    Url.Builder.int "id" id
        :: (case seed of
                Just s ->
                    [ Url.Builder.int "seed" s ]

                Nothing ->
                    []
           )


{-| Query params for `GET api/trade_goods/prices`. An empty `d66s` rolls every
priceable good (used for Sale); a non-empty one restricts the roll to those
goods (used for Purchase, scoped to the surveyed availability list).
-}
pricesQuery :
    { id : Int
    , direction : String
    , skillEffect : Int
    , counterpartBrokerSkill : Int
    , otherDm : Int
    , useBroker : Bool
    , brokerLevel : Int
    , brokerFeePercentage : Float
    , d66s : List Int
    }
    -> List Url.Builder.QueryParameter
pricesQuery { id, direction, skillEffect, counterpartBrokerSkill, otherDm, useBroker, brokerLevel, brokerFeePercentage, d66s } =
    [ Url.Builder.int "id" id
    , Url.Builder.string "direction" direction
    , Url.Builder.int "skill_effect" skillEffect
    , Url.Builder.int "counterpart_broker_skill" counterpartBrokerSkill
    , Url.Builder.int "other_dm" otherDm
    , Url.Builder.string "use_broker"
        (if useBroker then
            "true"

         else
            "false"
        )
    , Url.Builder.int "broker_level" brokerLevel
    , Url.Builder.string "broker_fee_percentage" (String.fromFloat brokerFeePercentage)
    ]
        ++ List.map (\d66 -> Url.Builder.string "d66s[]" (String.fromInt d66)) d66s
