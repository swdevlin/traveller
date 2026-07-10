module JumpRouteLayerTests exposing (..)

import Codec
import Expect
import Json.Decode as Decode
import Json.Encode as Encode
import Set
import Test exposing (Test, describe)
import Traveller.JumpRouteLayer as JumpRouteLayer


networkRouteJson : String
networkRouteJson =
    """
    {
      "id": 1,
      "name": "Spinward Main",
      "colour": "#3FB6FF",
      "line_style": "solid",
      "line_width": 4,
      "known": true,
      "route_type": "network",
      "notes": "Referee scratch notes",
      "max_jump": 2,
      "link_count": 5
    }
    """


plottedRouteJson : String
plottedRouteJson =
    """
    {
      "id": 2,
      "name": "Emergency Run",
      "colour": "#E87040",
      "line_style": "dashed",
      "line_width": 8,
      "known": false,
      "route_type": "plotted",
      "notes": null,
      "max_jump": null,
      "link_count": 0
    }
    """


routeDecoderTests : Test
routeDecoderTests =
    describe "routeDecoder"
        [ Test.test "decodes a network route with notes and max_jump" <|
            \_ ->
                case Decode.decodeString JumpRouteLayer.routeDecoder networkRouteJson of
                    Ok route ->
                        Expect.all
                            [ \r -> Expect.equal 1 r.id
                            , \r -> Expect.equal "Spinward Main" r.name
                            , \r -> Expect.equal "network" r.routeType
                            , \r -> Expect.equal (Just "Referee scratch notes") r.notes
                            , \r -> Expect.equal (Just 2) r.maxJump
                            , \r -> Expect.equal 5 r.linkCount
                            ]
                            route

                    Err err ->
                        Expect.fail (Decode.errorToString err)
        , Test.test "decodes a plotted route with null notes and max_jump" <|
            \_ ->
                case Decode.decodeString JumpRouteLayer.routeDecoder plottedRouteJson of
                    Ok route ->
                        Expect.all
                            [ \r -> Expect.equal "plotted" r.routeType
                            , \r -> Expect.equal Nothing r.notes
                            , \r -> Expect.equal Nothing r.maxJump
                            , \r -> Expect.equal 0 r.linkCount
                            ]
                            route

                    Err err ->
                        Expect.fail (Decode.errorToString err)
        ]


routesDecoderTests : Test
routesDecoderTests =
    describe "routesDecoder"
        [ Test.test "decodes a list of routes" <|
            \_ ->
                let
                    json =
                        "[" ++ networkRouteJson ++ "," ++ plottedRouteJson ++ "]"
                in
                case Decode.decodeString JumpRouteLayer.routesDecoder json of
                    Ok routes ->
                        Expect.equal [ 1, 2 ] (List.map .id routes)

                    Err err ->
                        Expect.fail (Decode.errorToString err)
        ]


hiddenIdsCodecTests : Test
hiddenIdsCodecTests =
    describe "hiddenIdsCodec"
        [ Test.test "round-trips a set of ids through encode/decode" <|
            \_ ->
                let
                    ids =
                        Set.fromList [ 1, 4, 9 ]

                    encoded =
                        Codec.encodeToValue JumpRouteLayer.hiddenIdsCodec ids
                in
                Expect.equal (Ok ids) (Codec.decodeValue JumpRouteLayer.hiddenIdsCodec encoded)
        , Test.test "fails to decode an unrelated JSON shape" <|
            \_ ->
                Expect.equal True
                    (Codec.decodeValue JumpRouteLayer.hiddenIdsCodec (Encode.object [ ( "nope", Encode.bool True ) ])
                        |> Result.toMaybe
                        |> (==) Nothing
                    )
        ]
