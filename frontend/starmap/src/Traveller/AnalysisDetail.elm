module Traveller.AnalysisDetail exposing
    ( AnalyisDetailGasGiantData
    , AnalyisDetailPlanetoidBeltData
    , AnalyisDetailPlanetoidData
    , AnalyisDetailStarData
    , AnalysisDetail(..)
    , AnalysisDetailHeader
    , CitiesTabConfig
    , MoonsTabConfig
    , viewGasGiantAnalysisDetail
    , viewObjectAnalysisDetail
    , viewPlanetoidAnalysisDetail
    , viewPlanetoidBeltAnalysisDetail
    )

{-| Analysis detail views for stellar objects, with UWP-driven tab navigation.
-}

import Array
import FormatNumber exposing (format)
import FormatNumber.Locales exposing (Decimals(..), usLocale)
import Html exposing (Html)
import Html.Attributes as HtmlAttrs
import Html.Events
import Http
import Json.Decode
import List.Extra
import RemoteData exposing (RemoteData(..))
import Round
import Traveller.City exposing (CitiesPage)
import Traveller.StarOrbitMap as StarOrbitMap
import Traveller.StellarObject exposing (MoonsPage, StarData, StellarObject(..))
import Traveller.TravelCalculations as TravelCalc


type alias AnalysisDetailHeader =
    { header : String
    }


type AnalysisDetail
    = AnalyisDetailTerrestialPlanet AnalysisDetailHeader AnalyisDetailPlanetoidData
    | AnalyisDetailPlanetoid AnalysisDetailHeader AnalyisDetailPlanetoidData
    | AnalyisDetailGasGiant AnalysisDetailHeader AnalyisDetailGasGiantData
    | AnalyisDetailPlanetoidBelt AnalysisDetailHeader AnalyisDetailPlanetoidBeltData
    | AnalyisDetailStar AnalysisDetailHeader AnalyisDetailStarData


type alias AnalyisDetailStarData =
    { spectralType : String
    , subtype : String
    , class_ : String
    , temperature : String
    , age : String
    , mass : String
    , diameter : String
    , luminosity : String
    , minimumOrbit : String
    , hzco : String
    , jumpShadow : String
    , showNames : Bool
    , primaryStarData : StarData
    , children : List StarOrbitMap.ChildNode
    }


type alias MoonsTabConfig msg =
    { page : RemoteData Http.Error MoonsPage
    , significantOnly : Bool
    , onToggleSignificant : msg
    , onSetPage : Int -> msg
    }


type alias CitiesTabConfig msg =
    { page : RemoteData Http.Error CitiesPage
    , onSetPage : Int -> msg
    }


type alias AnalyisDetailGasGiantData =
    { code : String
    , jumpShadowKm : Maybe Float
    , physical :
        { au : String
        , period : String
        , inclination : String
        , eccentricity : String
        , mass : String
        , diameter : String
        , axialTilt : String
        , moons : String
        , hasRing : String
        }
    }


type alias AnalyisDetailPlanetoidBeltData =
    { planet : AnalyisDetailPlanetoidData
    , composition :
        { mType : String
        , sType : String
        , cType : String
        , oType : String
        }
    , belt :
        { resourceRating : String
        , bulk : String
        , span : String
        }
    }


type alias CultureTraitItem =
    { label : String
    , value : Int
    , min : Int
    , max : Int
    , lowLabel : String
    , highLabel : String
    }


type alias AnalyisDetailPlanetoidData =
    { uwp : String
    , jumpShadowKm : Maybe Float
    , moons : Int
    , cityCount : Int
    , physical :
        { au : String
        , period : String
        , inclination : String
        , eccentricity : String
        , mass : String
        , density : String
        , gravity : String
        , diameter : String
        , meanTemperature : String
        , albedo : String
        , axialTilt : String
        , greenhouse : String
        , sizeCode : String
        , rotation : String
        }
    , orbital :
        { orbit : String
        , retrograde : String
        , effectiveHZCODeviation : String
        }
    , atmosphere :
        { type_ : String
        , hazardCode : String
        , bar : String
        , taint :
            { subtype : String
            , severity : String
            , persistence : String
            }
        }
    , hydrographics :
        { percentage : String
        , liquid : String
        , surfaceDistribution : String
        }
    , life :
        { biomass : String
        , biocomplexity : String
        , biodiversity : String
        , compatibility : String
        , habitability : String
        , sophonts : String
        }
    , starport :
        { code : String
        , quality : String
        , fuel : String
        , facilities : String
        }
    , social :
        { population : String
        , concentrationRating : Maybe Int
        , urbanizationPercentage : Maybe Int
        , majorCities : Maybe Int
        , government : String
        , lawLevel : String
        , techLevel : String
        }
    , cultureTrait : List CultureTraitItem
    , government :
        { type_ : String
        , description : String
        , judicial : String
        , executive : String
        , legislative : String
        , authority : String
        , centralisation : String
        }
    , lawSubClassifications :
        { weaponsAndArmour : String
        , criminalLaw : String
        , economicLaw : String
        , privateLaw : String
        , personalRights : String
        }
    , lawCharacteristics :
        { uniformity : String
        , judicialSystem : String
        , deathPenalty : String
        , presumedInnocence : String
        , econometricInfractionsAdministrative : String
        }
    , techDetail :
        { descriptor : String
        , energy : String
        , electronics : String
        , manufacturing : String
        , medical : String
        , environmental : String
        , land : String
        , sea : String
        , air : String
        , space : String
        , personalMilitary : String
        , heavyMilitary : String
        }
    }



-- ── HTML LAYOUT HELPERS ──────────────────────────────────────────────────────
--
-- Small elm-ui-flavoured wrappers kept local to this module rather than
-- shared via Traveller.UI, which is still elm-ui and used by other
-- not-yet-converted modules (Sidebar, StellarObjectView, ShipTraffic,
-- TravelTable). Named to match their elm-ui counterparts so the view code
-- below reads close to its previous shape.


fill : String
fill =
    "100%"


px : Int -> String
px n =
    String.fromInt n ++ "px"


width : String -> Html.Attribute msg
width =
    HtmlAttrs.style "width"


height : String -> Html.Attribute msg
height =
    HtmlAttrs.style "height"


row : List (Html.Attribute msg) -> List (Html msg) -> Html msg
row attrs =
    Html.div (HtmlAttrs.style "display" "flex" :: attrs)


column : List (Html.Attribute msg) -> List (Html msg) -> Html msg
column attrs =
    Html.div (HtmlAttrs.style "display" "flex" :: HtmlAttrs.style "flex-direction" "column" :: attrs)


el : List (Html.Attribute msg) -> Html msg -> Html msg
el attrs child =
    Html.div attrs [ child ]


text : String -> Html msg
text =
    Html.text


none : Html msg
none =
    Html.text ""


spacing : Int -> Html.Attribute msg
spacing n =
    HtmlAttrs.style "gap" (px n)


padding : Int -> Html.Attribute msg
padding n =
    HtmlAttrs.style "padding" (px n)


paddingXY : Int -> Int -> Html.Attribute msg
paddingXY x y =
    HtmlAttrs.style "padding" (px y ++ " " ++ px x)


type alias EachSides =
    { top : Int, right : Int, bottom : Int, left : Int }


zeroEach : EachSides
zeroEach =
    { top = 0, right = 0, bottom = 0, left = 0 }


paddingEach : EachSides -> Html.Attribute msg
paddingEach sides =
    HtmlAttrs.style "padding"
        (px sides.top ++ " " ++ px sides.right ++ " " ++ px sides.bottom ++ " " ++ px sides.left)


{-| Aligns a flex item to the start of its parent's cross axis (e.g. the top
of a `row`).
-}
alignTop : Html.Attribute msg
alignTop =
    HtmlAttrs.style "align-self" "flex-start"


{-| Centers a flex item along its parent's cross axis — the horizontal axis
inside a `column`, or the vertical axis inside a `row`.
-}
centerSelf : Html.Attribute msg
centerSelf =
    HtmlAttrs.style "align-self" "center"


pointerCursor : Html.Attribute msg
pointerCursor =
    HtmlAttrs.style "cursor" "pointer"


{-| Reserves exactly this many pixels in a flex row/column and never grows
or shrinks — for a fixed-width label sitting next to a wrapping value.
-}
fixedFlex : Int -> Html.Attribute msg
fixedFlex n =
    HtmlAttrs.style "flex" ("0 0 " ++ px n)


{-| Grows to fill the remaining space in a flex row/column, alongside
`shrinkable` so long unbroken text can still wrap instead of overflowing
(flex items default to a content-based minimum size that ignores `width`).
-}
growFlex : Html.Attribute msg
growFlex =
    HtmlAttrs.style "flex" "1 1 0%"


shrinkable : Html.Attribute msg
shrinkable =
    HtmlAttrs.style "min-width" "0"


{-| A CSS custom-property-backed attribute, e.g. `bgVar "--color-panel"`, so
the value can react to the Rails `data-theme` attribute at runtime.
-}
bgVar : String -> Html.Attribute msg
bgVar varName =
    HtmlAttrs.style "background-color" ("var(" ++ varName ++ ")")


fontVar : String -> Html.Attribute msg
fontVar varName =
    HtmlAttrs.style "color" ("var(" ++ varName ++ ")")


borderColorVar : String -> Html.Attribute msg
borderColorVar varName =
    HtmlAttrs.style "border-color" ("var(" ++ varName ++ ")")


