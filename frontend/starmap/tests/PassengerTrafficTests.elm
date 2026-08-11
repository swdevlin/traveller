module PassengerTrafficTests exposing (..)

import Expect
import Json.Decode as Decode
import Test exposing (Test, describe)
import Traveller.PassengerTraffic as PassengerTraffic


resultJson : String
resultJson =
    """
    {
      "from": { "id": 1, "name": "Alpha" },
      "to": { "id": 3, "name": "Gamma" },
      "parsec_distance": 4,
      "broker_effect": 2,
      "chief_steward_skill": 1,
      "referee_modifier": -1,
      "shared_modifiers": [
        { "label": "Population 8+ (destination)", "value": 3 },
        { "label": "Distance 4 parsecs", "value": -3 }
      ],
      "passenger_types": {
        "low": {
          "passengers": 4,
          "modifiers": [
            { "label": "Population 8+ (destination)", "value": 3 },
            { "label": "Rolling for Low", "value": 1 }
          ],
          "qualifying_roll": { "dice": 2, "sides": 6, "dm": 4, "rolls": [3, 4], "total": 11 },
          "count_roll": { "dice": 4, "sides": 6, "dm": 0, "rolls": [1, 1, 1, 1], "total": 4 }
        },
        "basic": {
          "passengers": 0,
          "modifiers": [
            { "label": "Population 8+ (destination)", "value": 3 }
          ],
          "qualifying_roll": { "dice": 2, "sides": 6, "dm": -20, "rolls": [3, 4], "total": -13 },
          "count_roll": null
        },
        "middle": {
          "passengers": 12,
          "modifiers": [],
          "qualifying_roll": { "dice": 2, "sides": 6, "dm": 0, "rolls": [6, 6], "total": 12 },
          "count_roll": { "dice": 4, "sides": 6, "dm": 0, "rolls": [1, 2, 3, 6], "total": 12 }
        },
        "high": {
          "passengers": 0,
          "modifiers": [
            { "label": "Rolling for High", "value": -4 }
          ],
          "qualifying_roll": { "dice": 2, "sides": 6, "dm": -4, "rolls": [2, 2], "total": 0 },
          "count_roll": null
        }
      }
    }
    """


passengerTrafficResultDecoderTests : Test
passengerTrafficResultDecoderTests =
    describe "passengerTrafficResultDecoder"
        [ Test.test "decodes the from/to endpoints, distance and manual modifiers" <|
            \_ ->
                case Decode.decodeString PassengerTraffic.passengerTrafficResultDecoder resultJson of
                    Ok result ->
                        Expect.all
                            [ \r -> Expect.equal 1 r.from.id
                            , \r -> Expect.equal "Gamma" r.to.name
                            , \r -> Expect.equal 4 r.parsecDistance
                            , \r -> Expect.equal 2 r.brokerEffect
                            , \r -> Expect.equal 1 r.chiefStewardSkill
                            , \r -> Expect.equal -1 r.refereeModifier
                            , \r -> Expect.equal 2 (List.length r.sharedModifiers)
                            ]
                            result

                    Err err ->
                        Expect.fail (Decode.errorToString err)
        , Test.test "decodes a passenger type with a count roll" <|
            \_ ->
                case Decode.decodeString PassengerTraffic.passengerTrafficResultDecoder resultJson of
                    Ok result ->
                        Expect.all
                            [ \r -> Expect.equal 4 r.passengerTypes.low.passengers
                            , \r -> Expect.equal 11 r.passengerTypes.low.qualifyingRoll.total
                            , \r -> Expect.equal [ 3, 4 ] r.passengerTypes.low.qualifyingRoll.rolls
                            , \r -> Expect.equal (Just 4) (Maybe.map .total r.passengerTypes.low.countRoll)
                            , \r -> Expect.equal 2 (List.length r.passengerTypes.low.modifiers)
                            ]
                            result

                    Err err ->
                        Expect.fail (Decode.errorToString err)
        , Test.test "decodes a passenger type with a null count roll as Nothing" <|
            \_ ->
                case Decode.decodeString PassengerTraffic.passengerTrafficResultDecoder resultJson of
                    Ok result ->
                        Expect.all
                            [ \r -> Expect.equal 0 r.passengerTypes.basic.passengers
                            , \r -> Expect.equal Nothing r.passengerTypes.basic.countRoll
                            , \r -> Expect.equal -13 r.passengerTypes.basic.qualifyingRoll.total
                            , \r -> Expect.equal 0 r.passengerTypes.high.passengers
                            , \r -> Expect.equal Nothing r.passengerTypes.high.countRoll
                            ]
                            result

                    Err err ->
                        Expect.fail (Decode.errorToString err)
        , Test.test "decodes all four passenger types" <|
            \_ ->
                case Decode.decodeString PassengerTraffic.passengerTrafficResultDecoder resultJson of
                    Ok result ->
                        Expect.equal 12 result.passengerTypes.middle.passengers

                    Err err ->
                        Expect.fail (Decode.errorToString err)
        ]


trafficQueryTests : Test
trafficQueryTests =
    describe "trafficQuery"
        [ Test.test "builds one query parameter per field" <|
            \_ ->
                PassengerTraffic.trafficQuery
                    { fromId = 1, toId = 3, brokerEffect = 2, chiefStewardSkill = 1, refereeModifier = -1 }
                    |> List.length
                    |> Expect.equal 5
        ]
