module Traveller.UI exposing
    ( accentHeadingColour
    , bgVar
    , borderVar
    , cssColor
    , descriptionStyle
    , floatDisplay
    , fontVar
    , groupAttrs
    , headerAttrs
    , imageStyle
    , jumpShadowTextColor
    , monospaceText
    , numberDisplay
    , orbitStyle
    , profileFieldDisplay
    , safeJumpStyle
    , sequenceStyle
    , taintTextDisplay
    , textDisplay
    , textDisplayMedium
    , textDisplayNarrow
    , travelStyle
    , travellerRed
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
import Html.Attributes


{-| A CSS custom-property-backed Element attribute, e.g. `cssColor "background-color" "--color-panel"`.
Used instead of elm-ui's native Background.color/Font.color/Border.color so the value can react to the
Rails `data-theme` attribute at runtime via `var(...)` rather than being baked in at compile time.
-}
cssColor : String -> String -> Element.Attribute msg
cssColor prop varName =
    Element.htmlAttribute (Html.Attributes.style prop ("var(" ++ varName ++ ")"))


bgVar : String -> Element.Attribute msg
bgVar =
    cssColor "background-color"


fontVar : String -> Element.Attribute msg
fontVar =
    cssColor "color"


borderVar : String -> Element.Attribute msg
borderVar =
    cssColor "border-color"


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
    Color.rgb255 26 74 106



-- Element Colors


jumpShadowTextColor : Element.Color
jumpShadowTextColor =
    textColor
        |> Color.Manipulate.desaturate 0.85
        |> Color.Manipulate.darken 0.85
        |> colorToElementColor


travellerRed : Element.Color
travellerRed =
    Element.rgb 0.882 0.024 0


{-| Colour for section headings, titles, and other accent text — e.g. "MAIN WORLD PROFILE",
the drawer's system name, active tab codes. Matches Rails' `.dg-subsection .label`/`.page-title`.
-}
accentHeadingColour : Element.Attribute msg
accentHeadingColour =
    fontVar "--color-highlight"



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
    [ fontVar "--color-fg-muted"
    , Font.size 14
    , Font.bold
    , Element.alignTop
    ]


valueAttrs : List (Element.Attribute msg)
valueAttrs =
    [ fontVar "--color-fg"
    , Font.size 14
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
    row [ width fill, Element.paddingEach <| { zeroEach | top = 5 } ]
        [ el ([ width <| Element.px 90 ] ++ headerAttrs) <| text lbl
        , el [ Font.size 14, Element.alignBottom ] <| monospaceText val
        ]


textDisplayMedium : String -> String -> Element.Element msg
textDisplayMedium lbl val =
    row [ width fill, Element.paddingEach <| { zeroEach | top = 5 } ]
        [ el ([ width <| Element.px 120 ] ++ headerAttrs) <| text lbl
        , el [ Font.size 14, Element.alignBottom ] <| monospaceText val
        ]


numberDisplay : String -> Int -> Element.Element msg
numberDisplay lbl val =
    textDisplay lbl <| String.fromInt val


profileFieldDisplay : String -> String -> Element.Element msg
profileFieldDisplay lbl val =
    row [ width fill, Element.paddingEach { zeroEach | top = 3 } ]
        [ el [ width (Element.px 80), fontVar "--color-fg-muted", Font.size 11, Font.bold, Element.alignTop ] (text lbl)
        , Element.paragraph [ width fill, Font.size 12, Element.alignTop, fontVar "--color-fg-bright" ] [ text val ]
        ]


floatDisplay : String -> Float -> Element.Element msg
floatDisplay lbl val =
    textDisplay lbl <| String.fromFloat val
