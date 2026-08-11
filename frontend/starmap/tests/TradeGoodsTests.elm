module TradeGoodsTests exposing (..)

import Expect
import Json.Decode as Decode
import List.Extra
import Test exposing (Test, describe)
import Traveller.TradeGoods as TradeGoods


availabilityResultJson : String
availabilityResultJson =
    """
    {
      "system": { "id": 1, "name": "Alpha" },
      "trade_codes": ["Ag", "Ri"],
      "population": 8,
      "seed": 42,
      "goods": [
        { "d66": 11, "name": "Common Electronics", "category": "common", "guaranteed": true, "tons": 45, "base_price": 20000 },
        { "d66": 66, "name": "Exotics", "category": "exotic", "guaranteed": false, "tons": null, "base_price": null }
      ]
    }
    """


pricesResultJson : String
pricesResultJson =
    """
    {
      "system": { "id": 1, "name": "Alpha" },
      "direction": "purchase",
      "skill_effect": 2,
      "counterpart_broker_skill": 1,
      "other_dm": -1,
      "results": [
        {
          "d66": 11,
          "name": "Common Electronics",
          "modifiers": [
            { "label": "Skill Effect", "value": 2 },
            { "label": "Purchase DM", "value": 3 }
          ],
          "result": {
            "base_price": 20000,
            "percent": 135,
            "price_per_ton": 27000,
            "net_price_per_ton": 27000,
            "fee_percentage": 0,
            "qualifying_roll": { "dice": 3, "sides": 6, "dm": 4, "rolls": [2, 3, 4], "total": 13 }
          }
        }
      ]
    }
    """


availabilityResultDecoderTests : Test
availabilityResultDecoderTests =
    describe "availabilityResultDecoder"
        [ Test.test "decodes the system, trade codes, population and seed" <|
            \_ ->
                case Decode.decodeString TradeGoods.availabilityResultDecoder availabilityResultJson of
                    Ok result ->
                        Expect.all
                            [ \r -> Expect.equal 1 r.system.id
                            , \r -> Expect.equal [ "Ag", "Ri" ] r.tradeCodes
                            , \r -> Expect.equal 8 r.population
                            , \r -> Expect.equal 42 r.seed
                            , \r -> Expect.equal 2 (List.length r.goods)
                            ]
                            result

                    Err err ->
                        Expect.fail (Decode.errorToString err)
        , Test.test "decodes a priceable good with tons and base price" <|
            \_ ->
                case Decode.decodeString TradeGoods.availabilityResultDecoder availabilityResultJson of
                    Ok result ->
                        case List.head result.goods of
                            Just electronics ->
                                Expect.all
                                    [ \g -> Expect.equal "Common Electronics" g.name
                                    , \g -> Expect.equal True g.guaranteed
                                    , \g -> Expect.equal (Just 45) g.tons
                                    , \g -> Expect.equal (Just 20000) g.basePrice
                                    ]
                                    electronics

                            Nothing ->
                                Expect.fail "expected at least one good"

                    Err err ->
                        Expect.fail (Decode.errorToString err)
        , Test.test "decodes Exotics with null tons and base_price" <|
            \_ ->
                case Decode.decodeString TradeGoods.availabilityResultDecoder availabilityResultJson of
                    Ok result ->
                        case List.Extra.last result.goods of
                            Just exotics ->
                                Expect.all
                                    [ \g -> Expect.equal Nothing g.tons
                                    , \g -> Expect.equal Nothing g.basePrice
                                    ]
                                    exotics

                            Nothing ->
                                Expect.fail "expected at least one good"

                    Err err ->
                        Expect.fail (Decode.errorToString err)
        ]


pricesResultDecoderTests : Test
pricesResultDecoderTests =
    describe "pricesResultDecoder"
        [ Test.test "decodes the manual inputs and one result row" <|
            \_ ->
                case Decode.decodeString TradeGoods.pricesResultDecoder pricesResultJson of
                    Ok result ->
                        Expect.all
                            [ \r -> Expect.equal "purchase" r.direction
                            , \r -> Expect.equal 2 r.skillEffect
                            , \r -> Expect.equal 1 r.counterpartBrokerSkill
                            , \r -> Expect.equal -1 r.otherDm
                            , \r -> Expect.equal 1 (List.length r.results)
                            ]
                            result

                    Err err ->
                        Expect.fail (Decode.errorToString err)
        , Test.test "decodes a result row's modifiers and price" <|
            \_ ->
                case Decode.decodeString TradeGoods.pricesResultDecoder pricesResultJson of
                    Ok result ->
                        case List.head result.results of
                            Just row ->
                                Expect.all
                                    [ \r -> Expect.equal 11 r.d66
                                    , \r -> Expect.equal "Common Electronics" r.name
                                    , \r -> Expect.equal 2 (List.length r.modifiers)
                                    , \r -> Expect.equal 135 r.result.percent
                                    , \r -> Expect.equal 27000 r.result.pricePerTon
                                    , \r -> Expect.equal 27000 r.result.netPricePerTon
                                    , \r -> Expect.equal 0 r.result.feePercentage
                                    , \r -> Expect.equal 13 r.result.qualifyingRoll.total
                                    ]
                                    row

                            Nothing ->
                                Expect.fail "expected at least one result"

                    Err err ->
                        Expect.fail (Decode.errorToString err)
        ]


availabilityQueryTests : Test
availabilityQueryTests =
    describe "TradeGoods.availabilityQuery"
        [ Test.test "omits seed when Nothing" <|
            \_ ->
                TradeGoods.availabilityQuery { id = 1, seed = Nothing }
                    |> List.length
                    |> Expect.equal 1
        , Test.test "includes seed when Just" <|
            \_ ->
                TradeGoods.availabilityQuery { id = 1, seed = Just 42 }
                    |> List.length
                    |> Expect.equal 2
        ]


pricesQueryTests : Test
pricesQueryTests =
    describe "TradeGoods.pricesQuery"
        [ Test.test "builds one query parameter per shared field, plus one per d66" <|
            \_ ->
                TradeGoods.pricesQuery
                    { id = 1
                    , direction = "purchase"
                    , skillEffect = 2
                    , counterpartBrokerSkill = 1
                    , otherDm = -1
                    , useBroker = False
                    , brokerLevel = 2
                    , brokerFeePercentage = 10
                    , d66s = [ 11, 21 ]
                    }
                    |> List.length
                    |> Expect.equal 10
        , Test.test "an empty d66s list still builds the shared fields" <|
            \_ ->
                TradeGoods.pricesQuery
                    { id = 1
                    , direction = "sale"
                    , skillEffect = 0
                    , counterpartBrokerSkill = 2
                    , otherDm = 0
                    , useBroker = True
                    , brokerLevel = 3
                    , brokerFeePercentage = 15
                    , d66s = []
                    }
                    |> List.length
                    |> Expect.equal 8
        ]
