module Traveller.Population exposing (Population(..), StellarPopulation, codec, population, populationDescription)

import Codec exposing (Codec)
import Json.Decode as JsDecode
import Json.Encode as JsEncode
import Parser exposing ((|.), (|=), Parser)
import Parser.Extras as Parser


type alias StellarPopulation =
    { code : Int, concentrationRating : Maybe Float }


codec : Codec StellarPopulation
codec =
    Codec.object StellarPopulation
        |> Codec.field "code" .code Codec.int
        |> Codec.field "concentrationRating" .concentrationRating (Codec.maybe Codec.float)
        |> Codec.buildObject



{- Population codes

   Population Codes
   Code    Description    Population (where P is the population multiplier)
   0    None    0
   1    Low    1 to 99 (P0)
   2    Low    100 to 999 (P00)
   3    Low    1,000 to 9,999 (P,000)
   4    Moderate    10,000 to 99,999 (P0,000)
   5    Moderate    100,000 to 999,999 (P00,000)
   6    Moderate    1 Million to just under 10 Million (P,000,000)
   7    Moderate    10 Million to just under 100 Million (P0,000,000)
   8    Pre-High    100 Million to just under 1 Billion (P00,000,000)
   9    High    1 Billion to just under 10 Billion (P,000,000,000)
   A    High    10 Billion to just under 100 Billion (P0,000,000,000)
   B    High    100 Billion to just under 1 Trillion (P00,000,000,000)
   C    Very High    1 Trillion to just under 10 Trillion (P,000,000,000,000)

-}


type Population
    = ZeroNone
    | OneLow
    | TwoLow
    | ThreeLow
    | FourModerate
    | FiveModerate
    | SixModerate
    | SevenModerate
    | EightPreHigh
    | NineHigh
    | AHigh
    | BHigh
    | CVeryHigh


population : Parser Population
population =
    Parser.oneOf
        [ Parser.succeed ZeroNone |. Parser.symbol "0"
        , Parser.succeed OneLow |. Parser.symbol "1"
        , Parser.succeed TwoLow |. Parser.symbol "2"
        , Parser.succeed ThreeLow |. Parser.symbol "3"
        , Parser.succeed FourModerate |. Parser.symbol "4"
        , Parser.succeed FiveModerate |. Parser.symbol "5"
        , Parser.succeed SixModerate |. Parser.symbol "6"
        , Parser.succeed SevenModerate |. Parser.symbol "7"
        , Parser.succeed EightPreHigh |. Parser.symbol "8"
        , Parser.succeed NineHigh |. Parser.symbol "9"
        , Parser.succeed AHigh |. Parser.symbol "A"
        , Parser.succeed BHigh |. Parser.symbol "B"
        , Parser.succeed CVeryHigh |. Parser.symbol "C"
        ]


populationDescription : Population -> String
populationDescription code =
    case code of
        ZeroNone ->
            "None"

        OneLow ->
            "Tens"

        TwoLow ->
            "Hundreds"

        ThreeLow ->
            "Thousands"

        FourModerate ->
            "Tens of Thousands"

        FiveModerate ->
            "Hundreds of Thousands"

        SixModerate ->
            "Millions"

        SevenModerate ->
            "Tens of Millions"

        EightPreHigh ->
            "Hundreds of Millions"

        NineHigh ->
            "Billions"

        AHigh ->
            "Tens of Billions"

        BHigh ->
            "Hundreds of Billions"

        CVeryHigh ->
            "Trillions"
