module Traveller.StarColour exposing (StarColour, codecStarColour, starColourRGB)

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
