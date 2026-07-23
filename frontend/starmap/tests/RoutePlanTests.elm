module RoutePlanTests exposing (..)

import Codec
import Expect
import Json.Decode as Decode
import Json.Encode as Encode
import Test exposing (Test, describe)
import Traveller.RoutePlan as RoutePlan


foundJson : String
foundJson =
    """
    {
      "found": true,
      "from": { "id": 1, "name": "Alpha" },
      "to": { "id": 3, "name": "Gamma" },
      "jump_range": 1,
      "refueling": "wilderness",
      "excluded_travel_zone_ids": [],
      "hops": [
        { "system": { "id": 1, "name": "Alpha", "hex_label": "0101", "x": 0, "y": 0 }, "distance": 0,
          "transit_hours": 1.5, "elapsed_avg_hours": 1.5 },
        { "system": { "id": 2, "name": "Beta", "hex_label": "0102", "x": 1, "y": 0 }, "distance": 1,
          "transit_hours": 2.5, "elapsed_avg_hours": 173.0 },
        { "system": { "id": 3, "name": "Gamma", "hex_label": "0103", "x": 2, "y": 0 }, "distance": 1,
          "transit_hours": 3.5, "elapsed_avg_hours": 348.0 }
      ],
      "total_distance": 2,
      "parsec_distance": 2,
      "total_jump_avg_hours": 338.0,
      "total_jump_min_hours": 308.0,
      "total_jump_max_hours": 368.0,
      "total_transit_hours": 10.0,
      "total_avg_hours": 348.0,
      "total_min_hours": 318.0,
      "total_max_hours": 378.0
    }
    """


notFoundJson : String
notFoundJson =
    """
    {
      "found": false,
      "from": { "id": 1, "name": "Alpha" },
      "to": { "id": 3, "name": "Gamma" },
      "jump_range": 1,
      "refueling": "wilderness",
      "excluded_travel_zone_ids": [7],
      "hops": [],
      "total_distance": null,
      "parsec_distance": null,
      "total_jump_avg_hours": null,
      "total_jump_min_hours": null,
      "total_jump_max_hours": null,
      "total_transit_hours": null,
      "total_avg_hours": null,
      "total_min_hours": null,
      "total_max_hours": null
    }
    """


routePlanResultDecoderTests : Test
routePlanResultDecoderTests =
    describe "routePlanResultDecoder"
        [ Test.test "decodes a found route with its hops and stats" <|
            \_ ->
                case Decode.decodeString RoutePlan.routePlanResultDecoder foundJson of
                    Ok result ->
                        Expect.all
                            [ \r -> Expect.equal True r.found
                            , \r -> Expect.equal 1 r.from.id
                            , \r -> Expect.equal "Gamma" r.to.name
                            , \r -> Expect.equal 3 (List.length r.hops)
                            , \r -> Expect.equal (Just 2) r.totalDistance
                            , \r -> Expect.equal (Just 2) r.parsecDistance
                            , \r -> Expect.equal (Just 338.0) r.totalJumpAvgHours
                            , \r -> Expect.equal (Just 308.0) r.totalJumpMinHours
                            , \r -> Expect.equal (Just 368.0) r.totalJumpMaxHours
                            , \r -> Expect.equal (Just 10.0) r.totalTransitHours
                            , \r -> Expect.equal (Just 348.0) r.totalAvgHours
                            , \r -> Expect.equal (Just 318.0) r.totalMinHours
                            , \r -> Expect.equal (Just 378.0) r.totalMaxHours
                            , \r -> Expect.equal (Just 1.5) (List.head r.hops |> Maybe.map .transitHours)
                            , \r -> Expect.equal (Just 1.5) (List.head r.hops |> Maybe.map .elapsedAvgHours)
                            , \r -> Expect.equal (Just 2.5) (List.drop 1 r.hops |> List.head |> Maybe.map .transitHours)
                            , \r -> Expect.equal (Just 173.0) (List.drop 1 r.hops |> List.head |> Maybe.map .elapsedAvgHours)
                            ]
                            result

                    Err err ->
                        Expect.fail (Decode.errorToString err)
        , Test.test "decodes a not-found route with null stats and empty hops" <|
            \_ ->
                case Decode.decodeString RoutePlan.routePlanResultDecoder notFoundJson of
                    Ok result ->
                        Expect.all
                            [ \r -> Expect.equal False r.found
                            , \r -> Expect.equal [] r.hops
                            , \r -> Expect.equal Nothing r.totalDistance
                            , \r -> Expect.equal Nothing r.parsecDistance
                            , \r -> Expect.equal Nothing r.totalAvgHours
                            , \r -> Expect.equal [ 7 ] r.excludedTravelZoneIds
                            ]
                            result

                    Err err ->
                        Expect.fail (Decode.errorToString err)
        ]


travelZoneOptionDecoderTests : Test
travelZoneOptionDecoderTests =
    describe "travelZoneOptionDecoder"
        [ Test.test "decodes id, code, name and colour" <|
            \_ ->
                let
                    json =
                        """{ "id": 4, "code": "RED", "name": "Red Zone", "colour": "#ff0000" }"""
                in
                Expect.equal
                    (Ok { id = 4, code = "RED", name = "Red Zone", colour = "#ff0000" })
                    (Decode.decodeString RoutePlan.travelZoneOptionDecoder json)
        ]


routePlanSystemResultDecoderTests : Test
routePlanSystemResultDecoderTests =
    describe "routePlanSystemResultDecoder"
        [ Test.test "decodes id, name and meta" <|
            \_ ->
                let
                    json =
                        """{ "id": 9, "name": "Zeta Prime", "meta": "Sector One · 0203" }"""
                in
                Expect.equal
                    (Ok { id = 9, name = "Zeta Prime", meta = "Sector One · 0203" })
                    (Decode.decodeString RoutePlan.routePlanSystemResultDecoder json)
        ]


storedRoutePlanCodecTests : Test
storedRoutePlanCodecTests =
    describe "storedRoutePlanCodec"
        [ Test.test "round-trips a stored route plan through encode/decode" <|
            \_ ->
                case Decode.decodeString RoutePlan.routePlanResultDecoder foundJson of
                    Ok result ->
                        let
                            stored =
                                { result = result, colour = "#3FB6FF" }

                            encoded =
                                Codec.encodeToValue RoutePlan.storedRoutePlanCodec stored
                        in
                        Expect.equal (Ok stored) (Codec.decodeValue RoutePlan.storedRoutePlanCodec encoded)

                    Err err ->
                        Expect.fail (Decode.errorToString err)
        , Test.test "fails to decode an unrelated JSON shape" <|
            \_ ->
                Expect.equal True
                    (Codec.decodeValue RoutePlan.storedRoutePlanCodec (Encode.object [ ( "nope", Encode.bool True ) ])
                        |> Result.toMaybe
                        |> (==) Nothing
                    )
        ]