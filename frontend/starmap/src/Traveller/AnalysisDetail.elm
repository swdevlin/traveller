module Traveller.AnalysisDetail exposing
    ( AnalysisDetail(..)
    , AnalysisDetailHeader
    , AnalyisDetailGasGiantData
    , AnalyisDetailPlanetoidBeltData
    , AnalyisDetailPlanetoidData
    , AnalyisDetailStarData
    , viewGasGiantAnalysisDetail
    , viewObjectAnalysisDetail
    , viewPlanetoidAnalysisDetail
    , viewPlanetoidBeltAnalysisDetail
    )

{-| Analysis detail views for stellar objects, with UWP-driven tab navigation.
-}

import Array
import Element
    exposing
        ( column
        , el
        , fill
        , height
        , row
        , text
        , width
        )
import Element.Background as Background
import Element.Border as Border
import Element.Events as Events
import Element.Font as Font
import Html
import Html.Attributes as HtmlAttrs
import Html.Events
import Json.Decode
import List.Extra
import Traveller.TravelCalculations as TravelCalc
import Traveller.UI
    exposing
        ( groupAttrs
        , profileFieldDisplay
        , taintTextDisplay
        , textDisplay
        , textDisplayMedium
        , textDisplayNarrow
        , uiDeepnightColorFontColour
        , zeroEach
        )


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
    , colour : String
    , temperature : String
    , age : String
    , mass : String
    , diameter : String
    , luminosity : String
    , minimumOrbit : String
    , hzco : String
    , jumpShadow : String
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


activeTabColour : Element.Color
activeTabColour =
    Element.rgba 0.87 0.50 0.20 1.0


mutedTabColour : Element.Color
mutedTabColour =
    Element.rgba 0.17 0.42 0.55 0.55


viewTabBar : String -> (String -> msg) -> List { id : String, label : String, code : String } -> Element.Element msg
viewTabBar activeTab setTab tabs =
    row
        [ width fill
        , Border.widthEach { zeroEach | bottom = 1 }
        , Border.color <| Element.rgba 0.17 0.42 0.55 0.15
        ]
        (List.map (viewOneTab activeTab setTab) tabs)


viewOneTab : String -> (String -> msg) -> { id : String, label : String, code : String } -> Element.Element msg
viewOneTab activeTab setTab tab =
    if tab.id == "-" then
        el
            [ Element.paddingEach { top = 8, left = 2, right = 2, bottom = 8 }
            , Font.color mutedTabColour
            ]
            (column [ Element.spacing 1, Element.centerX ]
                [ el [ Font.size 15, Font.bold, Font.center, Element.centerX ] (text "–")
                , el [ Font.size 11, Font.center, Element.centerX ] (text "")
                ]
            )

    else
        let
            isActive =
                tab.id == activeTab

            colour =
                if isActive then
                    activeTabColour

                else
                    mutedTabColour
        in
        el
            [ Element.paddingEach { top = 8, left = 12, right = 12, bottom = 8 }
            , Border.widthEach { zeroEach | bottom = 2 }
            , Border.color
                (if isActive then
                    activeTabColour

                 else
                    Element.rgba 0 0 0 0
                )
            , Font.color colour
            , Events.onClick (setTab tab.id)
            , Element.pointer
            ]
            (column [ Element.spacing 1, Element.centerX ]
                [ el [ Font.size 15, Font.bold, Font.center, Element.centerX, uiDeepnightColorFontColour ] (text tab.code)
                , el [ Font.size 11, Font.center, Element.centerX ] (text tab.label)
                ]
            )


viewSectionHeader : String -> Element.Element msg
viewSectionHeader title =
    row
        [ width fill
        , Element.spacing 8
        , Element.paddingEach { zeroEach | top = 12, bottom = 2 }
        ]
        [ el [ uiDeepnightColorFontColour, Font.size 11, Font.bold ] <| text (String.toUpper title)
        , el
            [ width fill
            , height (Element.px 1)
            , Background.color (Element.rgba 0.17 0.42 0.55 0.3)
            , Element.centerY
            ]
            Element.none
        ]


