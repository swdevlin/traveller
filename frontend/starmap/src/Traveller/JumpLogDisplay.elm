module Traveller.JumpLogDisplay exposing
    ( Mode(..)
    , Override
    , Settings
    , campaignCodec
    , dasharrayFor
    , defaultSettings
    , emptyOverride
    , isEmptyOverride
    , modeFromString
    , modeToString
    , overrideCodec
    , resolve
    , showsFill
    , showsLine
    )

{-| How the jump log is drawn: filled hexes, a line per jump, both, or neither.

The campaign supplies the defaults. A player's own choices are held as an
`Override`, with every field optional, and always win over the campaign value
for that field.

-}

import Codec exposing (Codec)


type Mode
    = Fill
    | Line
    | Both
    | Off


type alias Settings =
    { mode : Mode
    , fillColour : String
    , lineColour : String
    , lineStyle : String
    , lineWidth : Int
    }


type alias Override =
    { mode : Maybe Mode
    , fillColour : Maybe String
    , lineColour : Maybe String
    , lineStyle : Maybe String
    , lineWidth : Maybe Int
    }


defaultSettings : Settings
defaultSettings =
    { mode = Fill
    , fillColour = "#ffedd5"
    , lineColour = "#f97316"
    , lineStyle = "solid"
    , lineWidth = 4
    }


emptyOverride : Override
emptyOverride =
    { mode = Nothing
    , fillColour = Nothing
    , lineColour = Nothing
    , lineStyle = Nothing
    , lineWidth = Nothing
    }


isEmptyOverride : Override -> Bool
isEmptyOverride override =
    override == emptyOverride


showsFill : Settings -> Bool
showsFill settings =
    settings.mode == Fill || settings.mode == Both


showsLine : Settings -> Bool
showsLine settings =
    settings.mode == Line || settings.mode == Both


modeToString : Mode -> String
modeToString mode =
    case mode of
        Fill ->
            "fill"

        Line ->
            "line"

        Both ->
            "both"

        Off ->
            "none"


modeFromString : String -> Maybe Mode
modeFromString value =
    case value of
        "fill" ->
            Just Fill

        "line" ->
            Just Line

        "both" ->
            Just Both

        "none" ->
            Just Off

        _ ->
            Nothing


modeCodec : Codec Mode
modeCodec =
    Codec.andThen
        (\value ->
            case modeFromString value of
                Just mode ->
                    Codec.succeed mode

                Nothing ->
                    Codec.fail ("Unknown jump log display: " ++ value)
        )
        modeToString
        Codec.string


{-| The campaign defaults, as sent by `StarmapsController` (camelCase keys).
-}
campaignCodec : Codec Settings
campaignCodec =
    Codec.object Settings
        |> Codec.field "display" .mode modeCodec
        |> Codec.field "fillColour" .fillColour Codec.string
        |> Codec.field "lineColour" .lineColour Codec.string
        |> Codec.field "lineStyle" .lineStyle Codec.string
        |> Codec.field "lineWidth" .lineWidth Codec.int
        |> Codec.buildObject


{-| The player's stored choices. Unset fields are stored as null.
-}
overrideCodec : Codec Override
overrideCodec =
    Codec.object Override
        |> Codec.field "mode" .mode (Codec.maybe modeCodec)
        |> Codec.field "fillColour" .fillColour (Codec.maybe Codec.string)
        |> Codec.field "lineColour" .lineColour (Codec.maybe Codec.string)
        |> Codec.field "lineStyle" .lineStyle (Codec.maybe Codec.string)
        |> Codec.field "lineWidth" .lineWidth (Codec.maybe Codec.int)
        |> Codec.buildObject


{-| Personal choices win, field by field; anything unset falls back to the campaign.
-}
resolve : Settings -> Override -> Settings
resolve campaign override =
    { mode = Maybe.withDefault campaign.mode override.mode
    , fillColour = Maybe.withDefault campaign.fillColour override.fillColour
    , lineColour = Maybe.withDefault campaign.lineColour override.lineColour
    , lineStyle = Maybe.withDefault campaign.lineStyle override.lineStyle
    , lineWidth = Maybe.withDefault campaign.lineWidth override.lineWidth
    }


{-| Mirrors `JumpRoute::DASHARRAYS` in Rails; keep the two in step.
-}
dasharrayFor : String -> Maybe String
dasharrayFor style =
    case style of
        "dashed" ->
            Just "16,10"

        "dotted" ->
            Just "3,7"

        "dash_dot" ->
            Just "16,7,3,7"

        "dash_dot_dot" ->
            Just "16,7,3,7,3,7"

        "long_dash" ->
            Just "28,10"

        "short_dash" ->
            Just "8,7"

        _ ->
            Nothing
