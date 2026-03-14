module Traveller.UI exposing
    ( colorToElementColor
    , deepnightColor
    , deepnightGray
    , deepnightLightGray
    , descriptionStyle
    , floatDisplay
    , fontDarkTextColor
    , fontTextColor
    , groupAttrs
    , headerAttrs
    , imageStyle
    , jumpShadowTextColor
    , monospaceText
    , numberDisplay
    , orbitStyle
    , safeJumpStyle
    , sequenceStyle
    , taintTextDisplay
    , textColor
    , textDisplay
    , textDisplayMedium
    , textDisplayNarrow
    , travelStyle
    , travellerRed
    , uiDeepnightColorFontColour
    , valueAttrs
    , zeroEach
    )

import Color
import Color.Manipulate
import Element
    exposing
        ( el
        , fill
        , row
        , text
        , width
        )
import Element.Font as Font


{-| Convert a Color.Color to an Element.Color
-}
colorToElementColor : Color.Color -> Element.Color
colorToElementColor color =
    color
        |> Color.toRgba
        |> (\{ red, green, blue, alpha } -> Element.rgba red green blue alpha)



-- Color Constants (Color.Color)


{-| Color.Color is not Element.Color
-}
textColor : Color.Color
textColor =
    Color.rgb 0.5 1.0 0.5


deepnightColor : Color.Color
deepnightColor =
    Color.rgb255 223 127 51


deepnightLightGray : Color.Color
deepnightLightGray =
    Color.rgb255 167 180 183


deepnightGray : Color.Color
deepnightGray =
    Color.rgb255 121 137 144



-- Element Colors


fontTextColor : Element.Color
fontTextColor =
    textColor |> colorToElementColor


fontDarkTextColor : Element.Color
fontDarkTextColor =
    textColor
        |> Color.Manipulate.desaturate 0.85
        |> Color.Manipulate.darken 0.25
        |> colorToElementColor


jumpShadowTextColor : Element.Color
jumpShadowTextColor =
    textColor
        |> Color.Manipulate.desaturate 0.85
        |> Color.Manipulate.darken 0.85
        |> colorToElementColor


travellerRed : Element.Color
travellerRed =
    Element.rgb 0.882 0.024 0


uiDeepnightColorFontColour : Element.Attribute msg
uiDeepnightColorFontColour =
    Font.color <| colorToElementColor <| deepnightColor



-- Style Attributes


orbitStyle : List (Element.Attribute msg)
orbitStyle =
    [ width <| Element.px 45
    , Element.alignRight
    ]


descriptionStyle : List (Element.Attribute msg)
descriptionStyle =
    [ width <| Element.px 84
    ]


sequenceStyle : List (Element.Attribute msg)
sequenceStyle =
    [ width <| Element.px 60
    ]


safeJumpStyle : List (Element.Attribute msg)
safeJumpStyle =
    [ width <| Element.px 62
    , Font.size 12
    ]


imageStyle : List (Element.Attribute msg)
imageStyle =
    [ width <| Element.px 40
    ]


travelStyle : List (Element.Attribute msg)
travelStyle =
    [ width <| Element.px 60
    ]



-- Text Helpers


{-| Builds a monospace text element
-}
monospaceText : String -> Element.Element msg
monospaceText someString =
    text someString |> el [ Font.family [ Font.monospace ] ]


zeroEach : { top : number, left : number, bottom : number, right : number }
zeroEach =
    { top = 0, left = 0, bottom = 0, right = 0 }


headerAttrs : List (Element.Attribute msg)
headerAttrs =
    [ uiDeepnightColorFontColour
    , Font.size 14
    , Font.bold
    , Element.alignTop
    ]


valueAttrs : List (Element.Attribute msg)
valueAttrs =
    [ Font.size 14
    , Element.alignTop
    ]


groupAttrs : List (Element.Attribute msg)
groupAttrs =
    [ Element.paddingXY 5 0, width fill ]


textDisplay : String -> String -> Element.Element msg
textDisplay lbl val =
    row
        [ width fill
        , Element.paddingEach <| { zeroEach | top = 5 }
        ]
        [ Element.paragraph
            [ Element.alignTop, width Element.shrink ]
            [ el ((width <| Element.px 150) :: headerAttrs) <| text lbl ]
        , Element.paragraph
            [ width fill, Element.spacing 0 ]
            [ el valueAttrs <| monospaceText val ]
        ]


taintTextDisplay : String -> String -> Element.Element msg
taintTextDisplay lbl val =
    row []
        [ Element.paragraph [ Element.alignTop, width Element.shrink ]
            [ el ((width <| Element.px 100) :: headerAttrs) <| text lbl ]
        , Element.paragraph
            [ Element.alignTop, width <| Element.px 530, Element.spacing 0 ]
            [ el valueAttrs <| monospaceText val ]
        ]


textDisplayNarrow : String -> String -> Element.Element msg
textDisplayNarrow lbl val =
    row [ width fill ]
        [ el
            ([ width <| Element.px 90
             , Element.paddingEach <| { zeroEach | top = 5 }
             ]
                ++ headerAttrs
            )
          <|
            text lbl
        , Element.row [ Element.spacing 0 ]
            [ el ([ Element.alignTop, Element.spacing 0, Element.padding 0 ] ++ valueAttrs) <| monospaceText val
            ]
        ]


textDisplayMedium : String -> String -> Element.Element msg
textDisplayMedium lbl val =
    row [ width fill ]
        [ el
            ([ width <| Element.px 110
             , Element.paddingEach <| { zeroEach | top = 5 }
             ]
                ++ headerAttrs
            )
          <|
            text lbl
        , Element.row [ Element.spacing 0 ]
            [ el ([ Element.alignTop, Element.spacing 0, Element.padding 0 ] ++ valueAttrs) <| monospaceText val
            ]
        ]


numberDisplay : String -> Int -> Element.Element msg
numberDisplay lbl val =
    textDisplay lbl <| String.fromInt val


floatDisplay : String -> Float -> Element.Element msg
floatDisplay lbl val =
    textDisplay lbl <| String.fromFloat val
