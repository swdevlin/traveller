module Traveller.TechLevel exposing (TechLevel, description, parser)

{- Tech Level
   Technology Levels
   TL    Era or key development
   0    Neolithic Age
   1    Metal Age
   2    Age of Sail
   3    Industrial Age
   4    Mechanized Age
   5    Broadcast Age
   6    Atomic Age
   7    Space Age
   8    Information Age
   9    Gravitics Age; First Jump Drives
   10    Basic Fusion Age
   11    Fusion Plus Age
   12    Positronics Age
   13    Cloning Age
   14    Geneering Age
   15    Anagathics Age
   16    Artificial Persons Age
   17    Personality Transfer Age
   18    Exotics Age
   19    Antimatter Age
   20    Skip Drive Age
   21    Stasis Age
   22    Planet-scrubber Age
   23    Psychohistory Age
   24    Rosette Age
   25    Psionic Engineering Age
   26    Star Energy Age
   27    Ringworld Age
   28    Reality Engineering Age
   29    Dyson Sphere Age
   30    Remote Technology Age
   31    Pocket Universe Age

-}

import Parser exposing ((|.), Parser)


type TechLevel
    = ZeroNeolithicAge
    | OneMetalAge
    | TwoAgeOfSail
    | ThreeIndustrialAge
    | FourMechanizedAge
    | FiveBroadcastAge
    | SixAtomicAge
    | SevenSpaceAge
    | EightInformationAge
    | NineGraviticsAge
    | TenBasicFusionAge
    | ElevenFusionPlusAge
    | TwelvePositronicsAge
    | ThirteenCloningAge
    | FourteenGeneeringAge
    | FifteenAnagathicsAge
    | SixteenArtificialPersonsAge
    | SeventeenPersonalityTransferAge
    | EighteenExoticsAge
    | NineteenAntimatterAge
    | TwentySkipDriveAge
    | TwentyOneStasisAge
    | TwentyTwoPlanetScrubberAge
    | TwentyThreePsychohistoryAge
    | TwentyFourRosetteAge
    | TwentyFivePsionicEngineeringAge
    | TwentySixStarEnergyAge
    | TwentySevenRingworldAge
    | TwentyEightRealityEngineeringAge
    | TwentyNineDysonSphereAge
    | ThirtyRemoteTechnologyAge
    | ThirtyOnePocketUniverseAge


parser : Parser TechLevel
parser =
    Parser.oneOf
        [ Parser.succeed ZeroNeolithicAge |. Parser.symbol "0"
        , Parser.succeed OneMetalAge |. Parser.symbol "1"
        , Parser.succeed TwoAgeOfSail |. Parser.symbol "2"
        , Parser.succeed ThreeIndustrialAge |. Parser.symbol "3"
        , Parser.succeed FourMechanizedAge |. Parser.symbol "4"
        , Parser.succeed FiveBroadcastAge |. Parser.symbol "5"
        , Parser.succeed SixAtomicAge |. Parser.symbol "6"
        , Parser.succeed SevenSpaceAge |. Parser.symbol "7"
        , Parser.succeed EightInformationAge |. Parser.symbol "8"
        , Parser.succeed NineGraviticsAge |. Parser.symbol "9"
        , Parser.succeed TenBasicFusionAge |. Parser.symbol "10"
        , Parser.succeed ElevenFusionPlusAge |. Parser.symbol "11"
        , Parser.succeed TwelvePositronicsAge |. Parser.symbol "12"
        , Parser.succeed ThirteenCloningAge |. Parser.symbol "13"
        , Parser.succeed FourteenGeneeringAge |. Parser.symbol "14"
        , Parser.succeed FifteenAnagathicsAge |. Parser.symbol "15"
        , Parser.succeed SixteenArtificialPersonsAge |. Parser.symbol "16"
        , Parser.succeed SeventeenPersonalityTransferAge |. Parser.symbol "17"
        , Parser.succeed EighteenExoticsAge |. Parser.symbol "18"
        , Parser.succeed NineteenAntimatterAge |. Parser.symbol "19"
        , Parser.succeed TwentySkipDriveAge |. Parser.symbol "20"
        , Parser.succeed TwentyOneStasisAge |. Parser.symbol "21"
        , Parser.succeed TwentyTwoPlanetScrubberAge |. Parser.symbol "22"
        , Parser.succeed TwentyThreePsychohistoryAge |. Parser.symbol "23"
        , Parser.succeed TwentyFourRosetteAge |. Parser.symbol "24"
        , Parser.succeed TwentyFivePsionicEngineeringAge |. Parser.symbol "25"
        , Parser.succeed TwentySixStarEnergyAge |. Parser.symbol "26"
        , Parser.succeed TwentySevenRingworldAge |. Parser.symbol "27"
        , Parser.succeed TwentyEightRealityEngineeringAge |. Parser.symbol "28"
        , Parser.succeed TwentyNineDysonSphereAge |. Parser.symbol "29"
        , Parser.succeed ThirtyRemoteTechnologyAge |. Parser.symbol "30"
        , Parser.succeed ThirtyOnePocketUniverseAge |. Parser.symbol "31"
        ]


description : TechLevel -> String
description code =
    case code of
        ZeroNeolithicAge ->
            "Neolithic Age"

        OneMetalAge ->
            "Metal Age"

        TwoAgeOfSail ->
            "Age of Sail"

        ThreeIndustrialAge ->
            "Industrial Age"

        FourMechanizedAge ->
            "Mechanized Age"

        FiveBroadcastAge ->
            "Broadcast Age"

        SixAtomicAge ->
            "Atomic Age"

        SevenSpaceAge ->
            "Space Age"

        EightInformationAge ->
            "Information Age"

        NineGraviticsAge ->
            "Gravitics Age; First Jump Drives"

        TenBasicFusionAge ->
            "Basic Fusion Age"

        ElevenFusionPlusAge ->
            "Fusion Plus Age"

        TwelvePositronicsAge ->
            "Positronics Age"

        ThirteenCloningAge ->
            "Cloning Age"

        FourteenGeneeringAge ->
            "Geneering Age"

        FifteenAnagathicsAge ->
            "Anagathics Age"

        SixteenArtificialPersonsAge ->
            "Artificial Persons Age"

        SeventeenPersonalityTransferAge ->
            "Personality Transfer Age"

        EighteenExoticsAge ->
            "Exotics Age"

        NineteenAntimatterAge ->
            "Antimatter Age"

        TwentySkipDriveAge ->
            "Skip Drive Age"

        TwentyOneStasisAge ->
            "Stasis Age"

        TwentyTwoPlanetScrubberAge ->
            "Planet-scrubber Age"

        TwentyThreePsychohistoryAge ->
            "Psychohistory Age"

        TwentyFourRosetteAge ->
            "Rosette Age"

        TwentyFivePsionicEngineeringAge ->
            "Psionic Engineering Age"

        TwentySixStarEnergyAge ->
            "Star Energy Age"

        TwentySevenRingworldAge ->
            "Ringworld Age"

        TwentyEightRealityEngineeringAge ->
            "Reality Engineering Age"

        TwentyNineDysonSphereAge ->
            "Dyson Sphere Age"

        ThirtyRemoteTechnologyAge ->
            "Remote Technology Age"

        ThirtyOnePocketUniverseAge ->
            "Pocket Universe Age"