{-| Colour for section headings, titles, and other accent text — e.g. tab
codes, "Culture" section headers. Matches Rails' `.dg-subsection .label`.
-}
accentHeadingColour : Html.Attribute msg
accentHeadingColour =
    fontVar "--color-highlight"


outlineBorder : Html.Attribute msg
outlineBorder =
    borderColorVar "--color-outline"


monospaceText : String -> Html msg
monospaceText someString =
    Html.span [ HtmlAttrs.class "font-mono" ] [ Html.text someString ]


groupAttrs : List (Html.Attribute msg)
groupAttrs =
    [ paddingXY 5 0, width fill ]


headerAttrs : List (Html.Attribute msg)
headerAttrs =
    [ fontVar "--color-fg-muted"
    , HtmlAttrs.style "font-size" "14px"
    , HtmlAttrs.class "font-bold"
    , alignTop
    ]


valueAttrs : List (Html.Attribute msg)
valueAttrs =
    [ fontVar "--color-fg"
    , HtmlAttrs.style "font-size" "14px"
    , alignTop
    ]


textDisplay : String -> String -> Html msg
textDisplay lbl val =
    row
        [ width fill, paddingEach { zeroEach | top = 5 } ]
        [ el (fixedFlex 150 :: headerAttrs) (text lbl)
        , el (growFlex :: shrinkable :: valueAttrs) (monospaceText val)
        ]


taintTextDisplay : String -> String -> Html msg
taintTextDisplay lbl val =
    row []
        [ el (fixedFlex 100 :: headerAttrs) (text lbl)
        , el (fixedFlex 530 :: alignTop :: valueAttrs) (monospaceText val)
        ]


textDisplayNarrow : String -> String -> Html msg
textDisplayNarrow lbl val =
    row [ width fill, paddingEach { zeroEach | top = 5 } ]
        [ el (width (px 90) :: headerAttrs) (text lbl)
        , el [ HtmlAttrs.style "font-size" "14px" ] (monospaceText val)
        ]


textDisplayMedium : String -> String -> Html msg
textDisplayMedium lbl val =
    row [ width fill, paddingEach { zeroEach | top = 5 } ]
        [ el (width (px 120) :: headerAttrs) (text lbl)
        , el [ HtmlAttrs.style "font-size" "14px" ] (monospaceText val)
        ]


profileFieldDisplay : String -> String -> Html msg
profileFieldDisplay lbl val =
    row [ width fill, paddingEach { zeroEach | top = 3 } ]
        [ el
            [ fixedFlex 80
            , fontVar "--color-fg-muted"
            , HtmlAttrs.style "font-size" "11px"
            , HtmlAttrs.class "font-bold"
            , alignTop
            ]
            (text lbl)
        , el [ growFlex, shrinkable, HtmlAttrs.style "font-size" "12px", alignTop, fontVar "--color-fg-bright" ] (text val)
        ]



-- ── TAB BAR ──────────────────────────────────────────────────────────────────


activeTabColour : String
activeTabColour =
    "var(--color-highlight)"


mutedTabColour : String
mutedTabColour =
    "var(--color-fg-muted)"


viewTabBar : String -> (String -> msg) -> List { id : String, label : String, code : String } -> Html msg
viewTabBar activeTab setTab tabs =
    row
        [ width fill, HtmlAttrs.class "border-b", outlineBorder ]
        (List.map (viewOneTab activeTab setTab) tabs)


viewOneTab : String -> (String -> msg) -> { id : String, label : String, code : String } -> Html msg
viewOneTab activeTab setTab tab =
    if tab.id == "-" then
        el
            [ paddingEach { top = 8, left = 2, right = 2, bottom = 8 }
            , HtmlAttrs.style "color" mutedTabColour
            ]
            (column [ spacing 1, HtmlAttrs.style "align-items" "center" ]
                [ el [ HtmlAttrs.style "font-size" "15px", HtmlAttrs.class "font-bold text-center" ] (text "–")
                , el [ HtmlAttrs.style "font-size" "11px", HtmlAttrs.class "text-center" ] (text "")
                ]
            )

    else
        let
            isActive =
                tab.id == activeTab

            colour =
                if isActive then
                    "var(--color-fg-bright)"

                else
                    mutedTabColour
        in
        el
            [ paddingEach { top = 8, left = 12, right = 12, bottom = 8 }
            , HtmlAttrs.class "border-b-2"
            , HtmlAttrs.style "border-color"
                (if isActive then
                    activeTabColour

                 else
                    "transparent"
                )
            , HtmlAttrs.style "color" colour
            , Html.Events.onClick (setTab tab.id)
            , pointerCursor
            ]
            (column [ spacing 1, HtmlAttrs.style "align-items" "center" ]
                [ el [ HtmlAttrs.style "font-size" "15px", HtmlAttrs.class "font-bold text-center", accentHeadingColour ] (viewTabCode tab.code)
                , el [ HtmlAttrs.style "font-size" "11px", HtmlAttrs.class "text-center" ] (text tab.label)
                ]
            )


viewTabCode : String -> Html msg
viewTabCode code =
    case String.split ":" code of
        [ "fa", faClass ] ->
            Html.i [ HtmlAttrs.class faClass ] []

        _ ->
            text code


viewSectionHeader : String -> Html msg
viewSectionHeader title =
    row
        [ width fill, spacing 8, paddingEach { zeroEach | top = 12, bottom = 2 } ]
        [ el [ accentHeadingColour, HtmlAttrs.style "font-size" "11px", HtmlAttrs.class "font-bold" ] (text (String.toUpper title))
        , el
            [ growFlex
            , height (px 1)
            , HtmlAttrs.style "background-color" "var(--color-outline)"
            , centerSelf
            ]
            none
        ]


viewPlanetaryProfile : AnalyisDetailPlanetoidData -> Html msg
viewPlanetaryProfile data =
    column
        [ paddingEach { zeroEach | right = 16 }, spacing 0 ]
        [ el
            [ centerSelf
            , HtmlAttrs.style "font-size" "15px"
            , HtmlAttrs.class "font-mono"
            , fontVar "--color-fg-bright"
            , paddingEach { zeroEach | top = 6, bottom = 6 }
            ]
            (text data.uwp)
        , profileFieldDisplay "Starport" (data.starport.code ++ " – " ++ data.starport.quality)
        , profileFieldDisplay "Gravity" (data.physical.gravity ++ "g")
        , profileFieldDisplay "Temperature" (data.physical.meanTemperature ++ "°C")
        , profileFieldDisplay "Hazard" data.atmosphere.hazardCode
        , profileFieldDisplay "Population" data.social.population
        , profileFieldDisplay "Government" data.social.government
        , profileFieldDisplay "Law Level" data.social.lawLevel
        , profileFieldDisplay "Tech Level" data.social.techLevel
        , profileFieldDisplay "Sophonts" data.life.sophonts
        ]


viewGasGiantProfile : AnalyisDetailGasGiantData -> Html msg
viewGasGiantProfile data =
    let
        sizeDescription =
            case data.code of
                "GS" ->
                    "Small"

                "GM" ->
                    "Medium"

                "GL" ->
                    "Large"

                _ ->
                    data.code
    in
    column
        [ paddingEach { zeroEach | right = 16 }, spacing 0 ]
        [ profileFieldDisplay "Size" (data.code ++ " – " ++ sizeDescription)
        ]


viewBeltProfile : AnalyisDetailPlanetoidBeltData -> Html msg
viewBeltProfile data =
    column
        [ paddingEach { zeroEach | right = 16 }, spacing 0 ]
        [ profileFieldDisplay "Resource" data.belt.resourceRating
        , profileFieldDisplay "Bulk" data.belt.bulk
        , profileFieldDisplay "Metallic" data.composition.mType
        , profileFieldDisplay "Stony" data.composition.sType
        , profileFieldDisplay "Carbonaceous" data.composition.cType
        , profileFieldDisplay "Other" data.composition.oType
        ]


viewJumpShadowTable : Maybe Float -> Html msg
viewJumpShadowTable maybeKm =
    case maybeKm of
        Nothing ->
            none

        Just km ->
            if km <= 0 then
                none

            else
                let
                    mDrives =
                        [ 1, 2, 3, 4, 5, 6 ]

                    cell attrs child =
                        el
                            ([ width (px 46), paddingXY 0 4, HtmlAttrs.style "text-align" "center" ] ++ attrs)
                            child

                    headerCell m =
                        cell
                            [ HtmlAttrs.class "font-bold border-b"
                            , HtmlAttrs.style "font-size" "11px"
                            , fontVar "--color-fg"
                            , outlineBorder
                            ]
                            (text ("M" ++ String.fromInt m))

                    timeCell m =
                        let
                            secs =
                                TravelCalc.travelTimeInSeconds km m

                            t =
                                TravelCalc.travelTimeHoursDays secs
                        in
                        cell [ HtmlAttrs.style "font-size" "12px", HtmlAttrs.class "font-mono" ] (text t)
                in
                column [ width fill, paddingEach { zeroEach | top = 8 } ]
                    [ viewSectionHeader "Safe Jump Distance"
                    , row [] (List.map headerCell mDrives)
                    , row [] (List.map timeCell mDrives)
                    ]


