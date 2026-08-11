module FreightTrafficTests exposing (..)

import Expect
import Json.Decode as Decode
import Test exposing (Test, describe)
import Traveller.FreightTraffic as FreightTraffic


resultJson : String
resultJson =
    """
    {
      "from": { "id": 1, "name": "Alpha" },
      "to": { "id": 3, "name": "Gamma" },
      "parsec_distance": 4,
      "broker_effect": 2,
      "referee_modifier": -1,
      "shared_modifiers": [
        { "label": "Population 8+ (destination)", "value": 4 },
        { "label": "Distance 4 parsecs", "value": -3 }
      ],
      "lot_types": {
        "incidental": {
          "lots": 3,
          "total_tons": 9,
          "modifiers": [
            { "label": "Population 8+ (destination)", "value": 4 },
            { "label": "Rolling for Incidental Cargo", "value": 2 }
          ],
          "qualifying_roll": { "dice": 2, "sides": 6, "dm": 6, "rolls": [3, 4], "total": 13 },
          "lots_roll": { "dice": 4, "sides": 6, "dm": 0, "rolls": [1, 2, 1, 1], "total": 3 },
          "lot_size_rolls": [
            { "dice": 1, "sides": 6, "dm": 0, "rolls": [2], "total": 2, "tons": 2 },
            { "dice": 1, "sides": 6, "dm": 0, "rolls": [3], "total": 3, "tons": 3 },
            { "dice": 1, "sides": 6, "dm": 0, "rolls": [4], "total": 4, "tons": 4 }
          ]
        },
        "minor": {
          "lots": 0,
          "total_tons": 0,
          "modifiers": [
            { "label": "Population 8+ (destination)", "value": 4 }
          ],
          "qualifying_roll": { "dice": 2, "sides": 6, "dm": -20, "rolls": [3, 4], "total": -13 },
          "lots_roll": null,
          "lot_size_rolls": []
        },
        "major": {
          "lots": 0,
          "total_tons": 0,
          "modifiers": [
            { "label": "Rolling for Major Cargo", "value": -4 }
          ],
          "qualifying_roll": { "dice": 2, "sides": 6, "dm": -4, "rolls": [2, 2], "total": 0 },
          "lots_roll": null,
          "lot_size_rolls": []
        }
      }
    }
    """


freightTrafficResultDecoderTests : Test
freightTrafficResultDecoderTests =
    describe "freightTrafficResultDecoder"
        [ Test.test "decodes the from/to endpoints, distance and manual modifiers" <|
            \_ ->
                case Decode.decodeString FreightTraffic.freightTrafficResultDecoder resultJson of
                    Ok result ->
                        Expect.all
                            [ \r -> Expect.equal 1 r.from.id
                            , \r -> Expect.equal "Gamma" r.to.name
                            , \r -> Expect.equal 4 r.parsecDistance
                            , \r -> Expect.equal 2 r.brokerEffect
                            , \r -> Expect.equal -1 r.refereeModifier
                            , \r -> Expect.equal 2 (List.length r.sharedModifiers)
                            ]
                            result

                    Err err ->
                        Expect.fail (Decode.errorToString err)
        , Test.test "decodes a lot type with a lots roll and per-lot size rolls" <|
            \_ ->
                case Decode.decodeString FreightTraffic.freightTrafficResultDecoder resultJson of
                    Ok result ->
                        Expect.all
                            [ \r -> Expect.equal 3 r.lotTypes.incidental.lots
                            , \r -> Expect.equal 9 r.lotTypes.incidental.totalTons
                            , \r -> Expect.equal 13 r.lotTypes.incidental.qualifyingRoll.total
                            , \r -> Expect.equal (Just 3) (Maybe.map .total r.lotTypes.incidental.lotsRoll)
                            , \r -> Expect.equal 3 (List.length r.lotTypes.incidental.lotSizeRolls)
                            , \r -> Expect.equal (Just 4) (r.lotTypes.incidental.lotSizeRolls |> List.reverse |> List.head |> Maybe.andThen .tons)
                            ]
                            result

                    Err err ->
                        Expect.fail (Decode.errorToString err)
        , Test.test "decodes a lot type with a null lots roll and no lot size rolls" <|
            \_ ->
                case Decode.decodeString FreightTraffic.freightTrafficResultDecoder resultJson of
                    Ok result ->
                        Expect.all
                            [ \r -> Expect.equal 0 r.lotTypes.minor.lots
                            , \r -> Expect.equal Nothing r.lotTypes.minor.lotsRoll
                            , \r -> Expect.equal -13 r.lotTypes.minor.qualifyingRoll.total
                            , \r -> Expect.equal 0 r.lotTypes.major.lots
                            , \r -> Expect.equal Nothing r.lotTypes.major.lotsRoll
                            ]
                            result

                    Err err ->
                        Expect.fail (Decode.errorToString err)
        , Test.test "decodes all three lot types" <|
            \_ ->
                case Decode.decodeString FreightTraffic.freightTrafficResultDecoder resultJson of
                    Ok result ->
                        Expect.equal 0 result.lotTypes.major.lots

                    Err err ->
                        Expect.fail (Decode.errorToString err)
        ]


trafficQueryTests : Test
trafficQueryTests =
    describe "FreightTraffic.trafficQuery"
        [ Test.test "builds one query parameter per field" <|
            \_ ->
                FreightTraffic.trafficQuery
                    { fromId = 1, toId = 3, brokerEffect = 2, refereeModifier = -1 }
                    |> List.length
                    |> Expect.equal 4
        ]
