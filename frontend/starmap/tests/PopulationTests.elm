module PopulationTests exposing (suite)

import Expect
import Test exposing (Test, describe, test)
import Traveller.Population as Population exposing (Population(..))


suite : Test
suite =
    describe "Population.isNone"
        [ test "ZeroNone is none" <|
            \_ -> Expect.equal True (Population.isNone ZeroNone)
        , test "OneLow is not none" <|
            \_ -> Expect.equal False (Population.isNone OneLow)
        , test "TwoLow is not none" <|
            \_ -> Expect.equal False (Population.isNone TwoLow)
        , test "ThreeLow is not none" <|
            \_ -> Expect.equal False (Population.isNone ThreeLow)
        , test "FourModerate is not none" <|
            \_ -> Expect.equal False (Population.isNone FourModerate)
        , test "FiveModerate is not none" <|
            \_ -> Expect.equal False (Population.isNone FiveModerate)
        , test "SixModerate is not none" <|
            \_ -> Expect.equal False (Population.isNone SixModerate)
        , test "SevenModerate is not none" <|
            \_ -> Expect.equal False (Population.isNone SevenModerate)
        , test "EightPreHigh is not none" <|
            \_ -> Expect.equal False (Population.isNone EightPreHigh)
        , test "NineHigh is not none" <|
            \_ -> Expect.equal False (Population.isNone NineHigh)
        , test "AHigh is not none" <|
            \_ -> Expect.equal False (Population.isNone AHigh)
        , test "BHigh is not none" <|
            \_ -> Expect.equal False (Population.isNone BHigh)
        , test "CVeryHigh is not none" <|
            \_ -> Expect.equal False (Population.isNone CVeryHigh)
        , test "isNoneCode \"0\" is True" <|
            \_ -> Expect.equal True (Population.isNoneCode "0")
        , test "isNoneCode \"1\" is False" <|
            \_ -> Expect.equal False (Population.isNoneCode "1")
        , test "isNoneCode \"A\" is False" <|
            \_ -> Expect.equal False (Population.isNoneCode "A")
        ]
