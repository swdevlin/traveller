module Traveller.StarColour exposing (StarColour, codecStarColour, starColourName, starColourRGB, starFillColour)

import Codec exposing (Codec)


type StarColour
    = Blue
    | BlueWhite
    | White
    | YellowWhite
    | Yellow
    | LightOrange
    | OrangeRed
    | Red
    | Brown
    | DeepDimRed


codecStarColour : Codec StarColour
codecStarColour =
    Codec.enum Codec.string
        [ ( "Blue", Blue )
        , ( "Blue White", BlueWhite )
        , ( "White", White )
        , ( "Yellow White", YellowWhite )
        , ( "Yellow", Yellow )
        , ( "Light Orange", LightOrange )
        , ( "Orange Red", OrangeRed )
        , ( "Red", Red )
        , ( "Brown", Brown )
        , ( "Deep Dim Red", DeepDimRed )
        ]


starColourName : Maybe StarColour -> String
starColourName colour =
    case colour of
        Just Blue ->
            "Blue"

        Just BlueWhite ->
            "Blue White"

        Just White ->
            "White"

        Just YellowWhite ->
            "Yellow White"

        Just Yellow ->
            "Yellow"

        Just LightOrange ->
            "Light Orange"

        Just OrangeRed ->
            "Orange Red"

        Just Red ->
            "Red"

        Just Brown ->
            "Brown"

        Just DeepDimRed ->
            "Deep Dim Red"

        Nothing ->
            "—"


starColourRGB : Maybe StarColour -> String
starColourRGB colour =
    case colour of
        Just Blue ->
            "#000077"

        Just BlueWhite ->
            "#87cefa"

        Just White ->
            "#FFFFFF"

        Just YellowWhite ->
            "#ffffe0"

        Just Yellow ->
            "#ffff00"

        Just LightOrange ->
            "#ffbf00"

        Just OrangeRed ->
            "#ff4500"

        Just Red ->
            "#ff0000"

        Just Brown ->
            "#f4a460"

        Just DeepDimRed ->
            "#800000"

        Nothing ->
            "#000000"


{-| Fill colour for star circles in SVG diagrams — tuned for dark backgrounds.
-}
starFillColour : Maybe StarColour -> String
starFillColour colour =
    case colour of
        Just Blue ->
            "#6baed6"

        Just BlueWhite ->
            "#9ecae1"

        Just White ->
            "#e5e5e5"

        Just YellowWhite ->
            "#fee391"

        Just Yellow ->
            "#fed976"

        Just LightOrange ->
            "#fd8d3c"

        Just OrangeRed ->
            "#e6550d"

        Just Red ->
            "#de2d26"

        Just Brown ->
            "#8c6d31"

        Just DeepDimRed ->
            "#7a0177"

        Nothing ->
            "#969696"
