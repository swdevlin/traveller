module StellarObjectSummaryTests exposing (suite)

import Codec
import Expect
import Json.Decode as JsDecode
import SummaryFixtures
import Test exposing (Test, describe, test)
import Traveller.StellarObject exposing (StarData(..), StellarObject(..), codecStarData, decodeStellarObject, getInnerStarData)


decodeStar : String -> Result JsDecode.Error StarData
decodeStar =
    JsDecode.decodeString (Codec.decoder codecStarData)


objects : String -> List StellarObject
objects json =
    case decodeStar json of
        Ok star ->
            (getInnerStarData star).stellarObjects

        Err _ ->
            []


isGasGiant : StellarObject -> Bool
isGasGiant so =
    case so of
        GasGiant _ ->
            True

        _ ->
            False


isBelt : StellarObject -> Bool
isBelt so =
    case so of
        PlanetoidBelt _ ->
            True

        _ ->
            False


isPlanetoid : StellarObject -> Bool
isPlanetoid so =
    case so of
        Planetoid _ ->
            True

        _ ->
            False


suite : Test
suite =
    describe "decoding the summary system tree and the opened object"
        [ test "a Big Drizzle summary tree decodes" <|
            \_ ->
                decodeStar SummaryFixtures.drizzleTree
                    |> Result.map (always ())
                    |> Result.mapError JsDecode.errorToString
                    |> Expect.equal (Ok ())
        , test "it keeps every kind of body" <|
            \_ ->
                let
                    all =
                        objects SummaryFixtures.drizzleTree
                in
                Expect.equal
                    ( List.any isGasGiant all, List.any isBelt all, List.any isPlanetoid all )
                    ( True, True, True )
        , test "an opened gas giant decodes with its moon count" <|
            \_ ->
                case JsDecode.decodeString decodeStellarObject SummaryFixtures.fullGasGiant of
                    Ok (GasGiant d) ->
                        Expect.equal d.moonCount 15

                    Ok _ ->
                        Expect.fail "expected a gas giant"

                    Err e ->
                        Expect.fail (JsDecode.errorToString e)
        ]