cultureDm : Int -> String
cultureDm value =
    case value of
        1 ->
            "±2"

        2 ->
            "±2"

        3 ->
            "±1"

        4 ->
            "±1"

        5 ->
            "±1"

        6 ->
            "±0"

        7 ->
            "±0"

        8 ->
            "±0"

        9 ->
            "±1"

        10 ->
            "±1"

        11 ->
            "±1"

        12 ->
            "±2"

        13 ->
            "±2"

        14 ->
            "±2"

        15 ->
            "±3"

        16 ->
            "±3"

        17 ->
            "±3"

        _ ->
            "±4"


toHexChar : Int -> String
toHexChar n =
    if n < 10 then
        String.fromInt n

    else
        case n of
            10 ->
                "A"

            11 ->
                "B"

            12 ->
                "C"

            13 ->
                "D"

            14 ->
                "E"

            15 ->
                "F"

            16 ->
                "G"

            17 ->
                "H"

            18 ->
                "J"

            19 ->
                "K"

            20 ->
                "L"

            21 ->
                "M"

            22 ->
                "N"

            _ ->
                String.fromInt n


viewCultureGauge : CultureTraitItem -> Html msg
viewCultureGauge trait =
    let
        range =
            toFloat (trait.max - trait.min)

        pct =
            if range <= 0 then
                50.0

            else
                (toFloat (trait.value - trait.min) / range) * 100.0

        clampedPct =
            max 0.0 (min 100.0 pct)

        dm =
            cultureDm trait.value

        hexVal =
            toHexChar trait.value

        caretLeft =
            String.fromFloat clampedPct ++ "%"
    in
    column [ width fill, spacing 4 ]
        [ el [ HtmlAttrs.style "font-size" "12px", fontVar "--color-fg-muted", HtmlAttrs.class "font-bold" ] (text trait.label)
        , el [ width fill, paddingEach { zeroEach | top = 4 } ]
            (Html.div
                []
                [ Html.div
                    [ HtmlAttrs.style "position" "relative"
                    , HtmlAttrs.style "height" "16px"
                    ]
                    [ Html.div
                        [ HtmlAttrs.style "position" "absolute"
                        , HtmlAttrs.style "top" "50%"
                        , HtmlAttrs.style "left" "0"
                        , HtmlAttrs.style "right" "0"
                        , HtmlAttrs.style "height" "1px"
                        , HtmlAttrs.style "background-color" "var(--color-gauge-line)"
                        , HtmlAttrs.style "transform" "translateY(-50%)"
                        ]
                        []
                    , Html.div
                        [ HtmlAttrs.style "position" "absolute"
                        , HtmlAttrs.style "top" "50%"
                        , HtmlAttrs.style "left" caretLeft
                        , HtmlAttrs.style "transform" "translateX(-50%) translateY(-50%)"
                        , HtmlAttrs.style "font-size" "10px"
                        , HtmlAttrs.style "color" "var(--color-highlight)"
                        ]
                        [ Html.text "▲" ]
                    ]
                , Html.div
                    [ HtmlAttrs.style "display" "flex"
                    , HtmlAttrs.style "justify-content" "space-between"
                    , HtmlAttrs.style "font-size" "11px"
                    , HtmlAttrs.style "color" "var(--color-fg-muted)"
                    , HtmlAttrs.style "margin-top" "2px"
                    ]
                    [ Html.span [] [ Html.text trait.lowLabel ]
                    , Html.span
                        [ HtmlAttrs.style "font-family" "monospace"
                        , HtmlAttrs.style "color" "var(--color-fg)"
                        ]
                        [ Html.text hexVal
                        , if dm /= "±0" then
                            Html.text (" DM: " ++ dm)

                          else
                            Html.text ""
                        ]
                    , Html.span [] [ Html.text trait.highLabel ]
                    ]
                ]
            )
        ]


{-| Main view for object analysis detail overlay.
-}
viewObjectAnalysisDetail : Int -> msg -> msg -> String -> (String -> msg) -> Bool -> (StellarObject -> msg) -> MoonsTabConfig msg -> CitiesTabConfig msg -> Int -> StarOrbitMap.ResizeConfig msg -> AnalysisDetail -> Html msg
viewObjectAnalysisDetail timeChars closeMsg noOpMsg activeTab setTab isReferee onSelectObject moonsTabConfig citiesTabConfig zIndex starMapResizeConfig data =
    case data of
        AnalyisDetailStar detailHeader starData ->
            StarOrbitMap.viewModal
                { close = closeMsg, noOp = noOpMsg, onSelectObject = onSelectObject, zIndex = zIndex }
                starMapResizeConfig
                detailHeader.header
                (starStatItems starData)
                starData.showNames
                starData.primaryStarData
                starData.children

        _ ->
            viewNonStarAnalysisDetail timeChars closeMsg noOpMsg activeTab setTab isReferee onSelectObject moonsTabConfig citiesTabConfig zIndex data


starStatItems : AnalyisDetailStarData -> List StarOrbitMap.StatItem
starStatItems data =
    [ { label = "Temperature", value = data.temperature }
    , { label = "Age", value = data.age }
    , { label = "Mass", value = data.mass }
    , { label = "Diameter", value = data.diameter }
    , { label = "Luminosity", value = data.luminosity }
    , { label = "Min. Orbit", value = data.minimumOrbit }
    , { label = "HZCO", value = data.hzco }
    , { label = "Jump Shadow", value = data.jumpShadow }
    ]


viewNonStarAnalysisDetail : Int -> msg -> msg -> String -> (String -> msg) -> Bool -> (StellarObject -> msg) -> MoonsTabConfig msg -> CitiesTabConfig msg -> Int -> AnalysisDetail -> Html msg
viewNonStarAnalysisDetail timeChars closeMsg noOpMsg activeTab setTab isReferee onSelectObject moonsTabConfig citiesTabConfig zIndex data =
    let
        profileLayout profile content_ =
            row [ spacing 0 ]
                [ column
                    [ fixedFlex 220
                    , HtmlAttrs.class "border-r"
                    , outlineBorder
                    , alignTop
                    ]
                    [ profile ]
                , column [ growFlex, shrinkable, paddingEach { zeroEach | left = 16 }, alignTop ]
                    [ content_ ]
                ]

        ( header, content, modalWidth ) =
            case data of
                AnalyisDetailTerrestialPlanet detailHeader sharedPData ->
                    ( detailHeader.header
                    , profileLayout (viewPlanetaryProfile sharedPData) (viewPlanetoidAnalysisDetail timeChars activeTab setTab isReferee True onSelectObject moonsTabConfig citiesTabConfig sharedPData)
                    , 960
                    )

                AnalyisDetailPlanetoid detailHeader sharedPData ->
                    ( detailHeader.header
                    , profileLayout (viewPlanetaryProfile sharedPData) (viewPlanetoidAnalysisDetail timeChars activeTab setTab isReferee False onSelectObject moonsTabConfig citiesTabConfig sharedPData)
                    , 960
                    )

                AnalyisDetailGasGiant detailHeader sharedGGData ->
                    ( detailHeader.header
                    , profileLayout (viewGasGiantProfile sharedGGData) (viewGasGiantAnalysisDetail timeChars activeTab setTab onSelectObject moonsTabConfig sharedGGData)
                    , 900
                    )

                AnalyisDetailPlanetoidBelt detailHeader sharePBData ->
                    ( detailHeader.header
                    , profileLayout (viewBeltProfile sharePBData) (viewPlanetoidBeltAnalysisDetail timeChars activeTab setTab isReferee citiesTabConfig sharePBData)
                    , 960
                    )

                AnalyisDetailStar detailHeader _ ->
                    -- unreachable: viewObjectAnalysisDetail dispatches stars to StarOrbitMap.viewModal above
                    ( detailHeader.header, none, 750 )
    in
    Html.div
        [ HtmlAttrs.style "position" "fixed"
        , HtmlAttrs.style "inset" "0"
        , HtmlAttrs.style "display" "flex"
        , HtmlAttrs.style "align-items" "center"
        , HtmlAttrs.style "justify-content" "center"
        , HtmlAttrs.style "z-index" (String.fromInt zIndex)

        -- elm-ui's injected stylesheet sets `white-space: pre` on every
        -- `column`-rendered element, including this modal's elm-ui
        -- ancestors; since `white-space` inherits, that leaks into this
        -- plain-Html subtree (mounted via `Element.html`) and silences
        -- normal text wrapping unless reset here.
        , HtmlAttrs.style "white-space" "normal"
        , Html.Events.onClick closeMsg
        ]
        [ column
            [ Html.Events.stopPropagationOn "click" (Json.Decode.succeed ( noOpMsg, True ))
            , bgVar "--color-panel"
            , HtmlAttrs.class "border"
            , outlineBorder
            , HtmlAttrs.style "max-height" "92vh"
            , HtmlAttrs.style "overflow-y" "auto"
            , width (px modalWidth)
            , padding 20
            , HtmlAttrs.class "rounded-md"
            , HtmlAttrs.style "box-shadow" "0 8px 32px rgba(0, 0, 0, 0.25)"
            ]
            [ row
                [ width fill
                , paddingEach { zeroEach | bottom = 16 }
                , HtmlAttrs.class "border-b justify-between items-center"
                , outlineBorder
                ]
                [ el [ HtmlAttrs.style "font-size" "18px", fontVar "--color-fg-bright", HtmlAttrs.class "font-bold" ] (text header)
                , el
                    [ pointerCursor
                    , HtmlAttrs.class "starmap-modal-close"
                    , HtmlAttrs.style "font-size" "16px"
                    , fontVar "--color-fg-muted"
                    , Html.Events.onClick closeMsg
                    ]
                    (text "✕")
                ]
            , content
            ]
        ]


