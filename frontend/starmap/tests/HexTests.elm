module HexTests exposing (..)

import Expect
import Fuzz
import Test exposing (Test, describe)
import Traveller.HexAddress exposing (toSectorAddress, universalToSectorX, universalToSectorY)


suite : Test
suite =
    describe "HexAddress"
        [ Test.fuzz2 (Fuzz.intRange 0 31) (Fuzz.intRange -3 3) "X tests" <|
            \x sx ->
                let
                    sectorX =
                        universalToSectorX { x = x + sx * 32, y = 17 }
                in
                Expect.equal sx <| sectorX
        , Test.fuzz2 (Fuzz.intRange 0 39) (Fuzz.intRange -3 3) "Y tests" <|
            \y sy ->
                let
                    sectorY =
                        universalToSectorY { x = 17, y = sy * 40 - y }

                    message =
                        String.fromInt (sy * 40 - y) ++ " -> " ++ String.fromInt sectorY ++ " : " ++ String.fromInt sy
                in
                Expect.onFail message <| Expect.equal sy <| sectorY
        ]


universalToSectorTests : Test
universalToSectorTests =
    describe "universalToSector"
        [ Test.test "Test 1" <|
            \_ ->
                let
                    uha =
                        { x = 17, y = -9 }

                    expected =
                        { sectorX = 0, sectorY = 0, x = 17, y = 9 }
                in
                Expect.equal expected <| toSectorAddress uha
        , Test.test "Test 1 sector rimward" <|
            \_ ->
                let
                    uha =
                        { x = 17, y = -42 }

                    expected =
                        { sectorX = 0, sectorY = -1, x = 17, y = 2 }
                in
                Expect.equal expected <| toSectorAddress uha
        , Test.test "Test 2" <|
            \_ ->
                let
                    uha =
                        { x = 17, y = 42 }

                    expected =
                        { sectorX = 0, sectorY = 2, x = 17, y = 38 }
                in
                Expect.equal expected <| toSectorAddress uha
        , Test.test "Test 3" <|
            \_ ->
                let
                    uha =
                        { x = 17, y = -90 }

                    expected =
                        { sectorX = 0, sectorY = -2, x = 17, y = 10 }
                in
                Expect.equal expected <| toSectorAddress uha
        , Test.test "Demnan" <|
            \_ ->
                let
                    uha =
                        { x = -290, y = -103 }

                    expected =
                        { sectorX = -10, sectorY = -2, x = 30, y = 23 }
                in
                Expect.equal expected <| toSectorAddress uha
        , Test.test "Origin" <|
            \_ ->
                let
                    uha =
                        { x = 0, y = 0 }

                    expected =
                        { sectorX = 0, sectorY = 0, x = 0, y = 0 }
                in
                Expect.equal expected <| toSectorAddress uha
        ]
