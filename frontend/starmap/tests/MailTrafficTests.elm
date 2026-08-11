module MailTrafficTests exposing (..)

import Expect
import Json.Decode as Decode
import Test exposing (Test, describe)
import Traveller.MailTraffic as MailTraffic


availableResultJson : String
availableResultJson =
    """
    {
      "from": { "id": 1, "name": "Alpha" },
      "to": { "id": 3, "name": "Gamma" },
      "parsec_distance": 4,
      "freight_traffic_dm": 12,
      "ship_armed": true,
      "naval_or_scout_rank": 2,
      "soc_dm": 1,
      "referee_modifier": -1,
      "modifiers": [
        { "label": "Freight Traffic DM (+12)", "value": 2 },
        { "label": "Ship is armed", "value": 2 }
      ],
      "result": {
        "available": true,
        "containers": 4,
        "total_tons": 20,
        "total_payment": 100000,
        "qualifying_roll": { "dice": 2, "sides": 6, "dm": 6, "rolls": [3, 4], "total": 13 },
        "containers_roll": { "dice": 1, "sides": 6, "dm": 0, "rolls": [4], "total": 4 }
      }
    }
    """


unavailableResultJson : String
unavailableResultJson =
    """
    {
      "from": { "id": 1, "name": "Alpha" },
      "to": { "id": 3, "name": "Gamma" },
      "parsec_distance": 4,
      "freight_traffic_dm": -12,
      "ship_armed": false,
      "naval_or_scout_rank": 0,
      "soc_dm": 0,
      "referee_modifier": 0,
      "modifiers": [
        { "label": "Freight Traffic DM (-12)", "value": -2 }
      ],
      "result": {
        "available": false,
        "containers": 0,
        "total_tons": 0,
        "total_payment": 0,
        "qualifying_roll": { "dice": 2, "sides": 6, "dm": -2, "rolls": [3, 4], "total": 5 },
        "containers_roll": null
      }
    }
    """


mailTrafficResultDecoderTests : Test
mailTrafficResultDecoderTests =
    describe "mailTrafficResultDecoder"
        [ Test.test "decodes the from/to endpoints, distance and manual inputs" <|
            \_ ->
                case Decode.decodeString MailTraffic.mailTrafficResultDecoder availableResultJson of
                    Ok result ->
                        Expect.all
                            [ \r -> Expect.equal 1 r.from.id
                            , \r -> Expect.equal "Gamma" r.to.name
                            , \r -> Expect.equal 4 r.parsecDistance
                            , \r -> Expect.equal 12 r.freightTrafficDm
                            , \r -> Expect.equal True r.shipArmed
                            , \r -> Expect.equal 2 r.navalOrScoutRank
                            , \r -> Expect.equal 1 r.socDm
                            , \r -> Expect.equal -1 r.refereeModifier
                            , \r -> Expect.equal 2 (List.length r.modifiers)
                            ]
                            result

                    Err err ->
                        Expect.fail (Decode.errorToString err)
        , Test.test "decodes an available result with a containers roll" <|
            \_ ->
                case Decode.decodeString MailTraffic.mailTrafficResultDecoder availableResultJson of
                    Ok result ->
                        Expect.all
                            [ \r -> Expect.equal True r.result.available
                            , \r -> Expect.equal 4 r.result.containers
                            , \r -> Expect.equal 20 r.result.totalTons
                            , \r -> Expect.equal 100000 r.result.totalPayment
                            , \r -> Expect.equal (Just 4) (Maybe.map .total r.result.containersRoll)
                            ]
                            result

                    Err err ->
                        Expect.fail (Decode.errorToString err)
        , Test.test "decodes an unavailable result with a null containers roll" <|
            \_ ->
                case Decode.decodeString MailTraffic.mailTrafficResultDecoder unavailableResultJson of
                    Ok result ->
                        Expect.all
                            [ \r -> Expect.equal False r.result.available
                            , \r -> Expect.equal 0 r.result.containers
                            , \r -> Expect.equal Nothing r.result.containersRoll
                            ]
                            result

                    Err err ->
                        Expect.fail (Decode.errorToString err)
        ]


trafficQueryTests : Test
trafficQueryTests =
    describe "MailTraffic.trafficQuery"
        [ Test.test "builds one query parameter per field" <|
            \_ ->
                MailTraffic.trafficQuery
                    { fromId = 1, toId = 3, shipArmed = True, navalOrScoutRank = 2, socDm = 1, refereeModifier = -1 }
                    |> List.length
                    |> Expect.equal 6
        ]