viewPlanetoidAnalysisDetail : Int -> String -> (String -> msg) -> Bool -> Bool -> (StellarObject -> msg) -> MoonsTabConfig msg -> CitiesTabConfig msg -> AnalyisDetailPlanetoidData -> Html msg
viewPlanetoidAnalysisDetail timeChars activeTab setTab isReferee showMoonsTab onSelectObject moonsTabConfig citiesTabConfig data =
    let
        firstTabIndex =
            case safeTab of
                "starport" ->
                    76

                "physical" ->
                    7

                "atmo" ->
                    17

                "hydro" ->
                    23

                "pop" ->
                    26

                "gov" ->
                    44

                "law" ->
                    52

                "tech" ->
                    63

                _ ->
                    0

        tabOffset =
            Array.get firstTabIndex counts |> Maybe.withDefault 0

        show index str =
            let
                offset =
                    timeChars - ((Array.get index counts |> Maybe.withDefault 0) - tabOffset)
            in
            if timeChars < 0 then
                ""

            else
                String.left offset str

        -- Culture trait labels padded to exactly 8 slots so gov/law/tech indices are stable
        cultureLabels =
            let
                ls =
                    List.map .label data.cultureTrait
            in
            ls ++ List.repeat (max 0 (8 - List.length ls)) ""

        strings =
            -- 0–6: orbital tab
            [ data.orbital.orbit
            , data.physical.au
            , data.orbital.effectiveHZCODeviation
            , data.physical.period
            , data.orbital.retrograde
            , data.physical.inclination
            , data.physical.eccentricity

            -- 7–16: physical tab
            , data.physical.sizeCode
            , data.physical.diameter
            , data.physical.mass
            , data.physical.density
            , data.physical.gravity
            , data.physical.meanTemperature
            , data.physical.rotation
            , data.physical.axialTilt
            , data.physical.albedo
            , data.physical.greenhouse

            -- 17–22: atmo tab
            , data.atmosphere.type_
            , data.atmosphere.bar
            , data.atmosphere.hazardCode
            , data.atmosphere.taint.subtype
            , data.atmosphere.taint.severity
            , data.atmosphere.taint.persistence

            -- 23–25: hydro tab
            , data.hydrographics.percentage
            , data.hydrographics.liquid
            , data.hydrographics.surfaceDistribution

            -- 26–35: pop tab
            , data.social.population
            , data.social.concentrationRating |> Maybe.map String.fromInt |> Maybe.withDefault ""
            , data.social.urbanizationPercentage |> Maybe.map String.fromInt |> Maybe.withDefault ""
            , data.social.majorCities |> Maybe.map String.fromInt |> Maybe.withDefault ""
            , data.life.biomass
            , data.life.biocomplexity
            , data.life.biodiversity
            , data.life.compatibility
            , data.life.habitability
            , data.life.sophonts
            ]
                -- 36–43: culture (8 fixed slots)
                ++ cultureLabels
                -- 44–51: gov tab
                ++ [ data.social.government
                   , data.government.type_
                   , data.government.description
                   , data.government.judicial
                   , data.government.executive
                   , data.government.legislative
                   , data.government.authority
                   , data.government.centralisation
                   ]
                -- 52–62: law tab
                ++ [ data.social.lawLevel
                   , data.lawSubClassifications.weaponsAndArmour
                   , data.lawSubClassifications.criminalLaw
                   , data.lawSubClassifications.economicLaw
                   , data.lawSubClassifications.privateLaw
                   , data.lawSubClassifications.personalRights
                   , data.lawCharacteristics.uniformity
                   , data.lawCharacteristics.judicialSystem
                   , data.lawCharacteristics.deathPenalty
                   , data.lawCharacteristics.presumedInnocence
                   , data.lawCharacteristics.econometricInfractionsAdministrative
                   ]
                -- 63–75: tech tab
                ++ [ data.social.techLevel
                   , data.techDetail.descriptor
                   , data.techDetail.energy
                   , data.techDetail.electronics
                   , data.techDetail.manufacturing
                   , data.techDetail.medical
                   , data.techDetail.environmental
                   , data.techDetail.land
                   , data.techDetail.sea
                   , data.techDetail.air
                   , data.techDetail.space
                   , data.techDetail.personalMilitary
                   , data.techDetail.heavyMilitary
                   ]
                -- 76–79: starport tab
                ++ [ data.starport.code
                   , data.starport.quality
                   , data.starport.fuel
                   , data.starport.facilities
                   ]

        counts =
            List.Extra.scanl (\word total -> total + (floor <| sqrt <| toFloat <| String.length word)) 0 strings
                |> Array.fromList

        uc i =
            let
                s =
                    String.slice i (i + 1) data.uwp
            in
            if String.isEmpty s then
                "⊕"

            else
                s

        tabs =
            [ { id = "orbital", label = "Orbital", code = "⊕" }
            , { id = "starport", label = "Starport", code = uc 0 }
            , { id = "physical", label = "Physical", code = uc 1 }
            , { id = "atmo", label = "Atmo", code = uc 2 }
            , { id = "hydro", label = "Hydro", code = uc 3 }
            , { id = "pop", label = "Pop", code = uc 4 }
            , { id = "gov", label = "Gov", code = uc 5 }
            , { id = "law", label = "Law", code = uc 6 }
            , { id = "-", label = "", code = "–" }
            , { id = "tech", label = "Tech", code = uc 8 }
            ]
                ++ (if showMoonsTab then
                        [ { id = "moons", label = "Moons (" ++ String.fromInt data.moons ++ ")", code = "☾" } ]

                    else
                        []
                   )
                ++ [ { id = "cities", label = "Cities (" ++ String.fromInt data.cityCount ++ ")", code = "fa:fa-regular fa-city" } ]

        safeTab =
            if List.any (\t -> t.id == activeTab && t.id /= "-") tabs then
                activeTab

            else
                "orbital"

        tabContent =
            case safeTab of
                "moons" ->
                    viewMoonsTab onSelectObject moonsTabConfig

                "cities" ->
                    viewCitiesTab citiesTabConfig

                "starport" ->
                    column groupAttrs
                        [ textDisplay "Starport Class" <| show 76 data.starport.code
                        , textDisplay "Quality" <| show 77 data.starport.quality
                        , if data.starport.fuel /= "None" then
                            textDisplay "Fuel" <| show 78 data.starport.fuel

                          else
                            none
                        , if data.starport.facilities /= "None" then
                            textDisplay "Facilities" <| show 79 data.starport.facilities

                          else
                            none
                        ]

                "physical" ->
                    column [ width fill ]
                        [ viewSectionHeader "Physical Data"
                        , row (spacing 40 :: groupAttrs)
                            [ column [ alignTop ]
                                [ textDisplayMedium ("Diameter (" ++ show 7 data.physical.sizeCode ++ ")") <| show 8 data.physical.diameter
                                , textDisplayMedium "Mass" <|
                                    let
                                        m =
                                            show 9 data.physical.mass
                                    in
                                    if m == "—" || m == "" then
                                        m

                                    else
                                        m ++ " ☉"
                                , textDisplayMedium "Density" <|
                                    let
                                        d =
                                            show 10 data.physical.density
                                    in
                                    if d == "—" || d == "" then
                                        d

                                    else
                                        d ++ " ☉"
                                , textDisplayMedium "Gravity (G)" <| show 11 data.physical.gravity
                                ]
                            ]
                        , viewSectionHeader "Environmental Data"
                        , row (spacing 40 :: groupAttrs)
                            [ column [ alignTop ]
                                [ textDisplayNarrow "Temperature" <| show 12 data.physical.meanTemperature
                                , textDisplayNarrow "Rotation" <| show 13 data.physical.rotation
                                , textDisplayNarrow "Axial Tilt" <| show 14 data.physical.axialTilt
                                , textDisplayNarrow "Albedo" <| show 15 data.physical.albedo
                                , textDisplayNarrow "Greenhouse" <| show 16 data.physical.greenhouse
                                ]
                            ]
                        ]

                "atmo" ->
                    column groupAttrs
                        [ textDisplay "Type" <| show 17 data.atmosphere.type_
                        , textDisplay "BAR" <| show 18 data.atmosphere.bar
                        , textDisplay "Hazard Code" <| show 19 data.atmosphere.hazardCode
                        , row [ width fill ]
                            [ el
                                [ fontVar "--color-fg-muted"
                                , HtmlAttrs.class "font-bold"
                                , HtmlAttrs.style "font-size" "14px"
                                , alignTop
                                , width (px 50)
                                , paddingEach <| { zeroEach | top = 5 }
                                ]
                              <|
                                text "Taint"
                            , column [ width fill ]
                                [ taintTextDisplay "Subtype" <| show 20 data.atmosphere.taint.subtype
                                , taintTextDisplay "Severity" <| show 21 data.atmosphere.taint.severity
                                , taintTextDisplay "Persistence" <| show 22 data.atmosphere.taint.persistence
                                ]
                            ]
                        ]

                "hydro" ->
                    column groupAttrs
                        [ textDisplay "Percentage" <| show 23 data.hydrographics.percentage
                        , if data.hydrographics.liquid /= "" then
                            textDisplay "Liquid" <| show 24 data.hydrographics.liquid

                          else
                            none
                        , textDisplay "Surface Distribution" <| show 25 data.hydrographics.surfaceDistribution
                        ]

                "pop" ->
                    let
                        cultureRow1 =
                            List.take 4 data.cultureTrait
                                |> List.indexedMap
                                    (\i ct ->
                                        if show (36 + i) ct.label /= "" then
                                            viewCultureGauge ct

                                        else
                                            el [ width fill ] none
                                    )

                        cultureRow2 =
                            List.drop 4 data.cultureTrait
                                |> List.indexedMap
                                    (\i ct ->
                                        if show (40 + i) ct.label /= "" then
                                            viewCultureGauge ct

                                        else
                                            el [ width fill ] none
                                    )
                    in
                    column [ width fill ]
                        [ viewSectionHeader "Population"
                        , column groupAttrs
                            [ textDisplay "Population" <| show 26 data.social.population
                            , textDisplay "Concentration Rating"
                                (let
                                    s =
                                        show 27 (data.social.concentrationRating |> Maybe.map String.fromInt |> Maybe.withDefault "")
                                 in
                                 if s == "" then
                                    if data.social.concentrationRating == Nothing then
                                        "—"

                                    else
                                        ""

                                 else
                                    s
                                )
                            , textDisplay "Urbanisation %"
                                (let
                                    s =
                                        show 28 (data.social.urbanizationPercentage |> Maybe.map String.fromInt |> Maybe.withDefault "")
                                 in
                                 if s == "" then
                                    if data.social.urbanizationPercentage == Nothing then
                                        "—"

                                    else
                                        ""

                                 else
                                    s
                                )
                            , textDisplay "Major Cities"
                                (let
                                    s =
                                        show 29 (data.social.majorCities |> Maybe.map String.fromInt |> Maybe.withDefault "")
                                 in
                                 if s == "" then
                                    if data.social.majorCities == Nothing then
                                        "—"

                                    else
                                        ""

                                 else
                                    s
                                )
                            ]
                        , viewSectionHeader "Life"
                        , column groupAttrs
                            [ textDisplay "Biomass" <| show 30 data.life.biomass
                            , textDisplay "Biocomplexity" <| show 31 data.life.biocomplexity
                            , textDisplay "Biodiversity" <| show 32 data.life.biodiversity
                            , textDisplay "Compatibility" <| show 33 data.life.compatibility
                            , textDisplay "Habitability" <| show 34 data.life.habitability
                            , textDisplay "Sophonts" <| show 35 data.life.sophonts
                            ]
                        , if isReferee && not (List.isEmpty data.cultureTrait) then
                            column [ width fill ]
                                [ viewSectionHeader "Culture"
                                , column [ spacing 12, width fill, paddingEach { zeroEach | top = 8 } ]
                                    [ row [ spacing 16, width fill ] cultureRow1
                                    , row [ spacing 16, width fill ] cultureRow2
                                    ]
                                ]

                          else
                            none
                        ]

                "gov" ->
                    let
                        g =
                            data.government
                    in
                    column [ width fill ]
                        [ column groupAttrs
                            [ textDisplay "Government" <| show 44 data.social.government
                            , if g.description /= "" then
                                textDisplay "Description" <| show 46 g.description

                              else
                                none
                            ]
                        , if g.judicial /= "" || g.executive /= "" || g.legislative /= "" then
                            column [ width fill ]
                                [ viewSectionHeader "Structure"
                                , column groupAttrs
                                    [ if g.judicial /= "" then
                                        textDisplay "Judicial" <| show 47 g.judicial

                                      else
                                        none
                                    , if g.executive /= "" then
                                        textDisplay "Executive" <| show 48 g.executive

                                      else
                                        none
                                    , if g.legislative /= "" then
                                        textDisplay "Legislative" <| show 49 g.legislative

                                      else
                                        none
                                    ]
                                ]

                          else
                            none
                        , if g.authority /= "" || g.centralisation /= "" then
                            column [ width fill ]
                                [ viewSectionHeader "Characteristics"
                                , column groupAttrs
                                    [ if g.authority /= "" then
                                        textDisplay "Authority" <| show 50 g.authority

                                      else
                                        none
                                    , if g.centralisation /= "" then
                                        textDisplay "Centralisation" <| show 51 g.centralisation

                                      else
                                        none
                                    ]
                                ]

                          else
                            none
                        ]

                "law" ->
                    let
                        sc =
                            data.lawSubClassifications

                        ch =
                            data.lawCharacteristics
                    in
                    column [ width fill ]
                        [ column groupAttrs
                            [ textDisplay "Law Level" <| show 52 data.social.lawLevel
                            ]
                        , if sc.weaponsAndArmour /= "" || sc.criminalLaw /= "" || sc.economicLaw /= "" || sc.privateLaw /= "" || sc.personalRights /= "" then
                            column [ width fill ]
                                [ viewSectionHeader "Sub-Classifications"
                                , column groupAttrs
                                    [ if sc.weaponsAndArmour /= "" then
                                        textDisplay "Weapons & Armour" <| show 53 sc.weaponsAndArmour

                                      else
                                        none
                                    , if sc.criminalLaw /= "" then
                                        textDisplay "Criminal Law" <| show 54 sc.criminalLaw

                                      else
                                        none
                                    , if sc.economicLaw /= "" then
                                        textDisplay "Economic Law" <| show 55 sc.economicLaw

                                      else
                                        none
                                    , if sc.privateLaw /= "" then
                                        textDisplay "Private Law" <| show 56 sc.privateLaw

                                      else
                                        none
                                    , if sc.personalRights /= "" then
                                        textDisplay "Personal Rights" <| show 57 sc.personalRights

                                      else
                                        none
                                    ]
                                ]

                          else
                            none
                        , if ch.uniformity /= "" || ch.judicialSystem /= "" || ch.deathPenalty /= "" || ch.presumedInnocence /= "" || ch.econometricInfractionsAdministrative /= "" then
                            column [ width fill ]
                                [ viewSectionHeader "Characteristics"
                                , column groupAttrs
                                    [ if ch.uniformity /= "" then
                                        textDisplay "Law Uniformity" <| show 58 ch.uniformity

                                      else
                                        none
                                    , if ch.judicialSystem /= "" then
                                        textDisplay "Judicial System" <| show 59 ch.judicialSystem

                                      else
                                        none
                                    , if ch.deathPenalty /= "" then
                                        textDisplay "Death Penalty" <| show 60 ch.deathPenalty

                                      else
                                        none
                                    , if ch.presumedInnocence /= "" then
                                        textDisplay "Presumed Innocence" <| show 61 ch.presumedInnocence

                                      else
                                        none
                                    , if ch.econometricInfractionsAdministrative /= "" then
                                        textDisplay "Econometric Infractions Admin." <| show 62 ch.econometricInfractionsAdministrative

                                      else
                                        none
                                    ]
                                ]

                          else
                            none
                        ]

                "tech" ->
                    let
                        td =
                            data.techDetail

                        -- (label, raw value, string index)
                        capDefs =
                            [ ( "Energy", td.energy, 65 )
                            , ( "Electronics", td.electronics, 66 )
                            , ( "Manufacturing", td.manufacturing, 67 )
                            , ( "Medical", td.medical, 68 )
                            , ( "Environmental", td.environmental, 69 )
                            , ( "Land Transport", td.land, 70 )
                            , ( "Water Transport", td.sea, 71 )
                            , ( "Air Transport", td.air, 72 )
                            , ( "Space Transport", td.space, 73 )
                            , ( "Personal Military", td.personalMilitary, 74 )
                            , ( "Heavy Military", td.heavyMilitary, 75 )
                            ]

                        hasCaps =
                            List.any (\( _, raw, _ ) -> raw /= "") capDefs
                    in
                    column [ width fill ]
                        [ column groupAttrs
                            [ textDisplay "Tech Level" <| show 63 data.social.techLevel
                            , if td.descriptor /= "" then
                                textDisplay "Descriptor" <| show 64 td.descriptor

                              else
                                none
                            ]
                        , if hasCaps then
                            column [ width fill ]
                                [ viewSectionHeader "Capabilities"
                                , column groupAttrs
                                    (capDefs
                                        |> List.filter (\( _, raw, _ ) -> raw /= "")
                                        |> List.map (\( lbl, raw, idx ) -> textDisplay lbl (show idx raw))
                                    )
                                ]

                          else
                            none
                        ]

                _ ->
                    column [ width fill ]
                        [ row (spacing 40 :: groupAttrs)
                            [ column [ alignTop ]
                                [ textDisplayNarrow "Orbit" <| show 0 data.orbital.orbit
                                , textDisplayNarrow "AU" <| show 1 data.physical.au
                                , textDisplayNarrow "HZCO Dev" <| show 2 data.orbital.effectiveHZCODeviation
                                , textDisplayNarrow "Period (yrs)" <| show 3 data.physical.period
                                , textDisplayNarrow "Retrograde" <| show 4 data.orbital.retrograde
                                , textDisplayNarrow "Inclination" <| show 5 data.physical.inclination
                                , textDisplayNarrow "Eccentricity" <| show 6 data.physical.eccentricity
                                ]
                            ]
                        , viewJumpShadowTable data.jumpShadowKm
                        ]
    in
    column [ width fill ]
        [ viewTabBar safeTab setTab tabs
        , el [ paddingEach { zeroEach | top = 16 }, width fill ] tabContent
        ]


