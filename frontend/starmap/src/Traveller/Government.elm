module Traveller.Government exposing (Government, description, parser)

import Parser exposing ((|.), Parser)


type Government
    = ZeroNoGovernmentStructure
    | OneCompanyCorporation
    | TwoParticipatingDemocracy
    | ThreeSelfPerpetuatingOligarchy
    | FourRepresentativeDemocracy
    | FiveFeudalTechnocracy
    | SixCaptiveGovernmentColony
    | SevenBalkanization
    | EightCivilServiceBureaucracy
    | NineImpersonalBureaucracy
    | ACharismaticDictator
    | BNonCharismaticLeader
    | CCharismaticOligarchy
    | DReligiousDictatorship
    | EReligiousAutocracy
    | FTotalitarianOligarchy


parser : Parser Government
parser =
    Parser.oneOf
        [ Parser.succeed ZeroNoGovernmentStructure |. Parser.symbol "0"
        , Parser.succeed OneCompanyCorporation |. Parser.symbol "1"
        , Parser.succeed TwoParticipatingDemocracy |. Parser.symbol "2"
        , Parser.succeed ThreeSelfPerpetuatingOligarchy |. Parser.symbol "3"
        , Parser.succeed FourRepresentativeDemocracy |. Parser.symbol "4"
        , Parser.succeed FiveFeudalTechnocracy |. Parser.symbol "5"
        , Parser.succeed SixCaptiveGovernmentColony |. Parser.symbol "6"
        , Parser.succeed SevenBalkanization |. Parser.symbol "7"
        , Parser.succeed EightCivilServiceBureaucracy |. Parser.symbol "8"
        , Parser.succeed NineImpersonalBureaucracy |. Parser.symbol "9"
        , Parser.succeed ACharismaticDictator |. Parser.symbol "A"
        , Parser.succeed BNonCharismaticLeader |. Parser.symbol "B"
        , Parser.succeed CCharismaticOligarchy |. Parser.symbol "C"
        , Parser.succeed DReligiousDictatorship |. Parser.symbol "D"
        , Parser.succeed EReligiousAutocracy |. Parser.symbol "E"
        , Parser.succeed FTotalitarianOligarchy |. Parser.symbol "F"
        ]


description : Government -> String
description code =
    case code of
        ZeroNoGovernmentStructure ->
            "No Government Structure"

        OneCompanyCorporation ->
            "Company/Corporation"

        TwoParticipatingDemocracy ->
            "Participating Democracy"

        ThreeSelfPerpetuatingOligarchy ->
            "Self-perpetuating Oligarchy"

        FourRepresentativeDemocracy ->
            "Representative Democracy"

        FiveFeudalTechnocracy ->
            "Feudal Technocracy"

        SixCaptiveGovernmentColony ->
            "Captive Government/Colony"

        SevenBalkanization ->
            "Balkanization"

        EightCivilServiceBureaucracy ->
            "Civil Service Bureaucracy"

        NineImpersonalBureaucracy ->
            "Impersonal Bureaucracy"

        ACharismaticDictator ->
            "Charismatic Dictator"

        BNonCharismaticLeader ->
            "Non-Charismatic Leader"

        CCharismaticOligarchy ->
            "Charismatic Oligarchy"

        DReligiousDictatorship ->
            "Religious Dictatorship"

        EReligiousAutocracy ->
            "Religious Autocracy"

        FTotalitarianOligarchy ->
            "Totalitarian Oligarchy"
