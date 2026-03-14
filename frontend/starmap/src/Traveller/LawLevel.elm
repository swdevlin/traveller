module Traveller.LawLevel exposing (LawLevel, description, parser)

import Parser exposing ((|.), Parser)


type LawLevel
    = ZeroNoLaw
    | OneLowLaw
    | TwoLowLaw
    | ThreeLowLaw
    | FourModerateLaw
    | FiveModerateLaw
    | SixModerateLaw
    | SevenModerateLaw
    | EightHighLaw
    | NineHighLaw
    | AExtremeLaw
    | BExtremeLaw
    | CExtremeLaw
    | DExtremeLaw
    | EExtremeLaw
    | FExtremeLaw
    | GExtremeLaw
    | HExtremeLaw
    | JExtremeLaw


parser : Parser LawLevel
parser =
    Parser.oneOf
        [ Parser.succeed ZeroNoLaw |. Parser.symbol "0"
        , Parser.succeed OneLowLaw |. Parser.symbol "1"
        , Parser.succeed TwoLowLaw |. Parser.symbol "2"
        , Parser.succeed ThreeLowLaw |. Parser.symbol "3"
        , Parser.succeed FourModerateLaw |. Parser.symbol "4"
        , Parser.succeed FiveModerateLaw |. Parser.symbol "5"
        , Parser.succeed SixModerateLaw |. Parser.symbol "6"
        , Parser.succeed SevenModerateLaw |. Parser.symbol "7"
        , Parser.succeed EightHighLaw |. Parser.symbol "8"
        , Parser.succeed NineHighLaw |. Parser.symbol "9"
        , Parser.succeed AExtremeLaw |. Parser.symbol "A"
        , Parser.succeed BExtremeLaw |. Parser.symbol "B"
        , Parser.succeed CExtremeLaw |. Parser.symbol "C"
        , Parser.succeed DExtremeLaw |. Parser.symbol "D"
        , Parser.succeed EExtremeLaw |. Parser.symbol "E"
        , Parser.succeed FExtremeLaw |. Parser.symbol "F"
        , Parser.succeed GExtremeLaw |. Parser.symbol "G"
        , Parser.succeed HExtremeLaw |. Parser.symbol "H"
        , Parser.succeed JExtremeLaw |. Parser.symbol "J"
        ]


description : LawLevel -> String
description code =
    case code of
        ZeroNoLaw ->
            "Body Pistols, Explosives, Nuclear Weapons, Poison Gas"

        OneLowLaw ->
            "Portable Energy Weapons"

        TwoLowLaw ->
            "Machine Guns, Automatic Weapons, Flamethrowers, military weapons"

        ThreeLowLaw ->
            "Light Assault Weapons, Submachine guns, All Energy weapons."

        FourModerateLaw ->
            "Personal Concealable Firearms, EMP weapons, Radiation weapons, Non-automatic fire Gauss weapons"

        FiveModerateLaw ->
            "All firearms except Shotguns"

        SixModerateLaw ->
            "Shotguns"

        SevenModerateLaw ->
            "Blade Weapons Controlled, open display of weapons"

        EightHighLaw ->
            "Weapons outside home"

        NineHighLaw ->
            "Weapon possession"

        AExtremeLaw ->
            "Rigid control of civilian movement"

        BExtremeLaw ->
            "Unrestricted invasion of privacy"

        CExtremeLaw ->
            "Paramilitary law enforcement"

        DExtremeLaw ->
            "Full-fledged police state"

        EExtremeLaw ->
            "All facets of daily life rigidly controlled"

        FExtremeLaw ->
            "Severe punishment for petty infractions"

        GExtremeLaw ->
            "Legalized oppressive practices"

        HExtremeLaw ->
            "Legalized oppressive practices"

        JExtremeLaw ->
            "Legalized oppressive practices"
