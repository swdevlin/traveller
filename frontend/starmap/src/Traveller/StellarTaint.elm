module Traveller.StellarTaint exposing (StellarTaint, codecStellarTaint, taintSubtypeDescription, taintSeverityDescription, taintPersistenceDescription)

import Codec exposing (Codec)
import Json.Decode as JsDecode
import Json.Encode as JsEncode
import Parser exposing ((|.), (|=), Parser)
import Parser.Extras as Parser


type alias StellarTaint =
    { subtype : String, code : String, severity : Int, persistence : Int }


codecStellarTaint : Codec StellarTaint
codecStellarTaint =
    Codec.object StellarTaint
        |> Codec.field "subtype" .subtype Codec.string
        |> Codec.field "code" .code Codec.string
        |> Codec.field "severity" .severity Codec.int
        |> Codec.field "persistence" .persistence Codec.int
        |> Codec.buildObject


taintSubtypeDescription : String -> String
taintSubtypeDescription code =
    case String.toUpper (String.trim code) of
        "L" ->
            "Low Oxygen"

        "R" ->
            "Radioactivity"

        "B" ->
            "Biologic"

        "G" ->
            "Gas Mix"

        "P" ->
            "Particulates"

        "S" ->
            "Sulphur Compounds"

        "H" ->
            "High Oxygen"

        unknown ->
            "N/A" ++ " (Unknown subtype: " ++ unknown ++ ")"

taintSeverityDescription : Int -> String
taintSeverityDescription code =
    case code of
        1 ->
            "Trivial irritant (After 1D weeks acclimation, this taint is inconsequential)"

        2 ->
            "Surmountable irritant (After 1D months acclimation, this taint is inconsequential)"

        3 ->
            "Minor irritant (Surmountable on Difficult (10+) END check)"

        4 ->
            "Major irritant (Filter masks required or TL10+ medical intervention)"

        5 ->
            "Serious irritant (Filter masks required or TL12+ medical intervention)"

        6 ->
            "Hazardous irritant (Filter masks required or TL14+ medical intervention)"

        7 ->
            "Long term lethal: DM-2 to aging rolls (Filter masks required)"

        8 ->
            "Inevitably lethal: death within 1D days (Filter masks required; protective clothing recommended)"

        9 ->
            "Rapidly lethal: death within 1D minutes (Filter masks and protective clothing required)"

        _ ->
            "N/A"

taintPersistenceDescription : Int -> String
taintPersistenceDescription code =
    if code >= 9 then
        "Constant (Ever-present at indicated severity; no roll)"
    else
        case code of
            2 ->
                "Occasional and brief (Occurs periodically or on a 2D roll of 12 per day; lasts 1D hours)"

            3 ->
                "Occasional and lingering (Occurs periodically or on a 2D roll of 12 per day; lasts 1D days)"

            4 ->
                "Irregular (Occurs on 2D 9+; lasts D3 days)"

            5 ->
                "Fluctuating (Roll 2D daily: on 6- reduce severity by one level; on 12 increase severity by one level)"

            6 ->
                "Varying (Always present; roll 2D daily: on 6- reduce severity by one level for 1D hours)"

            7 ->
                "Varying (Always present; roll 2D daily: on 4- reduce severity by one level for 1D hours)"

            8 ->
                "Varying (Always present; roll 2D daily: on 2 reduce severity by one level for 1D hours)"

            _ ->
                "N/A"
