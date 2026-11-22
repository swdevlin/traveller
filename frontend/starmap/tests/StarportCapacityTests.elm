module StarportCapacityTests exposing (suite)

import Codec
import Expect
import Json.Decode as JsDecode
import Test exposing (Test, describe, test)
import Traveller.StarportCapacity as StarportCapacity


decode : String -> Result JsDecode.Error StarportCapacity.StarportCapacity
decode =
    JsDecode.decodeString (Codec.decoder StarportCapacity.codec)


suite : Test
suite =
    describe "StarportCapacity"
        [ test "decodes the REST shape" <|
            \_ ->
                decode """{"has_highport": true, "highport": 2020000, "downport": 808000, "internal_bay_capacity": 202000, "shipyard_capability": "starships", "shipyard_build_capacity": 2130000, "annual_shipyard_output": 532500}"""
                    |> Result.map StarportCapacity.rows
                    |> Expect.equal
                        (Ok
                            [ ( "Highport", "Present" )
                            , ( "Highport Capacity", "2,020,000 tons" )
                            , ( "Downport Capacity", "808,000 tons" )
                            , ( "Internal Bays", "202,000 tons" )
                            , ( "Shipyard", "Starships" )
                            , ( "Shipyard Build", "2,130,000 tons" )
                            , ( "Annual Output", "532,500 tons / year" )
                            ]
                        )
        , test "leaves out figures that are null" <|
            \_ ->
                decode """{"has_highport": false, "highport": null, "downport": 1000, "internal_bay_capacity": null, "shipyard_capability": "none", "shipyard_build_capacity": null, "annual_shipyard_output": null}"""
                    |> Result.map StarportCapacity.rows
                    |> Expect.equal
                        (Ok
                            [ ( "Highport", "None" )
                            , ( "Downport Capacity", "1,000 tons" )
                            , ( "Shipyard", "None" )
                            ]
                        )
        , test "an empty object decodes to no rows" <|
            \_ ->
                decode "{}"
                    |> Result.map StarportCapacity.rows
                    |> Expect.equal (Ok [])
        , test "small craft shipyards get a readable label" <|
            \_ ->
                decode """{"shipyard_capability": "smallCraft"}"""
                    |> Result.map StarportCapacity.rows
                    |> Expect.equal (Ok [ ( "Shipyard", "Small craft" ) ])
        ]
