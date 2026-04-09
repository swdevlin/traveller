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
            "#3366BB"

        Just BlueWhite ->
            "#5588CC"

        Just White ->
            "#8899AA"

        Just YellowWhite ->
            "#BBAA44"

        Just Yellow ->
            "#CC8800"

        Just LightOrange ->
            "#CC6622"

        Just OrangeRed ->
            "#CC3311"

        Just Red ->
            "#BB1111"

        Just Brown ->
            "#886644"

        Just DeepDimRed ->
            "#882255"

        Nothing ->
            "#778899"


{-| Fill colour for star circles in SVG diagrams — tuned for light backgrounds.
-}
starFillColour : Maybe StarColour -> String
starFillColour colour =
    case colour of
        Just Blue ->
            "#3366BB"

        Just BlueWhite ->
            "#5588CC"

        Just White ->
            "#8899AA"

        Just YellowWhite ->
            "#BBAA44"

        Just Yellow ->
            "#CC8800"

        Just LightOrange ->
            "#CC6622"

        Just OrangeRed ->
            "#CC3311"

        Just Red ->
            "#BB1111"

        Just Brown ->
            "#886644"

        Just DeepDimRed ->
            "#882255"

        Nothing ->
            "#778899"