viewGasGiantAnalysisDetail : Int -> String -> (String -> msg) -> (StellarObject -> msg) -> MoonsTabConfig msg -> AnalyisDetailGasGiantData -> Html msg
viewGasGiantAnalysisDetail timeChars activeTab setTab onSelectObject moonsTabConfig data =
    let
        firstTabIndex =
            case safeTab of
                "physical" ->
                    4

                _ ->
                    0

        tabOffset =
            Array.get firstTabIndex counts |> Maybe.withDefault 0

        show index str =
            let
                offset =
                    timeChars - ((Array.get index counts |> Maybe.withDefault 0) - tabOffset)
            in
            if timeChars < 0 then
                ""

            else
                String.left offset str

        strings =
            [ data.physical.au
            , data.physical.period
            , data.physical.inclination
            , data.physical.eccentricity
            , data.physical.mass
            , data.physical.diameter
            , data.physical.axialTilt
            , data.physical.moons
            , data.physical.hasRing
            ]

        counts =
            List.Extra.scanl (\word total -> total + (floor <| sqrt <| toFloat <| String.length word)) 0 strings
                |> Array.fromList

        tabs =
            [ { id = "orbital", label = "Orbital", code = "⊕" }
            , { id = "physical", label = "Physical", code = "⊕" }
            , { id = "moons", label = "Moons (" ++ data.physical.moons ++ ")", code = "☾" }
            ]

        safeTab =
            if List.any (\t -> t.id == activeTab) tabs then
                activeTab

            else
                "orbital"

        tabContent =
            case safeTab of
                "physical" ->
                    row (spacing 40 :: groupAttrs)
                        [ column [ alignTop ]
                            [ textDisplayMedium "Mass" <|
                                let
                                    m =
                                        show 4 data.physical.mass
                                in
                                if m == "—" || m == "" then
                                    m

                                else
                                    m ++ " ☉"
                            , textDisplayMedium "Diameter (km)" <| show 5 data.physical.diameter
                            , textDisplayMedium "Axial Tilt" <| show 6 data.physical.axialTilt
                            ]
                        , column [ alignTop ]
                            [ textDisplayNarrow "Moons" <| show 7 data.physical.moons
                            , textDisplayNarrow "Rings" <| show 8 data.physical.hasRing
                            ]
                        ]

                "moons" ->
                    viewMoonsTab onSelectObject moonsTabConfig

                _ ->
                    column [ width fill ]
                        [ row (spacing 40 :: groupAttrs)
                            [ column [ alignTop ]
                                [ textDisplayNarrow "AU" <| show 0 data.physical.au
                                , textDisplayNarrow "Period (yrs)" <| show 1 data.physical.period
                                , textDisplayNarrow "Inclination" <| show 2 data.physical.inclination
                                , textDisplayNarrow "Eccentricity" <| show 3 data.physical.eccentricity
                                ]
                            ]
                        , viewJumpShadowTable data.jumpShadowKm
                        ]
    in
    column [ width fill ]
        [ viewTabBar safeTab setTab tabs
        , el [ paddingEach { zeroEach | top = 16 }, width fill ] tabContent
        ]


