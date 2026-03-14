module Traveller.Hydrographics exposing (StellarHydrographics, codec, hydrographicsPercentageDescription, surfaceDistributionDescription)

import Codec exposing (Codec)


type alias StellarHydrographics =
    { code : Int, distribution : Int }


codec : Codec StellarHydrographics
codec =
    Codec.object StellarHydrographics
        |> Codec.field "code" .code Codec.int
        |> Codec.field "distribution" .distribution Codec.int
        |> Codec.buildObject


hydrographicsPercentageDescription : Int -> String
hydrographicsPercentageDescription code =
    String.fromInt (code * 10) ++ "%"


surfaceDistributionDescription : Maybe Int -> String
surfaceDistributionDescription code =
    case code of
        Nothing ->
            "No liquid present"

        Just 0 ->
            "Extremely Dispersed (Many minor and small bodies: no major bodies)"

        Just 1 ->
            "Very Dispersed (Mostly minor bodies: 5–10% of the surface coverage is in major bodies)"

        Just 2 ->
            "Dispersed (Mostly minor bodies: 10–20% of the surface coverage is in major bodies)"

        Just 3 ->
            "Scattered (Roughly 20–30% or less of the surface coverage is in major bodies)"

        Just 4 ->
            "Slightly Scattered (Roughly 30–40% or less of the surface coverage is in major bodies)"

        Just 5 ->
            "Mixed (Mix of major and minor bodies: roughly 40–60% of body coverage is major)"

        Just 6 ->
            "Slightly Skewed (Roughly 60–70% of surface coverage is in major bodies)"

        Just 7 ->
            "Skewed (Roughly 70–80% of surface coverage is in major bodies)"

        Just 8 ->
            "Concentrated (Mostly major bodies: 80–90% of the surface coverage is in major bodies)"

        Just 9 ->
            "Very Concentrated (Single very large major body: 90–95% of body coverage is in one body)"

        Just 10 ->
            "Extremely Concentrated (Single very large major body: 95% or more of body coverage is in one body)"

        Just _ ->
            "Unknown surface distribution code"
