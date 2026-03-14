module BetweenTests exposing (..)

import Expect
import Fuzz
import Test exposing (Test, describe)
import Traveller.HexAddress as HexAddress exposing (toSectorAddress, universalToSectorX, universalToSectorY)


betweenTests : Test
betweenTests =
    describe "Between"
        [ Test.test "Horizontal line" <|
            \_ ->
                let
                    upperLeft =
                        { x = 12, y = 1 }

                    lowerRight =
                        { x = 16, y = 1 }

                    expected =
                        [ { x = 12, y = 1 }, { x = 13, y = 1 }, { x = 14, y = 1 }, { x = 15, y = 1 }, { x = 16, y = 1 } ]

                    hexes =
                        HexAddress.between upperLeft lowerRight
                in
                Expect.equal expected <| hexes
        , Test.test "Vertical line" <|
            \_ ->
                let
                    upperLeft =
                        { y = 16, x = 1 }

                    lowerRight =
                        { y = 12, x = 1 }

                    expected =
                        [ { y = 12, x = 1 }, { y = 13, x = 1 }, { y = 14, x = 1 }, { y = 15, x = 1 }, { y = 16, x = 1 } ]

                    hexes =
                        HexAddress.between upperLeft lowerRight
                in
                Expect.equal expected <| hexes
        , Test.test "Box" <|
            \_ ->
                let
                    upperLeft =
                        { x = 1, y = 15 }

                    lowerRight =
                        { x = 2, y = 14 }

                    expected =
                        [ { x = 1, y = 14 }, { x = 1, y = 15 }, { x = 2, y = 14 }, { x = 2, y = 15 } ]

                    hexes =
                        HexAddress.between upperLeft lowerRight
                in
                Expect.equal expected <| hexes
        ]