viewMoonsTab : (StellarObject -> msg) -> MoonsTabConfig msg -> Html msg
viewMoonsTab onSelectObject moonsTabConfig =
    let
        checkboxRow =
            row
                [ spacing 6
                , pointerCursor
                , Html.Events.onClick moonsTabConfig.onToggleSignificant
                , paddingEach { zeroEach | bottom = 8 }
                ]
                [ el [ HtmlAttrs.style "font-size" "13px", fontVar "--color-fg" ]
                    (text
                        (if moonsTabConfig.significantOnly then
                            "☑"

                         else
                            "☐"
                        )
                    )
                , el [ HtmlAttrs.style "font-size" "13px", fontVar "--color-fg-muted" ] (text "Significant only")
                ]

        headerCell alignAttrs label =
            el
                ([ HtmlAttrs.style "font-size" "11px"
                 , HtmlAttrs.class "font-bold"
                 , fontVar "--color-fg-muted"
                 , paddingEach { left = 8, right = 8, top = 0, bottom = 6 }
                 , HtmlAttrs.class "border-b"
                 , outlineBorder
                 , HtmlAttrs.style "white-space" "nowrap"
                 ]
                    ++ alignAttrs
                )
                (text label)

        bodyCell moonObj alignAttrs content =
            el
                ([ HtmlAttrs.style "font-size" "13px"
                 , paddingEach { left = 8, right = 8, top = 6, bottom = 6 }
                 , pointerCursor
                 , Html.Events.onClick (onSelectObject moonObj)
                 ]
                    ++ alignAttrs
                )
                content

        asTerrestrialPlanet moonObj =
            case moonObj of
                TerrestrialPlanet pdata ->
                    Just ( moonObj, pdata )

                _ ->
                    Nothing

        moonsTable moons =
            Html.div
                [ HtmlAttrs.style "display" "grid"
                , HtmlAttrs.style "grid-template-columns" "2fr 108px 2fr"
                , width fill
                ]
                (headerCell [] "Name"
                    :: headerCell [ HtmlAttrs.class "text-right" ] "Orbit (diameters)"
                    :: headerCell [] "UWP"
                    :: (moons
                            |> List.filterMap asTerrestrialPlanet
                            |> List.concatMap
                                (\( moonObj, pdata ) ->
                                    [ bodyCell moonObj [] (text (pdata.name |> Maybe.withDefault pdata.orbitSequence))
                                    , bodyCell moonObj
                                        [ HtmlAttrs.class "text-right font-mono" ]
                                        (text
                                            (Round.round
                                                (if pdata.orbit < 10 then
                                                    1

                                                 else
                                                    0
                                                )
                                                pdata.orbit
                                            )
                                        )
                                    , bodyCell moonObj [ HtmlAttrs.class "font-mono" ] (text pdata.uwp)
                                    ]
                                )
                       )
                )

        mutedText str =
            el [ HtmlAttrs.style "font-size" "13px", fontVar "--color-fg-muted" ] (text str)
    in
    column [ width fill ]
        [ checkboxRow
        , case moonsTabConfig.page of
            NotAsked ->
                mutedText "Select this tab to load moons."

            Loading ->
                mutedText "Loading moons…"

            Failure _ ->
                mutedText "Could not load moons."

            Success page ->
                if List.isEmpty page.moons then
                    mutedText "No moons recorded."

                else
                    column [ width fill ]
                        [ moonsTable page.moons
                        , viewPager page.page page.pages moonsTabConfig.onSetPage
                        ]
        ]


viewPagerPill : List (Html.Attribute msg) -> String -> Html msg
viewPagerPill attrs label =
    el
        ([ paddingXY 12 8
         , HtmlAttrs.class "rounded-lg border"
         , HtmlAttrs.style "font-size" "13px"
         , HtmlAttrs.class "font-medium text-center"
         , HtmlAttrs.style "min-width" "34px"
         ]
            ++ attrs
        )
        (text label)


viewPagerArrow : Bool -> String -> msg -> Html msg
viewPagerArrow enabled label msg =
    if enabled then
        viewPagerPill
            [ bgVar "--color-panel-muted"
            , fontVar "--color-fg-bright"
            , outlineBorder
            , pointerCursor
            , Html.Events.onClick msg
            ]
            label

    else
        viewPagerPill
            [ bgVar "--color-panel-muted"
            , fontVar "--color-fg-muted"
            , outlineBorder
            , HtmlAttrs.style "opacity" "0.6"
            , HtmlAttrs.style "cursor" "not-allowed"
            ]
            label


viewPager : Int -> Int -> (Int -> msg) -> Html msg
viewPager page pages onSetPage =
    row
        [ centerSelf, spacing 8, paddingEach { zeroEach | top = 16 } ]
        [ viewPagerArrow (page > 1) "‹" (onSetPage (page - 1))
        , viewPagerPill [ bgVar "--color-panel-muted", fontVar "--color-fg-bright", outlineBorder ] (String.fromInt page)
        , viewPagerArrow (page < pages) "›" (onSetPage (page + 1))
        ]


viewCitiesTab : CitiesTabConfig msg -> Html msg
viewCitiesTab citiesTabConfig =
    let
        headerCell alignAttrs label =
            el
                ([ HtmlAttrs.style "font-size" "11px"
                 , HtmlAttrs.class "font-bold"
                 , fontVar "--color-fg-muted"
                 , paddingEach { left = 8, right = 8, top = 0, bottom = 6 }
                 , HtmlAttrs.class "border-b"
                 , outlineBorder
                 , HtmlAttrs.style "white-space" "nowrap"
                 ]
                    ++ alignAttrs
                )
                (text label)

        bodyCell alignAttrs content =
            el
                ([ HtmlAttrs.style "font-size" "13px"
                 , paddingEach { left = 8, right = 8, top = 6, bottom = 6 }
                 ]
                    ++ alignAttrs
                )
                content

        citiesTable cities =
            Html.div
                [ HtmlAttrs.style "display" "grid"
                , HtmlAttrs.style "grid-template-columns" "2fr 2fr 1fr 110px"
                , width fill
                ]
                (headerCell [] "Name"
                    :: headerCell [] "Type"
                    :: headerCell [] "Capital"
                    :: headerCell [ HtmlAttrs.class "text-right" ] "Population"
                    :: (cities
                            |> List.concatMap
                                (\city ->
                                    [ bodyCell [] (text city.name)
                                    , bodyCell [] (text (Maybe.withDefault "Standard" city.typeLabel))
                                    , bodyCell [] (text (Maybe.withDefault "—" city.capitalLabel))
                                    , bodyCell
                                        [ HtmlAttrs.class "text-right font-mono" ]
                                        (text (format { usLocale | decimals = Exact 0 } (toFloat city.population)))
                                    ]
                                )
                       )
                )

        mutedText str =
            el [ HtmlAttrs.style "font-size" "13px", fontVar "--color-fg-muted" ] (text str)
    in
    column [ width fill ]
        [ case citiesTabConfig.page of
            NotAsked ->
                mutedText "Select this tab to load cities."

            Loading ->
                mutedText "Loading cities…"

            Failure _ ->
                mutedText "Could not load cities."

            Success page ->
                if List.isEmpty page.cities then
                    mutedText "No cities recorded."

                else
                    column [ width fill ]
                        [ citiesTable page.cities
                        , viewPager page.page page.pages citiesTabConfig.onSetPage
                        ]
        ]