viewPlanetaryProfile : AnalyisDetailPlanetoidData -> Element.Element msg
viewPlanetaryProfile data =
    column
        [ Element.paddingEach { zeroEach | right = 16 }
        , Element.spacing 0
        ]
        [ viewSectionHeader "Planetary Profile"
        , el
            [ Element.centerX
            , Font.size 15
            , Font.family [ Font.monospace ]
            , uiDeepnightColorFontColour
            , Element.paddingEach { zeroEach | top = 6, bottom = 6 }
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


viewGasGiantProfile : AnalyisDetailGasGiantData -> Element.Element msg
viewGasGiantProfile data =
    let
        sizeDescription =
            case data.code of
                "GS" -> "Small"
                "GM" -> "Medium"
                "GL" -> "Large"
                _ -> data.code
    in
    column
        [ Element.paddingEach { zeroEach | right = 16 }
        , Element.spacing 0
        ]
        [ viewSectionHeader "Gas Giant Profile"
        , profileFieldDisplay "Size" (data.code ++ " – " ++ sizeDescription)
        ]


viewBeltProfile : AnalyisDetailPlanetoidBeltData -> Element.Element msg
viewBeltProfile data =
    column
        [ Element.paddingEach { zeroEach | right = 16 }
        , Element.spacing 0
        ]
        [ viewSectionHeader "Belt Profile"
        , profileFieldDisplay "Resource" data.belt.resourceRating
        , profileFieldDisplay "Bulk" data.belt.bulk
        , profileFieldDisplay "Metallic" data.composition.mType
        , profileFieldDisplay "Stony" data.composition.sType
        , profileFieldDisplay "Carbonaceous" data.composition.cType
        , profileFieldDisplay "Other" data.composition.oType
        ]


viewJumpShadowTable : Maybe Float -> Element.Element msg
viewJumpShadowTable maybeKm =
    case maybeKm of
        Nothing ->
            Element.none

        Just km ->
            if km <= 0 then
                Element.none

            else
                let
                    mDrives =
                        [ 1, 2, 3, 4, 5, 6 ]

                    cell attrs child =
                        el
                            ([ width fill
                             , Element.paddingXY 0 4
                             , Element.centerX
                             ]
                                ++ attrs
                            )
                            child

                    headerCell m =
                        cell
                            [ Font.bold
                            , Font.size 11
                            , uiDeepnightColorFontColour
                            , Border.widthEach { zeroEach | bottom = 1 }
                            , Border.color (Element.rgba 0.17 0.42 0.55 0.15)
                            ]
                            (el [ Element.centerX ] (text ("M" ++ String.fromInt m)))

                    timeCell m =
                        let
                            secs =
                                TravelCalc.travelTimeInSeconds km m

                            t =
                                TravelCalc.travelTimeHoursDays secs
                        in
                        cell [ Font.size 12, Font.family [ Font.monospace ] ]
                            (el [ Element.centerX ] (text t))
                in
                column [ width fill, Element.paddingEach { zeroEach | top = 8 } ]
                    [ viewSectionHeader "Safe Jump Distance"
                    , row [ width fill ] (List.map headerCell mDrives)
                    , row [ width fill ] (List.map timeCell mDrives)
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


viewCultureGauge : CultureTraitItem -> Element.Element msg
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
    in
    column [ width fill, Element.spacing 4 ]
        [ el [ Font.size 12, uiDeepnightColorFontColour, Font.bold ] (text trait.label)
        , el [ width fill, Element.paddingEach { zeroEach | top = 4 } ] <|
            Element.html <|
                let
                    caretLeft =
                        String.fromFloat clampedPct ++ "%"
                in
                Html.div
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
                            , HtmlAttrs.style "background-color" "rgba(44, 107, 140, 0.4)"
                            , HtmlAttrs.style "transform" "translateY(-50%)"
                            ]
                            []
                        , Html.div
                            [ HtmlAttrs.style "position" "absolute"
                            , HtmlAttrs.style "top" "50%"
                            , HtmlAttrs.style "left" caretLeft
                            , HtmlAttrs.style "transform" "translateX(-50%) translateY(-50%)"
                            , HtmlAttrs.style "font-size" "10px"
                            , HtmlAttrs.style "color" "rgb(223, 127, 51)"
                            ]
                            [ Html.text "▲" ]
                        ]
                    , Html.div
                        [ HtmlAttrs.style "display" "flex"
                        , HtmlAttrs.style "justify-content" "space-between"
                        , HtmlAttrs.style "font-size" "11px"
                        , HtmlAttrs.style "color" "rgba(26, 74, 106, 0.7)"
                        , HtmlAttrs.style "margin-top" "2px"
                        ]
                        [ Html.span [] [ Html.text trait.lowLabel ]
                        , Html.span
                            [ HtmlAttrs.style "font-family" "monospace"
                            , HtmlAttrs.style "color" "rgb(26, 74, 106)"
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
        ]


{-| Main view for object analysis detail overlay.
-}
viewObjectAnalysisDetail : Int -> msg -> msg -> String -> (String -> msg) -> Bool -> AnalysisDetail -> Element.Element msg
viewObjectAnalysisDetail timeChars closeMsg noOpMsg activeTab setTab isReferee data =
    let
        profileLayout profile content_ =
            row [ Element.spacing 0 ]
                [ column
                    [ width (Element.px 220)
                    , Border.widthEach { zeroEach | right = 1 }
                    , Border.color (Element.rgba 0.17 0.42 0.55 0.15)
                    , Element.alignTop
                    ]
                    [ profile ]
                , column [ width fill, Element.paddingEach { zeroEach | left = 16 }, Element.alignTop ]
                    [ content_ ]
                ]

        ( header, content, modalWidth ) =
            case data of
                AnalyisDetailTerrestialPlanet detailHeader sharedPData ->
                    ( detailHeader.header
                    , profileLayout (viewPlanetaryProfile sharedPData) (viewPlanetoidAnalysisDetail timeChars activeTab setTab isReferee sharedPData)
                    , 960
                    )

                AnalyisDetailPlanetoid detailHeader sharedPData ->
                    ( detailHeader.header
                    , profileLayout (viewPlanetaryProfile sharedPData) (viewPlanetoidAnalysisDetail timeChars activeTab setTab isReferee sharedPData)
                    , 960
                    )

                AnalyisDetailGasGiant detailHeader sharedGGData ->
                    ( detailHeader.header
                    , profileLayout (viewGasGiantProfile sharedGGData) (viewGasGiantAnalysisDetail timeChars activeTab setTab sharedGGData)
                    , 900
                    )

                AnalyisDetailPlanetoidBelt detailHeader sharePBData ->
                    ( detailHeader.header
                    , profileLayout (viewBeltProfile sharePBData) (viewPlanetoidBeltAnalysisDetail timeChars activeTab setTab isReferee sharePBData)
                    , 960
                    )

                AnalyisDetailStar detailHeader starData ->
                    ( detailHeader.header, viewStarAnalysisDetail starData, 750 )
    in
    el
        [ width fill
        , height fill
        , Events.onClick closeMsg
        ]
    <|
        column
            [ Element.centerX
            , Element.centerY
            , Element.htmlAttribute (Html.Events.stopPropagationOn "click" (Json.Decode.succeed ( noOpMsg, True )))
            , Element.htmlAttribute (HtmlAttrs.style "background-color" "rgba(245, 250, 255, 0.45)")
            , Element.htmlAttribute (HtmlAttrs.style "backdrop-filter" "blur(16px)")
            , Element.htmlAttribute (HtmlAttrs.style "-webkit-backdrop-filter" "blur(16px)")
            , Element.htmlAttribute (HtmlAttrs.style "max-height" "92vh")
            , Element.htmlAttribute (HtmlAttrs.style "overflow-y" "auto")
            , width <| Element.px modalWidth
            , Element.padding 20
            , Border.rounded 6
            , Border.width 1
            , Border.color <| Element.rgba 0.17 0.42 0.55 0.3
            , Border.shadow { offset = ( 0, 8 ), size = 0, blur = 32, color = Element.rgba 0 0 0 0.25 }
            ]
            [ row
                [ width fill
                , Element.paddingEach { zeroEach | bottom = 16 }
                , Border.widthEach { zeroEach | bottom = 1 }
                , Border.color <| Element.rgba 0.17 0.42 0.55 0.15
                ]
                [ el [ Font.size 18, uiDeepnightColorFontColour, Font.bold ] <|
                    text header
                , el
                    [ Element.paddingEach { top = 0, left = 10, right = 0, bottom = 0 }
                    , Element.pointer
                    , Element.mouseOver [ Font.color <| Element.rgb 0 0 0 ]
                    , Font.size 16
                    , Font.color <| Element.rgba 0.17 0.42 0.55 0.7
                    , Element.alignRight
                    , Element.alignTop
                    , Events.onClick closeMsg
                    ]
                  <|
                    text "✕"
                ]
            , content
            ]


viewStarAnalysisDetail : AnalyisDetailStarData -> Element.Element msg
viewStarAnalysisDetail data =
    column groupAttrs
        [ textDisplay "Colour" data.colour
        , textDisplay "Temperature" data.temperature
        , textDisplay "Age" data.age
        , textDisplay "Mass" data.mass
        , textDisplay "Diameter" data.diameter
        , textDisplay "Luminosity" data.luminosity
        , textDisplay "Min. Orbit" data.minimumOrbit
        , textDisplay "HZCO" data.hzco
        , textDisplay "Jump Shadow" data.jumpShadow
        ]


viewPlanetoidAnalysisDetail : Int -> String -> (String -> msg) -> Bool -> AnalyisDetailPlanetoidData -> Element.Element msg
viewPlanetoidAnalysisDetail timeChars activeTab setTab isReferee data =
    let
        firstTabIndex =
            case safeTab of
                "starport" -> 76
                "physical" -> 7
                "atmo" -> 17
                "hydro" -> 23
                "pop" -> 26
                "gov" -> 44
                "law" -> 52
                "tech" -> 63
                _ -> 0

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
                ls = List.map .label data.cultureTrait
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

        safeTab =
            if List.any (\t -> t.id == activeTab && t.id /= "-") tabs then
                activeTab

            else
                "orbital"

        tabContent =
            case safeTab of
                "starport" ->
                    column groupAttrs
                        [ textDisplay "Starport Class" <| show 76 data.starport.code
                        , textDisplay "Quality" <| show 77 data.starport.quality
                        , if data.starport.fuel /= "None" then
                            textDisplay "Fuel" <| show 78 data.starport.fuel

                          else
                            Element.none
                        , if data.starport.facilities /= "None" then
                            textDisplay "Facilities" <| show 79 data.starport.facilities

                          else
                            Element.none
                        ]

                "physical" ->
                    column [ width fill ]
                        [ viewSectionHeader "Physical Data"
                        , row (Element.spacing 40 :: groupAttrs)
                            [ column [ Element.alignTop ]
                                [ textDisplayMedium ("Diameter (" ++ show 7 data.physical.sizeCode ++ ")") <| show 8 data.physical.diameter
                                , textDisplayMedium "Mass" <| (let m = show 9 data.physical.mass in if m == "—" || m == "" then m else m ++ " ☉")
                                , textDisplayMedium "Density" <| (let d = show 10 data.physical.density in if d == "—" || d == "" then d else d ++ " ☉")
                                , textDisplayMedium "Gravity (G)" <| show 11 data.physical.gravity
                                ]
                            ]
                        , viewSectionHeader "Environmental Data"
                        , row (Element.spacing 40 :: groupAttrs)
                            [ column [ Element.alignTop ]
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
                                [ uiDeepnightColorFontColour
                                , Font.bold
                                , Font.size 14
                                , Element.alignTop
                                , width <| Element.px 50
                                , Element.paddingEach <| { zeroEach | top = 5 }
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
                            Element.none
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
                                            el [ width fill ] Element.none
                                    )

                        cultureRow2 =
                            List.drop 4 data.cultureTrait
                                |> List.indexedMap
                                    (\i ct ->
                                        if show (40 + i) ct.label /= "" then
                                            viewCultureGauge ct

                                        else
                                            el [ width fill ] Element.none
                                    )
                    in
                    column [ width fill ]
                        [ viewSectionHeader "Population"
                        , column groupAttrs
                            [ textDisplay "Population" <| show 26 data.social.population
                            , textDisplay "Concentration Rating" (let s = show 27 (data.social.concentrationRating |> Maybe.map String.fromInt |> Maybe.withDefault "") in if s == "" then if data.social.concentrationRating == Nothing then "—" else "" else s)
                            , textDisplay "Urbanisation %" (let s = show 28 (data.social.urbanizationPercentage |> Maybe.map String.fromInt |> Maybe.withDefault "") in if s == "" then if data.social.urbanizationPercentage == Nothing then "—" else "" else s)
                            , textDisplay "Major Cities" (let s = show 29 (data.social.majorCities |> Maybe.map String.fromInt |> Maybe.withDefault "") in if s == "" then if data.social.majorCities == Nothing then "—" else "" else s)
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
                                , column [ Element.spacing 12, width fill, Element.paddingEach { zeroEach | top = 8 } ]
                                    [ row [ Element.spacing 16, width fill ] cultureRow1
                                    , row [ Element.spacing 16, width fill ] cultureRow2
                                    ]
                                ]

                          else
                            Element.none
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
                                Element.none
                            ]
                        , if g.judicial /= "" || g.executive /= "" || g.legislative /= "" then
                            column [ width fill ]
                                [ viewSectionHeader "Structure"
                                , column groupAttrs
                                    [ if g.judicial /= "" then
                                        textDisplay "Judicial" <| show 47 g.judicial

                                      else
                                        Element.none
                                    , if g.executive /= "" then
                                        textDisplay "Executive" <| show 48 g.executive

                                      else
                                        Element.none
                                    , if g.legislative /= "" then
                                        textDisplay "Legislative" <| show 49 g.legislative

                                      else
                                        Element.none
                                    ]
                                ]

                          else
                            Element.none
                        , if g.authority /= "" || g.centralisation /= "" then
                            column [ width fill ]
                                [ viewSectionHeader "Characteristics"
                                , column groupAttrs
                                    [ if g.authority /= "" then
                                        textDisplay "Authority" <| show 50 g.authority

                                      else
                                        Element.none
                                    , if g.centralisation /= "" then
                                        textDisplay "Centralisation" <| show 51 g.centralisation

                                      else
                                        Element.none
                                    ]
                                ]

                          else
                            Element.none
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
                                    [ if sc.weaponsAndArmour /= "" then textDisplay "Weapons & Armour" <| show 53 sc.weaponsAndArmour else Element.none
                                    , if sc.criminalLaw /= "" then textDisplay "Criminal Law" <| show 54 sc.criminalLaw else Element.none
                                    , if sc.economicLaw /= "" then textDisplay "Economic Law" <| show 55 sc.economicLaw else Element.none
                                    , if sc.privateLaw /= "" then textDisplay "Private Law" <| show 56 sc.privateLaw else Element.none
                                    , if sc.personalRights /= "" then textDisplay "Personal Rights" <| show 57 sc.personalRights else Element.none
                                    ]
                                ]

                          else
                            Element.none
                        , if ch.uniformity /= "" || ch.judicialSystem /= "" || ch.deathPenalty /= "" || ch.presumedInnocence /= "" || ch.econometricInfractionsAdministrative /= "" then
                            column [ width fill ]
                                [ viewSectionHeader "Characteristics"
                                , column groupAttrs
                                    [ if ch.uniformity /= "" then textDisplay "Law Uniformity" <| show 58 ch.uniformity else Element.none
                                    , if ch.judicialSystem /= "" then textDisplay "Judicial System" <| show 59 ch.judicialSystem else Element.none
                                    , if ch.deathPenalty /= "" then textDisplay "Death Penalty" <| show 60 ch.deathPenalty else Element.none
                                    , if ch.presumedInnocence /= "" then textDisplay "Presumed Innocence" <| show 61 ch.presumedInnocence else Element.none
                                    , if ch.econometricInfractionsAdministrative /= "" then textDisplay "Econometric Infractions Admin." <| show 62 ch.econometricInfractionsAdministrative else Element.none
                                    ]
                                ]

                          else
                            Element.none
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
                                Element.none
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
                            Element.none
                        ]

                _ ->
                    column [ width fill ]
                        [ row (Element.spacing 40 :: groupAttrs)
                            [ column [ Element.alignTop ]
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
        , el [ Element.paddingEach { zeroEach | top = 16 }, width fill ] tabContent
        ]


showIfNonEmpty : String -> String -> Element.Element msg
showIfNonEmpty lbl val =
    if val /= "" then
        textDisplay lbl val

    else
        Element.none


viewGasGiantAnalysisDetail : Int -> String -> (String -> msg) -> AnalyisDetailGasGiantData -> Element.Element msg
viewGasGiantAnalysisDetail timeChars activeTab setTab data =
    let
        firstTabIndex =
            case safeTab of
                "physical" -> 4
                _ -> 0

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
            ]

        safeTab =
            if List.any (\t -> t.id == activeTab) tabs then
                activeTab

            else
                "orbital"

        tabContent =
            case safeTab of
                "physical" ->
                    row (Element.spacing 40 :: groupAttrs)
                        [ column [ Element.alignTop ]
                            [ textDisplayMedium "Mass" <| (let m = show 4 data.physical.mass in if m == "—" || m == "" then m else m ++ " ☉")
                            , textDisplayMedium "Diameter (km)" <| show 5 data.physical.diameter
                            , textDisplayMedium "Axial Tilt" <| show 6 data.physical.axialTilt
                            ]
                        , column [ Element.alignTop ]
                            [ textDisplayNarrow "Moons" <| show 7 data.physical.moons
                            , textDisplayNarrow "Rings" <| show 8 data.physical.hasRing
                            ]
                        ]

                _ ->
                    column [ width fill ]
                        [ row (Element.spacing 40 :: groupAttrs)
                            [ column [ Element.alignTop ]
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
        , el [ Element.paddingEach { zeroEach | top = 16 }, width fill ] tabContent
        ]


viewPlanetoidBeltAnalysisDetail : Int -> String -> (String -> msg) -> Bool -> AnalyisDetailPlanetoidBeltData -> Element.Element msg
viewPlanetoidBeltAnalysisDetail timeChars activeTab setTab isReferee data =
    let
        pd =
            data.planet

        firstTabIndex =
            case safeTab of
                "starport" -> 76
                "physical" -> 7
                "atmo" -> 17
                "hydro" -> 23
                "pop" -> 26
                "gov" -> 44
                "law" -> 52
                "tech" -> 63
                _ -> 0

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
                ls = List.map .label pd.cultureTrait
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
                s = String.slice i (i + 1) pd.uwp
            in
            if String.isEmpty s then "⊕" else s

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

        safeTab =
            if List.any (\t -> t.id == activeTab && t.id /= "-") tabs then
                activeTab

            else
                "orbital"

        tabContent =
            case safeTab of
                "starport" ->
                    column groupAttrs
                        [ textDisplay "Starport Class" <| show 76 pd.starport.code
                        , textDisplay "Quality" <| show 77 pd.starport.quality
                        , if pd.starport.fuel /= "None" then
                            textDisplay "Fuel" <| show 78 pd.starport.fuel

                          else
                            Element.none
                        , if pd.starport.facilities /= "None" then
                            textDisplay "Facilities" <| show 79 pd.starport.facilities

                          else
                            Element.none
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
                                [ uiDeepnightColorFontColour
                                , Font.bold
                                , Font.size 14
                                , Element.alignTop
                                , width <| Element.px 50
                                , Element.paddingEach <| { zeroEach | top = 5 }
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
                            Element.none
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
                                            el [ width fill ] Element.none
                                    )

                        cultureRow2 =
                            List.drop 4 pd.cultureTrait
                                |> List.indexedMap
                                    (\i ct ->
                                        if show (40 + i) ct.label /= "" then
                                            viewCultureGauge ct

                                        else
                                            el [ width fill ] Element.none
                                    )
                    in
                    column [ width fill ]
                        [ viewSectionHeader "Population"
                        , column groupAttrs
                            [ textDisplay "Population" <| show 26 pd.social.population
                            , textDisplay "Concentration Rating" (let s = show 27 (pd.social.concentrationRating |> Maybe.map String.fromInt |> Maybe.withDefault "") in if s == "" then if pd.social.concentrationRating == Nothing then "—" else "" else s)
                            , textDisplay "Urbanisation %" (let s = show 28 (pd.social.urbanizationPercentage |> Maybe.map String.fromInt |> Maybe.withDefault "") in if s == "" then if pd.social.urbanizationPercentage == Nothing then "—" else "" else s)
                            , textDisplay "Major Cities" (let s = show 29 (pd.social.majorCities |> Maybe.map String.fromInt |> Maybe.withDefault "") in if s == "" then if pd.social.majorCities == Nothing then "—" else "" else s)
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
                                , column [ Element.spacing 12, width fill, Element.paddingEach { zeroEach | top = 8 } ]
                                    [ row [ Element.spacing 16, width fill ] cultureRow1
                                    , row [ Element.spacing 16, width fill ] cultureRow2
                                    ]
                                ]

                          else
                            Element.none
                        ]

                "gov" ->
                    let
                        g = pd.government
                    in
                    column [ width fill ]
                        [ column groupAttrs
                            [ textDisplay "Government" <| show 44 pd.social.government
                            , if g.description /= "" then
                                textDisplay "Description" <| show 46 g.description

                              else
                                Element.none
                            ]
                        , if g.judicial /= "" || g.executive /= "" || g.legislative /= "" then
                            column [ width fill ]
                                [ viewSectionHeader "Structure"
                                , column groupAttrs
                                    [ if g.judicial /= "" then
                                        textDisplay "Judicial" <| show 47 g.judicial

                                      else
                                        Element.none
                                    , if g.executive /= "" then
                                        textDisplay "Executive" <| show 48 g.executive

                                      else
                                        Element.none
                                    , if g.legislative /= "" then
                                        textDisplay "Legislative" <| show 49 g.legislative

                                      else
                                        Element.none
                                    ]
                                ]

                          else
                            Element.none
                        , if g.authority /= "" || g.centralisation /= "" then
                            column [ width fill ]
                                [ viewSectionHeader "Characteristics"
                                , column groupAttrs
                                    [ if g.authority /= "" then
                                        textDisplay "Authority" <| show 50 g.authority

                                      else
                                        Element.none
                                    , if g.centralisation /= "" then
                                        textDisplay "Centralisation" <| show 51 g.centralisation

                                      else
                                        Element.none
                                    ]
                                ]

                          else
                            Element.none
                        ]

                "law" ->
                    let
                        sc = pd.lawSubClassifications
                        ch = pd.lawCharacteristics
                    in
                    column [ width fill ]
                        [ column groupAttrs
                            [ textDisplay "Law Level" <| show 52 pd.social.lawLevel
                            ]
                        , if sc.weaponsAndArmour /= "" || sc.criminalLaw /= "" || sc.economicLaw /= "" || sc.privateLaw /= "" || sc.personalRights /= "" then
                            column [ width fill ]
                                [ viewSectionHeader "Sub-Classifications"
                                , column groupAttrs
                                    [ if sc.weaponsAndArmour /= "" then textDisplay "Weapons & Armour" <| show 53 sc.weaponsAndArmour else Element.none
                                    , if sc.criminalLaw /= "" then textDisplay "Criminal Law" <| show 54 sc.criminalLaw else Element.none
                                    , if sc.economicLaw /= "" then textDisplay "Economic Law" <| show 55 sc.economicLaw else Element.none
                                    , if sc.privateLaw /= "" then textDisplay "Private Law" <| show 56 sc.privateLaw else Element.none
                                    , if sc.personalRights /= "" then textDisplay "Personal Rights" <| show 57 sc.personalRights else Element.none
                                    ]
                                ]

                          else
                            Element.none
                        , if ch.uniformity /= "" || ch.judicialSystem /= "" || ch.deathPenalty /= "" || ch.presumedInnocence /= "" || ch.econometricInfractionsAdministrative /= "" then
                            column [ width fill ]
                                [ viewSectionHeader "Characteristics"
                                , column groupAttrs
                                    [ if ch.uniformity /= "" then textDisplay "Law Uniformity" <| show 58 ch.uniformity else Element.none
                                    , if ch.judicialSystem /= "" then textDisplay "Judicial System" <| show 59 ch.judicialSystem else Element.none
                                    , if ch.deathPenalty /= "" then textDisplay "Death Penalty" <| show 60 ch.deathPenalty else Element.none
                                    , if ch.presumedInnocence /= "" then textDisplay "Presumed Innocence" <| show 61 ch.presumedInnocence else Element.none
                                    , if ch.econometricInfractionsAdministrative /= "" then textDisplay "Econometric Infractions Admin." <| show 62 ch.econometricInfractionsAdministrative else Element.none
                                    ]
                                ]

                          else
                            Element.none
                        ]

                "tech" ->
                    let
                        td = pd.techDetail

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
                                Element.none
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
                            Element.none
                        ]

                _ ->
                    column [ width fill ]
                        [ row (Element.spacing 40 :: groupAttrs)
                            [ column [ Element.alignTop ]
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
        , el [ Element.paddingEach { zeroEach | top = 16 }, width fill ] tabContent
        ]
