module StarOrbitMapTests exposing (suite)

import Expect
import Test exposing (Test, describe, test)
import Traveller.StarOrbitMap exposing (relativeOrbitPosition)


suite : Test
suite =
    describe "orbit coordinate frames"
        [ test "B I keeps its imported position relative to star B in system 49986" <|
            \_ ->
                relativeOrbitPosition
                    { x = 73184761279.09895, y = 69900141353.53479 }
                    { x = -687500.3922265603, y = -363985.5931330131 }
                    0.0052
                    |> Expect.equal { x = -687500.3922265603, y = -363985.5931330131 }
        , test "absolute positions are translated back to the parent star" <|
            \_ ->
                relativeOrbitPosition
                    { x = 73000000000, y = 69000000000 }
                    { x = 72999300000, y = 68999600000 }
                    0.0054
                    |> Expect.equal { x = -700000, y = -400000 }
        , test "primary-star positions remain unchanged" <|
            \_ ->
                relativeOrbitPosition
                    { x = 0, y = 0 }
                    { x = 149597870.7, y = 0 }
                    1
                    |> Expect.equal { x = 149597870.7, y = 0 }
        ]
