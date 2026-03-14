module Traveller.AnalysisDetail exposing
    ( AnalysisDetail(..)
    , AnalysisDetailHeader
    , AnalyisDetailGasGiantData
    , AnalyisDetailPlanetoidBeltData
    , AnalyisDetailPlanetoidData
    , viewGasGiantAnalysisDetail
    , viewObjectAnalysisDetail
    , viewPlanetoidAnalysisDetail
    , viewPlanetoidBeltAnalysisDetail
    )

{-| Analysis detail views for stellar objects.
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
import List.Extra
import Traveller.UI
    exposing
        ( groupAttrs
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
    | AnalyisDetailStar


type alias AnalyisDetailGasGiantData =
    { physical :
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
    { physical :
        { au : String
        , period : String
        , inclination : String
        , eccentricity : String
        , bulk : String
        , span : String
        , cType : String
        , sType : String
        , oType : String
        , mType : String
        }
    }


type alias AnalyisDetailPlanetoidData =
    { physical :
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
    }


{-| Main view for object analysis detail overlay.
Takes a close message to handle the X button click.
-}
viewObjectAnalysisDetail : Int -> msg -> AnalysisDetail -> Element.Element msg
viewObjectAnalysisDetail timeChars closeMsg data =
    let
        ( header, content ) =
            case data of
                AnalyisDetailTerrestialPlanet detailHeader sharedPData ->
                    ( detailHeader.header, viewPlanetoidAnalysisDetail timeChars sharedPData )

                AnalyisDetailPlanetoid detailHeader sharedPData ->
                    ( detailHeader.header, viewPlanetoidAnalysisDetail timeChars sharedPData )

                AnalyisDetailGasGiant detailHeader sharedGGData ->
                    ( detailHeader.header, viewGasGiantAnalysisDetail timeChars sharedGGData )

                AnalyisDetailPlanetoidBelt detailHeader sharePBData ->
                    ( detailHeader.header, viewPlanetoidBeltAnalysisDetail timeChars sharePBData )

                AnalyisDetailStar ->
                    ( "TODO: Star", text "Star not yet implemented" )
    in
    column
        [ height fill
        , Element.centerX
        , Element.centerY
        , Background.color <| Element.rgba 0.3 0.3 0.3 0.95
        , width <| Element.px 750
        , Element.padding 4
        , Border.rounded 3
        , Border.shadow { offset = ( 1, 1 ), size = 2, blur = 4, color = Element.rgba 0.1 0.1 0.1 (1 / 8) }
        ]
        [ row [ width fill ]
            [ el [ Font.size 24, Element.paddingEach { zeroEach | bottom = 15 } ] <|
                text <|
                    header
            , el
                [ Element.paddingEach { top = 0, left = 10, right = 10, bottom = 10 }
                , Element.pointer
                , Element.mouseOver [ Font.color <| Element.rgb 0.8 0.8 0.8 ]
                , Font.size 16
                , Element.alignRight
                , Element.alignTop
                , Events.onClick closeMsg
                ]
              <|
                text "X"
            ]
        , content
        ]


viewPlanetoidAnalysisDetail : Int -> AnalyisDetailPlanetoidData -> Element.Element msg
viewPlanetoidAnalysisDetail timeChars data =
    let
        showTimeCharsTEMP index str =
            let
                offset =
                    timeChars - (Array.get index counts |> Maybe.withDefault 0)
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
            , data.physical.density
            , data.physical.gravity
            , data.physical.diameter
            , data.physical.meanTemperature
            , data.physical.albedo
            , data.physical.axialTilt
            , data.physical.greenhouse
            , data.atmosphere.type_
            , data.atmosphere.bar
            , data.atmosphere.hazardCode
            , data.atmosphere.taint.subtype
            , data.atmosphere.taint.severity
            , data.atmosphere.taint.persistence
            , data.hydrographics.percentage
            , data.hydrographics.surfaceDistribution
            , data.life.biomass
            , data.life.biocomplexity
            , data.life.biodiversity
            , data.life.compatibility
            , data.life.habitability
            , data.life.sophonts
            ]

        counts =
            List.Extra.scanl (\word total -> total + (floor <| sqrt <| toFloat <| String.length word)) 0 strings
                |> Array.fromList
    in
    column []
        [ column []
            [ text <| "Physical"
            , row (Element.spacing 40 :: groupAttrs)
                [ column [ Element.alignTop ]
                    [ textDisplayNarrow "AU" <| showTimeCharsTEMP 0 data.physical.au
                    , textDisplayNarrow "Period (yrs)" <| showTimeCharsTEMP 1 data.physical.period
                    , textDisplayNarrow "Inclination" <| showTimeCharsTEMP 2 data.physical.inclination
                    , textDisplayNarrow "Eccentricity" <| showTimeCharsTEMP 3 data.physical.eccentricity
                    ]
                , column [ Element.alignTop ]
                    [ textDisplayMedium "Mass (earths)" <| showTimeCharsTEMP 4 data.physical.mass
                    , textDisplayMedium "Density (earth)" <| showTimeCharsTEMP 5 data.physical.density
                    , textDisplayMedium "Gravity (G)" <| showTimeCharsTEMP 6 data.physical.gravity
                    , textDisplayMedium "Diameter (km)" <| showTimeCharsTEMP 7 data.physical.diameter
                    ]
                , column [ Element.alignTop ]
                    [ textDisplayNarrow "Temperature" <| showTimeCharsTEMP 8 data.physical.meanTemperature
                    , textDisplayNarrow "Albedo" <| showTimeCharsTEMP 9 data.physical.albedo
                    , textDisplayNarrow "Axial Tilt" <| showTimeCharsTEMP 10 data.physical.axialTilt
                    , textDisplayNarrow "Greenhouse" <| showTimeCharsTEMP 11 data.physical.greenhouse
                    ]
                ]
            ]
        , column [ width fill, Element.paddingXY 0 10 ]
            [ text <| "Atmosphere"
            , column groupAttrs
                [ textDisplay "Type" <| showTimeCharsTEMP 12 data.atmosphere.type_
                , textDisplay "BAR" <| showTimeCharsTEMP 13 data.atmosphere.bar
                , if True then
                    textDisplay "Hazard Code" <| showTimeCharsTEMP 14 data.atmosphere.hazardCode

                  else
                    Element.none
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
                        [ taintTextDisplay "Subtype" <| showTimeCharsTEMP 15 data.atmosphere.taint.subtype
                        , taintTextDisplay "Severity" <| showTimeCharsTEMP 16 data.atmosphere.taint.severity
                        , taintTextDisplay "Persistence" <| showTimeCharsTEMP 17 data.atmosphere.taint.persistence
                        ]
                    ]
                ]
            ]
        , column [ Element.paddingXY 0 10 ]
            [ text <| "Hydrographics"
            , column groupAttrs
                [ textDisplay "Percentage" <| showTimeCharsTEMP 18 data.hydrographics.percentage
                , textDisplay "Surface Distribution" <| showTimeCharsTEMP 19 data.hydrographics.surfaceDistribution
                ]
            ]
        , column [ Element.paddingXY 0 10 ]
            [ text <| "Life"
            , column groupAttrs
                [ textDisplay "Biomass" <| showTimeCharsTEMP 20 data.life.biomass
                , textDisplay "Biocomplexity" <| showTimeCharsTEMP 21 data.life.biocomplexity
                , textDisplay "Biodiversity" <| showTimeCharsTEMP 22 data.life.biodiversity
                , textDisplay "Compatibilty" <| showTimeCharsTEMP 23 data.life.compatibility
                , textDisplay "Habitability" <| showTimeCharsTEMP 24 data.life.habitability
                , textDisplay "Sophonts" <| showTimeCharsTEMP 25 data.life.sophonts
                ]
            ]
        ]


viewGasGiantAnalysisDetail : Int -> AnalyisDetailGasGiantData -> Element.Element msg
viewGasGiantAnalysisDetail timeChars data =
    let
        showTimeCharsTEMP index str =
            let
                offset =
                    timeChars - (Array.get index counts |> Maybe.withDefault 0)
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
    in
    column []
        [ column []
            [ text <| "Physical"
            , row (Element.spacing 40 :: groupAttrs)
                [ column [ Element.alignTop ]
                    [ textDisplayNarrow "AU" <| showTimeCharsTEMP 0 data.physical.au
                    , textDisplayNarrow "Period (yrs)" <| showTimeCharsTEMP 1 data.physical.period
                    , textDisplayNarrow "Inclination" <| showTimeCharsTEMP 2 data.physical.inclination
                    , textDisplayNarrow "Eccentricity" <| showTimeCharsTEMP 3 data.physical.eccentricity
                    ]
                , column [ Element.alignTop ]
                    [ textDisplayMedium "Mass (earths)" <| showTimeCharsTEMP 4 data.physical.mass
                    , textDisplayMedium "Diameter (km)" <| showTimeCharsTEMP 5 data.physical.diameter
                    , textDisplayMedium "Axial Tilt" <| showTimeCharsTEMP 6 data.physical.axialTilt
                    ]
                , column [ Element.alignTop ]
                    [ textDisplayNarrow "Moons" <| showTimeCharsTEMP 7 data.physical.moons
                    , textDisplayNarrow "Rings" <| showTimeCharsTEMP 8 data.physical.hasRing
                    ]
                ]
            ]
        ]


viewPlanetoidBeltAnalysisDetail : Int -> AnalyisDetailPlanetoidBeltData -> Element.Element msg
viewPlanetoidBeltAnalysisDetail timeChars data =
    let
        showTimeCharsTEMP index str =
            let
                offset =
                    timeChars - (Array.get index counts |> Maybe.withDefault 0)
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
            , data.physical.span
            , data.physical.bulk
            , data.physical.cType
            , data.physical.mType
            , data.physical.sType
            , data.physical.oType
            ]

        counts =
            List.Extra.scanl (\word total -> total + (floor <| sqrt <| toFloat <| String.length word)) 0 strings
                |> Array.fromList
    in
    column []
        [ column []
            [ text <| "Physical"
            , row (Element.spacing 40 :: groupAttrs)
                [ column [ Element.alignTop ]
                    [ textDisplayNarrow "AU" <| showTimeCharsTEMP 0 data.physical.au
                    , textDisplayNarrow "Period (yrs)" <| showTimeCharsTEMP 1 data.physical.period
                    , textDisplayNarrow "Inclination" <| showTimeCharsTEMP 2 data.physical.inclination
                    , textDisplayNarrow "Eccentricity" <| showTimeCharsTEMP 3 data.physical.eccentricity
                    ]
                , column [ Element.alignTop ]
                    [ textDisplayNarrow "Span" <| showTimeCharsTEMP 4 data.physical.span
                    , textDisplayNarrow "Bulk" <| showTimeCharsTEMP 5 data.physical.bulk
                    ]
                , column [ Element.alignTop ]
                    [ textDisplayNarrow "c-type" <| showTimeCharsTEMP 6 data.physical.cType
                    , textDisplayNarrow "m-type" <| showTimeCharsTEMP 7 data.physical.mType
                    , textDisplayNarrow "s-type" <| showTimeCharsTEMP 8 data.physical.sType
                    , textDisplayNarrow "o-type" <| showTimeCharsTEMP 9 data.physical.oType
                    ]
                ]
            ]
        ]
