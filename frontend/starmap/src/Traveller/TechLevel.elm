module Traveller.TechLevel exposing (TechLevel, description, isNone, parser)

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


{-| Tech level is encoded in the UWP as a single EHex digit (0-9, then A, B, C, ... skipping I and O), not a decimal number.
-}
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
        , Parser.succeed TenBasicFusionAge |. Parser.symbol "A"
        , Parser.succeed ElevenFusionPlusAge |. Parser.symbol "B"
        , Parser.succeed TwelvePositronicsAge |. Parser.symbol "C"
        , Parser.succeed ThirteenCloningAge |. Parser.symbol "D"
        , Parser.succeed FourteenGeneeringAge |. Parser.symbol "E"
        , Parser.succeed FifteenAnagathicsAge |. Parser.symbol "F"
        , Parser.succeed SixteenArtificialPersonsAge |. Parser.symbol "G"
        , Parser.succeed SeventeenPersonalityTransferAge |. Parser.symbol "H"
        , Parser.succeed EighteenExoticsAge |. Parser.symbol "J"
        , Parser.succeed NineteenAntimatterAge |. Parser.symbol "K"
        , Parser.succeed TwentySkipDriveAge |. Parser.symbol "L"
        , Parser.succeed TwentyOneStasisAge |. Parser.symbol "M"
        , Parser.succeed TwentyTwoPlanetScrubberAge |. Parser.symbol "N"
        , Parser.succeed TwentyThreePsychohistoryAge |. Parser.symbol "P"
        , Parser.succeed TwentyFourRosetteAge |. Parser.symbol "Q"
        , Parser.succeed TwentyFivePsionicEngineeringAge |. Parser.symbol "R"
        , Parser.succeed TwentySixStarEnergyAge |. Parser.symbol "S"
        , Parser.succeed TwentySevenRingworldAge |. Parser.symbol "T"
        , Parser.succeed TwentyEightRealityEngineeringAge |. Parser.symbol "U"
        , Parser.succeed TwentyNineDysonSphereAge |. Parser.symbol "V"
        , Parser.succeed ThirtyRemoteTechnologyAge |. Parser.symbol "W"
        , Parser.succeed ThirtyOnePocketUniverseAge |. Parser.symbol "X"
        ]


isNone : TechLevel -> Bool
isNone code =
    code == ZeroNeolithicAge


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
