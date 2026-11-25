module StellarObjectSummaryTests exposing (suite)

import Codec
import Expect
import Json.Decode as JsDecode
import SummaryFixtures
import Test exposing (Test, describe, test)
import Traveller.StellarObject exposing (StarData(..), StellarObject(..), codecStarData, decodeStellarObject, getInnerStarData, moonsPageDecoder, planetoidsPageDecoder)


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
        , test "an opened moon decodes as a planet that is a moon" <|
            \_ ->
                case JsDecode.decodeString decodeStellarObject SummaryFixtures.fullMoon of
                    Ok (TerrestrialPlanet d) ->
                        Expect.equal d.isMoon True

                    Ok _ ->
                        Expect.fail "expected a terrestrial planet"

                    Err e ->
                        Expect.fail (JsDecode.errorToString e)
        , test "a page of the Moons tab decodes to a row per moon (three of ten kept)" <|
            \_ ->
                case JsDecode.decodeString moonsPageDecoder SummaryFixtures.moonsPage of
                    Ok page ->
                        Expect.equal ( List.length page.moons, page.count, page.pages ) ( 3, 27, 3 )

                    Err e ->
                        Expect.fail (JsDecode.errorToString e)
        , test "an opened planetoid decodes as a planetoid" <|
            \_ ->
                case JsDecode.decodeString decodeStellarObject SummaryFixtures.fullPlanetoid of
                    Ok (Planetoid d) ->
                        Expect.equal d.moonCount 0

                    Ok _ ->
                        Expect.fail "expected a planetoid"

                    Err e ->
                        Expect.fail (JsDecode.errorToString e)
        , test "a page of the Planetoids tab decodes to a row per planetoid" <|
            \_ ->
                case JsDecode.decodeString planetoidsPageDecoder SummaryFixtures.planetoidsPage of
                    Ok page ->
                        Expect.equal ( List.length page.planetoids, page.count, page.pages )
                            ( 10, 93, 10 )

                    Err e ->
                        Expect.fail (JsDecode.errorToString e)
        ]