viewPlanetoidBeltAnalysisDetail : Int -> String -> (String -> msg) -> Bool -> CitiesTabConfig msg -> AnalyisDetailPlanetoidBeltData -> Html msg
viewPlanetoidBeltAnalysisDetail timeChars activeTab setTab isReferee citiesTabConfig data =
    let
        pd =
            data.planet

        firstTabIndex =
            case safeTab of
                "starport" ->
                    76

                "physical" ->
                    7

                "atmo" ->
                    17

                "hydro" ->
                    23

                "pop" ->
                    26

                "gov" ->
                    44

                "law" ->
                    52

                "tech" ->
                    63

                _ ->
                    0

        tabOffset =
            Array.get firstTabIndex counts |> Maybe.withDefault 0

        show index str =
            let
                offset =
                    timeChars - ((Array.get index counts |> Maybe.withDefault 0) - tabOffset)
            in
            if timeChars < 0 then
                ""

            else
                String.left offset str

        cultureLabels =
            let
                ls =
                    List.map .label pd.cultureTrait
            in
            ls ++ List.repeat (max 0 (8 - List.length ls)) ""

        strings =
            -- 0–6: orbital tab
            [ pd.orbital.orbit
            , pd.physical.au
            , pd.orbital.effectiveHZCODeviation
            , pd.physical.period
            , pd.orbital.retrograde
            , pd.physical.inclination
            , pd.physical.eccentricity

            -- 7–16: physical tab (belt composition replaces planet physical; padded to 10 slots)
            , data.composition.mType
            , data.composition.sType
            , data.composition.cType
            , data.composition.oType
            , data.belt.resourceRating
            , data.belt.bulk
            , data.belt.span
            , ""
            , ""
            , ""

            -- 17–22: atmo tab
            , pd.atmosphere.type_
            , pd.atmosphere.bar
            , pd.atmosphere.hazardCode
            , pd.atmosphere.taint.subtype
            , pd.atmosphere.taint.severity
            , pd.atmosphere.taint.persistence

            -- 23–25: hydro tab
            , pd.hydrographics.percentage
            , pd.hydrographics.liquid
            , pd.hydrographics.surfaceDistribution

            -- 26–35: pop tab
            , pd.social.population
            , pd.social.concentrationRating |> Maybe.map String.fromInt |> Maybe.withDefault ""
            , pd.social.urbanizationPercentage |> Maybe.map String.fromInt |> Maybe.withDefault ""
            , pd.social.majorCities |> Maybe.map String.fromInt |> Maybe.withDefault ""
            , pd.life.biomass
            , pd.life.biocomplexity
            , pd.life.biodiversity
            , pd.life.compatibility
            , pd.life.habitability
            , pd.life.sophonts
            ]
                -- 36–43: culture (8 fixed slots)
                ++ cultureLabels
                -- 44–51: gov tab
                ++ [ pd.social.government
                   , pd.government.type_
                   , pd.government.description
                   , pd.government.judicial
                   , pd.government.executive
                   , pd.government.legislative
                   , pd.government.authority
                   , pd.government.centralisation
                   ]
                -- 52–62: law tab
                ++ [ pd.social.lawLevel
                   , pd.lawSubClassifications.weaponsAndArmour
                   , pd.lawSubClassifications.criminalLaw
                   , pd.lawSubClassifications.economicLaw
                   , pd.lawSubClassifications.privateLaw
                   , pd.lawSubClassifications.personalRights
                   , pd.lawCharacteristics.uniformity
                   , pd.lawCharacteristics.judicialSystem
                   , pd.lawCharacteristics.deathPenalty
                   , pd.lawCharacteristics.presumedInnocence
                   , pd.lawCharacteristics.econometricInfractionsAdministrative
                   ]
                -- 63–75: tech tab
                ++ [ pd.social.techLevel
                   , pd.techDetail.descriptor
                   , pd.techDetail.energy
                   , pd.techDetail.electronics
                   , pd.techDetail.manufacturing
                   , pd.techDetail.medical
                   , pd.techDetail.environmental
                   , pd.techDetail.land
                   , pd.techDetail.sea
                   , pd.techDetail.air
                   , pd.techDetail.space
                   , pd.techDetail.personalMilitary
                   , pd.techDetail.heavyMilitary
                   ]
                -- 76–79: starport tab
                ++ [ pd.starport.code
                   , pd.starport.quality
                   , pd.starport.fuel
                   , pd.starport.facilities
                   ]

        counts =
            List.Extra.scanl (\word total -> total + (floor <| sqrt <| toFloat <| String.length word)) 0 strings
                |> Array.fromList

        uc i =
            let
                s =
                    String.slice i (i + 1) pd.uwp
            in
            if String.isEmpty s then
                "⊕"

            else
                s

        tabs =
            [ { id = "orbital", label = "Orbital", code = "⊕" }
            , { id = "starport", label = "Starport", code = uc 0 }
            , { id = "physical", label = "Physical", code = uc 1 }
            , { id = "atmo", label = "Atmo", code = uc 2 }
            , { id = "hydro", label = "Hydro", code = uc 3 }
            , { id = "pop", label = "Pop", code = uc 4 }
            , { id = "gov", label = "Gov", code = uc 5 }
            , { id = "law", label = "Law", code = uc 6 }
            , { id = "-", label = "", code = "–" }
            , { id = "tech", label = "Tech", code = uc 8 }
            , { id = "cities", label = "Cities (" ++ String.fromInt pd.cityCount ++ ")", code = "fa:fa-regular fa-city" }
            ]

        safeTab =
            if List.any (\t -> t.id == activeTab && t.id /= "-") tabs then
                activeTab

            else
                "orbital"

        tabContent =
            case safeTab of
                "cities" ->
                    viewCitiesTab citiesTabConfig

                "starport" ->
                    column groupAttrs
                        [ textDisplay "Starport Class" <| show 76 pd.starport.code
                        , textDisplay "Quality" <| show 77 pd.starport.quality
                        , if pd.starport.fuel /= "None" then
                            textDisplay "Fuel" <| show 78 pd.starport.fuel

                          else
                            none
                        , if pd.starport.facilities /= "None" then
                            textDisplay "Facilities" <| show 79 pd.starport.facilities

                          else
                            none
                        ]

                "physical" ->
                    column [ width fill ]
                        [ viewSectionHeader "Belt Composition"
                        , column groupAttrs
                            [ textDisplay "Metallic" <| show 7 data.composition.mType
                            , textDisplay "Stony" <| show 8 data.composition.sType
                            , textDisplay "Carbonaceous" <| show 9 data.composition.cType
                            , textDisplay "Other" <| show 10 data.composition.oType
                            ]
                        , viewSectionHeader "Belt Data"
                        , column groupAttrs
                            [ textDisplay "Resource Rating" <| show 11 data.belt.resourceRating
                            , textDisplay "Bulk" <| show 12 data.belt.bulk
                            , textDisplay "Span" <| show 13 data.belt.span
                            ]
                        ]

                "atmo" ->
                    column groupAttrs
                        [ textDisplay "Type" <| show 17 pd.atmosphere.type_
                        , textDisplay "BAR" <| show 18 pd.atmosphere.bar
                        , textDisplay "Hazard Code" <| show 19 pd.atmosphere.hazardCode
                        , row [ width fill ]
                            [ el
                                [ fontVar "--color-fg-muted"
                                , HtmlAttrs.class "font-bold"
                                , HtmlAttrs.style "font-size" "14px"
                                , alignTop
                                , width (px 50)
                                , paddingEach <| { zeroEach | top = 5 }
                                ]
                              <|
                                text "Taint"
                            , column [ width fill ]
                                [ taintTextDisplay "Subtype" <| show 20 pd.atmosphere.taint.subtype
                                , taintTextDisplay "Severity" <| show 21 pd.atmosphere.taint.severity
                                , taintTextDisplay "Persistence" <| show 22 pd.atmosphere.taint.persistence
                                ]
                            ]
                        ]

                "hydro" ->
                    column groupAttrs
                        [ textDisplay "Percentage" <| show 23 pd.hydrographics.percentage
                        , if pd.hydrographics.liquid /= "" then
                            textDisplay "Liquid" <| show 24 pd.hydrographics.liquid

                          else
                            none
                        , textDisplay "Surface Distribution" <| show 25 pd.hydrographics.surfaceDistribution
                        ]

                "pop" ->
                    let
                        cultureRow1 =
                            List.take 4 pd.cultureTrait
                                |> List.indexedMap
                                    (\i ct ->
                                        if show (36 + i) ct.label /= "" then
                                            viewCultureGauge ct

                                        else
                                            el [ width fill ] none
                                    )

                        cultureRow2 =
                            List.drop 4 pd.cultureTrait
                                |> List.indexedMap
                                    (\i ct ->
                                        if show (40 + i) ct.label /= "" then
                                            viewCultureGauge ct

                                        else
                                            el [ width fill ] none
                                    )
                    in
                    column [ width fill ]
                        [ viewSectionHeader "Population"
                        , column groupAttrs
                            [ textDisplay "Population" <| show 26 pd.social.population
                            , textDisplay "Concentration Rating"
                                (let
                                    s =
                                        show 27 (pd.social.concentrationRating |> Maybe.map String.fromInt |> Maybe.withDefault "")
                                 in
                                 if s == "" then
                                    if pd.social.concentrationRating == Nothing then
                                        "—"

                                    else
                                        ""

                                 else
                                    s
                                )
                            , textDisplay "Urbanisation %"
                                (let
                                    s =
                                        show 28 (pd.social.urbanizationPercentage |> Maybe.map String.fromInt |> Maybe.withDefault "")
                                 in
                                 if s == "" then
                                    if pd.social.urbanizationPercentage == Nothing then
                                        "—"

                                    else
                                        ""

                                 else
                                    s
                                )
                            , textDisplay "Major Cities"
                                (let
                                    s =
                                        show 29 (pd.social.majorCities |> Maybe.map String.fromInt |> Maybe.withDefault "")
                                 in
                                 if s == "" then
                                    if pd.social.majorCities == Nothing then
                                        "—"

                                    else
                                        ""

                                 else
                                    s
                                )
                            ]
                        , viewSectionHeader "Life"
                        , column groupAttrs
                            [ textDisplay "Biomass" <| show 30 pd.life.biomass
                            , textDisplay "Biocomplexity" <| show 31 pd.life.biocomplexity
                            , textDisplay "Biodiversity" <| show 32 pd.life.biodiversity
                            , textDisplay "Compatibility" <| show 33 pd.life.compatibility
                            , textDisplay "Habitability" <| show 34 pd.life.habitability
                            , textDisplay "Sophonts" <| show 35 pd.life.sophonts
                            ]
                        , if isReferee && not (List.isEmpty pd.cultureTrait) then
                            column [ width fill ]
                                [ viewSectionHeader "Culture"
                                , column [ spacing 12, width fill, paddingEach { zeroEach | top = 8 } ]
                                    [ row [ spacing 16, width fill ] cultureRow1
                                    , row [ spacing 16, width fill ] cultureRow2
                                    ]
                                ]

                          else
                            none
                        ]

                "gov" ->
                    let
                        g =
                            pd.government
                    in
                    column [ width fill ]
                        [ column groupAttrs
                            [ textDisplay "Government" <| show 44 pd.social.government
                            , if g.description /= "" then
                                textDisplay "Description" <| show 46 g.description

                              else
                                none
                            ]
                        , if g.judicial /= "" || g.executive /= "" || g.legislative /= "" then
                            column [ width fill ]
                                [ viewSectionHeader "Structure"
                                , column groupAttrs
                                    [ if g.judicial /= "" then
                                        textDisplay "Judicial" <| show 47 g.judicial

                                      else
                                        none
                                    , if g.executive /= "" then
                                        textDisplay "Executive" <| show 48 g.executive

                                      else
                                        none
                                    , if g.legislative /= "" then
                                        textDisplay "Legislative" <| show 49 g.legislative

                                      else
                                        none
                                    ]
                                ]

                          else
                            none
                        , if g.authority /= "" || g.centralisation /= "" then
                            column [ width fill ]
                                [ viewSectionHeader "Characteristics"
                                , column groupAttrs
                                    [ if g.authority /= "" then
                                        textDisplay "Authority" <| show 50 g.authority

                                      else
                                        none
                                    , if g.centralisation /= "" then
                                        textDisplay "Centralisation" <| show 51 g.centralisation

                                      else
                                        none
                                    ]
                                ]

                          else
                            none
                        ]

                "law" ->
                    let
                        sc =
                            pd.lawSubClassifications

                        ch =
                            pd.lawCharacteristics
                    in
                    column [ width fill ]
                        [ column groupAttrs
                            [ textDisplay "Law Level" <| show 52 pd.social.lawLevel
                            ]
                        , if sc.weaponsAndArmour /= "" || sc.criminalLaw /= "" || sc.economicLaw /= "" || sc.privateLaw /= "" || sc.personalRights /= "" then
                            column [ width fill ]
                                [ viewSectionHeader "Sub-Classifications"
                                , column groupAttrs
                                    [ if sc.weaponsAndArmour /= "" then
                                        textDisplay "Weapons & Armour" <| show 53 sc.weaponsAndArmour

                                      else
                                        none
                                    , if sc.criminalLaw /= "" then
                                        textDisplay "Criminal Law" <| show 54 sc.criminalLaw

                                      else
                                        none
                                    , if sc.economicLaw /= "" then
                                        textDisplay "Economic Law" <| show 55 sc.economicLaw

                                      else
                                        none
                                    , if sc.privateLaw /= "" then
                                        textDisplay "Private Law" <| show 56 sc.privateLaw

                                      else
                                        none
                                    , if sc.personalRights /= "" then
                                        textDisplay "Personal Rights" <| show 57 sc.personalRights

                                      else
                                        none
                                    ]
                                ]

                          else
                            none
                        , if ch.uniformity /= "" || ch.judicialSystem /= "" || ch.deathPenalty /= "" || ch.presumedInnocence /= "" || ch.econometricInfractionsAdministrative /= "" then
                            column [ width fill ]
                                [ viewSectionHeader "Characteristics"
                                , column groupAttrs
                                    [ if ch.uniformity /= "" then
                                        textDisplay "Law Uniformity" <| show 58 ch.uniformity

                                      else
                                        none
                                    , if ch.judicialSystem /= "" then
                                        textDisplay "Judicial System" <| show 59 ch.judicialSystem

                                      else
                                        none
                                    , if ch.deathPenalty /= "" then
                                        textDisplay "Death Penalty" <| show 60 ch.deathPenalty

                                      else
                                        none
                                    , if ch.presumedInnocence /= "" then
                                        textDisplay "Presumed Innocence" <| show 61 ch.presumedInnocence

                                      else
                                        none
                                    , if ch.econometricInfractionsAdministrative /= "" then
                                        textDisplay "Econometric Infractions Admin." <| show 62 ch.econometricInfractionsAdministrative

                                      else
                                        none
                                    ]
                                ]

                          else
                            none
                        ]

                "tech" ->
                    let
                        td =
                            pd.techDetail

                        capDefs =
                            [ ( "Energy", td.energy, 65 )
                            , ( "Electronics", td.electronics, 66 )
                            , ( "Manufacturing", td.manufacturing, 67 )
                            , ( "Medical", td.medical, 68 )
                            , ( "Environmental", td.environmental, 69 )
                            , ( "Land Transport", td.land, 70 )
                            , ( "Water Transport", td.sea, 71 )
                            , ( "Air Transport", td.air, 72 )
                            , ( "Space Transport", td.space, 73 )
                            , ( "Personal Military", td.personalMilitary, 74 )
                            , ( "Heavy Military", td.heavyMilitary, 75 )
                            ]

                        hasCaps =
                            List.any (\( _, raw, _ ) -> raw /= "") capDefs
                    in
                    column [ width fill ]
                        [ column groupAttrs
                            [ textDisplay "Tech Level" <| show 63 pd.social.techLevel
                            , if td.descriptor /= "" then
                                textDisplay "Descriptor" <| show 64 td.descriptor

                              else
                                none
                            ]
                        , if hasCaps then
                            column [ width fill ]
                                [ viewSectionHeader "Capabilities"
                                , column groupAttrs
                                    (capDefs
                                        |> List.filter (\( _, raw, _ ) -> raw /= "")
                                        |> List.map (\( lbl, raw, idx ) -> textDisplay lbl (show idx raw))
                                    )
                                ]

                          else
                            none
                        ]

                _ ->
                    column [ width fill ]
                        [ row (spacing 40 :: groupAttrs)
                            [ column [ alignTop ]
                                [ textDisplayNarrow "Orbit" <| show 0 pd.orbital.orbit
                                , textDisplayNarrow "AU" <| show 1 pd.physical.au
                                , textDisplayNarrow "HZCO Dev" <| show 2 pd.orbital.effectiveHZCODeviation
                                , textDisplayNarrow "Period (yrs)" <| show 3 pd.physical.period
                                , textDisplayNarrow "Retrograde" <| show 4 pd.orbital.retrograde
                                , textDisplayNarrow "Inclination" <| show 5 pd.physical.inclination
                                , textDisplayNarrow "Eccentricity" <| show 6 pd.physical.eccentricity
                                ]
                            ]
                        , viewJumpShadowTable pd.jumpShadowKm
                        ]
    in
    column [ width fill ]
        [ viewTabBar safeTab setTab tabs
        , el [ paddingEach { zeroEach | top = 16 }, width fill ] tabContent
        ]
