port module Traveller exposing (FacilityIcon, Model, ModelData, Msg(..), ThemeOption, init, subscriptions, update, view)

import Browser.Dom
import Browser.Events
import Browser.Navigation
import Codec
import Color exposing (Color)
import Color.Convert
import Dict
import Element
    exposing
        ( Element
        , centerX
        , centerY
        , column
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
import Element.Input as Input
import Element.Lazy
import FormatNumber exposing (format)
import FormatNumber.Locales exposing (Decimals(..), usLocale)
import HostConfig exposing (HostConfig)
import Html exposing (Html)
import Html.Attributes as HtmlAttrs
import Html.Events
import Html.Events.Extra.Mouse
import Html.Lazy
import Http
import Json.Decode as JsDecode
import Json.Encode as Encode
import List.Extra
import Parser
import RemoteData exposing (RemoteData(..))
import Result.Extra as Result
import Round
import Set
import Svg exposing (Svg)
import Svg.Attributes as SvgAttrs exposing (points, viewBox)
import Svg.Events as SvgEvents
import Svg.Keyed
import Svg.Lazy
import Task
import Time
import Traveller.AnalysisDetail
    exposing
        ( AnalyisDetailGasGiantData
        , AnalyisDetailPlanetoidBeltData
        , AnalyisDetailPlanetoidData
        , AnalyisDetailStarData
        , AnalysisDetail(..)
        , AnalysisDetailHeader
        , viewObjectAnalysisDetail
        )
import Traveller.Atmosphere exposing (atmosphereDescription, atmosphereDescriptionEx, atmosphereHazardDescription)
import Traveller.Government as Government
import Traveller.HexAddress as HexAddress exposing (HexAddress, SectorHexAddress, createFromStarSystem, shiftAddressBy, toSectorAddress, toUniversalAddress)
import Traveller.HexGeometry
    exposing
        ( VisualHexOrigin
        , calcVisualOrigin
        , convertRawHexagonPoints
        , defaultHexSize
        , hexColOffset
        , hexHeight
        , hexSizeFactor
        , hexWidth
        , hexagonPoints
        , hexapointsBuilder
        , iconScale
        , rawHexagonPoint
        , rawHexagonPoints
        , rotatePoint
        , scaleAttr
        )
import Traveller.HighlightRule as HighlightRule
import Traveller.HighlightRuleEditor as HighlightRuleEditor
import Traveller.Hydrographics exposing (hydrographicsPercentageDescription, surfaceDistributionDescription)
import Traveller.JumpRouteLayer as JumpRouteLayer
import Traveller.JumpRouteLayerEditor as JumpRouteLayerEditor
import Traveller.LawLevel as LawLevel
import Traveller.Lifeforms exposing (bioChemistryCompatibilityDescription, biocomplexityDescription, biodiversityDescription, biomassDescription, habitabilityColour, habitabilityDescription)
import Traveller.Parser exposing (UWP, hydrosphereDescription, sizeDescription, uwp)
import Traveller.Population exposing (concentration_rating_description, populationDescription)
import Traveller.Region as Region exposing (Region, RegionDict)
import Traveller.Route as Route exposing (Route, RouteList)
import Traveller.RoutePlan as RoutePlan
import Traveller.RoutePlanForm as RoutePlanForm
import Traveller.Sector exposing (Sector, SectorDict, codec, sectorKey)
import Traveller.Ship exposing (Ship)
import Traveller.ShipTraffic as ShipTraffic
import Traveller.Sidebar
    exposing
        ( SidebarMsgs
        , viewSidebarColumn
        )
import Traveller.SolarSystem as SolarSystem exposing (SolarSystem)
import Traveller.SolarSystemStars exposing (FallibleStarSystem, StarSystem, StarType, StarTypeData, StrategicData, fallibleStarSystemDecoder, getStarTypeData, isBrownDwarfType)
import Traveller.StarColour exposing (starColourRGB)
import Traveller.StarOrbitMap as StarOrbitMap
import Traveller.Starport as Starport
import Traveller.StellarObject exposing (GasGiantData, InnerStarData, PlanetoidBeltData, PlanetoidData, SharedPData, StarData(..), StellarObject(..), getInnerStarData, getProfileString, getStarData, getStellarOrbit, isBrownDwarf)
import Traveller.StellarObjectView
    exposing
        ( JumpShadowChecker
        , JumpShadowCheckers
        , StellarObjectMsgs
        )
import Traveller.StellarTaint exposing (taintPersistenceDescription, taintSeverityDescription, taintSubtypeDescription)
import Traveller.TechLevel as TechLevel
import Traveller.ToggleSwitch as ToggleSwitch
import Traveller.TravelTable as TravelTable
import Traveller.UI
    exposing
        ( accentHeadingColour
        , bgVar
        , borderVar
        , fontVar
        , monospaceText
        , zeroEach
        )
import Url.Builder


type alias JumpRouteLink =
    { id : Int
    , colour : String
    , known : Bool
    , fromSurveyIndex : Int
    , toSurveyIndex : Int
    , fromX : Int
    , fromY : Int
    , toX : Int
    , toY : Int
    , strokeDasharray : String
    , lineWidth : Int
    , routeType : String
    , jumpRouteId : Int
    }


jumpRouteLinkDecoder : JsDecode.Decoder JumpRouteLink
jumpRouteLinkDecoder =
    JsDecode.map8
        (\id colour known fromSI toSI fromX fromY toX -> JumpRouteLink id colour known fromSI toSI fromX fromY toX)
        (JsDecode.field "id" JsDecode.int)
        (JsDecode.field "colour" (JsDecode.oneOf [ JsDecode.string, JsDecode.null "#888888" ])
            |> JsDecode.map
                (\s ->
                    if String.isEmpty s then
                        "#888888"

                    else
                        s
                )
        )
        (JsDecode.field "known" (JsDecode.oneOf [ JsDecode.bool, JsDecode.null False ]))
        (JsDecode.field "from_survey_index" JsDecode.int)
        (JsDecode.field "to_survey_index" JsDecode.int)
        (JsDecode.field "from_x" JsDecode.int)
        (JsDecode.field "from_y" JsDecode.int)
        (JsDecode.field "to_x" JsDecode.int)
        |> JsDecode.andThen
            (\partial ->
                JsDecode.map partial (JsDecode.field "to_y" JsDecode.int)
            )
        |> JsDecode.andThen
            (\partial ->
                JsDecode.map partial (JsDecode.field "stroke_dasharray" JsDecode.string)
            )
        |> JsDecode.andThen
            (\partial ->
                JsDecode.map partial (JsDecode.field "line_width" (JsDecode.oneOf [ JsDecode.int, JsDecode.null 2 ]))
            )
        |> JsDecode.andThen
            (\partial ->
                JsDecode.map partial
                    (JsDecode.field "route_type" (JsDecode.oneOf [ JsDecode.string, JsDecode.null "network" ]))
            )
        |> JsDecode.andThen
            (\partial ->
                JsDecode.map partial (JsDecode.field "jump_route_id" JsDecode.int)
            )


refereeSI =
    99


gasGiantSI =
    5


terrestrialSI =
    6


planetoidSI =
    6


uwpSI =
    10


cometSI =
    12


consoleTitleHeight =
    62


toEHexChar : Int -> String
toEHexChar n =
    if n < 10 then
        String.fromInt n

    else
        String.slice (n - 10) (n - 9) "ABCDEFGHJKLMNPQRSTUVWXYZ"


resourceRatingDescription : Int -> String
resourceRatingDescription rating =
    case rating of
        2 ->
            "No economically extractable resources"

        3 ->
            "Marginal at best"

        4 ->
            "Marginal at best"

        5 ->
            "Marginal at best"

        6 ->
            "Worthwhile with considerable effort"

        7 ->
            "Worthwhile with considerable effort"

        8 ->
            "Worthwhile with considerable effort"

        9 ->
            "Priority target"

        10 ->
            "Priority target"

        11 ->
            "Liable to experience a resource rush"

        12 ->
            "Liable to experience a resource rush"

        _ ->
            ""


fullJourneyImageWidth =
    2176


fullJourneyImageHeight =
    2240



-- Returns ( containerWidth, containerHeight, fittedWidth, fittedHeight ) for the full-journey view.
-- The container fills the available space; the fitted dimensions preserve the image aspect ratio
-- and are used as the zoom-1 base size for the image.


journeyDimensions : { a | width : Float, height : Float } -> { containerW : Float, containerH : Float, fittedW : Float, fittedH : Float }
journeyDimensions viewport =
    let
        containerW =
            viewport.width

        containerH =
            viewport.height - consoleTitleHeight

        aspectRatio =
            fullJourneyImageHeight / fullJourneyImageWidth

        heightFromWidth =
            containerW * aspectRatio
    in
    if heightFromWidth <= containerH then
        { containerW = containerW, containerH = containerH, fittedW = containerW, fittedH = heightFromWidth }

    else
        { containerW = containerW, containerH = containerH, fittedW = containerH / aspectRatio, fittedH = containerH }


type alias HexMapViewport =
    Result Browser.Dom.Error Browser.Dom.Viewport


type alias SearchResult =
    { resultType : String
    , displayType : String
    , name : String
    , meta : String
    , x : Maybe Int
    , y : Maybe Int
    , sectorX : Maybe Int
    , sectorY : Maybe Int
    , subsectorX : Maybe Int
    , subsectorY : Maybe Int
    }


type alias SearchState =
    { query : String
    , results : RemoteData Http.Error (List SearchResult)
    , dropdownOpen : Bool
    }


searchResultDecoder : JsDecode.Decoder SearchResult
searchResultDecoder =
    JsDecode.map8
        (\rt dt name meta x y sx sy ->
            { resultType = rt
            , displayType = dt
            , name = name
            , meta = meta
            , x = x
            , y = y
            , sectorX = sx
            , sectorY = sy
            , subsectorX = Nothing
            , subsectorY = Nothing
            }
        )
        (JsDecode.field "type" JsDecode.string)
        (JsDecode.field "display_type" JsDecode.string)
        (JsDecode.field "name" JsDecode.string)
        (JsDecode.field "meta" JsDecode.string)
        (JsDecode.field "x" (JsDecode.nullable JsDecode.int))
        (JsDecode.field "y" (JsDecode.nullable JsDecode.int))
        (JsDecode.field "sector_x" (JsDecode.nullable JsDecode.int))
        (JsDecode.field "sector_y" (JsDecode.nullable JsDecode.int))
        |> JsDecode.andThen
            (\partial ->
                JsDecode.map2
                    (\subX subY -> { partial | subsectorX = subX, subsectorY = subY })
                    (JsDecode.field "subsector_x" (JsDecode.nullable JsDecode.int))
                    (JsDecode.field "subsector_y" (JsDecode.nullable JsDecode.int))
            )


type DragMode
    = IsDragging { start : ( Float, Float ), last : ( Float, Float ) }
    | NoDragging


starMapMinWidth : Float
starMapMinWidth =
    480


starMapMaxWidth : Float
starMapMaxWidth =
    3000


starMapMinHeight : Float
starMapMinHeight =
    360


starMapMaxHeight : Float
starMapMaxHeight =
    2000


{-| RequestNum is a unique identifier for a request.

'Mk' is a prefix meaning 'make', to distinguishg it from the RequestNum parent,
even though they could be the same name.

-}
type RequestNum
    = MkRequestNum Int


{-| RequestEntry is a record of a request made to the server.

Each time we call sendSolarSystemRequest we prep a RequestEntry and store it in
the ModelData.

Then when we get a response back, we mark the request as complete and update
our model, using `markRequestComplete`.

-}
type alias RequestEntry =
    { requestNum : RequestNum
    , upperLeftHex : HexAddress
    , lowerRightHex : HexAddress
    , status :
        RemoteData
            Http.Error
            -- no data is kept beyond pass/fail. '()' means 'unit' or 'void' in other languages
            ()
    }


type alias RequestHistory =
    List RequestEntry


type alias HexKey =
    String


type alias HexColorDict =
    Dict.Dict HexKey Color


type alias RegionLabelDict =
    Dict.Dict HexKey String


nextRequestNum : RequestHistory -> RequestNum
nextRequestNum requestHistory =
    let
        lastRequestNum : Int
        lastRequestNum =
            case requestHistory of
                [] ->
                    0

                requests ->
                    requests
                        |> List.map (.requestNum >> (\(MkRequestNum x) -> x))
                        |> List.maximum
                        |> Maybe.withDefault 0
    in
    MkRequestNum (lastRequestNum + 1)


horizontalHexes : Maybe HexMapViewport -> Float -> Int
horizontalHexes hexmapViewport hexScale =
    case hexmapViewport of
        Just vp ->
            case vp of
                Ok viewport ->
                    (viewport.viewport.width / hexWidth hexScale) |> floor

                Err _ ->
                    defaultHorizontalHexes

        Nothing ->
            defaultHorizontalHexes


verticalHexes : Maybe HexMapViewport -> Float -> Int
verticalHexes hexmapViewport hexScale =
    case hexmapViewport of
        Just (Ok viewport) ->
            (viewport.viewport.height / hexHeight hexScale) |> floor

        Just (Err _) ->
            defaultVerticalHexes

        Nothing ->
            defaultVerticalHexes


{-| True if the point lies inside the polygon, using a standard ray-casting
even-odd test.
-}
pointInPolygon : ( Float, Float ) -> List ( Float, Float ) -> Bool
pointInPolygon ( px, py ) points =
    let
        edges =
            List.map2 Tuple.pair points (List.drop 1 points ++ List.take 1 points)

        crossesRay ( ( x1, y1 ), ( x2, y2 ) ) =
            ((y1 > py) /= (y2 > py))
                && (px < (x2 - x1) * (py - y1) / (y2 - y1) + x1)
    in
    edges |> List.filter crossesRay |> List.length |> (\n -> modBy 2 n == 1)


{-| Inverse of `calcVisualOrigin`: given a pixel coordinate in the same space
as the SVG viewBox, returns the hex address whose rendered polygon contains
that pixel. Flat-top hexes overlap their neighbouring column by half a hex,
so a simple floor/round of the column-spacing formula picks the wrong hex
near those overlaps; this checks actual polygon containment (the same
vertices used to draw the hex) against a small neighbourhood of candidates
instead, so it is correct regardless of the current pan offset.
-}
pixelToHexAddress : Float -> Float -> Float -> HexAddress
pixelToHexAddress hexScale vbx vby =
    let
        sin60 =
            sin hexSizeFactor

        roughCol =
            round ((vbx - hexScale) / hexWidth hexScale)

        roughRowFor col =
            round ((-vby / hexScale - 1 - hexColOffset col * sin60) / (2 * sin60))

        containsPoint hex =
            let
                ( originX, originY ) =
                    calcVisualOrigin hexScale { col = hex.x, row = hex.y }

                polygon =
                    rawHexagonPoints hexScale
                        |> List.map (\( dx, dy ) -> ( toFloat originX + dx, toFloat originY + dy ))
            in
            pointInPolygon ( vbx, vby ) polygon
    in
    List.range (roughCol - 1) (roughCol + 1)
        |> List.concatMap
            (\col ->
                let
                    row =
                        roughRowFor col
                in
                List.range (row - 1) (row + 1)
                    |> List.map (\r -> { x = col, y = r })
            )
        |> List.filter containsPoint
        |> List.head
        |> Maybe.withDefault { x = roughCol, y = roughRowFor roughCol }


{-| Builds a RequestEntry and updates the existing History with it.

This is so we have less chance of getting the history out of sync with the
entries, because this is the only way to construct a RequestEntry.

-}
prepNextRequest : ( SolarSystemDict, RequestHistory ) -> HexRect -> ( RequestEntry, ( SolarSystemDict, RequestHistory ) )
prepNextRequest ( oldSolarSystemDict, requestHistory ) { upperLeftHex, lowerRightHex } =
    let
        requestNum =
            nextRequestNum requestHistory

        requestEntry =
            { requestNum = requestNum
            , upperLeftHex = upperLeftHex
            , lowerRightHex = lowerRightHex
            , status = RemoteData.Loading
            }

        newSolarSystemDict =
            HexAddress.between upperLeftHex lowerRightHex
                |> List.foldl
                    (\hexAddr dict ->
                        let
                            key =
                                HexAddress.toKey hexAddr
                        in
                        case Dict.get key dict of
                            Nothing ->
                                Dict.insert key LoadingSolarSystem dict

                            Just _ ->
                                dict
                    )
                    oldSolarSystemDict
    in
    ( requestEntry, ( newSolarSystemDict, requestEntry :: requestHistory ) )


{-| Returns up to 2 tight bounding boxes covering only the hexes within hexRect
that are not yet present in the dict.

A straight pan reveals a single rectangular strip (1 rect). A diagonal drag
reveals an L-shape, which splits into 2 non-overlapping rectangles: the new
columns at full height and the new rows on the existing columns.

-}
missingHexRects : SolarSystemDict -> HexRect -> List HexRect
missingHexRects dict { upperLeftHex, lowerRightHex } =
    let
        missingHexes =
            HexAddress.between upperLeftHex lowerRightHex
                |> List.filter (\h -> Dict.get (HexAddress.toKey h) dict == Nothing)
    in
    case missingHexes of
        [] ->
            []

        _ ->
            let
                columnRanges : Dict.Dict Int { minY : Int, maxY : Int }
                columnRanges =
                    List.foldl
                        (\h acc ->
                            Dict.update h.x
                                (\mv ->
                                    case mv of
                                        Nothing ->
                                            Just { minY = h.y, maxY = h.y }

                                        Just r ->
                                            Just { minY = min r.minY h.y, maxY = max r.maxY h.y }
                                )
                                acc
                        )
                        Dict.empty
                        missingHexes

                globalMinX =
                    Dict.keys columnRanges |> List.minimum |> Maybe.withDefault 0

                globalMaxX =
                    Dict.keys columnRanges |> List.maximum |> Maybe.withDefault 0

                globalMinY =
                    Dict.values columnRanges |> List.map .minY |> List.minimum |> Maybe.withDefault 0

                globalMaxY =
                    Dict.values columnRanges |> List.map .maxY |> List.maximum |> Maybe.withDefault 0

                -- Columns spanning the full y range vs. those with a narrower band
                fullCols =
                    Dict.filter (\_ r -> r.minY == globalMinY && r.maxY == globalMaxY) columnRanges

                partialCols =
                    Dict.filter (\_ r -> r.minY /= globalMinY || r.maxY /= globalMaxY) columnRanges

                toRect minX maxX minY maxY =
                    { upperLeftHex = { x = minX, y = maxY }
                    , lowerRightHex = { x = maxX, y = minY }
                    }
            in
            if Dict.isEmpty partialCols || Dict.isEmpty fullCols then
                -- All columns have the same y range → single rectangle
                [ toRect globalMinX globalMaxX globalMinY globalMaxY ]

            else
                let
                    fullMinX =
                        Dict.keys fullCols |> List.minimum |> Maybe.withDefault globalMinX

                    fullMaxX =
                        Dict.keys fullCols |> List.maximum |> Maybe.withDefault globalMaxX

                    partialMinX =
                        Dict.keys partialCols |> List.minimum |> Maybe.withDefault globalMinX

                    partialMaxX =
                        Dict.keys partialCols |> List.maximum |> Maybe.withDefault globalMaxX

                    partialMinY =
                        Dict.values partialCols |> List.map .minY |> List.minimum |> Maybe.withDefault globalMinY

                    partialMaxY =
                        Dict.values partialCols |> List.map .maxY |> List.maximum |> Maybe.withDefault globalMaxY
                in
                [ toRect fullMinX fullMaxX globalMinY globalMaxY
                , toRect partialMinX partialMaxX partialMinY partialMaxY
                ]


{-| Computes tight sub-rects for missing hexes, fires one request per rect, and
returns the updated dict/history alongside a batched Cmd.
-}
prepAndSendRequests : ( SolarSystemDict, RequestHistory ) -> HexRect -> HostConfig.HostConfig -> ( ( SolarSystemDict, RequestHistory ), Cmd Msg )
prepAndSendRequests ( dict, history ) hexRect hostConfig =
    missingHexRects dict hexRect
        |> List.foldl
            (\rect ( ( d, h ), cmds ) ->
                let
                    ( entry, ( d2, h2 ) ) =
                        prepNextRequest ( d, h ) rect
                in
                ( ( d2, h2 ), sendSolarSystemRequest entry hostConfig :: sendRoguesRequest entry hostConfig :: cmds )
            )
            ( ( dict, history ), [] )
        |> Tuple.mapSecond Cmd.batch


type ViewMode
    = HexMap
    | FullJourney


type DisplayMode
    = ShowStars
    | ShowMainWorld
    | ShowWTN
    | ShowGWP
    | ShowTradeCodes
    | ShowImportance
    | ShowStrategic
    | ShowResource
    | ShowTechLevel
    | ShowHabitability
    | ShowGovernment


type RegionDisplay
    = HideRegions
    | ShowRegionsFill
    | ShowRegionsBorder
    | ShowRegionsBoth


type alias JourneyModel =
    { zoomScale : Float
    , zoomOffset : ( Float, Float )
    , hoverPoint : Maybe ( Float, Float )
    , dragMode : DragMode
    }


type alias Model =
    ( Time.Posix
    , ModelData
    )


type alias ModelData =
    { key : Browser.Navigation.Key
    , hexScale : Float
    , viewMode : ViewMode
    , journeyModel : JourneyModel
    , rawHexaPoints : List ( Float, Float )
    , solarSystems : SolarSystemDict
    , newSolarSystemErrors : List ( Http.Error, String )
    , oldSolarSystemErrors : List ( Http.Error, String )
    , lastSolarSystemError : Maybe Http.Error
    , requestHistory : RequestHistory
    , dragMode : DragMode
    , sectors : SectorDict
    , hoveringHex : Maybe HexAddress
    , selectedHex : Maybe HexAddress
    , selectedSystem : Maybe SolarSystem
    , sidebarHoverText : Maybe String
    , viewport :
        { viewport : Browser.Dom.Viewport
        , hexmapViewport : Maybe HexMapViewport
        }
    , showTravelTable : Bool
    , travelTableMDrive : Int
    , showShipTraffic : Bool
    , shipTraffic : RemoteData Http.Error ShipTraffic.ShipTraffic
    , shipTrafficFrontier : Bool
    , hexRect : HexRect
    , panOffset : { x : Float, y : Float }
    , currentAddress : HexAddress
    , hostConfig : HostConfig.HostConfig
    , route : RouteList
    , regions : RegionDict
    , regionLabels : Dict.Dict String String
    , hexColours : Dict.Dict String Color
    , ship : Maybe Ship
    , isReferee : Bool
    , pendingCtrlNavigation : Bool
    , objectToBeAnalyzed : List { stellarObject : StellarObject, data : AnalysisDetail } -- navigation stack; head is the currently shown modal
    , analysisTab : String
    , starMapModalSize : { width : Float, height : Float }
    , starMapResizeDrag : Maybe { startX : Float, startY : Float, startWidth : Float, startHeight : Float }
    , selectedRogueObjects : Maybe (List RogueObjectDetail)
    , timeOpened : Time.Posix
    , campaignName : String
    , allSectorsMapUrl : Maybe String
    , sidebarOpen : Bool
    , jumpRouteLinks : List JumpRouteLink
    , rogueObjectPathData : Maybe String
    , facilityIcons : Dict.Dict String FacilityIcon
    , facilities : List HighlightRule.Option
    , allegianceOptions : List HighlightRule.Option
    , sectorOptions : List HighlightRule.Option
    , subsectorOptions : List HighlightRule.Option
    , displayMode : DisplayMode
    , regionDisplay : RegionDisplay
    , showDisplaySettings : Bool
    , showMapDisplayDropdown : Bool
    , showRegionDropdown : Bool
    , showSectorLines : Bool
    , showSubsectorLines : Bool
    , showBackgroundNames : Bool
    , showJumpLogFill : Bool
    , searchState : SearchState
    , theme : String
    , themeIsLight : Bool
    , themeOptions : List ThemeOption
    , showThemeMenu : Bool
    , highlightRules : List HighlightRule.Rule
    , showHighlightRulesMenu : Bool
    , ruleEditor : Maybe HighlightRuleEditor.Model
    , nextRuleId : Int
    , pendingDeleteRuleId : Maybe String
    , routePlanForm : Maybe RoutePlanForm.Model
    , activeRoutePlan : Maybe RoutePlan.StoredRoutePlan
    , travelZoneOptions : List RoutePlan.TravelZoneOption
    , jumpRouteLayers : List JumpRouteLayer.Route
    , showJumpRouteLayersMenu : Bool
    , jumpRouteLayerEditor : Maybe JumpRouteLayerEditor.Model
    , pendingDeleteJumpRouteId : Maybe Int
    , hiddenJumpRouteIds : Set.Set Int
    }


type alias ThemeOption =
    { key : String
    , label : String
    , light : Bool
    }


type ZoomType
    = ZoomIn
    | ZoomOut
    | ZoomSet Float


type Msg
    = NoOpMsg
    | Tick Time.Posix
    | DownloadSolarSystems
    | RefreshMap
    | DownloadedSolarSystems ( RequestEntry, String ) (Result Http.Error (List FallibleStarSystem))
    | ClearAllErrors
    | FetchedSolarSystem (Result Http.Error SolarSystem)
    | DownloadedSectors ( RequestEntry, String ) (Result Http.Error (List Sector))
    | DownloadedRegions ( RequestEntry, String ) (Result Http.Error (List Region))
    | HoveringHex HexAddress
    | ViewingHex HexAddress
    | GotViewport Browser.Dom.Viewport
    | GotHexMapViewport (Result Browser.Dom.Error Browser.Dom.Viewport)
    | GotResize Int Int
    | ToggleTravelTable
    | SetTravelTableMDrive Int
    | OpenShipTraffic
    | CloseShipTraffic
    | RerollShipTraffic
    | ToggleShipTrafficFrontier
    | FetchedShipTraffic (Result Http.Error ShipTraffic.ShipTraffic)
    | SetKnown Bool
    | SetSurveyIndex Int
    | KnownSaved (Result Http.Error ())
    | SurveyIndexSaved (Result Http.Error ())
    | MapMouseDown ( Float, Float )
    | MapMouseUp (Maybe HexAddress) ( Float, Float ) Bool
    | MapMouseMove ( Float, Float )
    | MapMouseLeave
    | DownloadedRoute ( RequestEntry, String ) (Result Http.Error (List Route))
    | DownloadedJumpRouteLinks (Result Http.Error (List JumpRouteLink))
    | SetHexSize Float
    | ToggleHexmap
    | SetViewMode ViewMode
    | JumpToShip
    | ZoomToHex HexAddress Bool
    | JourneyMsg JourneyMsg
    | ViewObjectAnalysisDetail StellarObject
    | CloseObjectAnalysis
    | SetAnalysisTab String
    | StarMapResizeStart { startX : Float, startY : Float }
    | StarMapResizeMove ( Float, Float )
    | StarMapResizeEnd
    | PanMap { deltaX : Int, deltaY : Int }
    | PanPixels { dx : Float, dy : Float }
    | HexMapWheelZoom Float
    | CloseSidebar
    | DownloadedRogues String (Result Http.Error (List RogueResponseItem))
    | ClearSelectedRogueObjects
    | SetDisplayMode DisplayMode
    | SetRegionDisplay RegionDisplay
    | ToggleDisplaySettings
    | ToggleMapDisplayDropdown
    | ToggleRegionDropdown
    | ToggleSectorLines
    | ToggleSubsectorLines
    | ToggleBackgroundNames
    | ToggleJumpLogFill
    | SearchInput String
    | GotSearchResults (Result Http.Error (List SearchResult))
    | SelectSearchResult SearchResult
    | FocusSearch
    | CloseSearchDropdown
    | SelectTheme String
    | ToggleThemeMenu
    | ToggleHighlightRulesMenu
    | ToggleRuleEnabled String
    | StartNewRule
    | StartEditRule String
    | RequestDeleteRule String
    | CancelDeleteRule
    | DeleteRule String
    | MoveRuleUp String
    | MoveRuleDown String
    | HighlightRuleEditorMsg HighlightRuleEditor.Msg
    | GoToRailsApp
    | GotSubsectorLookupUrl (Result Http.Error String)
    | GotSurveyOverlays (Result Http.Error (List HighlightRule.Rule))
    | SurveyOverlayMutated (Result Http.Error ())
    | OpenRoutePlanner
    | RoutePlanFormMsg RoutePlanForm.Msg
    | DownloadedTravelZones (Result Http.Error (List RoutePlan.TravelZoneOption))
    | ToggleJumpRouteLayersMenu
    | ToggleJumpRouteLayerHidden Int
    | StartEditJumpRouteLayer Int
    | RequestDeleteJumpRouteLayer Int
    | CancelDeleteJumpRouteLayer
    | DeleteJumpRouteLayer Int
    | DeletedJumpRouteLayer Int (Result Http.Error ())
    | JumpRouteLayerEditorMsg JumpRouteLayerEditor.Msg
    | DownloadedJumpRouteLayers (Result Http.Error (List JumpRouteLayer.Route))


type JourneyMsg
    = Zoom ZoomType
    | MouseDown ( Float, Float )
    | MouseMove ( Float, Float )
    | MouseUp ( Float, Float )
    | MouseLeave
    | Pan ( Float, Float )
    | WheelZoom Float


keyDecoder : ModelData -> JsDecode.Decoder Msg
keyDecoder model =
    JsDecode.map2
        (toKey model)
        (JsDecode.field "key" JsDecode.string)
        (JsDecode.field "ctrlKey" JsDecode.bool)


toKey : ModelData -> String -> Bool -> Msg
toKey model key ctrl =
    let
        halfH =
            max 1 (horizontalHexes model.viewport.hexmapViewport model.hexScale // 2)

        halfV =
            max 1 (verticalHexes model.viewport.hexmapViewport model.hexScale // 2)

        panStep =
            model.hexScale * 0.5
    in
    case ( model.objectToBeAnalyzed, model.viewMode, key ) of
        ( _ :: _, _, "Escape" ) ->
            CloseObjectAnalysis

        ( [], _, "Escape" ) ->
            if model.searchState.dropdownOpen then
                CloseSearchDropdown

            else if model.sidebarOpen then
                CloseSidebar

            else
                NoOpMsg

        ( [], _, "/" ) ->
            FocusSearch

        ( [], HexMap, "ArrowRight" ) ->
            if ctrl then
                PanMap { deltaX = halfH, deltaY = 0 }

            else
                PanPixels { dx = panStep, dy = 0 }

        ( [], HexMap, "ArrowLeft" ) ->
            if ctrl then
                PanMap { deltaX = -halfH, deltaY = 0 }

            else
                PanPixels { dx = -panStep, dy = 0 }

        ( [], HexMap, "ArrowUp" ) ->
            if ctrl then
                PanMap { deltaX = 0, deltaY = -halfV }

            else
                PanPixels { dx = 0, dy = -panStep }

        ( [], HexMap, "ArrowDown" ) ->
            if ctrl then
                PanMap { deltaX = 0, deltaY = halfV }

            else
                PanPixels { dx = 0, dy = panStep }

        ( [], FullJourney, "ArrowRight" ) ->
            JourneyMsg (Pan ( -50, 0 ))

        ( [], FullJourney, "ArrowLeft" ) ->
            JourneyMsg (Pan ( 50, 0 ))

        ( [], FullJourney, "ArrowUp" ) ->
            JourneyMsg (Pan ( 0, 50 ))

        ( [], FullJourney, "ArrowDown" ) ->
            JourneyMsg (Pan ( 0, -50 ))

        _ ->
            NoOpMsg


subscriptions : Time.Posix -> ModelData -> Sub Msg
subscriptions time model =
    Sub.batch
        [ Browser.Events.onResize GotResize
        , Browser.Events.onKeyDown (keyDecoder model)
        , Time.every ((1 / 30) * 1000) Tick
        , if model.showThemeMenu then
            Browser.Events.onClick themeMenuOutsideClickDecoder

          else
            Sub.none
        , if model.showHighlightRulesMenu then
            Browser.Events.onClick highlightRulesMenuOutsideClickDecoder

          else
            Sub.none
        , if model.showJumpRouteLayersMenu then
            Browser.Events.onClick jumpRouteLayersMenuOutsideClickDecoder

          else
            Sub.none
        , if model.showMapDisplayDropdown then
            Browser.Events.onClick mapDisplayDropdownOutsideClickDecoder

          else
            Sub.none
        , if model.showRegionDropdown then
            Browser.Events.onClick regionDropdownOutsideClickDecoder

          else
            Sub.none
        , if model.starMapResizeDrag /= Nothing then
            Sub.batch
                [ Browser.Events.onMouseMove (mouseMoveDecoder StarMapResizeMove)
                , Browser.Events.onMouseUp (JsDecode.succeed StarMapResizeEnd)
                ]

          else
            Sub.none
        ]


{-| Fires `ToggleThemeMenu` when a click lands outside the theme swatch
button or its dropdown, by walking up the clicked element's `parentNode`
chain looking for either id.
-}
themeMenuOutsideClickDecoder : JsDecode.Decoder Msg
themeMenuOutsideClickDecoder =
    JsDecode.field "target" (isOutsideIds [ "starmap-theme-toggle", "starmap-theme-menu" ])
        |> JsDecode.andThen
            (\isOutside ->
                if isOutside then
                    JsDecode.succeed ToggleThemeMenu

                else
                    JsDecode.fail "click was inside the theme menu"
            )


{-| Fires `ToggleHighlightRulesMenu` when a click lands outside the highlight
rules toggle button or its dropdown.
-}
highlightRulesMenuOutsideClickDecoder : JsDecode.Decoder Msg
highlightRulesMenuOutsideClickDecoder =
    JsDecode.field "target" (isOutsideIds [ "starmap-highlight-toggle", "starmap-highlight-menu" ])
        |> JsDecode.andThen
            (\isOutside ->
                if isOutside then
                    JsDecode.succeed ToggleHighlightRulesMenu

                else
                    JsDecode.fail "click was inside the highlight rules menu"
            )


{-| Fires `ToggleJumpRouteLayersMenu` when a click lands outside the jump
route layers toggle button or its dropdown.
-}
jumpRouteLayersMenuOutsideClickDecoder : JsDecode.Decoder Msg
jumpRouteLayersMenuOutsideClickDecoder =
    JsDecode.field "target" (isOutsideIds [ "starmap-jump-route-layers-toggle", "starmap-jump-route-layers-menu" ])
        |> JsDecode.andThen
            (\isOutside ->
                if isOutside then
                    JsDecode.succeed ToggleJumpRouteLayersMenu

                else
                    JsDecode.fail "click was inside the jump route layers menu"
            )


{-| Fires `ToggleMapDisplayDropdown` when a click lands outside the map
display toggle button or its dropdown.
-}
mapDisplayDropdownOutsideClickDecoder : JsDecode.Decoder Msg
mapDisplayDropdownOutsideClickDecoder =
    JsDecode.field "target" (isOutsideIds [ "starmap-map-display-toggle", "starmap-map-display-menu" ])
        |> JsDecode.andThen
            (\isOutside ->
                if isOutside then
                    JsDecode.succeed ToggleMapDisplayDropdown

                else
                    JsDecode.fail "click was inside the map display dropdown"
            )


{-| Fires `ToggleRegionDropdown` when a click lands outside the region
toggle button or its dropdown.
-}
regionDropdownOutsideClickDecoder : JsDecode.Decoder Msg
regionDropdownOutsideClickDecoder =
    JsDecode.field "target" (isOutsideIds [ "starmap-region-toggle", "starmap-region-menu" ])
        |> JsDecode.andThen
            (\isOutside ->
                if isOutside then
                    JsDecode.succeed ToggleRegionDropdown

                else
                    JsDecode.fail "click was inside the region dropdown"
            )


isOutsideIds : List String -> JsDecode.Decoder Bool
isOutsideIds insideIds =
    JsDecode.oneOf
        [ JsDecode.field "id" JsDecode.string
            |> JsDecode.andThen
                (\id ->
                    if List.member id insideIds then
                        JsDecode.succeed False

                    else
                        JsDecode.fail "check parent"
                )
        , JsDecode.lazy (\_ -> JsDecode.field "parentNode" (isOutsideIds insideIds))
        , JsDecode.succeed True
        ]


type alias FacilityIcon =
    { code : String
    , name : String
    , viewBox : String
    , pathData : String
    }


type alias Flags =
    { upperLeft : Maybe ( Int, Int )
    , panOffset : Maybe ( Float, Float )
    , hexSize : Float
    , campaignName : Maybe String
    , ship : Maybe Ship
    , allSectorsMapUrl : Maybe String
    , viewMode : Maybe String
    , journeyState : Maybe String
    , centerOn : Maybe ( Int, Int )
    , rogueObjectPathData : Maybe String
    , facilityIcons : List FacilityIcon
    , facilities : List HighlightRule.Option
    , allegianceOptions : List HighlightRule.Option
    , sectorOptions : List HighlightRule.Option
    , subsectorOptions : List HighlightRule.Option
    , shipLocation : Maybe ( Int, Int )
    , displayMode : Maybe String
    , regionDisplay : Maybe String
    , showSectorLines : Maybe Bool
    , showSubsectorLines : Maybe Bool
    , showBackgroundNames : Maybe Bool
    , showJumpLogFill : Maybe Bool
    , theme : String
    , themeIsLight : Bool
    , themeOptions : List ThemeOption
    , highlightRules : JsDecode.Value
    , routePlan : JsDecode.Value
    , hiddenJumpRouteIds : JsDecode.Value
    }


defaultHexRectSize : Int
defaultHexRectSize =
    30


minHexSize : Float
minHexSize =
    20


maxHexSize : Float
maxHexSize =
    120


{-| Hex size above which the background name watermark is hidden entirely.
Past this zoom level the view is focused on individual system detail, so the
sector/subsector watermark would just be clutter.
-}
maxHexSizeForBackgroundNames : Float
maxHexSizeForBackgroundNames =
    70


defaultHorizontalHexes : Int
defaultHorizontalHexes =
    30


defaultVerticalHexes : Int
defaultVerticalHexes =
    25


init : Browser.Dom.Viewport -> Flags -> Browser.Navigation.Key -> HostConfig.HostConfig -> Bool -> ( Model, Cmd Msg )
init viewport settings key hostConfig referee =
    let
        -- requestHistory : RequestHistory
        ( initSystemDict, initRequestHistory ) =
            ( Dict.empty, [] )

        ( ( ssReqEntry, secReqEntry, routeReqEntry ), ( solarSystemDict, requestHistory ) ) =
            prepNextRequest ( initSystemDict, initRequestHistory ) hexRect
                |> -- build a new request entry for sector request
                   (\( ssReqEntry_, oldSsDictAndReqHistory ) ->
                        let
                            ( newReqEntry, ssDictAndReqHistory ) =
                                prepNextRequest oldSsDictAndReqHistory hexRect
                        in
                        ( ( ssReqEntry_, newReqEntry ), ssDictAndReqHistory )
                   )
                |> -- take the old ones and build a new one for route request
                   (\( ( ssReqEntry_, secReqEntry_ ), oldSsDictAndReqHistory ) ->
                        let
                            ( routeReqEntry_, ssDictAndReqHistory ) =
                                prepNextRequest oldSsDictAndReqHistory hexRect
                        in
                        ( ( ssReqEntry_, secReqEntry_, routeReqEntry_ ), ssDictAndReqHistory )
                   )

        hexRect =
            let
                hexmapWidth =
                    viewport.viewport.width

                hexmapHeight =
                    viewport.viewport.height - consoleTitleHeight

                deltaX =
                    (hexmapWidth / hexWidth settings.hexSize |> ceiling) + 2

                deltaY =
                    (hexmapHeight / hexHeight settings.hexSize |> ceiling) + 2

                upperLeftHex =
                    case settings.centerOn of
                        Just ( cx, cy ) ->
                            HexAddress (cx - deltaX // 2) (cy + deltaY // 2)

                        Nothing ->
                            case settings.upperLeft of
                                Just ( x, y ) ->
                                    HexAddress x y

                                Nothing ->
                                    case settings.shipLocation of
                                        Just ( sx, sy ) ->
                                            HexAddress (sx - deltaX // 2) (sy + deltaY // 2)

                                        Nothing ->
                                            toUniversalAddress
                                                { sectorX = -10
                                                , sectorY = -2
                                                , x = 21
                                                , y = 12
                                                }

                lowerRightHex =
                    upperLeftHex
                        |> HexAddress.shiftAddressBy
                            { deltaX = deltaX
                            , deltaY = deltaY
                            }
            in
            { upperLeftHex = upperLeftHex, lowerRightHex = lowerRightHex }

        initialPanOffset =
            case settings.centerOn of
                Just _ ->
                    { x = 0, y = 0 }

                Nothing ->
                    case settings.upperLeft of
                        Just _ ->
                            settings.panOffset
                                |> Maybe.map (\( px, py ) -> { x = px, y = py })
                                |> Maybe.withDefault { x = 0, y = 0 }

                        Nothing ->
                            { x = 0, y = 0 }

        journeyModel : JourneyModel
        journeyModel =
            let
                ( restoredScale, restoredOffset ) =
                    case settings.journeyState of
                        Just s ->
                            case String.split "," s of
                                [ scaleStr, oxStr, oyStr ] ->
                                    case ( String.toFloat scaleStr, String.toFloat oxStr, String.toFloat oyStr ) of
                                        ( Just scale, Just ox, Just oy ) ->
                                            ( scale, ( ox, oy ) )

                                        _ ->
                                            ( 1.0, ( 0, 0 ) )

                                _ ->
                                    ( 1.0, ( 0, 0 ) )

                        Nothing ->
                            ( 1.0, ( 0, 0 ) )
            in
            { zoomScale = restoredScale
            , zoomOffset = restoredOffset
            , hoverPoint = Nothing
            , dragMode = NoDragging
            }

        initialViewMode =
            case settings.viewMode of
                Just "FullJourney" ->
                    FullJourney

                _ ->
                    HexMap

        initialDisplayMode =
            case settings.displayMode of
                Just "MainWorld" ->
                    ShowMainWorld

                Just "WTN" ->
                    ShowWTN

                Just "GWP" ->
                    ShowGWP

                Just "TradeCodes" ->
                    ShowTradeCodes

                Just "Importance" ->
                    ShowImportance

                Just "Strategic" ->
                    ShowStrategic

                Just "Resource" ->
                    ShowResource

                Just "TechLevel" ->
                    ShowTechLevel

                Just "Habitability" ->
                    ShowHabitability

                Just "Government" ->
                    ShowGovernment

                _ ->
                    ShowStars

        initialRegionDisplay =
            case settings.regionDisplay of
                Just "Fill" ->
                    ShowRegionsFill

                Just "Border" ->
                    ShowRegionsBorder

                Just "Both" ->
                    ShowRegionsBoth

                Just "Hide" ->
                    HideRegions

                _ ->
                    ShowRegionsBoth

        initialShowSectorLines =
            settings.showSectorLines |> Maybe.withDefault True

        initialShowSubsectorLines =
            settings.showSubsectorLines |> Maybe.withDefault True

        initialShowBackgroundNames =
            settings.showBackgroundNames |> Maybe.withDefault False

        initialShowJumpLogFill =
            settings.showJumpLogFill |> Maybe.withDefault True

        -- Referee overlays are DB-backed (fetched via `sendSurveyOverlaysRequest`
        -- once init completes) and never available to non-referees; players keep
        -- their own private, browser-local rule set decoded from `localStorage`.
        initialHighlightRules =
            if referee then
                []

            else
                Codec.decodeValue HighlightRule.rulesCodec settings.highlightRules
                    |> Result.withDefault []

        initialActiveRoutePlan =
            Codec.decodeValue RoutePlan.storedRoutePlanCodec settings.routePlan
                |> Result.toMaybe

        initialHiddenJumpRouteIds =
            Codec.decodeValue JumpRouteLayer.hiddenIdsCodec settings.hiddenJumpRouteIds
                |> Result.withDefault Set.empty

        model : ModelData
        model =
            { hexScale = settings.hexSize
            , viewMode = initialViewMode
            , journeyModel = journeyModel
            , rawHexaPoints = rawHexagonPoints <| settings.hexSize
            , solarSystems = solarSystemDict
            , newSolarSystemErrors = []
            , oldSolarSystemErrors = []
            , lastSolarSystemError = Nothing
            , requestHistory = requestHistory
            , dragMode = NoDragging
            , hoveringHex = Nothing
            , selectedHex = Nothing
            , selectedSystem = Nothing
            , sidebarHoverText = Nothing
            , viewport =
                { viewport = viewport
                , hexmapViewport = Nothing
                }
            , key = key
            , showTravelTable = False
            , travelTableMDrive = settings.ship |> Maybe.andThen .mDrive |> Maybe.withDefault 2
            , showShipTraffic = False
            , shipTraffic = RemoteData.NotAsked
            , shipTrafficFrontier = False
            , hexRect = hexRect
            , panOffset = initialPanOffset
            , hostConfig = hostConfig
            , sectors = Dict.empty
            , route = []
            , currentAddress = toUniversalAddress { sectorX = -10, sectorY = -2, x = 31, y = 24 }
            , regions = Dict.empty
            , regionLabels = Dict.empty
            , hexColours = Dict.empty
            , isReferee = referee
            , pendingCtrlNavigation = False
            , objectToBeAnalyzed = []
            , analysisTab = "orbital"
            , starMapModalSize = { width = 760, height = 560 }
            , starMapResizeDrag = Nothing
            , selectedRogueObjects = Nothing
            , timeOpened = Time.millisToPosix 0
            , campaignName = settings.campaignName |> Maybe.withDefault "Navigation"
            , ship = settings.ship
            , allSectorsMapUrl = settings.allSectorsMapUrl
            , displayMode = initialDisplayMode
            , regionDisplay = initialRegionDisplay
            , showDisplaySettings = False
            , showMapDisplayDropdown = False
            , showRegionDropdown = False
            , showSectorLines = initialShowSectorLines
            , showSubsectorLines = initialShowSubsectorLines
            , showBackgroundNames = initialShowBackgroundNames
            , showJumpLogFill = initialShowJumpLogFill
            , sidebarOpen = False
            , jumpRouteLinks = []
            , rogueObjectPathData = settings.rogueObjectPathData
            , facilityIcons = settings.facilityIcons |> List.map (\icon -> ( icon.code, icon )) |> Dict.fromList
            , facilities = settings.facilities |> List.sortBy .name
            , allegianceOptions = settings.allegianceOptions |> List.sortBy .name
            , sectorOptions = settings.sectorOptions |> List.sortBy .name
            , subsectorOptions = settings.subsectorOptions |> List.sortBy .name
            , searchState = { query = "", results = RemoteData.NotAsked, dropdownOpen = False }
            , theme = settings.theme
            , themeIsLight = settings.themeIsLight
            , themeOptions = settings.themeOptions
            , showThemeMenu = False
            , highlightRules = initialHighlightRules
            , showHighlightRulesMenu = False
            , ruleEditor = Nothing
            , nextRuleId = 1
            , pendingDeleteRuleId = Nothing
            , routePlanForm = Nothing
            , activeRoutePlan = initialActiveRoutePlan
            , travelZoneOptions = []
            , jumpRouteLayers = []
            , showJumpRouteLayersMenu = False
            , jumpRouteLayerEditor = Nothing
            , pendingDeleteJumpRouteId = Nothing
            , hiddenJumpRouteIds = initialHiddenJumpRouteIds
            }
    in
    ( ( Time.millisToPosix 0
      , model
      )
    , Cmd.batch
        [ sendSolarSystemRequest ssReqEntry model.hostConfig
        , sendRoguesRequest ssReqEntry model.hostConfig
        , sendSectorRequest secReqEntry model.hostConfig
        , sendRegionRequest secReqEntry model.hostConfig -- Josh to fix later
        , sendRouteRequest routeReqEntry model.hostConfig
        , sendJumpRouteLinksRequest model.hostConfig
        , sendTravelZonesRequest model.hostConfig
        , sendJumpRouteLayersRequest model.hostConfig
        , if referee then
            sendSurveyOverlaysRequest model.hostConfig

          else
            Cmd.none
        , case settings.centerOn of
            Just _ ->
                saveMapCoords hexRect.upperLeftHex

            Nothing ->
                Cmd.none
        ]
    )


isOnRoute : RouteList -> HexAddress -> Bool
isOnRoute route address =
    List.any (\a -> a.address == address) route


hexAddressLabel : Int -> Int -> Float -> HexAddress -> String -> Svg msg
hexAddressLabel x y size hexAddress hexColour =
    if size <= 15 then
        Svg.text ""

    else
        let
            fontSize =
                max 9 (size * 0.15)

            -- distance from hex centre to the top edge, minus the glyph's
            -- own ascent (plus a small margin) so the text never crosses it
            yOffset =
                size * sin hexSizeFactor - fontSize * 0.8 - 2
        in
        Svg.text_
            [ SvgAttrs.x <| String.fromInt x
            , SvgAttrs.y <| String.fromInt <| y - round yOffset
            , SvgAttrs.fontSize (String.fromFloat fontSize)
            , SvgAttrs.textAnchor "middle"
            , SvgAttrs.fontFamily "Tomorrow"
            , SvgAttrs.fontWeight "400"
            , SvgAttrs.fill (hexTextColour hexColour)
            ]
            [ HexAddress.hexLabel hexAddress |> Svg.text ]


viewHexEmpty : Int -> Int -> Int -> Int -> Float -> String -> String -> Svg Msg
viewHexEmpty hx hy x y size childSvgTxt hexColour =
    let
        origin =
            ( toFloat x, toFloat y )

        hexAddress =
            HexAddress hx hy

        childSvg =
            Svg.text_
                [ SvgAttrs.x <| String.fromInt x
                , SvgAttrs.y <| String.fromInt y
                , SvgAttrs.fontSize "10"
                , SvgAttrs.textAnchor "middle"
                , SvgAttrs.fill (hexTextColour hexColour)
                , SvgAttrs.class "hex-scan"
                ]
                [ Svg.text childSvgTxt ]
    in
    Svg.g
        [ SvgEvents.onMouseOver (HoveringHex hexAddress)
        , SvgEvents.on "mouseup" <| mouseUpDecoder (\pos ctrlKey -> MapMouseUp (Just hexAddress) pos ctrlKey)
        , -- listens for the JS 'mousedown' event and then runs the `downDecoder` on the JS Event, returning the Msg
          SvgEvents.on "mousedown" <| mouseDownDecoder MapMouseDown
        , SvgEvents.on "mousemove" <| mouseMoveDecoder MapMouseMove
        , SvgAttrs.style "cursor: pointer; user-select: none"
        , SvgAttrs.id <| "rendered-hex:" ++ HexAddress.toKey hexAddress
        ]
        [ -- background hex
          Svg.Lazy.lazy2 renderPolygon (String.join " " <| hexagonPoints origin size) hexColour
        , hexAddressLabel x y size hexAddress hexColour
        , childSvg
        ]


viewHexRogue : HexAddress -> Int -> Int -> Float -> String -> Bool -> Maybe String -> RogueHexData -> Svg Msg
viewHexRogue hexAddress x y size hexColour isReferee rogueObjectPathData { surveyIndex, playerVisible, objects } =
    let
        origin =
            ( toFloat x, toFloat y )

        hasComet =
            List.any
                (\o ->
                    case o of
                        RogueCometDetail _ ->
                            True

                        _ ->
                            False
                )
                objects

        hasGasGiant =
            List.any
                (\o ->
                    case o of
                        RogueGasGiantDetail _ ->
                            True

                        _ ->
                            False
                )
                objects

        hasOther =
            List.any
                (\o ->
                    case o of
                        RogueOtherDetail _ ->
                            True

                        _ ->
                            False
                )
                objects

        anyKnown =
            List.any
                (\o ->
                    case o of
                        RogueOtherDetail d ->
                            d.known

                        _ ->
                            False
                )
                objects

        showComet =
            hasComet && (isReferee || surveyIndex >= cometSI)

        showGasGiant =
            hasGasGiant && (isReferee || surveyIndex >= gasGiantSI)

        showOther =
            hasOther && (isReferee || playerVisible || surveyIndex >= cometSI || anyKnown)
    in
    Svg.g
        [ SvgEvents.onMouseOver (HoveringHex hexAddress)
        , SvgEvents.on "mouseup" <| mouseUpDecoder (\pos ctrlKey -> MapMouseUp (Just hexAddress) pos ctrlKey)
        , SvgEvents.on "mousedown" <| mouseDownDecoder MapMouseDown
        , SvgEvents.on "mousemove" <| mouseMoveDecoder MapMouseMove
        , SvgAttrs.style "cursor: pointer; user-select: none"
        , SvgAttrs.id <| "rendered-hex:" ++ HexAddress.toKey hexAddress
        ]
        [ Svg.Lazy.lazy2 renderPolygon (String.join " " <| hexagonPoints origin size) hexColour
        , hexAddressLabel x y size hexAddress hexColour
        , if showComet && size > 15 then
            drawCometIcon (toFloat x) (toFloat y) size

          else
            Svg.text ""
        , if showGasGiant && size > 15 then
            drawRogueGasGiant (toFloat x) (toFloat y) size

          else
            Svg.text ""
        , if showOther && size > 15 then
            drawRogueOther rogueObjectPathData (toFloat x) (toFloat y) size

          else
            Svg.text ""
        ]


drawCometIcon : Float -> Float -> Float -> Svg Msg
drawCometIcon cx cy size =
    let
        iconSize =
            size * 0.5

        scale =
            iconSize / 640

        tx =
            cx - 320 * scale

        ty =
            cy - 320 * scale
    in
    Svg.g
        [ SvgAttrs.transform <|
            "translate("
                ++ String.fromFloat tx
                ++ ","
                ++ String.fromFloat ty
                ++ ") scale("
                ++ String.fromFloat scale
                ++ ")"
        ]
        [ Svg.path
            [ SvgAttrs.d "M363.4 139.6L557.7 64.9C559.2 64.3 560.9 64 562.5 64C570 64 576 70 576 77.5C576 79.2 575.7 80.8 575.1 82.3L500.4 276.5L529.7 274.2C542.5 273.2 551.2 287 544.8 298.2L442.6 474.7C406.3 537.4 339.4 576 267 576C154.9 576 64 485.1 64 373C64 300.6 102.6 233.7 165.3 197.4L341.7 95.2C352.8 88.7 366.7 97.4 365.7 110.3L363.4 139.6zM256 264C249.9 264 244.3 267.5 241.7 272.9L212.5 332.1L147.2 341.6C141.2 342.5 136.2 346.7 134.3 352.5C132.4 358.3 134 364.7 138.3 368.9L185.5 414.9L174.3 479.9C173.3 485.9 175.7 492 180.7 495.6C185.7 499.2 192.2 499.7 197.5 496.8L255.9 466.1L314.3 496.8C319.7 499.6 326.2 499.2 331.1 495.6C336 492 338.5 486 337.5 479.9L326.3 414.9L373.5 368.9C377.9 364.6 379.4 358.3 377.5 352.5C375.6 346.7 370.6 342.5 364.6 341.6L299.3 332.1L270.1 272.9C267.4 267.4 261.8 264 255.8 264z"
            , SvgAttrs.fill "#222222"
            ]
            []
        ]


drawRogueGasGiant : Float -> Float -> Float -> Svg Msg
drawRogueGasGiant cx cy size =
    let
        r =
            size * 0.5 / 4
    in
    Svg.g []
        [ Svg.circle
            [ SvgAttrs.cx <| String.fromFloat cx
            , SvgAttrs.cy <| String.fromFloat cy
            , SvgAttrs.r <| String.fromFloat r
            , SvgAttrs.fill "#222222"
            ]
            []
        , Svg.ellipse
            [ SvgAttrs.cx <| String.fromFloat cx
            , SvgAttrs.cy <| String.fromFloat cy
            , SvgAttrs.rx <| String.fromFloat (r * 1.8)
            , SvgAttrs.ry <| String.fromFloat (r * 0.55)
            , SvgAttrs.fill "none"
            , SvgAttrs.stroke "#222222"
            , SvgAttrs.strokeWidth "1.2"
            , SvgAttrs.transform <|
                "rotate(-30 "
                    ++ String.fromFloat cx
                    ++ " "
                    ++ String.fromFloat cy
                    ++ ")"
            ]
            []
        ]


drawRogueOther : Maybe String -> Float -> Float -> Float -> Svg Msg
drawRogueOther mPathData cx cy size =
    case mPathData of
        Nothing ->
            Svg.text ""

        Just pathData ->
            let
                iconSize =
                    size * 0.5

                scale =
                    iconSize / 640

                tx =
                    cx - 320 * scale

                ty =
                    cy - 320 * scale
            in
            Svg.g
                [ SvgAttrs.transform <|
                    "translate("
                        ++ String.fromFloat tx
                        ++ ","
                        ++ String.fromFloat ty
                        ++ ") scale("
                        ++ String.fromFloat scale
                        ++ ")"
                ]
                [ Svg.path
                    [ SvgAttrs.d pathData
                    , SvgAttrs.fill "#222222"
                    ]
                    []
                ]


renderPolyline : String -> String -> Svg msg
renderPolyline points_ borderColour =
    Svg.polyline
        [ points points_
        , SvgAttrs.stroke borderColour
        , SvgAttrs.fill "none"
        , SvgAttrs.strokeWidth "2"
        , SvgAttrs.pointerEvents "visiblePainted"
        ]
        []


renderPolygon : String -> String -> Svg msg
renderPolygon points_ fill =
    let
        hexColour =
            if fill == currentAddressHexBg then
                routeHexBg

            else
                fill

        strokeColour =
            if hexColour == "#000000" then
                "#3a3a3a"

            else
                "#e5e5e5"
    in
    Svg.polygon
        [ points points_
        , SvgAttrs.fill hexColour
        , SvgAttrs.stroke strokeColour
        , SvgAttrs.strokeWidth "0.5"
        , SvgAttrs.pointerEvents "visiblePainted"
        , SvgAttrs.class "hex-hover"
        ]
        []


{-| The default hex label/icon text colour for a given hex background —
light text on a black (dark-theme) hex, the original dark teal otherwise.
-}
hexTextColour : String -> String
hexTextColour hexColour =
    if hexColour == "#000000" then
        "#f1f5f9"

    else
        "#1a1a1a"


captiveGovernmentColour : String -> String
captiveGovernmentColour hexColour =
    if hexColour == "#000000" then
        "#facc15"

    else
        "#b45309"


renderHexBorderStroke : String -> Svg msg
renderHexBorderStroke hexapointsStr =
    Svg.polygon
        [ points hexapointsStr
        , SvgAttrs.fill "none"
        , SvgAttrs.stroke "#8AAFC4"
        , SvgAttrs.strokeWidth "1"
        , SvgAttrs.pointerEvents "none"
        ]
        []


{-| a decoder that takes JSON and emits either a decode failure or a Msg
-}
mouseDownDecoder : (( Float, Float ) -> msg) -> JsDecode.Decoder msg
mouseDownDecoder onDownMsg =
    let
        -- takes a raw JS mouse event and turns it into a parsed Elm mouse event
        jsMouseEventDecoder =
            Html.Events.Extra.Mouse.eventDecoder
                |> JsDecode.andThen
                    (\evt ->
                        case evt.button of
                            Html.Events.Extra.Mouse.MainButton ->
                                JsDecode.succeed evt

                            _ ->
                                -- We fail decoding here, to signal to Elm that we don't want
                                --   to process the event.
                                -- So we'll never see the decoder failure, unlike our Codecs
                                JsDecode.fail "Won't drag on non-main/left button"
                    )
    in
    -- run the mouse event decoder
    jsMouseEventDecoder
        |> -- then if that succeeds, pass the event object into msgConstructor
           JsDecode.map (\evt -> onDownMsg evt.clientPos)


mouseClickDecoder : (( Float, Float ) -> msg) -> JsDecode.Decoder msg
mouseClickDecoder onDownMsg =
    let
        -- takes a raw JS mouse event and turns it into a parsed Elm mouse event
        jsMouseEventDecoder =
            Html.Events.Extra.Mouse.eventDecoder
                |> JsDecode.andThen
                    (\evt ->
                        case evt.button of
                            Html.Events.Extra.Mouse.MainButton ->
                                JsDecode.succeed evt

                            _ ->
                                -- We fail decoding here, to signal to Elm that we don't want
                                --   to process the event.
                                -- So we'll never see the decoder failure, unlike our Codecs
                                JsDecode.fail "Won't drag on non-main/left button"
                    )
    in
    -- run the mouse event decoder
    jsMouseEventDecoder
        |> -- then if that succeeds, pass the event object into msgConstructor
           JsDecode.map (\evt -> onDownMsg evt.offsetPos)


mouseUpDecoder : (( Float, Float ) -> Bool -> msg) -> JsDecode.Decoder msg
mouseUpDecoder onDownMsg =
    let
        -- takes a raw JS mouse event and turns it into a parsed Elm mouse event
        jsMouseEventDecoder =
            Html.Events.Extra.Mouse.eventDecoder
                |> JsDecode.andThen
                    (\evt ->
                        case evt.button of
                            Html.Events.Extra.Mouse.MainButton ->
                                JsDecode.succeed evt

                            _ ->
                                -- We fail decoding here, to signal to Elm that we don't want
                                --   to process the event.
                                -- So we'll never see the decoder failure, unlike our Codecs
                                JsDecode.fail "Won't drag on non-main/left button"
                    )
    in
    -- run the mouse event decoder
    jsMouseEventDecoder
        |> -- then if that succeeds, pass the event object into msgConstructor
           JsDecode.map (\evt -> onDownMsg evt.clientPos evt.keys.ctrl)


mouseMoveDecoder : (( Float, Float ) -> msg) -> JsDecode.Decoder msg
mouseMoveDecoder onMoveMsg =
    Html.Events.Extra.Mouse.eventDecoder
        |> JsDecode.map (.clientPos >> onMoveMsg)


mouseOffsetPosMoveDecoder : (( Float, Float ) -> msg) -> JsDecode.Decoder msg
mouseOffsetPosMoveDecoder onMoveMsg =
    Html.Events.Extra.Mouse.eventDecoder
        |> JsDecode.map (.offsetPos >> onMoveMsg)


journeyMouseDownDecoder : (( Float, Float ) -> msg) -> JsDecode.Decoder msg
journeyMouseDownDecoder onDownMsg =
    Html.Events.Extra.Mouse.eventDecoder
        |> JsDecode.andThen
            (\evt ->
                case evt.button of
                    Html.Events.Extra.Mouse.MainButton ->
                        JsDecode.succeed (onDownMsg evt.offsetPos)

                    _ ->
                        JsDecode.fail "Won't drag on non-main/left button"
            )


journeyMouseUpDecoder : (( Float, Float ) -> msg) -> JsDecode.Decoder msg
journeyMouseUpDecoder onUpMsg =
    Html.Events.Extra.Mouse.eventDecoder
        |> JsDecode.map (.offsetPos >> onUpMsg)


{-| Shrink factor for star circles so they read a bit less oversized at max hex size.
-}
starScale : Float
starScale =
    0.8


drawStar : Float -> Float -> Int -> Float -> String -> Svg Msg
drawStar starX starY radius size starColor =
    Svg.circle
        [ SvgAttrs.cx <| String.fromFloat <| starX
        , SvgAttrs.cy <| String.fromFloat <| starY
        , SvgAttrs.r <| String.fromFloat <| toFloat radius * iconScale size * starScale
        , SvgAttrs.fill starColor
        , SvgAttrs.style "filter: drop-shadow(0 0 3px rgba(0,0,0,0.55))"
        ]
        []


{-| Shared shrink factor for the corner glyphs (bases, gas giant, planetoid belt,
and their "unknown" stand-ins) so they read a bit less oversized at max hex size.
-}
cornerGlyphScale : Float
cornerGlyphScale =
    0.8


drawUnknownSlot : Float -> Float -> Float -> Svg Msg
drawUnknownSlot iconX iconY size =
    let
        r =
            5 * iconScale size * cornerGlyphScale
    in
    Svg.g []
        [ Svg.circle
            [ SvgAttrs.cx <| String.fromFloat iconX
            , SvgAttrs.cy <| String.fromFloat iconY
            , SvgAttrs.r <| String.fromFloat r
            , SvgAttrs.fill "#DDDDDD"
            , SvgAttrs.opacity "0.6"
            ]
            []
        , Svg.text_
            [ SvgAttrs.x <| String.fromFloat iconX
            , SvgAttrs.y <| String.fromFloat iconY
            , SvgAttrs.fontSize (String.fromFloat (9 * iconScale size * cornerGlyphScale))
            , SvgAttrs.textAnchor "middle"
            , SvgAttrs.dominantBaseline "central"
            , SvgAttrs.fontFamily "Tomorrow"
            , SvgAttrs.fontWeight "400"
            , SvgAttrs.fill "#2A6A8A"
            ]
            [ Svg.text "?" ]
        ]


drawPlanetoidBelt : Bool -> Float -> Float -> Float -> Svg Msg
drawPlanetoidBelt themeIsLight iconX iconY size =
    let
        scale =
            7 * iconScale size / 16 * cornerGlyphScale

        ( darkest, mid, lightest ) =
            if themeIsLight then
                ( "#1e293b", "#475569", "#64748b" )

            else
                ( "#64748b", "#94a3b8", "#cbd5e1" )
    in
    Svg.g
        [ SvgAttrs.transform <|
            "translate("
                ++ String.fromFloat iconX
                ++ ","
                ++ String.fromFloat iconY
                ++ ") scale("
                ++ String.fromFloat scale
                ++ ")"
        ]
        [ Svg.polygon [ SvgAttrs.points "-12,-6 -7,-10 -3,-5 -6,-1 -10,-2", SvgAttrs.fill mid ] []
        , Svg.polygon [ SvgAttrs.points "4,-11 10,-9 8,-4 3,-6", SvgAttrs.fill lightest ] []
        , Svg.polygon [ SvgAttrs.points "-10,4 -5,2 -2,7 -7,10", SvgAttrs.fill darkest ] []
        , Svg.polygon [ SvgAttrs.points "2,1 8,-1 11,5 7,8 3,6", SvgAttrs.fill mid ] []
        , Svg.polygon [ SvgAttrs.points "-1,9 4,11 1,14 -3,12", SvgAttrs.fill lightest ] []
        ]


drawBases : Bool -> Dict.Dict String FacilityIcon -> List String -> Int -> Int -> Float -> Svg Msg
drawBases themeIsLight facilityIcons codes cx cy size =
    let
        baseIconColour =
            if themeIsLight then
                "#222222"

            else
                "#cbd5e1"

        renderable =
            codes
                |> List.filterMap (\code -> Dict.get code facilityIcons)
                |> List.take 3

        anchorX =
            toFloat cx - size * 0.38

        anchorY =
            toFloat cy - size * 0.45

        iconSize =
            8 * iconScale size * cornerGlyphScale

        offsets =
            case List.length renderable of
                1 ->
                    [ ( 0, 0 ) ]

                2 ->
                    [ ( -iconSize * 0.6, 0 ), ( iconSize * 0.6, 0 ) ]

                _ ->
                    [ ( -iconSize * 0.5, -iconSize * 0.5 ), ( iconSize * 0.6, -iconSize * 0.2 ), ( 0, iconSize * 0.6 ) ]

        renderIcon idx icon =
            let
                ( ox, oy ) =
                    offsets |> List.drop idx |> List.head |> Maybe.withDefault ( 0, 0 )
            in
            Svg.svg
                [ SvgAttrs.x (String.fromFloat (anchorX + ox - iconSize / 2))
                , SvgAttrs.y (String.fromFloat (anchorY + oy - iconSize / 2))
                , SvgAttrs.width (String.fromFloat iconSize)
                , SvgAttrs.height (String.fromFloat iconSize)
                , SvgAttrs.viewBox icon.viewBox
                ]
                [ Svg.path [ SvgAttrs.d icon.pathData, SvgAttrs.fill baseIconColour ] [] ]
    in
    Svg.g [] (List.indexedMap renderIcon renderable)


drawTravelZoneRing : Float -> Float -> Float -> String -> Svg Msg
drawTravelZoneRing cx cy size colour =
    let
        r =
            size * 0.78

        -- 270° arc open at the bottom (90° gap centred on 6 o'clock).
        -- SVG angles: 0° = right, clockwise. Bottom = 90°.
        -- Gap: 45° to 135°. Arc: start 135° → clockwise → end 45°.
        startX =
            cx + r * cos (degrees 135)

        startY =
            cy + r * sin (degrees 135)

        endX =
            cx + r * cos (degrees 45)

        endY =
            cy + r * sin (degrees 45)

        d =
            "M "
                ++ String.fromFloat startX
                ++ " "
                ++ String.fromFloat startY
                ++ " A "
                ++ String.fromFloat r
                ++ " "
                ++ String.fromFloat r
                ++ " 0 1 1 "
                ++ String.fromFloat endX
                ++ " "
                ++ String.fromFloat endY
    in
    Svg.path
        [ SvgAttrs.d d
        , SvgAttrs.fill "none"
        , SvgAttrs.stroke colour
        , SvgAttrs.strokeWidth "2"
        , SvgAttrs.strokeLinecap "round"
        , SvgAttrs.pointerEvents "none"
        ]
        []


drawGasGiant : Bool -> Float -> Float -> Float -> Svg Msg
drawGasGiant themeIsLight iconX iconY size =
    let
        r =
            5 * iconScale size * cornerGlyphScale

        colour =
            if themeIsLight then
                "#222222"

            else
                "#cbd5e1"
    in
    Svg.g []
        [ Svg.circle
            [ SvgAttrs.cx <| String.fromFloat iconX
            , SvgAttrs.cy <| String.fromFloat iconY
            , SvgAttrs.r <| String.fromFloat r
            , SvgAttrs.fill colour
            ]
            []
        , Svg.ellipse
            [ SvgAttrs.cx <| String.fromFloat iconX
            , SvgAttrs.cy <| String.fromFloat iconY
            , SvgAttrs.rx <| String.fromFloat (r * 1.8)
            , SvgAttrs.ry <| String.fromFloat (r * 0.55)
            , SvgAttrs.fill "none"
            , SvgAttrs.stroke colour
            , SvgAttrs.strokeWidth "1.2"
            , SvgAttrs.transform <|
                "rotate(-30 "
                    ++ String.fromFloat iconX
                    ++ " "
                    ++ String.fromFloat iconY
                    ++ ")"
            ]
            []
        ]


type alias HexRenderOpts =
    { starSystem : StarSystem
    , hexColour : String
    , hexAddrX : Int
    , hexAddrY : Int
    , vox : Int
    , voy : Int
    , size : Float
    , hexapointsStr : String
    , isReferee : Bool
    , facilityIcons : Dict.Dict String FacilityIcon
    , displayMode : DisplayMode
    , themeIsLight : Bool
    }


renderHexBg : HexRenderOpts -> Svg Msg
renderHexBg { hexColour, hexAddrX, hexAddrY, hexapointsStr } =
    let
        hexAddress =
            HexAddress hexAddrX hexAddrY
    in
    Svg.g
        [ SvgEvents.onMouseOver (HoveringHex hexAddress)
        , SvgEvents.on "mouseup" <| mouseUpDecoder (\pos ctrlKey -> MapMouseUp (Just hexAddress) pos ctrlKey)
        , -- listens for the JS 'mousedown' event and then runs the `downDecoder` on the JS Event, returning the Msg
          SvgEvents.on "mousedown" <| mouseDownDecoder MapMouseDown
        , SvgEvents.on "mousemove" <| mouseMoveDecoder MapMouseMove
        , SvgAttrs.style "cursor: pointer; user-select: none"
        ]
        [ Svg.Lazy.lazy2 renderPolygon hexapointsStr hexColour ]


viewBarRow : Float -> Float -> Float -> String -> Int -> String -> Svg Msg
viewBarRow size cx rowY label tier hexColour =
    let
        segW =
            size * 0.15

        segH =
            size * 0.1

        segGap =
            size * 0.045

        skew =
            segH * 0.6

        numSegs =
            5

        totalBarW =
            toFloat numSegs * segW + toFloat (numSegs - 1) * segGap

        barStartX =
            cx - (totalBarW + skew) / 2

        rhomboidPoints sx =
            let
                x0 =
                    sx

                x1 =
                    sx + segW

                y0 =
                    rowY + segH / 2

                y1 =
                    rowY - segH / 2
            in
            String.join " "
                [ String.fromFloat x0 ++ "," ++ String.fromFloat y0
                , String.fromFloat x1 ++ "," ++ String.fromFloat y0
                , String.fromFloat (x1 + skew) ++ "," ++ String.fromFloat y1
                , String.fromFloat (x0 + skew) ++ "," ++ String.fromFloat y1
                ]

        segment i =
            let
                sx =
                    barStartX + toFloat i * (segW + segGap)

                fillColour =
                    if i < tier then
                        "#1e3a5f"

                    else
                        "#dde3ec"
            in
            Svg.polygon
                [ SvgAttrs.points (rhomboidPoints sx)
                , SvgAttrs.fill fillColour
                ]
                []
    in
    Svg.g []
        (Svg.text_
            [ SvgAttrs.x (String.fromFloat (barStartX - size * 0.05))
            , SvgAttrs.y (String.fromFloat rowY)
            , SvgAttrs.textAnchor "end"
            , SvgAttrs.dominantBaseline "middle"
            , SvgAttrs.fill (hexTextColour hexColour)
            , SvgAttrs.fontSize (String.fromFloat (size * 0.2))
            , SvgAttrs.fontFamily "Oxanium, sans-serif"
            , SvgAttrs.fontWeight "600"
            ]
            [ Svg.text label ]
            :: List.map segment (List.range 0 (numSegs - 1))
        )


viewRoleBadge : Float -> Float -> Float -> String -> String -> Svg Msg
viewRoleBadge size cx rowY role hexColour =
    let
        isDarkHex =
            hexColour == "#000000"

        textColour =
            case role of
                "market" ->
                    if isDarkHex then
                        "#7fb8e6"

                    else
                        "#1e5a8a"

                "supplier" ->
                    if isDarkHex then
                        "#7fd9a3"

                    else
                        "#1e6b3f"

                "extractor" ->
                    if isDarkHex then
                        "#f0b070"

                    else
                        "#7a4010"

                "deficit" ->
                    if isDarkHex then
                        "#f08080"

                    else
                        "#7a1010"

                _ ->
                    hexTextColour hexColour
    in
    Svg.text_
        [ SvgAttrs.x (String.fromFloat cx)
        , SvgAttrs.y (String.fromFloat rowY)
        , SvgAttrs.textAnchor "middle"
        , SvgAttrs.dominantBaseline "middle"
        , SvgAttrs.fill textColour
        , SvgAttrs.fontSize (String.fromFloat (size * 0.22))
        , SvgAttrs.fontFamily "Oxanium, sans-serif"
        , SvgAttrs.fontWeight "700"
        ]
        [ Svg.text (String.toUpper role) ]


renderHexContent : HexRenderOpts -> Svg Msg
renderHexContent { starSystem, hexColour, hexAddrX, hexAddrY, vox, voy, size, isReferee, facilityIcons, displayMode, themeIsLight } =
    let
        hexAddress =
            HexAddress hexAddrX hexAddrY

        si =
            starSystem.surveyIndex

        worldVisible =
            starSystem.known || si >= 10

        effectiveMode =
            case displayMode of
                ShowStars ->
                    ShowStars

                ShowMainWorld ->
                    if isReferee || worldVisible then
                        ShowMainWorld

                    else
                        ShowStars

                ShowTradeCodes ->
                    if isReferee || worldVisible then
                        ShowTradeCodes

                    else
                        ShowStars

                ShowTechLevel ->
                    if isReferee || worldVisible then
                        ShowTechLevel

                    else
                        ShowStars

                ShowGovernment ->
                    if isReferee || worldVisible then
                        ShowGovernment

                    else
                        ShowStars

                _ ->
                    if isReferee then
                        displayMode

                    else
                        ShowStars

        showStar =
            si > 0

        showGasGiant =
            (isReferee || si >= gasGiantSI) && starSystem.gasGiantCount > 0

        showPlanetoidBelt =
            (isReferee || si >= planetoidSI) && starSystem.planetoidBeltCount > 0

        showBases =
            not (List.isEmpty starSystem.baseCodes)

        showUnknownGasGiant =
            showStar && not isReferee && si < gasGiantSI

        showUnknownPlanetoidBelt =
            showStar && not isReferee && si < planetoidSI

        gasGiantSlotActive =
            showGasGiant || showUnknownGasGiant

        beltSlotActive =
            showPlanetoidBelt || showUnknownPlanetoidBelt

        topRightAnchorX =
            toFloat vox + size * 0.38

        topRightAnchorY =
            toFloat voy - size * 0.45

        topRightSpread =
            size * 0.16

        gasGiantX =
            if gasGiantSlotActive && beltSlotActive then
                topRightAnchorX - topRightSpread

            else
                topRightAnchorX

        beltX =
            if gasGiantSlotActive && beltSlotActive then
                topRightAnchorX + topRightSpread

            else
                topRightAnchorX

        beltY =
            topRightAnchorY + size * 0.12

        showTravelZone =
            (isReferee || si >= uwpSI) && starSystem.travelZone /= Nothing

        travelZoneRing =
            if showTravelZone && size > 15 then
                case starSystem.travelZone of
                    Just tz ->
                        drawTravelZoneRing (toFloat vox) (toFloat voy) size tz.colour

                    Nothing ->
                        Svg.text ""

            else
                Svg.text ""

        hexCentreTextColoured : String -> String -> Svg Msg
        hexCentreTextColoured colour txt =
            Svg.text_
                [ SvgAttrs.x (String.fromInt vox)
                , SvgAttrs.y (String.fromInt voy)
                , SvgAttrs.textAnchor "middle"
                , SvgAttrs.dominantBaseline "middle"
                , SvgAttrs.fill colour
                , SvgAttrs.fontSize (String.fromFloat (size * 0.28))
                , SvgAttrs.fontFamily "Oxanium, sans-serif"
                , SvgAttrs.fontWeight "600"
                , SvgAttrs.pointerEvents "none"
                ]
                [ Svg.text txt ]

        hexCentreText : String -> Svg Msg
        hexCentreText txt =
            hexCentreTextColoured (hexTextColour hexColour) txt

        gwpCompact : Int -> String
        gwpCompact v =
            if v >= 1000000000000 then
                String.fromFloat (toFloat v / 1.0e12 |> roundTo1) ++ "T"

            else if v >= 1000000000 then
                String.fromFloat (toFloat v / 1.0e9 |> roundTo1) ++ "B"

            else if v >= 1000000 then
                String.fromFloat (toFloat v / 1.0e6 |> roundTo1) ++ "M"

            else
                String.fromInt v

        roundTo1 : Float -> Float
        roundTo1 f =
            toFloat (round (f * 10)) / 10
    in
    Svg.g []
        [ hexAddressLabel vox voy size hexAddress hexColour
        , case effectiveMode of
            ShowMainWorld ->
                Svg.g [ SvgAttrs.pointerEvents "none" ]
                    [ case starSystem.mainWorldImage of
                        Just imgName ->
                            let
                                d =
                                    size * 0.55

                                ix =
                                    toFloat vox - d / 2

                                iy =
                                    toFloat voy - d / 2
                            in
                            Svg.image
                                [ HtmlAttrs.attribute "href" ("/stellar_objects/" ++ imgName ++ ".webp")
                                , SvgAttrs.x (String.fromFloat ix)
                                , SvgAttrs.y (String.fromFloat iy)
                                , SvgAttrs.width (String.fromFloat d)
                                , SvgAttrs.height (String.fromFloat d)
                                , SvgAttrs.clipPath "url(#planet-hex-clip)"
                                , SvgAttrs.preserveAspectRatio "xMidYMid slice"
                                ]
                                []

                        Nothing ->
                            Svg.text ""
                    , if showGasGiant && size > 15 then
                        drawGasGiant themeIsLight topRightAnchorX topRightAnchorY size

                      else
                        Svg.text ""
                    , travelZoneRing
                    ]

            ShowWTN ->
                Svg.g [ SvgAttrs.pointerEvents "none" ]
                    [ case starSystem.wtn of
                        Just wtn ->
                            hexCentreText (String.fromFloat (toFloat (round (wtn * 10)) / 10))

                        Nothing ->
                            Svg.text ""
                    , travelZoneRing
                    ]

            ShowGWP ->
                Svg.g [ SvgAttrs.pointerEvents "none" ]
                    [ case starSystem.gwp of
                        Just gwp ->
                            hexCentreText (gwpCompact gwp)

                        Nothing ->
                            Svg.text ""
                    , travelZoneRing
                    ]

            ShowTradeCodes ->
                Svg.g [ SvgAttrs.pointerEvents "none" ]
                    [ if List.isEmpty starSystem.tradeCodes then
                        Svg.text ""

                      else
                        hexCentreText (String.join " " starSystem.tradeCodes)
                    , if showGasGiant && size > 15 then
                        drawGasGiant themeIsLight topRightAnchorX topRightAnchorY size

                      else
                        Svg.text ""
                    , travelZoneRing
                    ]

            ShowImportance ->
                Svg.g [ SvgAttrs.pointerEvents "none" ]
                    [ case starSystem.importance of
                        Just imp ->
                            hexCentreText
                                ("{"
                                    ++ (if imp >= 0 then
                                            "+"

                                        else
                                            ""
                                       )
                                    ++ String.fromInt imp
                                    ++ "}"
                                )

                        Nothing ->
                            Svg.text ""
                    , travelZoneRing
                    ]

            ShowStrategic ->
                case starSystem.strategic of
                    Just strat ->
                        if size >= 30 then
                            Svg.g [ SvgAttrs.pointerEvents "none" ]
                                [ viewBarRow size (toFloat vox) (toFloat voy - size * 0.28) "Ix" strat.importanceTier hexColour
                                , viewBarRow size (toFloat vox) (toFloat voy - size * 0.09) "RU" strat.resourceUnitsTier hexColour
                                , viewBarRow size (toFloat vox) (toFloat voy + size * 0.1) "Rs" strat.resourceTier hexColour
                                , viewBarRow size (toFloat vox) (toFloat voy + size * 0.29) "Td" strat.tradeEaseTier hexColour
                                , travelZoneRing
                                ]

                        else
                            Svg.text ""

                    Nothing ->
                        Svg.text ""

            ShowResource ->
                case starSystem.strategic of
                    Just strat ->
                        if size >= 30 then
                            Svg.g [ SvgAttrs.pointerEvents "none" ]
                                [ case strat.routeRole of
                                    Just role ->
                                        viewRoleBadge size (toFloat vox) (toFloat voy - size * 0.36) role hexColour

                                    Nothing ->
                                        Svg.text ""
                                , viewBarRow size (toFloat vox) (toFloat voy - size * 0.07) "Ix" strat.importanceTier hexColour
                                , viewBarRow size (toFloat vox) (toFloat voy + size * 0.15) "Td" strat.tradeEaseTier hexColour
                                , travelZoneRing
                                ]

                        else
                            Svg.text ""

                    Nothing ->
                        Svg.text ""

            ShowTechLevel ->
                Svg.g [ SvgAttrs.pointerEvents "none" ]
                    [ case starSystem.techLevel of
                        Just tl ->
                            hexCentreText (String.fromInt tl)

                        Nothing ->
                            Svg.text ""
                    , travelZoneRing
                    ]

            ShowHabitability ->
                Svg.g [ SvgAttrs.pointerEvents "none" ]
                    [ case starSystem.habitabilityRating of
                        Just rating ->
                            hexCentreText (String.fromInt rating)

                        Nothing ->
                            Svg.text ""
                    , travelZoneRing
                    ]

            ShowGovernment ->
                Svg.g [ SvgAttrs.pointerEvents "none" ]
                    [ case ( starSystem.governmentCode, starSystem.governmentName ) of
                        ( Just code, Just name ) ->
                            let
                                colour =
                                    if code == 6 then
                                        captiveGovernmentColour hexColour

                                    else
                                        hexTextColour hexColour
                            in
                            Svg.g []
                                [ Svg.text_
                                    [ SvgAttrs.x (String.fromInt vox)
                                    , SvgAttrs.y (String.fromFloat (toFloat voy - size * 0.32))
                                    , SvgAttrs.textAnchor "middle"
                                    , SvgAttrs.dominantBaseline "middle"
                                    , SvgAttrs.fill colour
                                    , SvgAttrs.fontSize (String.fromFloat (size * 0.28))
                                    , SvgAttrs.fontFamily "Oxanium, sans-serif"
                                    , SvgAttrs.fontWeight "700"
                                    , SvgAttrs.pointerEvents "none"
                                    ]
                                    [ Svg.text (String.fromInt code) ]
                                , Svg.text_
                                    [ SvgAttrs.x (String.fromInt vox)
                                    , SvgAttrs.y (String.fromFloat (toFloat voy - size * 0.02))
                                    , SvgAttrs.textAnchor "middle"
                                    , SvgAttrs.dominantBaseline "middle"
                                    , SvgAttrs.fill colour
                                    , SvgAttrs.fontSize (String.fromFloat (size * 0.2))
                                    , SvgAttrs.fontFamily "Oxanium, sans-serif"
                                    , SvgAttrs.fontWeight "700"
                                    , SvgAttrs.pointerEvents "none"
                                    ]
                                    [ Svg.text name ]
                                ]

                        _ ->
                            Svg.text ""
                    , travelZoneRing
                    ]

            ShowStars ->
                Svg.g
                    [ SvgAttrs.pointerEvents "none" ]
                    [ -- center star
                      if showStar then
                        let
                            primaryPos =
                                ( toFloat vox, toFloat voy )

                            isKnown : StarType -> Bool
                            isKnown theStar =
                                if theStar |> (getStarTypeData >> isBrownDwarfType) then
                                    starSystem.surveyIndex >= 4

                                else
                                    starSystem.surveyIndex >= 1

                            generateStar : Int -> StarType -> Svg Msg
                            generateStar idx starType =
                                let
                                    starData =
                                        getStarTypeData starType

                                    ( sx, sy ) =
                                        if idx == 0 then
                                            ( toFloat vox, toFloat voy )

                                        else
                                            rotatePoint size (idx + 2) primaryPos 60 (round (20 * starScale))
                                in
                                case starData.companion of
                                    Just companion ->
                                        let
                                            primaryRadius =
                                                7

                                            companionRadius =
                                                3

                                            -- nestle the companion against the primary's inner edge,
                                            -- scaling with zoom so it doesn't get swallowed at high size
                                            ( cx, cy ) =
                                                ( sx - toFloat (primaryRadius - companionRadius) * iconScale size * starScale, sy )

                                            compStarData =
                                                getStarTypeData companion
                                        in
                                        Svg.g []
                                            [ Svg.Lazy.lazy5 drawStar sx sy primaryRadius size <| starColourRGB starData.colour
                                            , Svg.Lazy.lazy5 drawStar cx cy companionRadius size <| starColourRGB compStarData.colour
                                            ]

                                    Nothing ->
                                        Svg.Lazy.lazy5 drawStar sx sy 7 size <| starColourRGB starData.colour
                        in
                        Svg.g
                            []
                            (starSystem.stars
                                |> List.filter isKnown
                                |> List.indexedMap (Svg.Lazy.lazy2 generateStar)
                            )

                      else
                        Svg.text ""
                    , if showGasGiant && size > 15 then
                        drawGasGiant themeIsLight gasGiantX topRightAnchorY size

                      else
                        Svg.text ""
                    , if showPlanetoidBelt && size > 15 then
                        drawPlanetoidBelt themeIsLight beltX beltY size

                      else
                        Svg.text ""
                    , if showUnknownGasGiant && size > 15 then
                        drawUnknownSlot gasGiantX topRightAnchorY size

                      else
                        Svg.text ""
                    , if showUnknownPlanetoidBelt && size > 15 then
                        drawUnknownSlot beltX beltY size

                      else
                        Svg.text ""
                    , travelZoneRing
                    ]
        , if showBases && size > 15 then
            drawBases themeIsLight facilityIcons starSystem.baseCodes vox voy size

          else
            Svg.text ""
        ]


renderHexSystemLabels : HexRenderOpts -> Svg Msg
renderHexSystemLabels { starSystem, hexColour, vox, voy, size, isReferee } =
    let
        si =
            starSystem.surveyIndex

        showStar =
            si > 0
    in
    if not showStar || size <= 25 then
        Svg.text ""

    else
        Svg.g []
            [ if (isReferee || si >= uwpSI) && size >= 60 then
                case starSystem.mainWorldUwp of
                    Just uwpStr ->
                        Svg.text_
                            [ SvgAttrs.x <| String.fromInt vox
                            , SvgAttrs.y <| String.fromInt <| voy + floor (size * 0.48)
                            , SvgAttrs.fontSize <| String.fromFloat (size * 0.18)
                            , SvgAttrs.textAnchor "middle"
                            , SvgAttrs.fontFamily "Oxanium"
                            , SvgAttrs.fontWeight "400"
                            , SvgAttrs.fill (hexTextColour hexColour)
                            ]
                            [ Svg.text uwpStr ]

                    Nothing ->
                        Svg.text ""

              else
                Svg.text ""
            , if (isReferee || si >= uwpSI) && starSystem.name /= "" then
                Svg.text_
                    [ SvgAttrs.x <| String.fromInt vox
                    , SvgAttrs.y <| String.fromInt <| voy + floor (size * 0.78)
                    , SvgAttrs.fontSize <| String.fromFloat (size * 0.25)
                    , SvgAttrs.textAnchor "middle"
                    , SvgAttrs.fontFamily "Oxanium"
                    , SvgAttrs.fontWeight "600"
                    , SvgAttrs.fill (hexTextColour hexColour)
                    ]
                    [ Svg.text starSystem.name ]

              else
                Svg.text ""
            ]


selectedHexBg =
    "#B8E0F0"


routeHexBg =
    "#FFE8C0"


currentAddressHexBg =
    "#fe5a1d"


allegianceColours : Dict.Dict String String
allegianceColours =
    Dict.fromList
        [ ( "C", "#D0EAF8" )
        , ( "GR", "#FFE4C8" )
        , ( "AL", "#E8D4B8" )
        ]


viewHexLoading : Int -> Int -> Int -> Int -> Float -> String -> Svg Msg
viewHexLoading hx hy x y size hexColour =
    let
        origin =
            ( toFloat x, toFloat y )

        hexAddress =
            HexAddress hx hy

        spacing =
            max 7 (size * 0.18)

        dotY =
            String.fromInt y

        dot cls offset =
            Svg.text_
                [ SvgAttrs.x (String.fromFloat (toFloat x + offset))
                , SvgAttrs.y dotY
                , SvgAttrs.textAnchor "middle"
                , SvgAttrs.fill "var(--color-highlight)"
                , SvgAttrs.fontSize "14"
                , SvgAttrs.class cls
                ]
                [ Svg.text "·" ]
    in
    Svg.g
        [ SvgEvents.onMouseOver (HoveringHex hexAddress)
        , SvgEvents.on "mouseup" <| mouseUpDecoder (\pos ctrlKey -> MapMouseUp (Just hexAddress) pos ctrlKey)
        , SvgEvents.on "mousedown" <| mouseDownDecoder MapMouseDown
        , SvgEvents.on "mousemove" <| mouseMoveDecoder MapMouseMove
        , SvgAttrs.style "cursor: pointer; user-select: none"
        , SvgAttrs.id <| "rendered-hex:" ++ HexAddress.toKey hexAddress
        ]
        [ Svg.Lazy.lazy2 renderPolygon (String.join " " <| hexagonPoints origin size) hexColour
        , hexAddressLabel x y size hexAddress hexColour
        , dot "hex-dot hex-dot-1" -spacing
        , dot "hex-dot hex-dot-2" 0
        , dot "hex-dot hex-dot-3" spacing
        ]


viewHex :
    Float
    -> SolarSystemDict
    -> HexAddress
    -> Int
    -> Int
    -> String
    -> List ( Float, Float )
    -> Bool
    -> Maybe String
    -> Dict.Dict String FacilityIcon
    -> DisplayMode
    -> Bool
    -> ( Svg Msg, Svg Msg )
viewHex hexSize solarSystemDict hexAddress vox voy hexColour rawHexaPoints isReferee rogueObjectPathData facilityIcons displayMode themeIsLight =
    let
        remoteSolarSystem =
            Dict.get (HexAddress.toKey hexAddress) solarSystemDict

        viewEmptyHelper txt =
            Svg.Lazy.lazy7 viewHexEmpty hexAddress.x hexAddress.y vox voy hexSize txt hexColour
    in
    case remoteSolarSystem of
        Just (LoadedSolarSystem loadedSystem) ->
            let
                hexapointsStr =
                    convertRawHexagonPoints ( toFloat vox, toFloat voy ) rawHexaPoints

                opts =
                    { starSystem = loadedSystem
                    , hexColour = hexColour
                    , hexAddrX = hexAddress.x
                    , hexAddrY = hexAddress.y
                    , vox = vox
                    , voy = voy
                    , size = hexSize
                    , hexapointsStr = hexapointsStr
                    , isReferee = isReferee
                    , facilityIcons = facilityIcons
                    , displayMode = displayMode
                    , themeIsLight = themeIsLight
                    }
            in
            ( Svg.Lazy.lazy renderHexBg opts
            , Svg.Lazy.lazy renderHexContent opts
            )

        Just LoadingSolarSystem ->
            ( viewHexLoading hexAddress.x hexAddress.y vox voy hexSize hexColour
            , Svg.text ""
            )

        Just (FailedSolarSystem _) ->
            ( viewEmptyHelper "Failed."
            , Svg.text ""
            )

        Just LoadedEmptyHex ->
            ( viewEmptyHelper ""
            , Svg.text ""
            )

        Just (LoadedRogueHex rogueData) ->
            ( viewHexRogue hexAddress vox voy hexSize hexColour isReferee rogueObjectPathData rogueData
            , Svg.text ""
            )

        Just (FailedStarsSolarSystem _) ->
            ( Svg.Lazy.lazy7 viewHexEmpty hexAddress.x hexAddress.y vox voy hexSize "Star Failed." "#aaaaaa"
            , Svg.text ""
            )

        Nothing ->
            ( viewEmptyHelper ""
            , Svg.text ""
            )


type RogueObjectDetail
    = RogueCometDetail { name : String, cometType : String }
    | RogueGasGiantDetail { name : String, code : String, diameter : Float, mass : Maybe Float }
    | RogueOtherDetail { name : String, typeName : String, known : Bool }


type alias RogueHexData =
    { surveyIndex : Int
    , playerVisible : Bool
    , objects : List RogueObjectDetail
    }


type alias RogueResponseItem =
    { detail : RogueObjectDetail
    , x : Int
    , y : Int
    , surveyIndex : Int
    , playerVisible : Bool
    }


rogueObjectDetailDecoder : JsDecode.Decoder RogueObjectDetail
rogueObjectDetailDecoder =
    JsDecode.field "type" JsDecode.string
        |> JsDecode.andThen
            (\objType ->
                case objType of
                    "Comet" ->
                        JsDecode.map2
                            (\n ct -> RogueCometDetail { name = n, cometType = ct })
                            (JsDecode.field "name" (JsDecode.oneOf [ JsDecode.string, JsDecode.null "" ]))
                            (JsDecode.field "comet_type" (JsDecode.oneOf [ JsDecode.string, JsDecode.null "" ]))

                    "GasGiant" ->
                        JsDecode.map4
                            (\n code diam mass -> RogueGasGiantDetail { name = n, code = code, diameter = diam, mass = mass })
                            (JsDecode.field "name" (JsDecode.oneOf [ JsDecode.string, JsDecode.null "" ]))
                            (JsDecode.field "code" (JsDecode.oneOf [ JsDecode.string, JsDecode.null "" ]))
                            (JsDecode.field "diameter" (JsDecode.oneOf [ JsDecode.float, JsDecode.null 0 ]))
                            (JsDecode.field "mass" (JsDecode.nullable JsDecode.float))

                    _ ->
                        JsDecode.map2
                            (\n k -> RogueOtherDetail { name = n, typeName = objType, known = k })
                            (JsDecode.field "name" (JsDecode.oneOf [ JsDecode.string, JsDecode.null "" ]))
                            (JsDecode.field "known" (JsDecode.oneOf [ JsDecode.bool, JsDecode.null False ]))
            )


rogueResponseItemDecoder : JsDecode.Decoder RogueResponseItem
rogueResponseItemDecoder =
    JsDecode.map5 RogueResponseItem
        rogueObjectDetailDecoder
        (JsDecode.field "x" JsDecode.int)
        (JsDecode.field "y" JsDecode.int)
        (JsDecode.field "survey_index" JsDecode.int)
        (JsDecode.field "player_visible" (JsDecode.oneOf [ JsDecode.bool, JsDecode.null False ]))


type RemoteSolarSystem
    = LoadedSolarSystem StarSystem
    | LoadedEmptyHex
    | LoadedRogueHex RogueHexData
    | LoadingSolarSystem
    | FailedStarsSolarSystem FallibleStarSystem
    | FailedSolarSystem Http.Error


type alias SolarSystemDict =
    Dict.Dict String RemoteSolarSystem


type HorizontalOffsetDir
    = Top
    | Bottom


type VerticalOffsetDir
    = Left
    | Right


renderSectorOutline : Float -> SectorHexAddress -> Svg Msg
renderSectorOutline hexSize hex =
    let
        hWidth =
            hexWidth hexSize |> floor

        hHeight =
            hexHeight hexSize |> floor

        topLeft : HexAddress
        topLeft =
            { hex | x = 0, y = 0 } |> HexAddress.toUniversalAddress

        botRight : HexAddress
        botRight =
            { hex | x = 32, y = 40 } |> HexAddress.toUniversalAddress

        topRight : HexAddress
        topRight =
            { hex | x = 32, y = 0 } |> HexAddress.toUniversalAddress

        botLeft : HexAddress
        botLeft =
            { hex | x = 0, y = 40 } |> HexAddress.toUniversalAddress

        computePoints hexAddr =
            calcVisualOrigin hexSize
                { row = hexAddr.y, col = hexAddr.x }
                |> (\( x, y ) ->
                        ( x - hWidth // 2, y - hHeight // 2 )
                   )
                |> (\( x, y ) ->
                        (x |> String.fromInt)
                            ++ ", "
                            ++ (y |> String.fromInt)
                   )

        points_ =
            List.map computePoints [ topLeft, topRight, botRight, botLeft, topLeft ]
                |> String.join " "
    in
    Svg.polyline
        [ points points_
        , SvgAttrs.id ("sectorOutline-" ++ String.fromInt hex.sectorX ++ "-" ++ String.fromInt hex.sectorY)
        , SvgAttrs.stroke "#2A6A8A60"
        , SvgAttrs.fill "none"
        , SvgAttrs.strokeWidth "2"
        , SvgAttrs.pointerEvents "visiblePainted"
        ]
        []


renderSubsectorLines : Float -> SectorHexAddress -> List (Svg Msg)
renderSubsectorLines hexSize hex =
    let
        hWidth =
            hexWidth hexSize |> floor

        hHeight =
            hexHeight hexSize |> floor

        toUniversal localX localY =
            { hex | x = localX, y = localY } |> HexAddress.toUniversalAddress

        visualOf localX localY =
            let
                ua =
                    toUniversal localX localY
            in
            calcVisualOrigin hexSize { row = ua.y, col = ua.x }

        ( rawLeftX, rawTopY ) =
            visualOf 0 0

        sectorLeftX =
            rawLeftX - hWidth // 2

        sectorTopY =
            rawTopY - hHeight // 2

        ( _, rawBotY ) =
            visualOf 0 40

        sectorBotY =
            rawBotY - hHeight // 2

        ( rawRightX, _ ) =
            visualOf 32 0

        sectorRightX =
            rawRightX - hWidth // 2

        sharedAttrs =
            [ SvgAttrs.stroke "#888888"
            , SvgAttrs.strokeWidth "1.5"
            , SvgAttrs.strokeDasharray "5,3"
            , SvgAttrs.fill "none"
            , SvgAttrs.pointerEvents "none"
            ]

        verticalLine bc =
            let
                ( xLeft, _ ) =
                    visualOf bc 0

                ( xRight, _ ) =
                    visualOf (bc + 1) 0

                lineX =
                    (xLeft + xRight) // 2
            in
            Svg.line
                (sharedAttrs
                    ++ [ SvgAttrs.x1 (String.fromInt lineX)
                       , SvgAttrs.y1 (String.fromInt sectorTopY)
                       , SvgAttrs.x2 (String.fromInt lineX)
                       , SvgAttrs.y2 (String.fromInt sectorBotY)
                       ]
                )
                []

        horizontalLine br =
            let
                ( _, yAbove ) =
                    visualOf 1 br

                ( _, yBelow ) =
                    visualOf 1 (br + 1)

                lineY =
                    (yAbove + yBelow) // 2
            in
            Svg.line
                (sharedAttrs
                    ++ [ SvgAttrs.x1 (String.fromInt sectorLeftX)
                       , SvgAttrs.y1 (String.fromInt lineY)
                       , SvgAttrs.x2 (String.fromInt sectorRightX)
                       , SvgAttrs.y2 (String.fromInt lineY)
                       ]
                )
                []
    in
    List.map verticalLine [ 7, 15, 23 ]
        ++ List.map horizontalLine [ 9, 19, 29 ]


{-| Pixel center of a rectangular local-coordinate cell within a sector (used for
both whole-sector and single-subsector background name labels).
-}
sectorCellCenterPixel : Float -> SectorHexAddress -> { x : Int, y : Int } -> { x : Int, y : Int } -> ( Int, Int )
sectorCellCenterPixel hexSize hex topLeftLocal botRightLocal =
    let
        hWidth =
            hexWidth hexSize |> floor

        hHeight =
            hexHeight hexSize |> floor

        pixelOf local =
            { hex | x = local.x, y = local.y }
                |> HexAddress.toUniversalAddress
                |> (\ua -> calcVisualOrigin hexSize { row = ua.y, col = ua.x })
                |> (\( x, y ) -> ( x - hWidth // 2, y - hHeight // 2 ))

        ( tlx, tly ) =
            pixelOf topLeftLocal

        ( brx, bry ) =
            pixelOf botRightLocal
    in
    ( (tlx + brx) // 2, (tly + bry) // 2 )


{-| A faint, rotated, background watermark of a sector or subsector name. Each word
of the name is stacked on its own line, and the whole stack is rotated 45 degrees
around its center point.
-}
backgroundNameLabel : Bool -> Int -> Int -> Int -> String -> Svg msg
backgroundNameLabel themeIsLight fontSize cx cy name =
    let
        words =
            String.words name

        lineHeightEm =
            1.15

        wordCount =
            List.length words

        firstDy =
            -(toFloat (wordCount - 1) * lineHeightEm / 2)

        tspans =
            List.indexedMap
                (\i word ->
                    Svg.tspan
                        [ SvgAttrs.x (String.fromInt cx)
                        , SvgAttrs.dy
                            (String.fromFloat
                                (if i == 0 then
                                    firstDy

                                 else
                                    lineHeightEm
                                )
                                ++ "em"
                            )
                        ]
                        [ Svg.text word ]
                )
                words

        colour =
            if themeIsLight then
                "#D3D3D3"

            else
                "#4d4d4d"
    in
    Svg.text_
        [ SvgAttrs.x (String.fromInt cx)
        , SvgAttrs.y (String.fromInt cy)
        , SvgAttrs.textAnchor "middle"
        , SvgAttrs.dominantBaseline "middle"
        , SvgAttrs.fontFamily "Tomorrow"
        , SvgAttrs.fontWeight "500"
        , SvgAttrs.fontSize (String.fromInt fontSize)
        , SvgAttrs.fill colour
        , SvgAttrs.style "pointer-events: none; user-select: none;"
        , SvgAttrs.transform ("rotate(-45 " ++ String.fromInt cx ++ " " ++ String.fromInt cy ++ ")")
        ]
        tspans


regionLabel : Int -> Int -> String -> Svg msg
regionLabel x y name =
    Svg.text_
        [ SvgAttrs.x <| String.fromInt x
        , SvgAttrs.y <| String.fromInt y
        , SvgAttrs.textAnchor "middle"
        , SvgAttrs.dominantBaseline "middle"
        , SvgAttrs.fontFamily "Tomorrow"
        , SvgAttrs.fontWeight "500"
        , SvgAttrs.fill "#1A4A6A"
        , SvgAttrs.style "pointer-events: none; user-select: none;"
        ]
        [ Svg.text name ]


hexBackgroundColour : DisplayMode -> Bool -> Bool -> String -> SolarSystemDict -> String
hexBackgroundColour displayMode themeIsLight referee hexKey solarSystemDict =
    let
        defaultBg =
            if themeIsLight then
                "#FFFFFF"

            else
                "#000000"
    in
    if referee then
        case Dict.get hexKey solarSystemDict of
            Just rss ->
                case rss of
                    LoadedSolarSystem system ->
                        if displayMode == ShowHabitability then
                            habitabilityColour themeIsLight system.habitabilityRating

                        else
                            case system.allegiance of
                                Just allegiance ->
                                    case Dict.get allegiance allegianceColours of
                                        Just color ->
                                            color

                                        Nothing ->
                                            defaultBg

                                Nothing ->
                                    defaultBg

                    _ ->
                        defaultBg

            Nothing ->
                defaultBg

    else
        defaultBg


type alias ViewHexesConfig =
    { hexRect : HexRect
    , rawHexaPoints : List ( Float, Float )
    , svgWidth : Float
    , svgHeight : Float
    , maxAcross : Int
    , maxTall : Int
    , solarSystemDict : SolarSystemDict
    , hexColours : HexColorDict
    , regionLabels : RegionLabelDict
    , regions : RegionDict
    , regionDisplay : RegionDisplay
    , showSectorLines : Bool
    , showSubsectorLines : Bool
    , sectors : SectorDict
    , showBackgroundNames : Bool
    , showJumpLogFill : Bool
    , themeIsLight : Bool
    , highlightRules : List HighlightRule.Rule
    , previewRoute : Maybe { hops : List RoutePlan.Hop, colour : String }
    , route : RouteList
    , currentAddress : HexAddress
    , hexSize : Float
    , maybeSelectedHex : Maybe HexAddress
    , isReferee : Bool
    , panOffset : { x : Float, y : Float }
    , jumpRouteLinks : List JumpRouteLink
    , hiddenJumpRouteIds : Set.Set Int
    , rogueObjectPathData : Maybe String
    , facilityIcons : Dict.Dict String FacilityIcon
    , displayMode : DisplayMode
    }


viewHexes : ViewHexesConfig -> Html Msg
viewHexes config =
    let
        renderCurrentAddressOutline : HexAddress -> Svg Msg
        renderCurrentAddressOutline ca =
            let
                locationOrigin =
                    calcVisualOrigin config.hexSize
                        { row = ca.y, col = ca.x }
                        |> Tuple.mapBoth toFloat toFloat

                pointsStr =
                    hexagonPoints locationOrigin config.hexSize
                        |> String.join " "
            in
            Svg.polygon
                [ points pointsStr
                , SvgAttrs.fill "none"
                , SvgAttrs.stroke currentAddressHexBg
                , SvgAttrs.strokeWidth "3"
                , SvgAttrs.pointerEvents "none"
                ]
                []

        hexRange =
            HexAddress.betweenWithMax
                (HexAddress.shiftAddressBy { deltaX = -1, deltaY = -1 } config.hexRect.upperLeftHex)
                config.hexRect.lowerRightHex
                { maxAcross = config.maxAcross, maxTall = config.maxTall }

        computeHexColour : HexAddress -> String -> String
        computeHexColour hexAddr hexKey =
            if hexAddr == config.currentAddress then
                currentAddressHexBg

            else if config.showJumpLogFill && isOnRoute config.route hexAddr then
                routeHexBg

            else
                let
                    regionFill =
                        case config.regionDisplay of
                            ShowRegionsFill ->
                                Dict.get hexKey config.hexColours

                            ShowRegionsBoth ->
                                Dict.get hexKey config.hexColours

                            _ ->
                                Nothing
                in
                case regionFill of
                    Just color ->
                        Color.Convert.colorToHex color

                    Nothing ->
                        case config.maybeSelectedHex of
                            Just selectedHex ->
                                if selectedHex == hexAddr then
                                    selectedHexBg

                                else
                                    hexBackgroundColour config.displayMode config.themeIsLight config.isReferee hexKey config.solarSystemDict

                            Nothing ->
                                hexBackgroundColour config.displayMode config.themeIsLight config.isReferee hexKey config.solarSystemDict

        -- Survey Overlay's rule-highlight colour, rendered as its own SVG layer
        -- above the background-name watermark (see `keyedRuleOverlays`) rather
        -- than folded into `computeHexColour`'s base fill, so the highlight
        -- colour isn't obscured by the subsector/sector name text.
        ruleOverlayFill : String -> Maybe String
        ruleOverlayFill hexKey =
            HighlightRule.matchColour config.highlightRules
                (Dict.get hexKey config.solarSystemDict
                    |> Maybe.andThen
                        (\remote ->
                            case remote of
                                LoadedSolarSystem system ->
                                    Just system

                                _ ->
                                    Nothing
                        )
                )
                |> Maybe.map Color.Convert.colorToHex

        viewSingleHex hexAddr =
            let
                hexKey =
                    HexAddress.toKey hexAddr

                ( vox, voy ) =
                    calcVisualOrigin config.hexSize
                        { row = hexAddr.y, col = hexAddr.x }

                hexColour =
                    computeHexColour hexAddr hexKey
            in
            ( hexAddr
            , viewHex
                config.hexSize
                config.solarSystemDict
                hexAddr
                vox
                voy
                hexColour
                config.rawHexaPoints
                config.isReferee
                config.rogueObjectPathData
                config.facilityIcons
                config.displayMode
                config.themeIsLight
            )
    in
    hexRange
        |> List.map viewSingleHex
        |> (\hexSvgsWithHexAddress ->
                let
                    labelPos hexAddr =
                        calcVisualOrigin config.hexSize
                            { row = hexAddr.y, col = hexAddr.x }

                    renderRegionLabel : HexAddress -> Maybe (Svg.Svg msg)
                    renderRegionLabel hexAddress =
                        case config.regionDisplay of
                            HideRegions ->
                                Nothing

                            _ ->
                                config.regionLabels
                                    |> Dict.get (HexAddress.toKey hexAddress)
                                    |> Maybe.map
                                        (\name ->
                                            let
                                                ( x, y ) =
                                                    labelPos hexAddress
                                            in
                                            Html.Lazy.lazy3 regionLabel x y name
                                        )

                    labels =
                        hexRange
                            |> List.filterMap renderRegionLabel

                    viewHexSystemLabels hexAddr =
                        let
                            hexKey =
                                HexAddress.toKey hexAddr

                            ( vox, voy ) =
                                calcVisualOrigin config.hexSize
                                    { row = hexAddr.y, col = hexAddr.x }
                        in
                        case Dict.get hexKey config.solarSystemDict of
                            Just (LoadedSolarSystem loadedSystem) ->
                                renderHexSystemLabels
                                    { starSystem = loadedSystem
                                    , hexColour = computeHexColour hexAddr hexKey
                                    , hexAddrX = hexAddr.x
                                    , hexAddrY = hexAddr.y
                                    , vox = vox
                                    , voy = voy
                                    , size = config.hexSize
                                    , hexapointsStr = ""
                                    , isReferee = config.isReferee
                                    , facilityIcons = config.facilityIcons
                                    , displayMode = config.displayMode
                                    , themeIsLight = config.themeIsLight
                                    }

                            _ ->
                                Svg.text ""

                    systemLabels =
                        hexRange |> List.map viewHexSystemLabels
                in
                ( hexSvgsWithHexAddress, labels, systemLabels )
           )
        |> (\( hexSvgsWithHexAddress, labels, systemLabels ) ->
                let
                    singlePolyHex =
                        renderCurrentAddressOutline config.currentAddress

                    keyedHexBackgrounds : Svg Msg
                    keyedHexBackgrounds =
                        hexSvgsWithHexAddress
                            |> List.map
                                (\( addr, ( bg, _ ) ) ->
                                    ( HexAddress.toKey addr, bg )
                                )
                            |> Svg.Keyed.node "g" []

                    keyedHexBorders : Svg Msg
                    keyedHexBorders =
                        hexRange
                            |> List.map
                                (\hexAddr ->
                                    let
                                        ( vox, voy ) =
                                            calcVisualOrigin config.hexSize { row = hexAddr.y, col = hexAddr.x }

                                        hexapointsStr =
                                            convertRawHexagonPoints ( toFloat vox, toFloat voy ) config.rawHexaPoints
                                    in
                                    ( HexAddress.toKey hexAddr
                                    , Svg.Lazy.lazy renderHexBorderStroke hexapointsStr
                                    )
                                )
                            |> Svg.Keyed.node "g" [ SvgAttrs.pointerEvents "none" ]

                    keyedRuleOverlays : Svg Msg
                    keyedRuleOverlays =
                        hexRange
                            |> List.filterMap
                                (\hexAddr ->
                                    let
                                        hexKey =
                                            HexAddress.toKey hexAddr
                                    in
                                    ruleOverlayFill hexKey
                                        |> Maybe.map
                                            (\fillColour ->
                                                let
                                                    ( vox, voy ) =
                                                        calcVisualOrigin config.hexSize { row = hexAddr.y, col = hexAddr.x }

                                                    hexapointsStr =
                                                        convertRawHexagonPoints ( toFloat vox, toFloat voy ) config.rawHexaPoints
                                                in
                                                ( hexKey
                                                , Svg.polygon
                                                    [ SvgAttrs.points hexapointsStr
                                                    , SvgAttrs.fill fillColour
                                                    , SvgAttrs.pointerEvents "none"
                                                    ]
                                                    []
                                                )
                                            )
                                )
                            |> Svg.Keyed.node "g" [ SvgAttrs.pointerEvents "none" ]

                    keyedHexForegrounds : Svg Msg
                    keyedHexForegrounds =
                        hexSvgsWithHexAddress
                            |> List.map
                                (\( addr, ( _, fg ) ) ->
                                    ( HexAddress.toKey addr, fg )
                                )
                            |> Svg.Keyed.node "g" [ SvgAttrs.pointerEvents "none" ]
                in
                let
                    ulSector =
                        HexAddress.toSectorAddress config.hexRect.upperLeftHex

                    lrSector =
                        HexAddress.toSectorAddress config.hexRect.lowerRightHex

                    sectorOutlines =
                        if config.showSectorLines then
                            List.range (min ulSector.sectorX lrSector.sectorX) (max ulSector.sectorX lrSector.sectorX)
                                |> List.concatMap
                                    (\sx ->
                                        List.range (min ulSector.sectorY lrSector.sectorY) (max ulSector.sectorY lrSector.sectorY)
                                            |> List.map
                                                (\sy ->
                                                    renderSectorOutline config.hexSize { ulSector | sectorX = sx, sectorY = sy }
                                                )
                                    )

                        else
                            []

                    subsectorLinesList =
                        if config.showSubsectorLines then
                            List.range (min ulSector.sectorX lrSector.sectorX) (max ulSector.sectorX lrSector.sectorX)
                                |> List.concatMap
                                    (\sx ->
                                        List.range (min ulSector.sectorY lrSector.sectorY) (max ulSector.sectorY lrSector.sectorY)
                                            |> List.concatMap
                                                (\sy ->
                                                    renderSubsectorLines config.hexSize { ulSector | sectorX = sx, sectorY = sy }
                                                )
                                    )

                        else
                            []

                    backgroundNameLabels =
                        if not config.showBackgroundNames || config.hexSize > maxHexSizeForBackgroundNames then
                            []

                        else
                            let
                                nonBlank str =
                                    if String.trim str == "" then
                                        Nothing

                                    else
                                        Just str

                                -- A subsector still has its default generated name if it's
                                -- blank or just its grid letter (A, B, C, ... P) - not a name
                                -- a referee has actually given it.
                                isNamedSubsector sub =
                                    case sub.name |> Maybe.andThen nonBlank of
                                        Nothing ->
                                            False

                                        Just name ->
                                            String.length (String.trim name) > 1

                                subsectorFontSize =
                                    round (config.hexSize * 2.2)

                                sectorFontSize =
                                    round (toFloat subsectorFontSize * 2.5)

                                labelsForSector sx sy =
                                    let
                                        hex =
                                            { ulSector | sectorX = sx, sectorY = sy }
                                    in
                                    case Dict.get (HexAddress.toSectorKey hex) config.sectors of
                                        Nothing ->
                                            []

                                        Just sector ->
                                            if not (List.any isNamedSubsector sector.subsectors) then
                                                case nonBlank sector.name of
                                                    Nothing ->
                                                        []

                                                    Just name ->
                                                        let
                                                            ( cx, cy ) =
                                                                sectorCellCenterPixel config.hexSize hex { x = 0, y = 0 } { x = 32, y = 40 }
                                                        in
                                                        [ backgroundNameLabel config.themeIsLight sectorFontSize cx cy name ]

                                            else
                                                List.range 1 4
                                                    |> List.concatMap
                                                        (\subCol ->
                                                            List.range 1 4
                                                                |> List.filterMap
                                                                    (\subRow ->
                                                                        sector.subsectors
                                                                            |> List.filter (\s -> s.x == subCol && s.y == subRow && isNamedSubsector s)
                                                                            |> List.head
                                                                            |> Maybe.andThen .name
                                                                            |> Maybe.andThen nonBlank
                                                                            |> Maybe.map
                                                                                (\name ->
                                                                                    let
                                                                                        ( cx, cy ) =
                                                                                            sectorCellCenterPixel config.hexSize
                                                                                                hex
                                                                                                { x = (subCol - 1) * 8, y = (subRow - 1) * 10 }
                                                                                                { x = subCol * 8, y = subRow * 10 }
                                                                                    in
                                                                                    backgroundNameLabel config.themeIsLight subsectorFontSize cx cy name
                                                                                )
                                                                    )
                                                        )
                            in
                            List.range (min ulSector.sectorX lrSector.sectorX) (max ulSector.sectorX lrSector.sectorX)
                                |> List.concatMap
                                    (\sx ->
                                        List.range (min ulSector.sectorY lrSector.sectorY) (max ulSector.sectorY lrSector.sectorY)
                                            |> List.concatMap (\sy -> labelsForSector sx sy)
                                    )
                in
                let
                    hexEdgeNeighbours : HexAddress -> List HexAddress
                    hexEdgeNeighbours { x, y } =
                        if modBy 2 x == 0 then
                            [ { x = x + 1, y = y }
                            , { x = x, y = y - 1 }
                            , { x = x - 1, y = y }
                            , { x = x - 1, y = y + 1 }
                            , { x = x, y = y + 1 }
                            , { x = x + 1, y = y + 1 }
                            ]

                        else
                            [ { x = x + 1, y = y - 1 }
                            , { x = x, y = y - 1 }
                            , { x = x - 1, y = y - 1 }
                            , { x = x - 1, y = y }
                            , { x = x, y = y + 1 }
                            , { x = x + 1, y = y }
                            ]

                    renderBorderRegion : Region -> Maybe (Svg Msg)
                    renderBorderRegion region =
                        case region.borderColour of
                            Nothing ->
                                Nothing

                            Just colour ->
                                let
                                    borderSet =
                                        region.hexes
                                            |> List.map HexAddress.toKey
                                            |> Set.fromList

                                    edgesFor : HexAddress -> List ( ( Float, Float ), ( Float, Float ) )
                                    edgesFor hexAddr =
                                        let
                                            ( vox, voy ) =
                                                calcVisualOrigin config.hexSize { row = hexAddr.y, col = hexAddr.x }

                                            verts =
                                                config.rawHexaPoints
                                                    |> List.map (\( dx, dy ) -> ( toFloat vox + dx, toFloat voy + dy ))

                                            vertPairs =
                                                case verts of
                                                    first :: _ ->
                                                        List.map2 Tuple.pair verts (List.drop 1 verts ++ [ first ])

                                                    [] ->
                                                        []

                                            neighbours =
                                                hexEdgeNeighbours hexAddr
                                        in
                                        List.map2 Tuple.pair vertPairs neighbours
                                            |> List.filterMap
                                                (\( edgePair, neighbour ) ->
                                                    if Set.member (HexAddress.toKey neighbour) borderSet then
                                                        Nothing

                                                    else
                                                        Just edgePair
                                                )

                                    lines =
                                        region.borderHexes |> List.concatMap edgesFor
                                in
                                Just
                                    (Svg.g
                                        [ SvgAttrs.stroke (Color.Convert.colorToHex colour)
                                        , SvgAttrs.strokeWidth "2.5"
                                        , SvgAttrs.strokeLinecap "round"
                                        , SvgAttrs.fill "none"
                                        , SvgAttrs.pointerEvents "none"
                                        ]
                                        (List.map
                                            (\( ( x1, y1 ), ( x2, y2 ) ) ->
                                                Svg.line
                                                    [ SvgAttrs.x1 (String.fromFloat x1)
                                                    , SvgAttrs.y1 (String.fromFloat y1)
                                                    , SvgAttrs.x2 (String.fromFloat x2)
                                                    , SvgAttrs.y2 (String.fromFloat y2)
                                                    ]
                                                    []
                                            )
                                            lines
                                        )
                                    )

                    regionBorderLines =
                        case config.regionDisplay of
                            HideRegions ->
                                []

                            ShowRegionsFill ->
                                []

                            _ ->
                                config.regions |> Dict.values |> List.filterMap renderBorderRegion
                in
                let
                    visibleLinks =
                        List.filter
                            (\link ->
                                (config.isReferee
                                    || link.known
                                    || (link.routeType
                                            == "network"
                                            && (link.fromSurveyIndex >= 10 || link.toSurveyIndex >= 10)
                                       )
                                )
                                    && not (Set.member link.jumpRouteId config.hiddenJumpRouteIds)
                            )
                            config.jumpRouteLinks

                    jumpRouteLinkLines =
                        List.map
                            (\link ->
                                let
                                    ( fx, fy ) =
                                        calcVisualOrigin config.hexSize { row = link.fromY, col = link.fromX }

                                    ( tx, ty ) =
                                        calcVisualOrigin config.hexSize { row = link.toY, col = link.toX }
                                in
                                Svg.line
                                    [ SvgAttrs.x1 (String.fromInt fx)
                                    , SvgAttrs.y1 (String.fromInt fy)
                                    , SvgAttrs.x2 (String.fromInt tx)
                                    , SvgAttrs.y2 (String.fromInt ty)
                                    , SvgAttrs.stroke link.colour
                                    , SvgAttrs.strokeWidth (String.fromInt link.lineWidth)
                                    , SvgAttrs.strokeDasharray link.strokeDasharray
                                    , SvgAttrs.strokeOpacity "0.7"
                                    , SvgAttrs.strokeLinecap "round"
                                    , SvgAttrs.pointerEvents "none"
                                    ]
                                    []
                            )
                            visibleLinks

                    -- width "8" and dasharray "16,10" mirror JumpRoute's plotted-route
                    -- save defaults (line_width: 8, line_style: 'dashed'), so the preview
                    -- doesn't change appearance the moment it's saved - only the colour differs.
                    previewRouteLines =
                        case config.previewRoute of
                            Nothing ->
                                []

                            Just { hops, colour } ->
                                let
                                    coords =
                                        List.map (\hop -> ( hop.system.x, hop.system.y )) hops
                                in
                                List.map2
                                    (\( fromX, fromY ) ( toX, toY ) ->
                                        let
                                            ( fx, fy ) =
                                                calcVisualOrigin config.hexSize { row = fromY, col = fromX }

                                            ( tx, ty ) =
                                                calcVisualOrigin config.hexSize { row = toY, col = toX }
                                        in
                                        Svg.line
                                            [ SvgAttrs.x1 (String.fromInt fx)
                                            , SvgAttrs.y1 (String.fromInt fy)
                                            , SvgAttrs.x2 (String.fromInt tx)
                                            , SvgAttrs.y2 (String.fromInt ty)
                                            , SvgAttrs.stroke colour
                                            , SvgAttrs.strokeWidth "8"
                                            , SvgAttrs.strokeDasharray "16,10"
                                            , SvgAttrs.strokeOpacity "0.7"
                                            , SvgAttrs.strokeLinecap "round"
                                            , SvgAttrs.pointerEvents "none"
                                            ]
                                            []
                                    )
                                    coords
                                    (List.drop 1 coords)
                in
                [ Svg.defs []
                    [ Svg.node "clipPath"
                        [ SvgAttrs.id "planet-hex-clip"
                        , HtmlAttrs.attribute "clipPathUnits" "objectBoundingBox"
                        ]
                        [ Svg.circle [ SvgAttrs.cx "0.5", SvgAttrs.cy "0.5", SvgAttrs.r "0.5" ] [] ]
                    ]
                ]
                    ++ [ keyedHexBackgrounds ]
                    ++ backgroundNameLabels
                    ++ [ keyedRuleOverlays ]
                    ++ [ keyedHexBorders ]
                    ++ [ singlePolyHex ]
                    ++ [ Svg.g [ SvgAttrs.pointerEvents "none" ] jumpRouteLinkLines ]
                    ++ [ Svg.g [ SvgAttrs.pointerEvents "none" ] previewRouteLines ]
                    ++ [ keyedHexForegrounds ]
                    ++ subsectorLinesList
                    ++ sectorOutlines
                    ++ regionBorderLines
                    ++ [ Svg.g [ SvgAttrs.pointerEvents "none", SvgAttrs.style "transform: translateZ(0)" ] systemLabels ]
                    ++ labels
           )
        |> (let
                widthString =
                    String.fromFloat <| config.svgWidth

                heightString =
                    String.fromFloat <| config.svgHeight
            in
            Svg.svg
                [ SvgAttrs.width <| widthString
                , SvgAttrs.height <| heightString
                , SvgAttrs.id "hexmap"
                , SvgEvents.on "mouseleave" (JsDecode.succeed MapMouseLeave)
                , Html.Events.preventDefaultOn "wheel"
                    (JsDecode.map (\dy -> ( HexMapWheelZoom dy, True )) (JsDecode.field "deltaY" JsDecode.float))
                , viewBox <|
                    toViewBox config.hexSize config.hexRect.upperLeftHex config.panOffset
                        ++ " "
                        ++ widthString
                        ++ " "
                        ++ heightString
                ]
           )


toViewBox : Float -> HexAddress -> { x : Float, y : Float } -> String
toViewBox hexScale { x, y } panOffset =
    calcVisualOrigin hexScale { col = x, row = y }
        |> (\( x_, y_ ) ->
                String.fromFloat (toFloat x_ + panOffset.x)
                    ++ " "
                    ++ String.fromFloat (toFloat y_ + panOffset.y)
           )


uwpBreakdown : UWP -> List ( String, String )
uwpBreakdown uwp =
    [ ( "Starport", Starport.description uwp.starport )
    , ( "Size", sizeDescription uwp.size )
    , ( "Atmosphere", atmosphereDescription uwp.atmosphere )
    , ( "Hydrosphere", hydrosphereDescription uwp.hydrosphere )
    , ( "Population", populationDescription uwp.population )
    , ( "Government", Government.description uwp.government )
    , ( "Law level", LawLevel.description uwp.lawLevel )
    , ( "Tech level", TechLevel.description uwp.techLevel )
    ]


uwpExplainer : String -> Element.Element Msg
uwpExplainer uwpString =
    let
        parsedUWP =
            Parser.run uwp uwpString
    in
    case parsedUWP of
        Ok theUWP ->
            column
                [ bgVar "--color-panel-muted"
                , Element.width <| Element.px 300
                , Element.moveDown 20
                , Element.padding 1
                , Border.rounded 3
                , Border.widthEach { zeroEach | top = 2 }
                , borderVar "--color-button-primary"
                , Border.glow (Element.rgba255 0 0 0 100) 6
                , fontVar "--color-fg-bright"
                , Font.shadow
                    { offset = ( 1, 1 )
                    , blur = 1
                    , color = Element.rgb 0 0 0
                    }
                ]
                [ Element.table [ Element.spacing 4 ]
                    { columns =
                        [ { header = Element.text "", width = Element.shrink, view = \u -> text <| Tuple.first u }
                        , { header = Element.text "", width = Element.fill, view = \u -> Element.paragraph [] [ text <| Tuple.second u ] }
                        ]
                    , data = uwpBreakdown theUWP
                    }
                ]

        _ ->
            text ("Could not parse " ++ uwpString)


universalHexLabel : SectorDict -> HexAddress -> String
universalHexLabel sectors hexAddress =
    case Dict.get (HexAddress.toSectorKey <| HexAddress.toSectorAddress hexAddress) sectors of
        Nothing ->
            " "

        Just sector ->
            sector.name ++ " " ++ HexAddress.hexLabel hexAddress


universalHexLabelMaybe : SectorDict -> HexAddress -> Maybe String
universalHexLabelMaybe sectors hexAddress =
    sectors
        |> Dict.get (HexAddress.toSectorKey <| HexAddress.toSectorAddress hexAddress)
        |> Maybe.map (\sector -> sector.name ++ " " ++ HexAddress.hexLabel hexAddress)


errorDialog : List ( Http.Error, String ) -> Html Msg
errorDialog httpErrors =
    let
        openAttr =
            if (not << List.isEmpty) httpErrors then
                HtmlAttrs.attribute "open" "open"

            else
                HtmlAttrs.classList []

        errorButton { onPress, label } =
            Input.button
                [ Element.width <| Element.px 100
                , Border.width 2
                , Border.rounded 10
                , Element.padding 10
                , Element.htmlAttribute (HtmlAttrs.class "starmap-error-btn")
                ]
                { onPress = onPress, label = el [ centerX ] <| text label }

        pluralize n singular plural =
            if n == 1 then
                singular

            else
                plural

        renderError ( httpError, url ) =
            column []
                [ -- clickable url
                  Element.link []
                    { url = url
                    , label =
                        el
                            [ Element.htmlAttribute (HtmlAttrs.class "starmap-error-link")
                            , Font.italic
                            , fontVar "--color-fg-muted"
                            ]
                        <|
                            monospaceText url
                    }
                , case httpError of
                    Http.BadBody error ->
                        Element.textColumn []
                            [ monospaceText "JSON Decode Error:"
                            , monospaceText error
                            ]

                    Http.BadUrl url_ ->
                        text <| "Invalid URL: " ++ url_

                    Http.NetworkError ->
                        text "Network Error"

                    Http.BadStatus statusCode ->
                        text <| "BadStatus: " ++ String.fromInt statusCode

                    Http.Timeout ->
                        text "Request timedout"
                ]
    in
    Html.node "dialog"
        [ openAttr ]
        [ Element.layoutWith { options = [ Element.noStaticStyleSheet ] }
            [ Element.centerX
            , width fill
            ]
          <|
            column
                [ Element.height <| Element.minimum 500 <| Element.fill
                , Element.width <| Element.minimum 500 <| Element.fill
                , fontVar "--color-fg-bright"
                , Element.scrollbars
                , Element.spacing 10
                ]
                [ -- header
                  el [ centerX, Font.size 24, Font.underline, Element.padding 10 ] <|
                    let
                        errorCount =
                            List.length httpErrors
                    in
                    text <|
                        pluralize
                            errorCount
                            "One Error!"
                            ("Many errors! (" ++ String.fromInt errorCount ++ " of 'em)")
                , -- error renderer
                  column
                    [ Element.spacing 10
                    , Element.height <| Element.minimum 100 <| Element.fill
                    , width fill
                    , Element.scrollbars
                    , Font.size 16
                    ]
                  <|
                    List.map renderError httpErrors
                , --buttons
                  row [ centerX, Element.spacing 10 ]
                    [ errorButton { onPress = Just ClearAllErrors, label = "Close" }
                    ]
                ]
        ]


faIcon : String -> Int -> Html Msg
faIcon icon size =
    Html.i
        [ HtmlAttrs.style "font-size" (String.fromInt size ++ "px"), HtmlAttrs.class icon ]
        []


type alias HexRect =
    { upperLeftHex : HexAddress, lowerRightHex : HexAddress }


type alias XY a =
    { x : a, y : a }


toXY : ( a, a ) -> XY a
toXY ( left, right ) =
    { x = left, y = right }


type alias ImageSize =
    { width : Float, height : Float }


mouseCoordsToSector : XY Float -> XY Float -> ImageSize -> XY Int
mouseCoordsToSector mousePos offset imageSize =
    let
        ( sectorsAcross, sectorsTall ) =
            ( 17, 14 )

        ( correctedX, correctedY ) =
            let
                ( officialX, officialY ) =
                    ( -21, -2 )

                ( oursX, oursY ) =
                    ( 5, 1 )
            in
            ( officialX - oursX, officialY + oursY )

        ( sectorX, sectorY ) =
            ( (mousePos.x - offset.x) / (imageSize.width / sectorsAcross)
            , (mousePos.y - offset.y) / (imageSize.height / sectorsTall)
            )
    in
    { x = correctedX + floor sectorX, y = correctedY - floor sectorY }


viewFullJourney : Maybe String -> JourneyModel -> Browser.Dom.Viewport -> Element.Element Msg
viewFullJourney allSectorsMapUrl model viewport =
    let
        dims =
            journeyDimensions viewport.viewport

        ( imageSizeWidth, imageSizeHeight ) =
            ( dims.fittedW * model.zoomScale
            , dims.fittedH * model.zoomScale
            )

        ( offsetLeft, offsetTop ) =
            model.zoomOffset
    in
    el
        [ Element.alignTop
        , width <| Element.px <| floor dims.containerW
        , height <| Element.px <| floor dims.containerH
        , Element.clip
        , Element.htmlAttribute <| Html.Events.on "mousemove" <| mouseOffsetPosMoveDecoder (JourneyMsg << MouseMove)
        , Element.htmlAttribute <| Html.Events.on "mousedown" <| journeyMouseDownDecoder (JourneyMsg << MouseDown)
        , Element.htmlAttribute <| Html.Events.on "mouseup" <| journeyMouseUpDecoder (JourneyMsg << MouseUp)
        , Events.onMouseLeave (JourneyMsg MouseLeave)
        , Element.htmlAttribute <|
            Html.Events.preventDefaultOn "wheel" <|
                JsDecode.map (\dy -> ( JourneyMsg (WheelZoom dy), True )) (JsDecode.field "deltaY" JsDecode.float)
        , Background.color <| Element.rgb 0.0 0.0 0.0
        ]
    <|
        Element.image
            [ width <| Element.px <| floor <| imageSizeWidth
            , height <| Element.px <| floor <| imageSizeHeight
            , Element.moveRight <| offsetLeft
            , Element.moveDown <| offsetTop
            , pointerEventsNone
            , userSelectNone
            , case model.hoverPoint of
                Just ( hovX, hovY ) ->
                    Element.inFront <|
                        let
                            ( sectorsAcross, sectorsTall ) =
                                ( 17, 14 )

                            ( correctedX, correctedY ) =
                                let
                                    ( officialX, officialY ) =
                                        ( -21, -2 )

                                    ( oursX, oursY ) =
                                        ( 3, 2 )
                                in
                                ( officialX - oursX, officialY + oursY )

                            ( sectorX, sectorY ) =
                                ( (hovX - offsetLeft) / (imageSizeWidth / sectorsAcross)
                                , (hovY - offsetTop) / (imageSizeHeight / sectorsTall)
                                )

                            ( xoff, yoff ) =
                                ( (toFloat <| floor sectorX)
                                    * (imageSizeWidth / sectorsAcross)
                                , (toFloat <| floor sectorY)
                                    * (imageSizeHeight / sectorsTall)
                                )
                        in
                        Element.el
                            [ Element.moveRight xoff
                            , Element.moveDown yoff
                            , userSelectNone
                            , pointerEventsNone
                            , Font.size 14
                            ]
                        <|
                            text <|
                                "Sector: "
                                    ++ String.fromInt (correctedX + floor sectorX)
                                    ++ ", "
                                    ++ String.fromInt (correctedY - floor sectorY)

                Nothing ->
                    noopAttribute
            ]
            { src = allSectorsMapUrl |> Maybe.withDefault "/images/uncharted-space.png", description = "Full Journey Map" }


pointerEventsNone =
    Element.htmlAttribute <| HtmlAttrs.style "pointer-events" "none"


userSelectNone =
    Element.htmlAttribute <| HtmlAttrs.style "user-select" "none"


{-| Element attribute that does nothing
-}
noopAttribute : Element.Attribute msg
noopAttribute =
    Element.htmlAttribute <| HtmlAttrs.style "" ""


conditionalAttribute : Bool -> Element.Attribute msg -> Element.Attribute msg
conditionalAttribute condition attribute =
    if condition then
        attribute

    else
        noopAttribute


fitHexScaleForGrid : Maybe HexMapViewport -> Int -> Int -> Float
fitHexScaleForGrid hexmapViewport gridW gridH =
    case hexmapViewport of
        Just (Ok vp) ->
            clamp minHexSize
                maxHexSize
                (min
                    (vp.viewport.width / (toFloat gridW * hexWidth 1.0))
                    (vp.viewport.height / (toFloat gridH * hexHeight 1.0))
                )

        _ ->
            defaultHexSize


searchNavigation : SearchResult -> ModelData -> Maybe ( HexAddress, Maybe Float )
searchNavigation result model =
    case result.resultType of
        "StarSystem" ->
            Maybe.map2 (\x y -> ( { x = x, y = y }, Nothing )) result.x result.y

        "Sector" ->
            Maybe.map2
                (\sx sy ->
                    ( { x = sx * 32 + 16, y = sy * 40 - 20 }
                    , Just (fitHexScaleForGrid model.viewport.hexmapViewport 32 40)
                    )
                )
                result.sectorX
                result.sectorY

        "Subsector" ->
            Maybe.map4
                (\sx sy subX subY ->
                    let
                        ulX =
                            sx * 32 + (subX - 1) * 8

                        ulY =
                            sy * 40 - (subY - 1) * 10
                    in
                    ( { x = ulX + 4, y = ulY - 5 }
                    , Just (fitHexScaleForGrid model.viewport.hexmapViewport 8 10)
                    )
                )
                result.sectorX
                result.sectorY
                result.subsectorX
                result.subsectorY

        _ ->
            Maybe.map2 (\x y -> ( { x = x, y = y }, Nothing )) result.x result.y


viewSearchField : ModelData -> List (Html Msg)
viewSearchField model =
    if model.viewMode /= HexMap then
        []

    else
        [ Html.div
            [ HtmlAttrs.id "starmap-search"
            , HtmlAttrs.style "position" "relative"
            ]
            [ Html.input
                [ HtmlAttrs.type_ "text"
                , HtmlAttrs.value model.searchState.query
                , HtmlAttrs.placeholder "Search… [/]"
                , HtmlAttrs.style "width" "220px"
                , HtmlAttrs.style "font-size" "13px"
                , HtmlAttrs.style "color" "var(--color-fg-bright)"
                , HtmlAttrs.style "background-color" "var(--color-panel)"
                , HtmlAttrs.style "border" "1px solid var(--color-outline)"
                , HtmlAttrs.style "border-radius" "4px"
                , HtmlAttrs.style "padding" "6px"
                , Html.Events.onInput SearchInput
                , Html.Events.stopPropagationOn "keydown"
                    (JsDecode.field "key" JsDecode.string
                        |> JsDecode.map
                            (\k ->
                                if k == "Escape" then
                                    ( CloseSearchDropdown, True )

                                else
                                    ( NoOpMsg, True )
                            )
                    )
                ]
                []
            , if model.searchState.dropdownOpen then
                viewSearchDropdown model.searchState

              else
                Html.text ""
            ]
        ]


viewSearchDropdown : SearchState -> Html Msg
viewSearchDropdown searchState =
    Html.div
        [ HtmlAttrs.class "starmap-glass-panel"
        , HtmlAttrs.style "position" "absolute"
        , HtmlAttrs.style "top" "100%"
        , HtmlAttrs.style "left" "0"
        , HtmlAttrs.style "margin-top" "4px"
        , HtmlAttrs.style "border-radius" "4px"
        , HtmlAttrs.style "width" "340px"
        , HtmlAttrs.style "padding" "4px"
        , HtmlAttrs.style "z-index" "100"
        ]
        [ case searchState.results of
            RemoteData.Loading ->
                Html.div
                    [ HtmlAttrs.style "font-size" "12px", HtmlAttrs.style "color" "var(--color-fg-muted)", HtmlAttrs.style "padding" "8px" ]
                    [ Html.text "Searching…" ]

            RemoteData.Success [] ->
                Html.div
                    [ HtmlAttrs.style "font-size" "12px", HtmlAttrs.style "color" "var(--color-fg-muted)", HtmlAttrs.style "padding" "8px" ]
                    [ Html.text "No matches" ]

            RemoteData.Success results ->
                Html.div
                    [ HtmlAttrs.style "display" "flex", HtmlAttrs.style "flex-direction" "column", HtmlAttrs.style "gap" "2px" ]
                    (List.map viewSearchResultRow results)

            RemoteData.Failure _ ->
                Html.div
                    [ HtmlAttrs.style "font-size" "12px", HtmlAttrs.style "color" "var(--color-danger)", HtmlAttrs.style "padding" "8px" ]
                    [ Html.text "Search failed" ]

            RemoteData.NotAsked ->
                Html.text ""
        ]


viewSearchResultRow : SearchResult -> Html Msg
viewSearchResultRow result =
    Html.div
        [ HtmlAttrs.style "padding" "8px"
        , HtmlAttrs.style "cursor" "pointer"
        , HtmlAttrs.style "border-radius" "3px"
        , HtmlAttrs.class "starmap-search-result"
        , Html.Events.onMouseDown (SelectSearchResult result)
        ]
        [ Html.div [ HtmlAttrs.style "display" "flex", HtmlAttrs.style "align-items" "center", HtmlAttrs.style "gap" "8px" ]
            [ Html.span
                [ HtmlAttrs.style "font-size" "14px", HtmlAttrs.style "color" "var(--color-fg-bright)", HtmlAttrs.style "flex" "1" ]
                [ Html.text result.name ]
            , Html.span
                [ HtmlAttrs.style "font-size" "10px", HtmlAttrs.style "color" "var(--color-fg-muted)" ]
                [ Html.text (String.toUpper result.displayType) ]
            ]
        , Html.div
            [ HtmlAttrs.style "font-size" "12px", HtmlAttrs.style "color" "var(--color-fg-muted)", HtmlAttrs.style "margin-top" "3px" ]
            [ Html.text result.meta ]
        ]


{-| Built as a raw `Html` tree rather than elm-ui, for the same reason as
`HighlightRuleEditor.view` and `viewHighlightRulesMenuHtml`: elm-ui's layout
doesn't cooperate reliably with native controls (the search `<input>`) or
with the CSS `gap`-based spacing this row needs. The status bar is the
primary interaction surface on the starmap, so it's the natural next piece to
migrate as part of the ongoing move off elm-ui.
-}
viewStatusRow : ModelData -> Element.Element Msg
viewStatusRow model =
    Element.html (viewStatusRowHtml model)


navIconColour : String
navIconColour =
    "var(--color-fg)"


navIcon : { title : String, icon : String, onClick : Msg } -> Html Msg
navIcon opts =
    Html.span
        [ HtmlAttrs.class "starmap-icon-hover"
        , HtmlAttrs.style "color" navIconColour
        , HtmlAttrs.style "cursor" "pointer"
        , HtmlAttrs.style "display" "inline-flex"
        , HtmlAttrs.style "align-items" "center"
        , HtmlAttrs.title opts.title
        , Html.Events.onClick opts.onClick
        ]
        [ faIcon opts.icon 16 ]


viewStatusRowHtml : ModelData -> Html Msg
viewStatusRowHtml model =
    let
        displayModeLabel =
            case model.displayMode of
                ShowStars ->
                    ""

                ShowMainWorld ->
                    "Main World"

                ShowWTN ->
                    "WTN"

                ShowGWP ->
                    "GWP"

                ShowTradeCodes ->
                    "Trade Codes"

                ShowImportance ->
                    "Importance"

                ShowStrategic ->
                    "Strategic"

                ShowResource ->
                    "Resource"

                ShowTechLevel ->
                    "Tech Level"

                ShowHabitability ->
                    "Habitability"

                ShowGovernment ->
                    "Government"

        extras =
            case model.viewMode of
                HexMap ->
                    [ navIcon { title = "Zoom in", icon = "fa-regular fa-magnifying-glass-plus", onClick = SetHexSize (clamp minHexSize maxHexSize (model.hexScale * 1.1)) }
                    , navIcon { title = "Zoom out", icon = "fa-regular fa-magnifying-glass-minus", onClick = SetHexSize (clamp minHexSize maxHexSize (model.hexScale / 1.1)) }
                    , navIcon { title = "Refresh map", icon = "fa-regular fa-refresh", onClick = RefreshMap }
                    , if displayModeLabel /= "" then
                        Html.span [ HtmlAttrs.style "color" navIconColour, HtmlAttrs.style "font-size" "12px" ] [ Html.text displayModeLabel ]

                      else
                        Html.text ""
                    , Html.span
                        [ HtmlAttrs.style "color" navIconColour
                        , HtmlAttrs.style "font-family" "monospace"
                        , HtmlAttrs.style "font-size" "14px"
                        , HtmlAttrs.style "min-width" "10px"
                        ]
                        [ case model.hoveringHex of
                            Just hoveringHex ->
                                let
                                    hexLabel =
                                        universalHexLabel model.sectors hoveringHex

                                    displayText =
                                        case Dict.get (HexAddress.toKey hoveringHex) model.solarSystems of
                                            Just (LoadedSolarSystem system) ->
                                                if system.name /= "" then
                                                    system.name ++ " (" ++ hexLabel ++ ")"

                                                else
                                                    hexLabel

                                            _ ->
                                                hexLabel
                                in
                                Html.text displayText

                            Nothing ->
                                Html.text ""
                        ]
                    ]

                FullJourney ->
                    [ navIcon { title = "Zoom in", icon = "fa-regular fa-magnifying-glass-plus", onClick = JourneyMsg (Zoom ZoomIn) }
                    , navIcon { title = "Zoom out", icon = "fa-regular fa-magnifying-glass-minus", onClick = JourneyMsg (Zoom ZoomOut) }
                    ]

        viewModeIcon : ViewMode -> String -> Html Msg
        viewModeIcon targetMode iconName =
            let
                isActive =
                    model.viewMode == targetMode

                iconStyle =
                    if isActive then
                        "fa-regular"

                    else
                        "fa-thin"

                colour =
                    if isActive then
                        navIconColour

                    else
                        "var(--color-fg-muted)"
            in
            Html.span
                [ HtmlAttrs.class "starmap-icon-hover"
                , HtmlAttrs.style "color" colour
                , HtmlAttrs.style "cursor" "pointer"
                , HtmlAttrs.style "display" "inline-flex"
                , HtmlAttrs.style "align-items" "center"
                , Html.Events.onClick (SetViewMode targetMode)
                ]
                [ faIcon (iconStyle ++ " " ++ iconName) 16 ]

        backToRailsButton =
            if model.isReferee then
                [ navIcon { title = "Return to Rails app", icon = "fa-regular fa-house", onClick = GoToRailsApp } ]

            else
                []

        displaySettingsGear =
            if model.viewMode == HexMap then
                [ navIcon { title = "Map display settings", icon = "fa-regular fa-gear", onClick = ToggleDisplaySettings } ]

            else
                []

        themeSwatchIcon =
            [ Html.div [ HtmlAttrs.style "position" "relative" ]
                [ Html.span
                    [ HtmlAttrs.id "starmap-theme-toggle"
                    , HtmlAttrs.class "starmap-icon-hover"
                    , HtmlAttrs.style "color" navIconColour
                    , HtmlAttrs.style "cursor" "pointer"
                    , HtmlAttrs.style "display" "inline-flex"
                    , HtmlAttrs.style "align-items" "center"
                    , HtmlAttrs.title "Change theme"
                    , Html.Events.onClick ToggleThemeMenu
                    ]
                    [ faIcon "fa-regular fa-swatchbook" 16 ]
                , if model.showThemeMenu then
                    viewThemeMenuHtml model.themeOptions model.theme

                  else
                    Html.text ""
                ]
            ]

        highlightRulesIcon =
            if model.viewMode == HexMap then
                [ Html.div [ HtmlAttrs.style "position" "relative" ]
                    [ Html.span
                        [ HtmlAttrs.id "starmap-highlight-toggle"
                        , HtmlAttrs.class "starmap-icon-hover"
                        , HtmlAttrs.style "color" navIconColour
                        , HtmlAttrs.style "cursor" "pointer"
                        , HtmlAttrs.style "display" "inline-flex"
                        , HtmlAttrs.style "align-items" "center"
                        , HtmlAttrs.title "Survey Overlay"
                        , Html.Events.onClick ToggleHighlightRulesMenu
                        ]
                        [ faIcon "fa-regular fa-layer-group" 16 ]
                    , if model.showHighlightRulesMenu then
                        viewHighlightRulesMenuHtml model.highlightRules

                      else
                        Html.text ""
                    ]
                ]

            else
                []

        jumpRouteLayersIcon =
            if model.viewMode == HexMap then
                [ Html.div [ HtmlAttrs.style "position" "relative" ]
                    [ Html.span
                        [ HtmlAttrs.id "starmap-jump-route-layers-toggle"
                        , HtmlAttrs.class "starmap-icon-hover"
                        , HtmlAttrs.style "color" navIconColour
                        , HtmlAttrs.style "cursor" "pointer"
                        , HtmlAttrs.style "display" "inline-flex"
                        , HtmlAttrs.style "align-items" "center"
                        , HtmlAttrs.title "Jump Route Layers"
                        , Html.Events.onClick ToggleJumpRouteLayersMenu
                        ]
                        [ faIcon "fa-regular fa-route" 16 ]
                    , if model.showJumpRouteLayersMenu then
                        viewJumpRouteLayersMenuHtml model.jumpRouteLayers model.hiddenJumpRouteIds model.pendingDeleteJumpRouteId model.isReferee

                      else
                        Html.text ""
                    ]
                ]

            else
                []

        mapAreaText =
            case model.viewMode of
                HexMap ->
                    Html.div
                        [ HtmlAttrs.style "flex" "1"
                        , HtmlAttrs.style "text-align" "center"
                        , HtmlAttrs.style "color" navIconColour
                        , HtmlAttrs.style "font-size" "14px"
                        ]
                        [ Html.text <|
                            let
                                svgWidth =
                                    model.viewport.viewport.viewport.width

                                svgHeight =
                                    model.viewport.viewport.viewport.height - consoleTitleHeight

                                ( ulPX, ulPY ) =
                                    calcVisualOrigin model.hexScale
                                        { col = model.hexRect.upperLeftHex.x
                                        , row = model.hexRect.upperLeftHex.y
                                        }

                                vbx =
                                    toFloat ulPX + model.panOffset.x

                                vby =
                                    toFloat ulPY + model.panOffset.y

                                first =
                                    pixelToHexAddress model.hexScale vbx vby

                                last =
                                    pixelToHexAddress model.hexScale (vbx + svgWidth) (vby + svgHeight)
                            in
                            (universalHexLabelMaybe model.sectors first
                                |> Maybe.withDefault "???"
                            )
                                ++ " – "
                                ++ (universalHexLabelMaybe model.sectors last
                                        |> Maybe.withDefault "???"
                                   )
                        ]

                FullJourney ->
                    Html.div [ HtmlAttrs.style "flex" "1" ] []

        shipLocationDisplay =
            case model.viewMode of
                HexMap ->
                    [ Html.div
                        [ HtmlAttrs.style "color" navIconColour
                        , HtmlAttrs.style "font-size" "14px"
                        , HtmlAttrs.style "display" "flex"
                        , HtmlAttrs.style "align-items" "center"
                        , HtmlAttrs.style "gap" "5px"
                        , HtmlAttrs.style "cursor" "pointer"
                        , HtmlAttrs.class "starmap-icon-hover"
                        , Html.Events.onClick JumpToShip
                        ]
                        [ Html.text (model.ship |> Maybe.map .name |> Maybe.withDefault "Ship")
                        , faIcon "fa-regular fa-crosshairs-simple" 16
                        , Html.text
                            (universalHexLabelMaybe model.sectors model.currentAddress
                                |> Maybe.withDefault "???"
                            )
                        ]
                    ]

                FullJourney ->
                    []
    in
    Html.div
        [ HtmlAttrs.style "display" "flex"
        , HtmlAttrs.style "align-items" "center"
        , HtmlAttrs.style "gap" "8px"
        , HtmlAttrs.style "width" "100%"
        , HtmlAttrs.style "padding" "4px 8px 10px 0"
        ]
        ([ Html.span
            [ HtmlAttrs.style "font-size" "20px", HtmlAttrs.style "color" navIconColour, HtmlAttrs.style "padding-left" "8px" ]
            [ Html.text model.campaignName ]
         , viewModeIcon HexMap "fa-hexagon"
         , viewModeIcon FullJourney "fa-map"
         ]
            ++ backToRailsButton
            ++ viewSearchField model
            ++ extras
            ++ [ mapAreaText ]
            ++ shipLocationDisplay
            ++ highlightRulesIcon
            ++ jumpRouteLayersIcon
            ++ themeSwatchIcon
            ++ displaySettingsGear
        )


viewThemeMenuHtml : List ThemeOption -> String -> Html Msg
viewThemeMenuHtml options currentTheme =
    Html.div
        [ HtmlAttrs.class "starmap-glass-panel"
        , HtmlAttrs.id "starmap-theme-menu"
        , HtmlAttrs.style "position" "absolute"
        , HtmlAttrs.style "top" "100%"
        , HtmlAttrs.style "right" "0"
        , HtmlAttrs.style "margin-top" "4px"
        , HtmlAttrs.style "border-radius" "6px"
        , HtmlAttrs.style "width" "176px"
        , HtmlAttrs.style "padding" "4px 0"
        , HtmlAttrs.style "z-index" "100"
        ]
        (options
            |> List.map
                (\option ->
                    Html.div
                        [ HtmlAttrs.class "starmap-display-option"
                        , HtmlAttrs.style "display" "flex"
                        , HtmlAttrs.style "align-items" "center"
                        , HtmlAttrs.style "gap" "8px"
                        , HtmlAttrs.style "padding" "8px 16px"
                        , HtmlAttrs.style "cursor" "pointer"
                        , HtmlAttrs.style "font-size" "13px"
                        , HtmlAttrs.style "color" "var(--color-fg)"
                        , Html.Events.onClick (SelectTheme option.key)
                        ]
                        [ Html.span [ HtmlAttrs.style "flex" "1" ] [ Html.text option.label ]
                        , if option.key == currentTheme then
                            Html.i
                                [ HtmlAttrs.class "fa-regular fa-check"
                                , HtmlAttrs.style "font-size" "12px"
                                , HtmlAttrs.style "color" navIconColour
                                ]
                                []

                          else
                            Html.text ""
                        ]
                )
        )


pickerData : ModelData -> HighlightRule.PickerData
pickerData model =
    { facilities = model.facilities
    , allegiances = model.allegianceOptions
    , sectors = model.sectorOptions
    , subsectors = model.subsectorOptions
    }


routePlanFormConfig : ModelData -> RoutePlanForm.Config
routePlanFormConfig model =
    { hostConfig = model.hostConfig
    , isReferee = model.isReferee
    , travelZoneOptions = model.travelZoneOptions
    }


jumpRouteLayerEditorConfig : ModelData -> JumpRouteLayerEditor.Config
jumpRouteLayerEditorConfig model =
    { hostConfig = model.hostConfig }


{-| Display colour for a player's locally-stored active route line - distinct
from both the default saved-route colour (`#E87040`) and any referee-chosen
colour, so a player's own plan is always recognisable regardless of what
routes a referee has published.
-}
playerRoutePlanColour : String
playerRoutePlanColour =
    "#3FB6FF"


{-| The route line currently drawn on the map for route-planning purposes:
the open form's live plan preview takes priority over the player's
previously-stored route, falling back to that stored route once the form is
closed (or has no successful plan yet). The preview uses the form's own
`saveColour` (default `#E87040`, matching `Api::RoutePlansController#save`'s
default) so the line never changes colour out from under the user the moment
they save - it just becomes the saved route.
-}
activePreviewRoute : ModelData -> Maybe { hops : List RoutePlan.Hop, colour : String }
activePreviewRoute model =
    case model.routePlanForm of
        Just form ->
            case RemoteData.toMaybe form.planResult of
                Just result ->
                    if result.found then
                        Just { hops = result.hops, colour = form.saveColour }

                    else
                        storedActiveRoute model

                Nothing ->
                    storedActiveRoute model

        Nothing ->
            storedActiveRoute model


storedActiveRoute : ModelData -> Maybe { hops : List RoutePlan.Hop, colour : String }
storedActiveRoute model =
    model.activeRoutePlan |> Maybe.map (\stored -> { hops = stored.result.hops, colour = stored.colour })


moveRule : String -> Int -> List HighlightRule.Rule -> List HighlightRule.Rule
moveRule ruleId delta rules =
    case List.Extra.findIndex (\r -> r.id == ruleId) rules of
        Just idx ->
            List.Extra.swapAt idx (idx + delta) rules

        Nothing ->
            rules


{-| Referee overlay ids are the `SurveyOverlay` row's real integer id (see
`HighlightRule.apiRulesDecoder`), stringified only because `Rule.id` is
shared with the player's locally-generated `"rule-N"` ids - this looks the
rule back up and parses its id back to an `Int` for API calls.
-}
findRuleWithId : String -> List HighlightRule.Rule -> Maybe ( Int, HighlightRule.Rule )
findRuleWithId ruleId rules =
    rules
        |> List.filter (\r -> r.id == ruleId)
        |> List.head
        |> Maybe.andThen (\r -> String.toInt r.id |> Maybe.map (\id -> ( id, r )))


{-| Built as a raw `Html` tree (rather than elm-ui `Element`s), for the same
reason as `HighlightRuleEditor.view`: the enabled toggle switch is a native
control, and elm-ui's spacing doesn't reliably apply around embedded native
elements.
-}
viewHighlightRulesMenuHtml : List HighlightRule.Rule -> Html Msg
viewHighlightRulesMenuHtml rules =
    let
        lastIdx =
            List.length rules - 1
    in
    Html.div
        [ HtmlAttrs.id "starmap-highlight-menu"
        , HtmlAttrs.class "starmap-glass-panel"
        , HtmlAttrs.style "position" "absolute"
        , HtmlAttrs.style "top" "100%"
        , HtmlAttrs.style "right" "0"
        , HtmlAttrs.style "margin-top" "4px"
        , HtmlAttrs.style "border-radius" "6px"
        , HtmlAttrs.style "width" "max-content"
        , HtmlAttrs.style "min-width" "260px"
        , HtmlAttrs.style "max-width" "360px"
        , HtmlAttrs.style "z-index" "100"
        , HtmlAttrs.style "padding" "4px 0"
        , HtmlAttrs.style "display" "flex"
        , HtmlAttrs.style "flex-direction" "column"
        ]
        ((if List.length rules > 1 then
            [ Html.div
                [ HtmlAttrs.class "text-xs text-fg-muted"
                , HtmlAttrs.style "padding" "4px 16px 8px"
                , HtmlAttrs.style "box-sizing" "border-box"
                , HtmlAttrs.style "width" "100%"
                , HtmlAttrs.style "white-space" "normal"
                , HtmlAttrs.style "overflow-wrap" "break-word"
                ]
                [ Html.text "Earlier overlays take precedence when more than one matches." ]
            ]

          else
            []
         )
            ++ List.indexedMap
                (\idx rule -> ruleRowHtml (idx == 0) (idx == lastIdx) rule)
                rules
            ++ [ newOverlayRowHtml ]
        )


ruleRowHtml : Bool -> Bool -> HighlightRule.Rule -> Html Msg
ruleRowHtml isFirst isLast rule =
    let
        moveButton attrs iconClass =
            Html.span
                (HtmlAttrs.style "font-size" "12px" :: attrs)
                [ Html.i [ HtmlAttrs.class iconClass ] [] ]
    in
    Html.div
        [ HtmlAttrs.class "starmap-display-option"
        , HtmlAttrs.style "display" "flex"
        , HtmlAttrs.style "align-items" "center"
        , HtmlAttrs.style "gap" "10px"
        , HtmlAttrs.style "padding" "8px 16px"
        , HtmlAttrs.style "cursor" "pointer"
        , Html.Events.onClick (StartEditRule rule.id)
        ]
        [ Html.span
            [ HtmlAttrs.style "display" "inline-block"
            , HtmlAttrs.style "width" "12px"
            , HtmlAttrs.style "height" "12px"
            , HtmlAttrs.style "flex-shrink" "0"
            , HtmlAttrs.style "border-radius" "6px"
            , HtmlAttrs.style "background-color" (Color.Convert.colorToHex rule.colour)
            ]
            []
        , ToggleSwitch.view ToggleSwitch.Small
            rule.enabled
            (Html.Events.stopPropagationOn "click" (JsDecode.succeed ( ToggleRuleEnabled rule.id, True )))
        , Html.span
            [ HtmlAttrs.class "text-sm text-fg"
            , HtmlAttrs.style "flex" "1"
            , HtmlAttrs.style "min-width" "0"
            , HtmlAttrs.style "white-space" "nowrap"
            , HtmlAttrs.style "overflow" "hidden"
            , HtmlAttrs.style "text-overflow" "ellipsis"
            ]
            [ Html.text rule.name ]
        , if isFirst then
            moveButton [ HtmlAttrs.class "text-fg-muted", HtmlAttrs.style "opacity" "0.3" ] "fa-regular fa-chevron-up"

          else
            moveButton
                [ HtmlAttrs.class "text-fg-muted cursor-pointer"
                , HtmlAttrs.title "Move up (higher precedence)"
                , Html.Events.stopPropagationOn "click" (JsDecode.succeed ( MoveRuleUp rule.id, True ))
                ]
                "fa-regular fa-chevron-up"
        , if isLast then
            moveButton [ HtmlAttrs.class "text-fg-muted", HtmlAttrs.style "opacity" "0.3" ] "fa-regular fa-chevron-down"

          else
            moveButton
                [ HtmlAttrs.class "text-fg-muted cursor-pointer"
                , HtmlAttrs.title "Move down (lower precedence)"
                , Html.Events.stopPropagationOn "click" (JsDecode.succeed ( MoveRuleDown rule.id, True ))
                ]
                "fa-regular fa-chevron-down"
        , Html.span
            [ HtmlAttrs.class "text-fg-muted cursor-pointer"
            , Html.Events.stopPropagationOn "click" (JsDecode.succeed ( RequestDeleteRule rule.id, True ))
            ]
            [ Html.i [ HtmlAttrs.class "fa-regular fa-trash", HtmlAttrs.style "font-size" "12px" ] [] ]
        ]


newOverlayRowHtml : Html Msg
newOverlayRowHtml =
    Html.button
        [ HtmlAttrs.type_ "button"
        , Html.Events.onClick StartNewRule
        , HtmlAttrs.class "starmap-display-option text-sm text-link no-underline hover:text-link-hover hover:underline hover:underline-offset-2 cursor-pointer bg-transparent border-0 text-left"
        , HtmlAttrs.style "width" "100%"
        , HtmlAttrs.style "padding" "8px 16px"
        ]
        [ Html.text "+ New Overlay" ]


{-| A confirmation modal for deleting a survey overlay, in the same visual
style as `HighlightRuleEditor.viewHtml` (fixed dimmed backdrop, centered
glass panel, backdrop click cancels). Replaces the old inline "Delete? ✓ ✕"
prompt that appeared in place of the trash icon within the dropdown row.
-}
viewDeleteRuleConfirmModal : HighlightRule.Rule -> Html Msg
viewDeleteRuleConfirmModal rule =
    Html.div
        [ HtmlAttrs.style "position" "fixed"
        , HtmlAttrs.style "inset" "0"
        , HtmlAttrs.style "z-index" "150"
        , HtmlAttrs.style "display" "flex"
        , HtmlAttrs.style "align-items" "center"
        , HtmlAttrs.style "justify-content" "center"
        , HtmlAttrs.style "background-color" "color-mix(in srgb, var(--color-bg) 30%, transparent)"
        , Html.Events.onClick CancelDeleteRule
        ]
        [ Html.div
            [ HtmlAttrs.class "starmap-glass-panel"
            , Html.Events.stopPropagationOn "click" (JsDecode.succeed ( NoOpMsg, True ))
            , HtmlAttrs.style "display" "flex"
            , HtmlAttrs.style "flex-direction" "column"
            , HtmlAttrs.style "gap" "16px"
            , HtmlAttrs.style "border-radius" "6px"
            , HtmlAttrs.style "box-shadow" "0 8px 32px rgba(0, 0, 0, 0.25)"
            , HtmlAttrs.style "padding" "20px"
            , HtmlAttrs.style "width" "100%"
            , HtmlAttrs.style "max-width" "360px"
            ]
            [ Html.span [ HtmlAttrs.class "text-sm text-fg-bright" ]
                [ Html.text ("Delete the survey overlay \"" ++ rule.name ++ "\"?") ]
            , Html.span [ HtmlAttrs.class "text-xs text-fg-muted" ]
                [ Html.text "This cannot be undone." ]
            , Html.div
                [ HtmlAttrs.style "display" "flex"
                , HtmlAttrs.style "gap" "8px"
                , HtmlAttrs.style "justify-content" "flex-end"
                ]
                [ Html.button
                    [ HtmlAttrs.type_ "button"
                    , HtmlAttrs.class "btn btn-sm"
                    , Html.Events.onClick CancelDeleteRule
                    ]
                    [ Html.text "Cancel" ]
                , Html.button
                    [ HtmlAttrs.type_ "button"
                    , HtmlAttrs.class "btn btn-danger btn-sm"
                    , Html.Events.onClick (DeleteRule rule.id)
                    ]
                    [ Html.text "Delete" ]
                ]
            ]
        ]


{-| The "Jump Route Layers" dropdown: lists every `JumpRoute`, with a toggle
switch that hides/shows that route's lines on this browser only (never
persisted server-side). Referees additionally get click-to-edit rows and a
two-step delete confirm; non-referees see a read-only list. Everyone gets the
trailing "+ Plan a Route…" row, which opens the Route Planner - the only way
to create a new jump route, whether a referee's hand-built network link or a
player's calculated path.
-}
viewJumpRouteLayersMenuHtml : List JumpRouteLayer.Route -> Set.Set Int -> Maybe Int -> Bool -> Html Msg
viewJumpRouteLayersMenuHtml routes hiddenIds pendingDeleteId isReferee =
    Html.div
        [ HtmlAttrs.id "starmap-jump-route-layers-menu"
        , HtmlAttrs.class "starmap-glass-panel"
        , HtmlAttrs.style "position" "absolute"
        , HtmlAttrs.style "top" "100%"
        , HtmlAttrs.style "right" "0"
        , HtmlAttrs.style "margin-top" "4px"
        , HtmlAttrs.style "border-radius" "6px"
        , HtmlAttrs.style "width" "280px"
        , HtmlAttrs.style "z-index" "100"
        , HtmlAttrs.style "padding" "4px 0"
        , HtmlAttrs.style "display" "flex"
        , HtmlAttrs.style "flex-direction" "column"
        ]
        ((if List.isEmpty routes then
            [ Html.div
                [ HtmlAttrs.class "text-xs text-fg-muted"
                , HtmlAttrs.style "padding" "8px 16px"
                ]
                [ Html.text "No jump routes yet." ]
            ]

          else
            List.map (jumpRouteLayerRowHtml hiddenIds pendingDeleteId isReferee) routes
         )
            ++ [ planRouteRowHtml ]
        )


jumpRouteLayerRowHtml : Set.Set Int -> Maybe Int -> Bool -> JumpRouteLayer.Route -> Html Msg
jumpRouteLayerRowHtml hiddenIds pendingDeleteId isReferee route =
    let
        isHidden =
            Set.member route.id hiddenIds

        isPendingDelete =
            pendingDeleteId == Just route.id

        linkCountLabel =
            String.fromInt route.linkCount
                ++ " link"
                ++ (if route.linkCount == 1 then
                        ""

                    else
                        "s"
                   )
    in
    Html.div
        [ HtmlAttrs.class "starmap-display-option"
        , HtmlAttrs.style "display" "flex"
        , HtmlAttrs.style "align-items" "center"
        , HtmlAttrs.style "gap" "10px"
        , HtmlAttrs.style "padding" "8px 16px"
        , HtmlAttrs.style "cursor"
            (if isReferee then
                "pointer"

             else
                "default"
            )
        , Html.Events.onClick
            (if isReferee then
                StartEditJumpRouteLayer route.id

             else
                NoOpMsg
            )
        ]
        [ Html.span
            [ HtmlAttrs.style "display" "inline-block"
            , HtmlAttrs.style "width" "12px"
            , HtmlAttrs.style "height" "12px"
            , HtmlAttrs.style "flex-shrink" "0"
            , HtmlAttrs.style "border-radius" "6px"
            , HtmlAttrs.style "background-color" route.colour
            ]
            []
        , ToggleSwitch.view ToggleSwitch.Small
            (not isHidden)
            (Html.Events.stopPropagationOn "click" (JsDecode.succeed ( ToggleJumpRouteLayerHidden route.id, True )))
        , Html.div [ HtmlAttrs.style "flex" "1", HtmlAttrs.style "min-width" "0" ]
            [ Html.div [ HtmlAttrs.class "text-sm text-fg" ] [ Html.text route.name ]
            , Html.div [ HtmlAttrs.class "text-xs text-fg-muted" ]
                [ Html.text (route.routeType ++ " · " ++ linkCountLabel) ]
            ]
        , if not isReferee then
            Html.text ""

          else if isPendingDelete then
            Html.span [ HtmlAttrs.style "display" "flex", HtmlAttrs.style "align-items" "center", HtmlAttrs.style "gap" "8px" ]
                [ Html.span [ HtmlAttrs.class "text-xs text-fg-muted" ] [ Html.text "Delete?" ]
                , Html.span
                    [ HtmlAttrs.class "text-danger cursor-pointer"
                    , Html.Events.stopPropagationOn "click" (JsDecode.succeed ( DeleteJumpRouteLayer route.id, True ))
                    ]
                    [ Html.i [ HtmlAttrs.class "fa-regular fa-check", HtmlAttrs.style "font-size" "12px" ] [] ]
                , Html.span
                    [ HtmlAttrs.class "text-fg-muted cursor-pointer"
                    , HtmlAttrs.style "font-size" "12px"
                    , Html.Events.stopPropagationOn "click" (JsDecode.succeed ( CancelDeleteJumpRouteLayer, True ))
                    ]
                    [ Html.text "✕" ]
                ]

          else
            Html.span
                [ HtmlAttrs.class "text-fg-muted cursor-pointer"
                , Html.Events.stopPropagationOn "click" (JsDecode.succeed ( RequestDeleteJumpRouteLayer route.id, True ))
                ]
                [ Html.i [ HtmlAttrs.class "fa-regular fa-trash", HtmlAttrs.style "font-size" "12px" ] [] ]
        ]


{-| Every new jump route - whether a referee's hand-built network link or a
player's calculated path - is created through the Route Planner, opened here
the same way the old standalone "Plan a route" toolbar icon did. Available to
everyone, referees and players alike, matching that icon's prior visibility.
-}
planRouteRowHtml : Html Msg
planRouteRowHtml =
    Html.button
        [ HtmlAttrs.type_ "button"
        , Html.Events.onClick OpenRoutePlanner
        , HtmlAttrs.class "starmap-display-option text-sm text-link no-underline hover:text-link-hover hover:underline hover:underline-offset-2 cursor-pointer bg-transparent border-0 text-left"
        , HtmlAttrs.style "width" "100%"
        , HtmlAttrs.style "padding" "8px 16px"
        ]
        [ Html.text "+ Plan a Route…" ]


type alias DisplaySettingsConfig =
    { displayMode : DisplayMode
    , regionDisplay : RegionDisplay
    , isReferee : Bool
    , showSectorLines : Bool
    , showSubsectorLines : Bool
    , showBackgroundNames : Bool
    , showJumpLogFill : Bool
    , showMapDisplayDropdown : Bool
    , showRegionDropdown : Bool
    }


dsStopPropagation : Html.Attribute Msg
dsStopPropagation =
    Html.Events.stopPropagationOn "click" (JsDecode.succeed ( NoOpMsg, True ))


dsFieldLabel : String -> Html Msg
dsFieldLabel label =
    Html.div
        [ HtmlAttrs.style "font-size" "11px"
        , HtmlAttrs.style "text-transform" "uppercase"
        , HtmlAttrs.style "letter-spacing" "0.15em"
        , HtmlAttrs.style "font-weight" "700"
        , HtmlAttrs.style "color" "var(--color-fg-muted)"
        , HtmlAttrs.style "margin-bottom" "4px"
        ]
        [ Html.text label ]


dsRadioIcon : Bool -> Html Msg
dsRadioIcon isActive =
    Html.div
        [ HtmlAttrs.style "width" "16px"
        , HtmlAttrs.style "height" "16px"
        , HtmlAttrs.style "flex" "0 0 auto"
        , HtmlAttrs.style "border-radius" "8px"
        , HtmlAttrs.style "border"
            ("2px solid "
                ++ (if isActive then
                        "var(--color-outline)"

                    else
                        "color-mix(in srgb, var(--color-outline) 35%, transparent)"
                   )
            )
        , HtmlAttrs.style "display" "flex"
        , HtmlAttrs.style "align-items" "center"
        , HtmlAttrs.style "justify-content" "center"
        , HtmlAttrs.style "box-sizing" "border-box"
        ]
        [ if isActive then
            Html.div
                [ HtmlAttrs.style "width" "8px"
                , HtmlAttrs.style "height" "8px"
                , HtmlAttrs.style "border-radius" "4px"
                , HtmlAttrs.style "background-color" "var(--color-outline)"
                ]
                []

          else
            Html.text ""
        ]


dsCheckboxIcon : Bool -> Html Msg
dsCheckboxIcon isActive =
    Html.div
        [ HtmlAttrs.style "width" "16px"
        , HtmlAttrs.style "height" "16px"
        , HtmlAttrs.style "flex" "0 0 auto"
        , HtmlAttrs.style "border-radius" "3px"
        , HtmlAttrs.style "border"
            ("2px solid "
                ++ (if isActive then
                        "var(--color-outline)"

                    else
                        "color-mix(in srgb, var(--color-outline) 35%, transparent)"
                   )
            )
        , HtmlAttrs.style "display" "flex"
        , HtmlAttrs.style "align-items" "center"
        , HtmlAttrs.style "justify-content" "center"
        , HtmlAttrs.style "box-sizing" "border-box"
        ]
        [ if isActive then
            Html.div
                [ HtmlAttrs.style "width" "8px"
                , HtmlAttrs.style "height" "8px"
                , HtmlAttrs.style "border-radius" "1px"
                , HtmlAttrs.style "background-color" "var(--color-outline)"
                ]
                []

          else
            Html.text ""
        ]


dsOptionRow : Bool -> String -> String -> Msg -> Html Msg
dsOptionRow isActive label description msg =
    Html.div
        [ HtmlAttrs.class "starmap-display-option"
        , HtmlAttrs.style "display" "flex"
        , HtmlAttrs.style "align-items" "flex-start"
        , HtmlAttrs.style "gap" "10px"
        , HtmlAttrs.style "padding" "8px 10px"
        , HtmlAttrs.style "border-radius" "4px"
        , HtmlAttrs.style "cursor" "pointer"
        , HtmlAttrs.style "background-color"
            (if isActive then
                "color-mix(in srgb, var(--color-outline) 10%, transparent)"

             else
                "transparent"
            )
        , Html.Events.onClick msg
        ]
        [ Html.div [ HtmlAttrs.style "margin-top" "2px" ] [ dsRadioIcon isActive ]
        , Html.div
            [ HtmlAttrs.style "display" "flex"
            , HtmlAttrs.style "flex-direction" "column"
            , HtmlAttrs.style "gap" "2px"
            ]
            [ Html.div [ HtmlAttrs.style "font-size" "13px", HtmlAttrs.style "font-weight" "700", HtmlAttrs.style "color" "var(--color-fg)" ] [ Html.text label ]
            , Html.div [ HtmlAttrs.style "font-size" "11px", HtmlAttrs.style "color" "var(--color-fg-muted)" ] [ Html.text description ]
            ]
        ]


dsCheckboxRow : Bool -> String -> Msg -> Html Msg
dsCheckboxRow isActive label msg =
    Html.div
        [ HtmlAttrs.class "starmap-display-option"
        , HtmlAttrs.style "display" "flex"
        , HtmlAttrs.style "align-items" "center"
        , HtmlAttrs.style "gap" "10px"
        , HtmlAttrs.style "padding" "6px 10px"
        , HtmlAttrs.style "border-radius" "4px"
        , HtmlAttrs.style "cursor" "pointer"
        , Html.Events.onClick msg
        ]
        [ dsCheckboxIcon isActive
        , Html.div [ HtmlAttrs.style "font-size" "13px", HtmlAttrs.style "color" "var(--color-fg)" ] [ Html.text label ]
        ]


dsDropdownField :
    { label : String
    , toggleId : String
    , menuId : String
    , isOpen : Bool
    , onToggle : Msg
    , currentLabel : String
    , rows : List (Html Msg)
    }
    -> Html Msg
dsDropdownField field =
    Html.div
        [ HtmlAttrs.style "position" "relative"
        , HtmlAttrs.style "margin-bottom" "12px"
        ]
        [ dsFieldLabel field.label
        , Html.div
            [ HtmlAttrs.id field.toggleId
            , HtmlAttrs.style "display" "flex"
            , HtmlAttrs.style "align-items" "center"
            , HtmlAttrs.style "justify-content" "space-between"
            , HtmlAttrs.style "font-size" "13px"
            , HtmlAttrs.style "color" "var(--color-fg)"
            , HtmlAttrs.style "background-color" "var(--color-panel)"
            , HtmlAttrs.style "border" "1px solid var(--color-outline)"
            , HtmlAttrs.style "border-radius" "4px"
            , HtmlAttrs.style "padding" "8px 10px"
            , HtmlAttrs.style "cursor" "pointer"
            , Html.Events.onClick field.onToggle
            ]
            [ Html.text field.currentLabel
            , faIcon "fa-regular fa-chevron-down" 12
            ]
        , if field.isOpen then
            Html.div
                [ HtmlAttrs.class "starmap-glass-panel"
                , HtmlAttrs.id field.menuId
                , HtmlAttrs.style "position" "absolute"
                , HtmlAttrs.style "top" "100%"
                , HtmlAttrs.style "left" "0"
                , HtmlAttrs.style "right" "0"
                , HtmlAttrs.style "margin-top" "4px"
                , HtmlAttrs.style "border-radius" "4px"
                , HtmlAttrs.style "padding" "4px"
                , HtmlAttrs.style "z-index" "10"
                , HtmlAttrs.style "max-height" "260px"
                , HtmlAttrs.style "overflow-y" "auto"
                ]
                field.rows

          else
            Html.text ""
        ]


mapDisplayModes : Bool -> List ( DisplayMode, String, String )
mapDisplayModes isReferee =
    [ ( ShowStars, "Stars", "Primary stars in each system" )
    , ( ShowMainWorld, "Main World", "Planet image for the main world" )
    , ( ShowTradeCodes, "Trade Codes", "Abbreviated trade classification codes" )
    , ( ShowTechLevel, "Tech Level", "Tech level rating" )
    , ( ShowGovernment, "Government", "Government type and code per hex" )
    ]
        ++ (if isReferee then
                [ ( ShowWTN, "WTN", "World Trade Number" )
                , ( ShowGWP, "GWP", "Gross World Product" )
                , ( ShowImportance, "Importance", "Economic importance rating" )
                , ( ShowStrategic, "Strategic", "Tiered bars: Importance, Resource Units, Resource Factor, Trade Ease" )
                , ( ShowResource, "Resource", "Tiered bars: Importance, Trade Ease, plus route role badge" )
                , ( ShowHabitability, "Habitability", "Main world habitability rating" )
                ]

            else
                []
           )


regionModes : List ( RegionDisplay, String, String )
regionModes =
    [ ( HideRegions, "Hidden", "Regions not shown" )
    , ( ShowRegionsFill, "Fill", "Hex colour fill only" )
    , ( ShowRegionsBorder, "Border", "Region border lines only" )
    , ( ShowRegionsBoth, "Fill & Border", "Hex colour fill with border lines" )
    ]


dsCurrentLabel : a -> List ( a, String, String ) -> String
dsCurrentLabel current modes =
    modes
        |> List.filter (\( mode, _, _ ) -> mode == current)
        |> List.head
        |> Maybe.map (\( _, label, _ ) -> label)
        |> Maybe.withDefault ""


viewDisplaySettingsModalHtml : DisplaySettingsConfig -> Html Msg
viewDisplaySettingsModalHtml config =
    let
        mapModes =
            mapDisplayModes config.isReferee

        mapDisplayRows =
            mapModes
                |> List.map (\( mode, label, description ) -> dsOptionRow (mode == config.displayMode) label description (SetDisplayMode mode))

        regionRows =
            regionModes
                |> List.map (\( mode, label, description ) -> dsOptionRow (mode == config.regionDisplay) label description (SetRegionDisplay mode))

        overlayRows =
            [ dsCheckboxRow config.showSectorLines "Sector lines" ToggleSectorLines
            , dsCheckboxRow config.showSubsectorLines "Subsector lines" ToggleSubsectorLines
            , dsCheckboxRow config.showBackgroundNames "Names" ToggleBackgroundNames
            , dsCheckboxRow config.showJumpLogFill "Jump log" ToggleJumpLogFill
            ]
    in
    Html.div
        [ HtmlAttrs.style "position" "fixed"
        , HtmlAttrs.style "inset" "0"
        , HtmlAttrs.style "z-index" "200"
        , HtmlAttrs.style "display" "flex"
        , HtmlAttrs.style "align-items" "center"
        , HtmlAttrs.style "justify-content" "center"
        , HtmlAttrs.style "background-color" "color-mix(in srgb, var(--color-bg) 30%, transparent)"
        , Html.Events.onClick ToggleDisplaySettings
        ]
        [ Html.div
            [ HtmlAttrs.class "starmap-glass-panel"
            , HtmlAttrs.style "width" "480px"
            , HtmlAttrs.style "border-radius" "6px"
            , HtmlAttrs.style "padding" "20px"
            , dsStopPropagation
            ]
            [ Html.div
                [ HtmlAttrs.style "display" "flex"
                , HtmlAttrs.style "align-items" "center"
                , HtmlAttrs.style "justify-content" "space-between"
                , HtmlAttrs.style "padding-bottom" "12px"
                , HtmlAttrs.style "margin-bottom" "12px"
                , HtmlAttrs.style "border-bottom" "1px solid var(--color-outline)"
                ]
                [ Html.span [ HtmlAttrs.style "font-size" "14px", HtmlAttrs.style "font-weight" "700", HtmlAttrs.style "color" "var(--color-fg)" ] [ Html.text "Map Display" ]
                , Html.span
                    [ HtmlAttrs.class "starmap-modal-close"
                    , HtmlAttrs.style "cursor" "pointer"
                    , HtmlAttrs.style "font-size" "14px"
                    , HtmlAttrs.style "color" "var(--color-fg-muted)"
                    , Html.Events.onClick ToggleDisplaySettings
                    ]
                    [ Html.text "✕" ]
                ]
            , dsDropdownField
                { label = "Map Display"
                , toggleId = "starmap-map-display-toggle"
                , menuId = "starmap-map-display-menu"
                , isOpen = config.showMapDisplayDropdown
                , onToggle = ToggleMapDisplayDropdown
                , currentLabel = dsCurrentLabel config.displayMode mapModes
                , rows = mapDisplayRows
                }
            , dsDropdownField
                { label = "Regions"
                , toggleId = "starmap-region-toggle"
                , menuId = "starmap-region-menu"
                , isOpen = config.showRegionDropdown
                , onToggle = ToggleRegionDropdown
                , currentLabel = dsCurrentLabel config.regionDisplay regionModes
                , rows = regionRows
                }
            , Html.div [ HtmlAttrs.style "margin-top" "8px" ]
                (dsFieldLabel "Overlays" :: overlayRows)
            ]
        ]


viewHexMap : ModelData -> Element Msg
viewHexMap model =
    let
        svgHeight =
            model.viewport.viewport.viewport.height - consoleTitleHeight

        svgWidth =
            model.viewport.viewport.viewport.width

        ( maxAcross, maxTall ) =
            case model.viewport.hexmapViewport of
                Nothing ->
                    ( 10000, 10000 )

                Just (Ok hvp) ->
                    ( (hvp.viewport.width / toFloat visualHexWidth) + 2 |> floor
                    , (hvp.viewport.height / toFloat visualHexHeight) + 2 |> floor
                    )

                Just (Err _) ->
                    ( 10000, 10000 )

        ( visualHexWidth, visualHexHeight ) =
            let
                ( left_x, left_y ) =
                    calcVisualOrigin model.hexScale { row = 1, col = 1 }

                ( right_x, _ ) =
                    calcVisualOrigin model.hexScale { row = 1, col = 2 }

                ( _, down_y ) =
                    calcVisualOrigin model.hexScale { row = 2, col = 1 }
            in
            ( left_x - right_x |> abs, down_y - left_y |> abs )
    in
    viewHexes
        { hexRect = model.hexRect
        , rawHexaPoints = model.rawHexaPoints
        , svgWidth = svgWidth
        , svgHeight = svgHeight
        , maxAcross = maxAcross
        , maxTall = maxTall
        , solarSystemDict = model.solarSystems
        , hexColours = model.hexColours
        , regionLabels = model.regionLabels
        , regions = model.regions
        , regionDisplay = model.regionDisplay
        , showSectorLines = model.showSectorLines
        , showSubsectorLines = model.showSubsectorLines
        , sectors = model.sectors
        , showBackgroundNames = model.showBackgroundNames
        , showJumpLogFill = model.showJumpLogFill
        , themeIsLight = model.themeIsLight
        , highlightRules = model.highlightRules
        , previewRoute = activePreviewRoute model
        , route = model.route
        , currentAddress = model.currentAddress
        , hexSize = model.hexScale
        , maybeSelectedHex = model.selectedHex
        , isReferee = model.isReferee
        , panOffset = model.panOffset
        , jumpRouteLinks = model.jumpRouteLinks
        , hiddenJumpRouteIds = model.hiddenJumpRouteIds
        , rogueObjectPathData = model.rogueObjectPathData
        , facilityIcons = model.facilityIcons
        , displayMode = model.displayMode
        }
        |> Element.html


humanizeTypeName : String -> String
humanizeTypeName name =
    name
        |> String.toList
        |> List.foldl
            (\c acc ->
                if Char.isUpper c && not (String.isEmpty acc) then
                    acc ++ " " ++ String.fromChar c

                else
                    acc ++ String.fromChar c
            )
            ""


viewRogueContent : List RogueObjectDetail -> Element Msg
viewRogueContent objects =
    let
        sectionHeader =
            el
                [ accentHeadingColour
                , Font.size 16
                , Font.bold
                , Element.paddingEach { zeroEach | top = 8, bottom = 4 }
                ]
                (text "Rogue Objects")

        headerRow =
            row
                [ width fill
                , Element.paddingXY 0 4
                , Border.widthEach { zeroEach | bottom = 1 }
                , Element.htmlAttribute (HtmlAttrs.style "border-color" "var(--color-outline)")
                ]
                [ el [ Font.size 11, Font.bold, fontVar "--color-fg", Element.width (Element.px 120) ] (text "Type")
                , el [ Font.size 11, Font.bold, fontVar "--color-fg" ] (text "Name")
                ]

        objectRow detail =
            let
                ( typeName, name ) =
                    case detail of
                        RogueCometDetail d ->
                            ( "Comet", d.name )

                        RogueGasGiantDetail d ->
                            ( "Gas Giant", d.name )

                        RogueOtherDetail d ->
                            ( humanizeTypeName d.typeName, d.name )
            in
            row [ width fill, Element.paddingXY 0 2 ]
                [ el [ Font.size 12, Element.width (Element.px 120) ] (text typeName)
                , el [ Font.size 12 ] (text name)
                ]
    in
    column [ width fill, Element.paddingXY 8 4 ]
        [ sectionHeader
        , headerRow
        , column [ width fill, Element.spacing 2 ] (List.map objectRow objects)
        ]


view : Model -> Element.Element Msg
view ( time, model ) =
    let
        sidebarMsgs : SidebarMsgs Msg
        sidebarMsgs =
            { viewDetail = ViewObjectAnalysisDetail
            , closeSidebar = CloseSidebar
            , toggleTravelTable = ToggleTravelTable
            , openShipTraffic = OpenShipTraffic
            , setKnown = SetKnown
            , setSurveyIndex = SetSurveyIndex
            }

        solarSystemStatus =
            case model.selectedHex of
                Just viewingAddress ->
                    case model.solarSystems |> Dict.get (HexAddress.toKey viewingAddress) of
                        Just LoadingSolarSystem ->
                            Just "Acquiring signal..."

                        Just (FailedSolarSystem _) ->
                            Just "failed."

                        Just (FailedStarsSolarSystem _) ->
                            Just "decoding a star failed"

                        Nothing ->
                            case model.selectedSystem of
                                Just _ ->
                                    Nothing

                                Nothing ->
                                    Just "No solar system data found for system."

                        _ ->
                            Nothing

                Nothing ->
                    Nothing

        sidebarData =
            { selectedHex = model.selectedHex
            , solarSystemStatus = solarSystemStatus
            , sectors = model.sectors
            , regions = model.regions
            , selectedSystem = model.selectedSystem
            , isReferee = model.isReferee
            , allSectorsMapUrl = model.allSectorsMapUrl
            , mDrive = model.ship |> Maybe.andThen .mDrive
            , showTravelTable = model.showTravelTable
            , rogueContent = model.selectedRogueObjects |> Maybe.map viewRogueContent
            }

        travelTableMsgs : TravelTable.Msgs Msg
        travelTableMsgs =
            { setMDrive = SetTravelTableMDrive
            , close = ToggleTravelTable
            , noOp = NoOpMsg
            }

        shipTrafficMsgs : ShipTraffic.Msgs Msg
        shipTrafficMsgs =
            { close = CloseShipTraffic
            , noOp = NoOpMsg
            , reroll = RerollShipTraffic
            , toggleFrontier = ToggleShipTrafficFrontier
            }

        sidebarColumn =
            Element.Lazy.lazy2 viewSidebarColumn sidebarMsgs sidebarData

        sidebarOverlay =
            el
                [ Element.height Element.fill
                , Element.width (Element.px 320)
                , Element.alignLeft
                , Font.size 14
                , bgVar "--color-panel"
                , Border.widthEach { zeroEach | right = 1 }
                , borderVar "--color-outline"
                , Element.scrollbarY
                , Element.htmlAttribute (HtmlAttrs.class "sidebar-panel")
                ]
                sidebarColumn

        contentColumn =
            case model.viewMode of
                HexMap ->
                    viewHexMap model

                FullJourney ->
                    viewFullJourney model.allSectorsMapUrl model.journeyModel model.viewport.viewport

        timeChars : Int
        timeChars =
            (Time.posixToMillis time - Time.posixToMillis model.timeOpened) // 12

        -- One `inFront` layer per open object, oldest first (so each newer
        -- drill-down paints on top of, not instead of, whatever's beneath
        -- it — closing the top one reveals the previous one, still there).
        objectAnalysisLayers : List (Element.Attribute Msg)
        objectAnalysisLayers =
            model.objectToBeAnalyzed
                |> List.reverse
                |> List.indexedMap
                    (\index entry ->
                        Element.inFront <|
                            viewObjectAnalysisDetail timeChars
                                CloseObjectAnalysis
                                NoOpMsg
                                model.analysisTab
                                SetAnalysisTab
                                model.isReferee
                                ViewObjectAnalysisDetail
                                (1000 + index * 10)
                                { width = model.starMapModalSize.width
                                , height = model.starMapModalSize.height
                                , onResizeStart = StarMapResizeStart
                                }
                                entry.data
                    )
    in
    row
        ([ width fill
         , height fill
         , Font.size 20
         , fontVar "--color-fg"
         , bgVar "--color-bg"
         ]
            ++ objectAnalysisLayers
            ++ [ Element.htmlAttribute <| HtmlAttrs.class ""
               , case ( model.showTravelTable, model.selectedSystem ) of
                    ( True, Just solarSystem ) ->
                        Element.inFront <| TravelTable.viewModal travelTableMsgs model.travelTableMDrive solarSystem

                    _ ->
                        Element.htmlAttribute <| HtmlAttrs.class ""
               , if model.showShipTraffic then
                    Element.inFront <| ShipTraffic.viewModal shipTrafficMsgs model.shipTraffic model.shipTrafficFrontier

                 else
                    Element.htmlAttribute <| HtmlAttrs.class ""
               , if model.showDisplaySettings then
                    Element.inFront <|
                        Element.html
                            (viewDisplaySettingsModalHtml
                                { displayMode = model.displayMode
                                , regionDisplay = model.regionDisplay
                                , isReferee = model.isReferee
                                , showSectorLines = model.showSectorLines
                                , showSubsectorLines = model.showSubsectorLines
                                , showBackgroundNames = model.showBackgroundNames
                                , showJumpLogFill = model.showJumpLogFill
                                , showMapDisplayDropdown = model.showMapDisplayDropdown
                                , showRegionDropdown = model.showRegionDropdown
                                }
                            )

                 else
                    Element.htmlAttribute <| HtmlAttrs.class ""
               , case model.ruleEditor of
                    Just editorModel ->
                        Element.inFront <| Element.map HighlightRuleEditorMsg (HighlightRuleEditor.view (pickerData model) editorModel)

                    Nothing ->
                        Element.htmlAttribute <| HtmlAttrs.class ""
               , case model.pendingDeleteRuleId |> Maybe.andThen (\id -> List.filter (\r -> r.id == id) model.highlightRules |> List.head) of
                    Just rule ->
                        Element.inFront <| Element.html (viewDeleteRuleConfirmModal rule)

                    Nothing ->
                        Element.htmlAttribute <| HtmlAttrs.class ""
               , case model.routePlanForm of
                    Just formModel ->
                        Element.inFront <| Element.map RoutePlanFormMsg (Element.html (RoutePlanForm.view (routePlanFormConfig model) formModel))

                    Nothing ->
                        Element.htmlAttribute <| HtmlAttrs.class ""
               , case model.jumpRouteLayerEditor of
                    Just editorModel ->
                        Element.inFront <| Element.map JumpRouteLayerEditorMsg (Element.html (JumpRouteLayerEditor.view editorModel))

                    Nothing ->
                        Element.htmlAttribute <| HtmlAttrs.class ""
               ]
        )
        [ column [ width fill, Element.alignTop ]
            [ viewStatusRow model
            , el
                [ Element.alignTop
                , width fill
                , if model.sidebarOpen then
                    Element.inFront sidebarOverlay

                  else
                    Element.htmlAttribute <| HtmlAttrs.class ""
                ]
                contentColumn
            ]
        , Element.html <| errorDialog model.newSolarSystemErrors
        ]


sendSolarSystemRequest : RequestEntry -> HostConfig -> Cmd Msg
sendSolarSystemRequest requestEntry hostConfig =
    let
        solarSystemsDecoder : JsDecode.Decoder (List FallibleStarSystem)
        solarSystemsDecoder =
            JsDecode.list fallibleStarSystemDecoder

        ( urlHostRoot, urlHostPath ) =
            hostConfig

        url =
            Url.Builder.crossOrigin
                urlHostRoot
                (urlHostPath ++ [ "star_map" ])
                [ Url.Builder.int "ulx" requestEntry.upperLeftHex.x
                , Url.Builder.int "uly" requestEntry.upperLeftHex.y
                , Url.Builder.int "lrx" requestEntry.lowerRightHex.x
                , Url.Builder.int "lry" requestEntry.lowerRightHex.y
                ]
    in
    -- using Http.request instead of Http.get, to allow setting a timeout
    Http.request
        { method = "GET"
        , headers = []
        , url = url
        , body = Http.emptyBody
        , expect = Http.expectJson (DownloadedSolarSystems ( requestEntry, url )) solarSystemsDecoder
        , timeout = Just 15000
        , tracker = Nothing
        }


sendRoguesRequest : RequestEntry -> HostConfig -> Cmd Msg
sendRoguesRequest requestEntry hostConfig =
    let
        ( urlHostRoot, urlHostPath ) =
            hostConfig

        url =
            Url.Builder.crossOrigin
                urlHostRoot
                (urlHostPath ++ [ "rogues" ])
                [ Url.Builder.int "ulx" requestEntry.upperLeftHex.x
                , Url.Builder.int "uly" requestEntry.upperLeftHex.y
                , Url.Builder.int "lrx" requestEntry.lowerRightHex.x
                , Url.Builder.int "lry" requestEntry.lowerRightHex.y
                ]
    in
    Http.request
        { method = "GET"
        , headers = []
        , url = url
        , body = Http.emptyBody
        , expect = Http.expectJson (DownloadedRogues url) (JsDecode.list rogueResponseItemDecoder)
        , timeout = Just 15000
        , tracker = Nothing
        }


sendSubsectorLookupRequest : HostConfig -> Int -> Int -> Cmd Msg
sendSubsectorLookupRequest hostConfig x y =
    let
        ( urlHostRoot, urlHostPath ) =
            hostConfig

        url =
            Url.Builder.crossOrigin
                urlHostRoot
                (urlHostPath ++ [ "subsector_at" ])
                [ Url.Builder.int "x" x
                , Url.Builder.int "y" y
                ]
    in
    Http.get
        { url = url
        , expect = Http.expectJson GotSubsectorLookupUrl (JsDecode.field "url" JsDecode.string)
        }


fallbackSectorsUrl : HostConfig -> String
fallbackSectorsUrl ( root, pathSegments ) =
    Url.Builder.crossOrigin root (List.take (List.length pathSegments - 1) pathSegments ++ [ "sectors" ]) []


{-| The full-page Rails edit URL for a jump route, used when a "plotted"
route (or any field outside the quick-edit set) needs editing - opened via
the `navigateToUrlSameTab` port rather than replicated in Elm. Built the same
way as the ctrl-click "open star system" navigation: take the
`c/:campaign_slug` prefix off the API host's path segments.
-}
jumpRouteEditUrl : HostConfig -> Int -> String
jumpRouteEditUrl ( _, pathSegments ) routeId =
    let
        campaignPrefix =
            List.take 2 pathSegments |> String.join "/"
    in
    "/" ++ campaignPrefix ++ "/jump_routes/" ++ String.fromInt routeId ++ "/edit?return_to=starmap"


sendRouteRequest : RequestEntry -> HostConfig -> Cmd Msg
sendRouteRequest requestEntry hostConfig =
    let
        routeDecoder : JsDecode.Decoder (List Route)
        routeDecoder =
            Codec.list Route.codec
                |> Codec.decoder

        ( urlHostRoot, urlHostPath ) =
            hostConfig

        url =
            Url.Builder.crossOrigin
                urlHostRoot
                (urlHostPath ++ [ "jumps" ])
                []

        requestCmd =
            Http.request
                { method = "GET"
                , headers = []
                , url = url
                , body = Http.emptyBody
                , expect = Http.expectJson (DownloadedRoute ( requestEntry, url )) routeDecoder
                , timeout = Just 15000
                , tracker = Nothing
                }
    in
    requestCmd


fetchSingleSolarSystemRequest : HostConfig -> SectorHexAddress -> Cmd Msg
fetchSingleSolarSystemRequest hostConfig hex =
    let
        solarSystemDecoder : JsDecode.Decoder SolarSystem
        solarSystemDecoder =
            SolarSystem.codec |> Codec.decoder

        ( urlHostRoot, urlHostPath ) =
            hostConfig

        url =
            Url.Builder.crossOrigin
                urlHostRoot
                (urlHostPath ++ [ "starsystem" ])
                [ Url.Builder.int "sx" hex.sectorX
                , Url.Builder.int "sy" hex.sectorY
                , Url.Builder.int "hx" <| hex.x + 1
                , Url.Builder.int "hy" <| hex.y + 1
                ]

        requestCmd =
            -- using Http.request instead of Http.get, to allow setting a timeout
            Http.request
                { method = "GET"
                , headers = []
                , url = url
                , body = Http.emptyBody
                , expect = Http.expectJson FetchedSolarSystem solarSystemDecoder
                , timeout = Just 5000
                , tracker = Nothing
                }
    in
    requestCmd


sendShipTrafficRequest : HostConfig -> Int -> Bool -> Cmd Msg
sendShipTrafficRequest hostConfig starSystemId frontier =
    let
        shipTrafficDecoder : JsDecode.Decoder ShipTraffic.ShipTraffic
        shipTrafficDecoder =
            ShipTraffic.codec |> Codec.decoder

        ( urlHostRoot, urlHostPath ) =
            hostConfig

        url =
            Url.Builder.crossOrigin
                urlHostRoot
                (urlHostPath ++ [ "star_systems", String.fromInt starSystemId, "ship_traffic" ])
                [ Url.Builder.string "frontier"
                    (if frontier then
                        "1"

                     else
                        "0"
                    )
                ]
    in
    Http.request
        { method = "GET"
        , headers = []
        , url = url
        , body = Http.emptyBody
        , expect = Http.expectJson FetchedShipTraffic shipTrafficDecoder
        , timeout = Just 5000
        , tracker = Nothing
        }


updateStarSystemKnown : HostConfig -> Int -> Bool -> Cmd Msg
updateStarSystemKnown hostConfig starSystemId known =
    let
        ( urlHostRoot, urlHostPath ) =
            hostConfig

        url =
            Url.Builder.crossOrigin
                urlHostRoot
                (urlHostPath ++ [ "star_systems", String.fromInt starSystemId ])
                []
    in
    Http.request
        { method = "PATCH"
        , headers = []
        , url = url
        , body = Http.jsonBody (Encode.object [ ( "known", Encode.bool known ) ])
        , expect = Http.expectWhatever KnownSaved
        , timeout = Just 5000
        , tracker = Nothing
        }


updateStarSystemSurveyIndex : HostConfig -> Int -> Int -> Cmd Msg
updateStarSystemSurveyIndex hostConfig starSystemId surveyIndex =
    let
        ( urlHostRoot, urlHostPath ) =
            hostConfig

        url =
            Url.Builder.crossOrigin
                urlHostRoot
                (urlHostPath ++ [ "star_systems", String.fromInt starSystemId ])
                []
    in
    Http.request
        { method = "PATCH"
        , headers = []
        , url = url
        , body = Http.jsonBody (Encode.object [ ( "survey_index", Encode.int surveyIndex ) ])
        , expect = Http.expectWhatever SurveyIndexSaved
        , timeout = Just 5000
        , tracker = Nothing
        }


sendSearchRequest : String -> HostConfig.HostConfig -> Cmd Msg
sendSearchRequest query ( urlRoot, urlPath ) =
    Http.get
        { url =
            Url.Builder.crossOrigin urlRoot
                (urlPath ++ [ "search" ])
                [ Url.Builder.string "q" query ]
        , expect = Http.expectJson GotSearchResults (JsDecode.list searchResultDecoder)
        }


saveMapCoords : HexAddress -> Cmd Msg
saveMapCoords upperLeft =
    storeInLocalStorage ( upperLeft.x, upperLeft.y )


port storeInLocalStorage : ( Int, Int ) -> Cmd msg


savePanOffset : { x : Float, y : Float } -> Cmd Msg
savePanOffset offset =
    storePanOffset ( offset.x, offset.y )


port storePanOffset : ( Float, Float ) -> Cmd msg


port storeViewMode : String -> Cmd msg


port storeJourneyState : String -> Cmd msg


saveHexSize : Float -> Cmd Msg
saveHexSize size =
    storeHexSize size


port storeHexSize : Float -> Cmd msg


port storeDisplayMode : String -> Cmd msg


port storeRegionDisplay : String -> Cmd msg


port storeSectorLines : Bool -> Cmd msg


port storeSubsectorLines : Bool -> Cmd msg


port storeBackgroundNames : Bool -> Cmd msg


port storeJumpLogFill : Bool -> Cmd msg


port storeHighlightRules : Encode.Value -> Cmd msg


port storeRoutePlan : Encode.Value -> Cmd msg


port storeHiddenJumpRouteIds : Encode.Value -> Cmd msg


port navigateToUrl : String -> Cmd msg


port navigateToUrlSameTab : String -> Cmd msg


port setTheme : String -> Cmd msg


encodeJourneyState : Float -> ( Float, Float ) -> String
encodeJourneyState scale ( ox, oy ) =
    String.join "," [ String.fromFloat scale, String.fromFloat ox, String.fromFloat oy ]


updateJourney : JourneyMsg -> Model -> ( Model, Cmd Msg )
updateJourney journeyMsg ( time, { journeyModel } as model ) =
    let
        setJourneyModel : JourneyModel -> Model
        setJourneyModel newJourneyModel =
            ( time, { model | journeyModel = newJourneyModel } )
    in
    case journeyMsg of
        Zoom zoomType ->
            let
                newZoomScale =
                    case zoomType of
                        ZoomIn ->
                            journeyModel.zoomScale * 1.5

                        ZoomOut ->
                            journeyModel.zoomScale / 1.5

                        ZoomSet newZoom ->
                            newZoom

                newJourneyModel =
                    { journeyModel | zoomScale = newZoomScale }
            in
            ( setJourneyModel newJourneyModel, storeJourneyState (encodeJourneyState newZoomScale journeyModel.zoomOffset) )

        Pan ( dx, dy ) ->
            let
                dims =
                    journeyDimensions model.viewport.viewport.viewport

                curImgWidth =
                    dims.fittedW * journeyModel.zoomScale

                curImgHeight =
                    dims.fittedH * journeyModel.zoomScale

                ( oldX, oldY ) =
                    journeyModel.zoomOffset
            in
            let
                newOffset =
                    ( clamp (min 0 (dims.containerW - curImgWidth)) 0 (oldX + dx)
                    , clamp (min 0 (dims.containerH - curImgHeight)) 0 (oldY + dy)
                    )
            in
            ( setJourneyModel { journeyModel | zoomOffset = newOffset }
            , storeJourneyState (encodeJourneyState journeyModel.zoomScale newOffset)
            )

        WheelZoom delta ->
            let
                factor =
                    if delta > 0 then
                        1 / 1.1

                    else
                        1.1

                oldZoomScale =
                    journeyModel.zoomScale

                newZoomScale =
                    clamp 1.0 7.0 (oldZoomScale * factor)

                actualFactor =
                    newZoomScale / oldZoomScale

                dims =
                    journeyDimensions model.viewport.viewport.viewport

                curImgWidth =
                    dims.fittedW * newZoomScale

                curImgHeight =
                    dims.fittedH * newZoomScale

                ( ox, oy ) =
                    journeyModel.zoomOffset

                ( newOx, newOy ) =
                    case journeyModel.hoverPoint of
                        Just ( mx, my ) ->
                            ( mx - (mx - ox) * actualFactor
                            , my - (my - oy) * actualFactor
                            )

                        Nothing ->
                            let
                                cx =
                                    dims.containerW / 2

                                cy =
                                    dims.containerH / 2
                            in
                            ( cx - (cx - ox) * actualFactor
                            , cy - (cy - oy) * actualFactor
                            )
            in
            let
                clampedOffset =
                    ( clamp (min 0 (dims.containerW - curImgWidth)) 0 newOx
                    , clamp (min 0 (dims.containerH - curImgHeight)) 0 newOy
                    )
            in
            ( setJourneyModel
                { journeyModel
                    | zoomScale = newZoomScale
                    , zoomOffset = clampedOffset
                }
            , storeJourneyState (encodeJourneyState newZoomScale clampedOffset)
            )

        MouseDown originalPos ->
            ( setJourneyModel { journeyModel | dragMode = IsDragging { start = originalPos, last = originalPos } }, Cmd.none )

        MouseLeave ->
            ( setJourneyModel { journeyModel | dragMode = NoDragging, hoverPoint = Nothing }, Cmd.none )

        MouseMove ( newX, newY ) ->
            case journeyModel.dragMode of
                IsDragging { start, last } ->
                    let
                        ( originalX, originalY ) =
                            last

                        ( xDelta, yDelta ) =
                            ( newX - originalX
                            , newY - originalY
                            )

                        dims =
                            journeyDimensions model.viewport.viewport.viewport

                        ( oldX, oldY ) =
                            journeyModel.zoomOffset

                        curImgWidth =
                            dims.fittedW * journeyModel.zoomScale

                        curImgHeight =
                            dims.fittedH * journeyModel.zoomScale

                        newModel =
                            { journeyModel
                                | dragMode = IsDragging { start = start, last = ( newX, newY ) }
                                , zoomOffset =
                                    ( clamp (min 0 (dims.containerW - curImgWidth)) 0 (oldX + xDelta)
                                    , clamp (min 0 (dims.containerH - curImgHeight)) 0 (oldY + yDelta)
                                    )
                                , hoverPoint = Nothing
                            }
                    in
                    if xDelta /= 0 || yDelta /= 0 then
                        ( setJourneyModel newModel, Cmd.none )

                    else
                        ( setJourneyModel { journeyModel | hoverPoint = Nothing }, Cmd.none )

                NoDragging ->
                    ( setJourneyModel { journeyModel | hoverPoint = Just ( newX, newY ) }, Cmd.none )

        MouseUp coordinates ->
            case journeyModel.dragMode of
                IsDragging { start } ->
                    let
                        ( ox, oy ) =
                            start

                        ( cx, cy ) =
                            coordinates

                        dist =
                            sqrt ((cx - ox) ^ 2 + (cy - oy) ^ 2)

                        hexViewToSector arg1 =
                            let
                                dims =
                                    journeyDimensions model.viewport.viewport.viewport

                                imageSize =
                                    { width = dims.fittedW * journeyModel.zoomScale, height = dims.fittedH * journeyModel.zoomScale }

                                sector =
                                    mouseCoordsToSector (toXY coordinates) (toXY journeyModel.zoomOffset) imageSize

                                hexAddress =
                                    shiftAddressBy { deltaX = -2, deltaY = -2 } <| createFromStarSystem { x = 1, y = 1, sectorX = sector.x, sectorY = sector.y }

                                hh =
                                    horizontalHexes model.viewport.hexmapViewport model.hexScale + 2

                                vh =
                                    verticalHexes model.viewport.hexmapViewport model.hexScale + 3

                                newHexRect =
                                    { upperLeftHex = hexAddress
                                    , lowerRightHex = shiftAddressBy { deltaX = hh, deltaY = vh } hexAddress
                                    }

                                newJourneyModel =
                                    { journeyModel | dragMode = NoDragging }

                                newModel =
                                    { model
                                        | hexRect = newHexRect
                                        , dragMode = NoDragging
                                        , viewMode = HexMap
                                        , journeyModel = newJourneyModel
                                        , panOffset = { x = 0, y = 0 }
                                    }
                            in
                            let
                                ( updatedModel, downloadCmds ) =
                                    update DownloadSolarSystems ( time, newModel )
                            in
                            ( updatedModel, Cmd.batch [ storeViewMode "HexMap", saveMapCoords newHexRect.upperLeftHex, savePanOffset { x = 0, y = 0 }, downloadCmds ] )
                    in
                    if dist > 2 then
                        ( setJourneyModel { journeyModel | dragMode = NoDragging }
                        , storeJourneyState (encodeJourneyState journeyModel.zoomScale journeyModel.zoomOffset)
                        )

                    else
                        hexViewToSector ()

                NoDragging ->
                    ( ( time, model ), Cmd.none )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg ( time, model ) =
    let
        withTime m =
            ( time, m )
    in
    case msg of
        NoOpMsg ->
            ( withTime model, Cmd.none )

        Tick newTime ->
            ( ( newTime, model ), Cmd.none )

        HexMapWheelZoom dy ->
            let
                factor =
                    if dy > 0 then
                        1 / 1.1

                    else
                        1.1

                newSize =
                    clamp minHexSize maxHexSize (model.hexScale * factor)
            in
            update (SetHexSize newSize) ( time, model )

        SetHexSize newSize ->
            let
                extraPaddingHexes =
                    2

                hh =
                    horizontalHexes model.viewport.hexmapViewport newSize + extraPaddingHexes

                vh =
                    verticalHexes model.viewport.hexmapViewport newSize + extraPaddingHexes

                ratio =
                    newSize / model.hexScale

                ( svgW, svgH ) =
                    case model.viewport.hexmapViewport of
                        Just (Ok vp) ->
                            ( vp.viewport.width, vp.viewport.height )

                        _ ->
                            ( model.viewport.viewport.viewport.width
                            , model.viewport.viewport.viewport.height - consoleTitleHeight
                            )

                ( ulPX, ulPY ) =
                    calcVisualOrigin model.hexScale
                        { col = model.hexRect.upperLeftHex.x
                        , row = model.hexRect.upperLeftHex.y
                        }

                oldVBX =
                    toFloat ulPX + model.panOffset.x

                oldVBY =
                    toFloat ulPY + model.panOffset.y

                newVBX =
                    ratio * (oldVBX + svgW / 2) - svgW / 2

                newVBY =
                    ratio * (oldVBY + svgH / 2) - svgH / 2

                newULX =
                    floor ((newVBX - newSize) / hexWidth newSize)

                sin60 =
                    sin hexSizeFactor

                newULY =
                    floor ((-newVBY / newSize - 1 - hexColOffset newULX * sin60) / (2 * sin60))

                newUpperLeft =
                    { x = newULX, y = newULY }

                ( newULPX, newULPY ) =
                    calcVisualOrigin newSize { col = newULX, row = newULY }

                newHexRect =
                    { upperLeftHex = newUpperLeft
                    , lowerRightHex = HexAddress.shiftAddressBy { deltaX = hh, deltaY = vh } newUpperLeft
                    }

                ( newModel, newCmds ) =
                    let
                        ( newModel_, newCmds_ ) =
                            ( { model
                                | hexScale = newSize
                                , rawHexaPoints = rawHexagonPoints newSize
                                , hexRect = newHexRect
                                , viewMode = HexMap
                                , panOffset =
                                    { x = newVBX - toFloat newULPX
                                    , y = newVBY - toFloat newULPY
                                    }
                              }
                            , saveHexSize newSize
                            )
                    in
                    update DownloadSolarSystems (withTime newModel_)
                        |> Tuple.mapSecond (\newestCmds -> Cmd.batch [ newCmds_, newestCmds ])
            in
            ( newModel, newCmds )

        RefreshMap ->
            let
                clearedSolarSystems =
                    HexAddress.between model.hexRect.upperLeftHex model.hexRect.lowerRightHex
                        |> List.foldl (\addr dict -> Dict.remove (HexAddress.toKey addr) dict) model.solarSystems
            in
            update DownloadSolarSystems (withTime { model | solarSystems = clearedSolarSystems })

        DownloadSolarSystems ->
            let
                ( ( newSolarSystemDict, newRequestHistory ), cmds ) =
                    prepAndSendRequests ( model.solarSystems, model.requestHistory ) model.hexRect model.hostConfig
            in
            ( withTime
                { model
                    | requestHistory = newRequestHistory
                    , solarSystems = newSolarSystemDict
                }
            , cmds
            )

        DownloadedSolarSystems ( requestEntry, url_ ) (Ok fallibleSolarSystems) ->
            let
                rangeAsPairs =
                    HexAddress.between requestEntry.upperLeftHex requestEntry.lowerRightHex
                        |> List.map
                            (\addr ->
                                let
                                    addrKey =
                                        HexAddress.toKey addr
                                in
                                ( addrKey
                                , case Dict.get addrKey sortedSolarSystems of
                                    Just system ->
                                        system

                                    Nothing ->
                                        case Dict.get addrKey model.solarSystems of
                                            Just (LoadedRogueHex data) ->
                                                LoadedRogueHex data

                                            _ ->
                                                LoadedEmptyHex
                                )
                            )

                newErrors =
                    potentiallyNewErrors
                        |> List.filter
                            (\( newErr, errUrl ) ->
                                List.member newErr (model.oldSolarSystemErrors |> List.map Tuple.first) |> not
                            )

                ( sortedSolarSystems, potentiallyNewErrors ) =
                    fallibleSolarSystems
                        |> List.foldl
                            (\fallibleSystem ( systems, errs ) ->
                                let
                                    -- WARN: don't skip this check before filtering out errors, or we'll miss errors (see below)
                                    hasFailed =
                                        List.any Result.isErr fallibleSystem.stars
                                in
                                if not hasFailed then
                                    let
                                        si =
                                            if model.isReferee then
                                                refereeSI

                                            else
                                                fallibleSystem.surveyIndex

                                        starSystem : StarSystem
                                        starSystem =
                                            { address = fallibleSystem.address
                                            , sectorName = fallibleSystem.sectorName
                                            , name = fallibleSystem.name
                                            , scanPoints = fallibleSystem.scanPoints
                                            , surveyIndex = si
                                            , gasGiantCount = fallibleSystem.gasGiantCount
                                            , terrestrialPlanetCount = fallibleSystem.terrestrialPlanetCount
                                            , planetoidBeltCount = fallibleSystem.planetoidBeltCount
                                            , allegiance = fallibleSystem.allegiance
                                            , nativeSophont = fallibleSystem.nativeSophont
                                            , extinctSophont = fallibleSystem.extinctSophont
                                            , techLevel = fallibleSystem.techLevel
                                            , stars =
                                                -- WARN: relies on hasFailed to be false. if we don't do that check, we'll miss errors
                                                List.map Result.toMaybe fallibleSystem.stars |> List.filterMap identity
                                            , mainWorldUwp = fallibleSystem.mainWorldUwp
                                            , travelZone = fallibleSystem.travelZone
                                            , known = fallibleSystem.known
                                            , mainWorldName = fallibleSystem.mainWorldName
                                            , mainWorldImage = fallibleSystem.mainWorldImage
                                            , wtn = fallibleSystem.wtn
                                            , gwp = fallibleSystem.gwp
                                            , importance = fallibleSystem.importance
                                            , tradeCodes = fallibleSystem.tradeCodes
                                            , strategic = fallibleSystem.strategic
                                            , baseCodes = fallibleSystem.baseCodes
                                            , habitabilityRating = fallibleSystem.habitabilityRating
                                            , governmentCode = fallibleSystem.governmentCode
                                            , governmentName = fallibleSystem.governmentName
                                            , sectorId = fallibleSystem.sectorId
                                            , subsectorId = fallibleSystem.subsectorId
                                            }
                                    in
                                    ( ( HexAddress.toKey fallibleSystem.address
                                      , LoadedSolarSystem starSystem
                                      )
                                        :: systems
                                    , errs
                                    )

                                else
                                    ( ( HexAddress.toKey fallibleSystem.address
                                      , FailedStarsSolarSystem fallibleSystem
                                      )
                                        :: systems
                                    , (fallibleSystem.stars
                                        |> List.filterMap
                                            (\res ->
                                                case res of
                                                    Ok _ ->
                                                        Nothing

                                                    Err er ->
                                                        Just ("Specific Star failed to decode:\n" ++ JsDecode.errorToString er)
                                            )
                                        |> List.map
                                            (\er ->
                                                ( Http.BadBody er, url_ )
                                            )
                                      )
                                        ++ errs
                                    )
                            )
                            ( [], [] )
                        |> Tuple.mapFirst Dict.fromList

                viewportCentre =
                    { x = (model.hexRect.upperLeftHex.x + model.hexRect.lowerRightHex.x) // 2
                    , y = (model.hexRect.upperLeftHex.y + model.hexRect.lowerRightHex.y) // 2
                    }

                solarSystemDict =
                    rangeAsPairs
                        |> Dict.fromList
                        |> (\newDict ->
                                -- `Dict.union` merges the dict, preferring the left arg's to resolve dupes, so we want to prefer the new one
                                Dict.union newDict existingDict
                           )
                        |> evictDistantEntries viewportCentre model.hexRect

                existingDict =
                    model.solarSystems

                newRequestHistory =
                    markRequestComplete requestEntry (RemoteData.Success ()) model.requestHistory
            in
            ( withTime
                { model
                    | solarSystems = solarSystemDict
                    , newSolarSystemErrors = newErrors ++ model.newSolarSystemErrors
                    , requestHistory = newRequestHistory
                }
            , Cmd.batch
                [ Browser.Dom.getViewportOf "hexmap"
                    |> Task.attempt GotHexMapViewport
                ]
            )

        DownloadedSectors requestEntry (Ok sectors) ->
            let
                sectorDict =
                    List.foldl
                        (\sector acc ->
                            Dict.insert (sectorKey sector) sector acc
                        )
                        Dict.empty
                        sectors
            in
            ( withTime
                { model
                    | sectors = sectorDict
                }
            , Cmd.none
            )

        DownloadedSectors ( requestEntry, url ) (Err err) ->
            ( withTime { model | newSolarSystemErrors = ( err, url ) :: model.newSolarSystemErrors }, Cmd.none )

        DownloadedRegions requestEntry (Ok regions) ->
            let
                visibleRegions =
                    if model.isReferee then
                        regions

                    else
                        List.filter .playerVisible regions

                parsecList : Region -> List ( String, Color )
                parsecList region =
                    List.map (\p -> ( HexAddress.toKey p, region.colour ))
                        region.hexes

                regionDict =
                    List.foldl
                        (\region acc ->
                            Dict.insert region.id region acc
                        )
                        Dict.empty
                        visibleRegions

                hexColourDict : Dict.Dict String Color
                hexColourDict =
                    List.map
                        (\region ->
                            parsecList region
                        )
                        visibleRegions
                        |> List.concat
                        |> Dict.fromList

                regionLabelDict : Dict.Dict String String
                regionLabelDict =
                    List.filterMap
                        (\region ->
                            region.labelPosition
                                |> Maybe.map (\pos -> ( HexAddress.toKey pos, region.name ))
                        )
                        visibleRegions
                        |> Dict.fromList
            in
            ( withTime
                { model
                    | regions = regionDict
                    , hexColours = hexColourDict
                    , regionLabels = regionLabelDict
                }
            , Cmd.none
            )

        DownloadedRegions ( requestEntry, url ) (Err err) ->
            let
                parsecList : Region -> List ( String, Color )
                parsecList region =
                    List.map (\p -> ( HexAddress.toKey p, region.colour ))
                        region.hexes

                stub : Region
                stub =
                    { id = 1
                    , colour = Color.blue
                    , borderColour = Nothing
                    , name = "Stub Hennlix Nebula"
                    , playerVisible = True
                    , labelPosition = Just { x = -308, y = -104 }
                    , hexes =
                        [ { x = -308, y = -104 }
                        , { x = -308, y = -105 }
                        , { x = -307, y = -104 }
                        , { x = -309, y = -104 }
                        ]
                    , borderHexes = []
                    }

                hexColourDict : Dict.Dict String Color
                hexColourDict =
                    List.map
                        (\region ->
                            parsecList region
                        )
                        [ stub ]
                        |> List.concat
                        |> Dict.fromList

                regionLabelDict : Dict.Dict String String
                regionLabelDict =
                    List.filterMap
                        (\region ->
                            region.labelPosition
                                |> Maybe.map (\pos -> ( HexAddress.toKey pos, region.name ))
                        )
                        [ stub ]
                        |> Dict.fromList
            in
            ( withTime
                { model
                    | regions = Dict.fromList [ ( 1, stub ) ]
                    , hexColours = hexColourDict
                    , regionLabels = regionLabelDict
                }
            , Cmd.none
            )

        --let
        --    _ =
        --        Debug.log "Regions did not work" err
        --in
        --( { model | newSolarSystemErrors = ( err, url ) :: model.newSolarSystemErrors }, Cmd.none )
        DownloadedRoute ( requestEntry, url ) (Ok route) ->
            let
                firstEntry =
                    List.reverse route |> List.head |> Maybe.map .address
            in
            case firstEntry of
                Just address ->
                    ( withTime
                        { model
                            | route = route
                            , currentAddress = address
                        }
                    , Cmd.none
                    )

                Nothing ->
                    ( withTime
                        { model
                            | route = route
                        }
                    , Cmd.none
                    )

        DownloadedRoute ( requestEntry, url ) (Err err) ->
            ( withTime { model | newSolarSystemErrors = ( err, url ) :: model.newSolarSystemErrors }, Cmd.none )

        DownloadedJumpRouteLinks (Ok links) ->
            ( withTime { model | jumpRouteLinks = links }, Cmd.none )

        DownloadedJumpRouteLinks (Err _) ->
            ( withTime model, Cmd.none )

        FetchedSolarSystem (Ok solarSystem) ->
            if model.pendingCtrlNavigation then
                let
                    ( _, pathParts ) =
                        model.hostConfig

                    campaignPrefix =
                        List.take 2 pathParts |> String.join "/"

                    url =
                        "/" ++ campaignPrefix ++ "/star_systems/" ++ String.fromInt solarSystem.id
                in
                ( withTime { model | pendingCtrlNavigation = False }
                , navigateToUrl url
                )

            else
                let
                    si =
                        if model.isReferee then
                            refereeSI

                        else
                            solarSystem.surveyIndex

                    updatedSS =
                        { solarSystem
                            | surveyIndex = si
                        }
                in
                ( withTime
                    { model
                        | selectedSystem = Just updatedSS
                    }
                , Cmd.none
                )

        FetchedSolarSystem (Err (Http.BadBody err)) ->
            ( withTime { model | pendingCtrlNavigation = False, newSolarSystemErrors = model.newSolarSystemErrors ++ [ ( Http.BadBody err, "foo" ) ] }, Cmd.none )

        FetchedSolarSystem (Err err) ->
            ( withTime { model | pendingCtrlNavigation = False }, Cmd.none )

        SetKnown known ->
            case model.selectedSystem of
                Just solarSystem ->
                    ( withTime { model | selectedSystem = Just { solarSystem | known = known } }
                    , updateStarSystemKnown model.hostConfig solarSystem.id known
                    )

                Nothing ->
                    ( withTime model, Cmd.none )

        SetSurveyIndex surveyIndex ->
            case model.selectedSystem of
                Just solarSystem ->
                    ( withTime { model | selectedSystem = Just { solarSystem | actualSurveyIndex = surveyIndex } }
                    , updateStarSystemSurveyIndex model.hostConfig solarSystem.id surveyIndex
                    )

                Nothing ->
                    ( withTime model, Cmd.none )

        KnownSaved (Err err) ->
            ( withTime { model | newSolarSystemErrors = ( err, "known" ) :: model.newSolarSystemErrors }, Cmd.none )

        KnownSaved (Ok ()) ->
            ( withTime model, Cmd.none )

        SurveyIndexSaved (Err err) ->
            ( withTime { model | newSolarSystemErrors = ( err, "survey_index" ) :: model.newSolarSystemErrors }, Cmd.none )

        SurveyIndexSaved (Ok ()) ->
            ( withTime model, Cmd.none )

        DownloadedSolarSystems ( requestEntry, url ) (Err err) ->
            let
                newRequestHistory =
                    markRequestComplete requestEntry (RemoteData.Failure err) model.requestHistory

                rangeAsPairs =
                    HexAddress.between requestEntry.upperLeftHex requestEntry.lowerRightHex
                        |> List.map
                            (\addr ->
                                let
                                    addrKey =
                                        HexAddress.toKey addr
                                in
                                ( addrKey
                                , Dict.get addrKey existingDict
                                    |> (\maybeSolarsystem ->
                                            case maybeSolarsystem of
                                                Just LoadingSolarSystem ->
                                                    FailedSolarSystem err

                                                Just LoadedEmptyHex ->
                                                    FailedSolarSystem err

                                                Just (FailedSolarSystem _) ->
                                                    FailedSolarSystem err

                                                Just (LoadedSolarSystem solarSystem) ->
                                                    LoadedSolarSystem solarSystem

                                                Just (FailedStarsSolarSystem _) ->
                                                    FailedSolarSystem err

                                                Just (LoadedRogueHex data) ->
                                                    LoadedRogueHex data

                                                Nothing ->
                                                    FailedSolarSystem err
                                       )
                                )
                            )

                solarSystemDict =
                    rangeAsPairs
                        |> Dict.fromList
                        |> (\newDict ->
                                -- `Dict.union` merges the dict, preferring the left arg's to resolve dupes, so we want to prefer the new one
                                Dict.union newDict existingDict
                           )

                existingDict =
                    model.solarSystems
            in
            ( withTime
                { model
                    | solarSystems = solarSystemDict
                    , newSolarSystemErrors = ( err, url ) :: model.newSolarSystemErrors
                    , lastSolarSystemError = Just err
                    , requestHistory = newRequestHistory
                }
            , Cmd.none
            )

        HoveringHex hoveringHex ->
            ( withTime { model | hoveringHex = Just hoveringHex }, Cmd.none )

        GotViewport viewport ->
            let
                oldViewport =
                    model.viewport
            in
            ( withTime { model | viewport = { oldViewport | viewport = viewport } }
            , Browser.Dom.getViewportOf "hexmap"
                |> Task.attempt GotHexMapViewport
            )

        GotHexMapViewport hexmapOrErr ->
            let
                oldViewport =
                    model.viewport

                newViewport =
                    { oldViewport | hexmapViewport = Just hexmapOrErr }

                extraPadding =
                    2

                hh =
                    horizontalHexes (Just hexmapOrErr) model.hexScale + extraPadding

                vh =
                    verticalHexes (Just hexmapOrErr) model.hexScale + extraPadding

                newLowerRight =
                    HexAddress.shiftAddressBy { deltaX = hh, deltaY = vh } model.hexRect.upperLeftHex
            in
            if newLowerRight /= model.hexRect.lowerRightHex then
                let
                    newHexRect =
                        { upperLeftHex = model.hexRect.upperLeftHex, lowerRightHex = newLowerRight }
                in
                update DownloadSolarSystems (withTime { model | viewport = newViewport, hexRect = newHexRect })

            else
                ( withTime { model | viewport = newViewport }, Cmd.none )

        GotResize width height ->
            ( withTime model
            , Cmd.batch
                [ Browser.Dom.getViewport
                    |> Task.perform GotViewport
                , Browser.Dom.getViewportOf "hexmap"
                    |> Task.attempt GotHexMapViewport
                ]
            )

        ViewingHex hexAddress ->
            let
                focusedErrors : List ( Http.Error, String )
                focusedErrors =
                    Dict.get (HexAddress.toKey hexAddress) model.solarSystems
                        |> Maybe.map
                            (\system ->
                                case system of
                                    FailedStarsSolarSystem fallibleSystem ->
                                        fallibleSystem.stars
                                            |> List.filterMap
                                                (\res ->
                                                    case res of
                                                        Ok _ ->
                                                            Nothing

                                                        Err er ->
                                                            Just ("Specific Star failed to decode:\n" ++ JsDecode.errorToString er)
                                                )
                                            |> List.map
                                                (\er ->
                                                    ( Http.BadBody er, "TODO: tie RequestEntry to URL" )
                                                )

                                    _ ->
                                        []
                            )
                        |> Maybe.withDefault []
            in
            ( withTime
                { model
                    | selectedHex = Just hexAddress
                    , selectedSystem = Nothing
                    , showTravelTable = False
                    , showShipTraffic = False
                    , newSolarSystemErrors = focusedErrors
                    , sidebarOpen = True
                }
            , fetchSingleSolarSystemRequest model.hostConfig <| toSectorAddress hexAddress
            )

        ToggleTravelTable ->
            ( withTime { model | showTravelTable = not model.showTravelTable }
            , Cmd.none
            )

        SetTravelTableMDrive n ->
            ( withTime { model | travelTableMDrive = n }
            , Cmd.none
            )

        OpenShipTraffic ->
            case model.selectedSystem of
                Just solarSystem ->
                    ( withTime
                        { model
                            | showShipTraffic = True
                            , shipTraffic = RemoteData.Loading
                            , shipTrafficFrontier = False
                        }
                    , sendShipTrafficRequest model.hostConfig solarSystem.id False
                    )

                Nothing ->
                    ( withTime model, Cmd.none )

        CloseShipTraffic ->
            ( withTime { model | showShipTraffic = False }
            , Cmd.none
            )

        RerollShipTraffic ->
            case model.selectedSystem of
                Just solarSystem ->
                    ( withTime model
                    , sendShipTrafficRequest model.hostConfig solarSystem.id model.shipTrafficFrontier
                    )

                Nothing ->
                    ( withTime model, Cmd.none )

        ToggleShipTrafficFrontier ->
            let
                newFrontier =
                    not model.shipTrafficFrontier
            in
            case model.selectedSystem of
                Just solarSystem ->
                    ( withTime { model | shipTrafficFrontier = newFrontier }
                    , sendShipTrafficRequest model.hostConfig solarSystem.id newFrontier
                    )

                Nothing ->
                    ( withTime { model | shipTrafficFrontier = newFrontier }, Cmd.none )

        FetchedShipTraffic result ->
            ( withTime { model | shipTraffic = RemoteData.fromResult result }
            , Cmd.none
            )

        MapMouseDown coordinates ->
            ( withTime
                { model
                    | dragMode = IsDragging { start = coordinates, last = coordinates }
                }
            , Cmd.none
            )

        PanMap delta ->
            let
                shiftBoth hex =
                    HexAddress.shiftAddressBy delta hex

                newHexRect =
                    { upperLeftHex = shiftBoth model.hexRect.upperLeftHex
                    , lowerRightHex = shiftBoth model.hexRect.lowerRightHex
                    }

                yCompensation =
                    (hexColOffset newHexRect.upperLeftHex.x - hexColOffset model.hexRect.upperLeftHex.x)
                        * model.hexScale
                        * sin hexSizeFactor

                newPanOffset =
                    { x = 0, y = model.panOffset.y + yCompensation }

                ( newModel, downloadCmds ) =
                    update DownloadSolarSystems
                        (withTime { model | hexRect = newHexRect, panOffset = newPanOffset })
            in
            ( newModel
            , Cmd.batch [ saveMapCoords newHexRect.upperLeftHex, savePanOffset newPanOffset, downloadCmds ]
            )

        PanPixels { dx, dy } ->
            let
                colStep =
                    hexWidth model.hexScale

                rowStep =
                    2 * model.hexScale * sin hexSizeFactor

                newRawX =
                    model.panOffset.x + dx

                newRawY =
                    model.panOffset.y + dy

                hexDeltaX =
                    truncate (newRawX / colStep)

                hexDeltaY =
                    truncate (newRawY / rowStep)

                remainderX =
                    newRawX - toFloat hexDeltaX * colStep

                remainderY =
                    newRawY - toFloat hexDeltaY * rowStep

                shiftBoth hex =
                    HexAddress.shiftAddressBy { deltaX = hexDeltaX, deltaY = hexDeltaY } hex

                newHexRect =
                    { upperLeftHex = shiftBoth model.hexRect.upperLeftHex
                    , lowerRightHex = shiftBoth model.hexRect.lowerRightHex
                    }

                yCompensation =
                    (hexColOffset newHexRect.upperLeftHex.x - hexColOffset model.hexRect.upperLeftHex.x)
                        * model.hexScale
                        * sin hexSizeFactor

                newPanOffset =
                    { x = remainderX, y = remainderY + yCompensation }

                newModel =
                    withTime { model | hexRect = newHexRect, panOffset = newPanOffset }
            in
            if hexDeltaX /= 0 || hexDeltaY /= 0 then
                let
                    ( updatedModel, downloadCmds ) =
                        update DownloadSolarSystems newModel
                in
                ( updatedModel, Cmd.batch [ saveMapCoords newHexRect.upperLeftHex, savePanOffset newPanOffset, downloadCmds ] )

            else
                ( newModel, savePanOffset newPanOffset )

        MapMouseUp maybeHexAddress ( upX, upY ) ctrlKey ->
            case model.dragMode of
                IsDragging { start } ->
                    let
                        ( startX, startY ) =
                            start

                        distance =
                            sqrt ((upX - startX) ^ 2 + (upY - startY) ^ 2)

                        isDrag =
                            distance > 5
                    in
                    if isDrag then
                        let
                            ( ( newSolarSystemDict, newRequestHistory ), cmds ) =
                                prepAndSendRequests ( model.solarSystems, model.requestHistory ) model.hexRect model.hostConfig
                        in
                        ( withTime
                            { model
                                | dragMode = NoDragging
                                , requestHistory = newRequestHistory
                                , solarSystems = newSolarSystemDict
                            }
                        , Cmd.batch [ savePanOffset model.panOffset, cmds ]
                        )

                    else
                        case maybeHexAddress of
                            Just hexAddress ->
                                if ctrlKey && model.isReferee then
                                    ( withTime
                                        { model
                                            | dragMode = NoDragging
                                            , pendingCtrlNavigation = True
                                        }
                                    , fetchSingleSolarSystemRequest model.hostConfig <| toSectorAddress hexAddress
                                    )

                                else
                                    let
                                        rogueObjects =
                                            case Dict.get (HexAddress.toKey hexAddress) model.solarSystems of
                                                Just (LoadedRogueHex data) ->
                                                    Just data.objects

                                                _ ->
                                                    Nothing

                                        focusedErrors =
                                            Dict.get (HexAddress.toKey hexAddress) model.solarSystems
                                                |> Maybe.map
                                                    (\system ->
                                                        case system of
                                                            FailedStarsSolarSystem fallibleSystem ->
                                                                fallibleSystem.stars
                                                                    |> List.filterMap
                                                                        (\res ->
                                                                            case res of
                                                                                Ok _ ->
                                                                                    Nothing

                                                                                Err er ->
                                                                                    Just ("Specific Star failed to decode:\n" ++ JsDecode.errorToString er)
                                                                        )
                                                                    |> List.map
                                                                        (\er ->
                                                                            ( Http.BadBody er, "TODO: tie RequestEntry to URL" )
                                                                        )

                                                            _ ->
                                                                []
                                                    )
                                                |> Maybe.withDefault []
                                    in
                                    ( withTime
                                        { model
                                            | dragMode = NoDragging
                                            , selectedHex = Just hexAddress
                                            , selectedSystem = Nothing
                                            , showTravelTable = False
                                            , showShipTraffic = False
                                            , selectedRogueObjects = rogueObjects
                                            , newSolarSystemErrors = focusedErrors
                                            , sidebarOpen = True
                                        }
                                    , case rogueObjects of
                                        Just _ ->
                                            Cmd.none

                                        Nothing ->
                                            fetchSingleSolarSystemRequest model.hostConfig <| toSectorAddress hexAddress
                                    )

                            Nothing ->
                                ( withTime { model | dragMode = NoDragging }
                                , Cmd.none
                                )

                _ ->
                    ( withTime { model | dragMode = NoDragging }
                    , Cmd.none
                    )

        MapMouseMove ( newX, newY ) ->
            case model.dragMode of
                IsDragging { start, last } ->
                    let
                        ( originX, originY ) =
                            last

                        colStep =
                            hexWidth model.hexScale

                        rowStep =
                            2 * model.hexScale * sin hexSizeFactor

                        newRawX =
                            model.panOffset.x + (originX - newX)

                        newRawY =
                            model.panOffset.y + (originY - newY)

                        hexDeltaX =
                            truncate (newRawX / colStep)

                        hexDeltaY =
                            truncate (newRawY / rowStep)

                        remainderX =
                            newRawX - toFloat hexDeltaX * colStep

                        remainderY =
                            newRawY - toFloat hexDeltaY * rowStep

                        shiftAddress hex =
                            HexAddress.shiftAddressBy
                                { deltaX = hexDeltaX, deltaY = hexDeltaY }
                                hex

                        newHexRect =
                            { lowerRightHex = shiftAddress model.hexRect.lowerRightHex
                            , upperLeftHex = shiftAddress model.hexRect.upperLeftHex
                            }

                        yCompensation =
                            (hexColOffset newHexRect.upperLeftHex.x - hexColOffset model.hexRect.upperLeftHex.x)
                                * model.hexScale
                                * sin hexSizeFactor

                        newModel =
                            { model
                                | dragMode = IsDragging { start = start, last = ( newX, newY ) }
                                , hexRect = newHexRect
                                , panOffset = { x = remainderX, y = remainderY + yCompensation }
                            }
                    in
                    ( withTime newModel
                    , if hexDeltaX /= 0 || hexDeltaY /= 0 then
                        saveMapCoords newModel.hexRect.upperLeftHex

                      else
                        Cmd.none
                    )

                NoDragging ->
                    ( withTime model, Cmd.none )

        MapMouseLeave ->
            ( withTime { model | hoveringHex = Nothing, dragMode = NoDragging }, Cmd.none )

        ClearAllErrors ->
            ( withTime { model | newSolarSystemErrors = [], oldSolarSystemErrors = model.newSolarSystemErrors ++ model.oldSolarSystemErrors }, Cmd.none )

        JumpToShip ->
            update (ZoomToHex model.currentAddress True) <| withTime model

        ZoomToHex hexAddress centre ->
            let
                extraPadding =
                    2

                hHexes =
                    horizontalHexes model.viewport.hexmapViewport model.hexScale + extraPadding

                vHexes =
                    verticalHexes model.viewport.hexmapViewport model.hexScale + extraPadding

                newUpperLeft =
                    if centre then
                        hexAddress
                            |> HexAddress.shiftAddressBy
                                { deltaX = -1 * hHexes // 2
                                , deltaY = -1 * vHexes // 2
                                }

                    else
                        hexAddress
                            |> HexAddress.shiftAddressBy
                                { deltaX = -2
                                , deltaY = -2
                                }

                newHexRect =
                    { upperLeftHex = newUpperLeft
                    , lowerRightHex =
                        newUpperLeft
                            |> HexAddress.shiftAddressBy
                                { deltaX = hHexes
                                , deltaY = vHexes
                                }
                    }

                ( ( newSolarSystemDict, newRequestHistory ), cmds ) =
                    prepAndSendRequests ( model.solarSystems, model.requestHistory ) newHexRect model.hostConfig
            in
            ( withTime
                { model
                    | hexRect = newHexRect
                    , requestHistory = newRequestHistory
                    , solarSystems = newSolarSystemDict
                    , panOffset = { x = 0, y = 0 }
                }
            , Cmd.batch
                [ saveMapCoords newHexRect.upperLeftHex
                , savePanOffset { x = 0, y = 0 }
                , cmds
                ]
            )

        SetViewMode targetMode ->
            let
                viewModeString =
                    case targetMode of
                        FullJourney ->
                            "FullJourney"

                        HexMap ->
                            "HexMap"

                ( updatedModel, downloadCmds ) =
                    case targetMode of
                        HexMap ->
                            update DownloadSolarSystems (withTime { model | viewMode = targetMode })

                        FullJourney ->
                            ( withTime { model | viewMode = targetMode }, Cmd.none )
            in
            ( updatedModel, Cmd.batch [ storeViewMode viewModeString, downloadCmds ] )

        SetDisplayMode mode ->
            let
                modeString =
                    case mode of
                        ShowStars ->
                            "Stars"

                        ShowMainWorld ->
                            "MainWorld"

                        ShowWTN ->
                            "WTN"

                        ShowGWP ->
                            "GWP"

                        ShowTradeCodes ->
                            "TradeCodes"

                        ShowImportance ->
                            "Importance"

                        ShowStrategic ->
                            "Strategic"

                        ShowResource ->
                            "Resource"

                        ShowTechLevel ->
                            "TechLevel"

                        ShowHabitability ->
                            "Habitability"

                        ShowGovernment ->
                            "Government"
            in
            ( withTime { model | displayMode = mode, showMapDisplayDropdown = False }
            , storeDisplayMode modeString
            )

        SetRegionDisplay mode ->
            let
                modeString =
                    case mode of
                        HideRegions ->
                            "Hide"

                        ShowRegionsFill ->
                            "Fill"

                        ShowRegionsBorder ->
                            "Border"

                        ShowRegionsBoth ->
                            "Both"
            in
            ( withTime { model | regionDisplay = mode, showRegionDropdown = False }
            , storeRegionDisplay modeString
            )

        ToggleDisplaySettings ->
            ( withTime
                { model
                    | showDisplaySettings = not model.showDisplaySettings
                    , showMapDisplayDropdown = False
                    , showRegionDropdown = False
                }
            , Cmd.none
            )

        ToggleMapDisplayDropdown ->
            ( withTime
                { model
                    | showMapDisplayDropdown = not model.showMapDisplayDropdown
                    , showRegionDropdown = False
                }
            , Cmd.none
            )

        ToggleRegionDropdown ->
            ( withTime
                { model
                    | showRegionDropdown = not model.showRegionDropdown
                    , showMapDisplayDropdown = False
                }
            , Cmd.none
            )

        ToggleSectorLines ->
            ( withTime { model | showSectorLines = not model.showSectorLines }
            , storeSectorLines (not model.showSectorLines)
            )

        ToggleSubsectorLines ->
            ( withTime { model | showSubsectorLines = not model.showSubsectorLines }
            , storeSubsectorLines (not model.showSubsectorLines)
            )

        ToggleBackgroundNames ->
            ( withTime { model | showBackgroundNames = not model.showBackgroundNames }
            , storeBackgroundNames (not model.showBackgroundNames)
            )

        ToggleJumpLogFill ->
            ( withTime { model | showJumpLogFill = not model.showJumpLogFill }
            , storeJumpLogFill (not model.showJumpLogFill)
            )

        SearchInput query ->
            let
                ss =
                    model.searchState

                newState =
                    { ss
                        | query = query
                        , dropdownOpen = String.length query >= 3
                        , results =
                            if String.length query >= 3 then
                                RemoteData.Loading

                            else
                                RemoteData.NotAsked
                    }
            in
            ( withTime { model | searchState = newState }
            , if String.length query >= 3 then
                sendSearchRequest query model.hostConfig

              else
                Cmd.none
            )

        GotSearchResults (Ok results) ->
            let
                ss =
                    model.searchState

                stillValid =
                    String.length ss.query >= 3

                newState =
                    { ss
                        | results =
                            if stillValid then
                                RemoteData.Success results

                            else
                                RemoteData.NotAsked
                        , dropdownOpen = stillValid && not (List.isEmpty results)
                    }
            in
            ( withTime { model | searchState = newState }
            , Cmd.none
            )

        GotSearchResults (Err err) ->
            let
                ss =
                    model.searchState

                newState =
                    { ss | results = RemoteData.Failure err, dropdownOpen = False }
            in
            ( withTime { model | searchState = newState }
            , Cmd.none
            )

        SelectSearchResult result ->
            let
                ss =
                    model.searchState

                clearedSS =
                    { ss | dropdownOpen = False, query = "", results = RemoteData.NotAsked }

                clearedModel =
                    { model | searchState = clearedSS, viewMode = HexMap }
            in
            case searchNavigation result clearedModel of
                Nothing ->
                    ( withTime clearedModel, Cmd.none )

                Just ( targetHex, Nothing ) ->
                    let
                        ( scaledModel, scaleCmds ) =
                            update (SetHexSize 60) (withTime clearedModel)

                        ( zoomedModel, zoomCmds ) =
                            update (ZoomToHex targetHex True) scaledModel

                        ( finalModel, viewCmds ) =
                            update (ViewingHex targetHex) zoomedModel
                    in
                    ( finalModel, Cmd.batch [ scaleCmds, zoomCmds, viewCmds ] )

                Just ( targetHex, Just newScale ) ->
                    let
                        ( scaledModel, scaleCmds ) =
                            update (SetHexSize newScale) (withTime clearedModel)

                        ( finalModel, zoomCmds ) =
                            update (ZoomToHex targetHex True) scaledModel
                    in
                    ( finalModel, Cmd.batch [ scaleCmds, zoomCmds ] )

        FocusSearch ->
            ( withTime model
            , Task.attempt (\_ -> NoOpMsg) (Browser.Dom.focus "starmap-search")
            )

        CloseSearchDropdown ->
            let
                ss =
                    model.searchState

                clearedSS =
                    { ss | dropdownOpen = False, query = "", results = RemoteData.NotAsked }
            in
            ( withTime { model | searchState = clearedSS }
            , Cmd.none
            )

        SelectTheme key ->
            let
                newIsLight =
                    model.themeOptions
                        |> List.filter (\option -> option.key == key)
                        |> List.head
                        |> Maybe.map .light
                        |> Maybe.withDefault model.themeIsLight
            in
            ( withTime { model | theme = key, themeIsLight = newIsLight, showThemeMenu = False }
            , setTheme key
            )

        ToggleThemeMenu ->
            ( withTime { model | showThemeMenu = not model.showThemeMenu }
            , Cmd.none
            )

        ToggleHighlightRulesMenu ->
            ( withTime
                { model
                    | showHighlightRulesMenu = not model.showHighlightRulesMenu
                    , pendingDeleteRuleId = Nothing
                }
            , Cmd.none
            )

        ToggleRuleEnabled ruleId ->
            if model.isReferee then
                case findRuleWithId ruleId model.highlightRules of
                    Just ( id, rule ) ->
                        ( withTime model, sendUpdateSurveyOverlayRequest model.hostConfig id { rule | enabled = not rule.enabled } )

                    Nothing ->
                        ( withTime model, Cmd.none )

            else
                let
                    newRules =
                        List.map
                            (\rule ->
                                if rule.id == ruleId then
                                    { rule | enabled = not rule.enabled }

                                else
                                    rule
                            )
                            model.highlightRules
                in
                ( withTime { model | highlightRules = newRules }
                , storeHighlightRules (Codec.encodeToValue HighlightRule.rulesCodec newRules)
                )

        StartNewRule ->
            let
                newId =
                    "rule-" ++ String.fromInt model.nextRuleId
            in
            ( withTime
                { model
                    | ruleEditor = Just (HighlightRuleEditor.init (HighlightRule.newRule newId (Color.rgb255 250 204 21)))
                    , nextRuleId = model.nextRuleId + 1
                    , showHighlightRulesMenu = False
                    , pendingDeleteRuleId = Nothing
                }
            , Cmd.none
            )

        StartEditRule ruleId ->
            case model.highlightRules |> List.filter (\r -> r.id == ruleId) |> List.head of
                Just rule ->
                    ( withTime
                        { model
                            | ruleEditor = Just (HighlightRuleEditor.init rule)
                            , showHighlightRulesMenu = False
                            , pendingDeleteRuleId = Nothing
                        }
                    , Cmd.none
                    )

                Nothing ->
                    ( withTime model, Cmd.none )

        RequestDeleteRule ruleId ->
            ( withTime { model | pendingDeleteRuleId = Just ruleId, showHighlightRulesMenu = False }, Cmd.none )

        CancelDeleteRule ->
            ( withTime { model | pendingDeleteRuleId = Nothing }, Cmd.none )

        DeleteRule ruleId ->
            if model.isReferee then
                case String.toInt ruleId of
                    Just id ->
                        ( withTime { model | pendingDeleteRuleId = Nothing }, sendDeleteSurveyOverlayRequest model.hostConfig id )

                    Nothing ->
                        ( withTime { model | pendingDeleteRuleId = Nothing }, Cmd.none )

            else
                let
                    newRules =
                        List.filter (\r -> r.id /= ruleId) model.highlightRules
                in
                ( withTime { model | highlightRules = newRules, pendingDeleteRuleId = Nothing }
                , storeHighlightRules (Codec.encodeToValue HighlightRule.rulesCodec newRules)
                )

        MoveRuleUp ruleId ->
            if model.isReferee then
                case String.toInt ruleId of
                    Just id ->
                        ( withTime model, sendMoveSurveyOverlayRequest model.hostConfig id True )

                    Nothing ->
                        ( withTime model, Cmd.none )

            else
                let
                    newRules =
                        moveRule ruleId -1 model.highlightRules
                in
                ( withTime { model | highlightRules = newRules }
                , storeHighlightRules (Codec.encodeToValue HighlightRule.rulesCodec newRules)
                )

        MoveRuleDown ruleId ->
            if model.isReferee then
                case String.toInt ruleId of
                    Just id ->
                        ( withTime model, sendMoveSurveyOverlayRequest model.hostConfig id False )

                    Nothing ->
                        ( withTime model, Cmd.none )

            else
                let
                    newRules =
                        moveRule ruleId 1 model.highlightRules
                in
                ( withTime { model | highlightRules = newRules }
                , storeHighlightRules (Codec.encodeToValue HighlightRule.rulesCodec newRules)
                )

        HighlightRuleEditorMsg editorMsg ->
            case model.ruleEditor of
                Nothing ->
                    ( withTime model, Cmd.none )

                Just editorModel ->
                    case editorMsg of
                        HighlightRuleEditor.Cancel ->
                            ( withTime { model | ruleEditor = Nothing }, Cmd.none )

                        HighlightRuleEditor.Save ->
                            let
                                savedRule =
                                    editorModel.draft

                                isExisting =
                                    List.any (\r -> r.id == savedRule.id) model.highlightRules
                            in
                            if model.isReferee then
                                case ( isExisting, String.toInt savedRule.id ) of
                                    ( True, Just id ) ->
                                        ( withTime { model | ruleEditor = Nothing }
                                        , sendUpdateSurveyOverlayRequest model.hostConfig id savedRule
                                        )

                                    _ ->
                                        ( withTime { model | ruleEditor = Nothing }
                                        , sendCreateSurveyOverlayRequest model.hostConfig savedRule
                                        )

                            else
                                let
                                    newRules =
                                        if isExisting then
                                            List.map
                                                (\r ->
                                                    if r.id == savedRule.id then
                                                        savedRule

                                                    else
                                                        r
                                                )
                                                model.highlightRules

                                        else
                                            model.highlightRules ++ [ savedRule ]
                                in
                                ( withTime { model | ruleEditor = Nothing, highlightRules = newRules }
                                , storeHighlightRules (Codec.encodeToValue HighlightRule.rulesCodec newRules)
                                )

                        _ ->
                            ( withTime { model | ruleEditor = Just (HighlightRuleEditor.update (pickerData model) editorMsg editorModel) }
                            , Cmd.none
                            )

        GoToRailsApp ->
            let
                centreX =
                    (model.hexRect.upperLeftHex.x + model.hexRect.lowerRightHex.x) // 2

                centreY =
                    (model.hexRect.upperLeftHex.y + model.hexRect.lowerRightHex.y) // 2
            in
            ( withTime model, sendSubsectorLookupRequest model.hostConfig centreX centreY )

        GotSubsectorLookupUrl result ->
            case result of
                Ok url ->
                    ( withTime model, Browser.Navigation.load url )

                Err _ ->
                    ( withTime model, Browser.Navigation.load (fallbackSectorsUrl model.hostConfig) )

        OpenRoutePlanner ->
            ( withTime { model | routePlanForm = Just (RoutePlanForm.init (routePlanFormConfig model)) }, Cmd.none )

        DownloadedTravelZones (Ok zones) ->
            ( withTime { model | travelZoneOptions = zones }, Cmd.none )

        DownloadedTravelZones (Err _) ->
            ( withTime model, Cmd.none )

        GotSurveyOverlays (Ok rules) ->
            ( withTime { model | highlightRules = rules }, Cmd.none )

        GotSurveyOverlays (Err _) ->
            ( withTime model, Cmd.none )

        SurveyOverlayMutated (Ok ()) ->
            ( withTime model, sendSurveyOverlaysRequest model.hostConfig )

        SurveyOverlayMutated (Err _) ->
            ( withTime model, Cmd.none )

        ToggleJumpRouteLayersMenu ->
            ( withTime
                { model
                    | showJumpRouteLayersMenu = not model.showJumpRouteLayersMenu
                    , pendingDeleteJumpRouteId = Nothing
                }
            , Cmd.none
            )

        ToggleJumpRouteLayerHidden routeId ->
            let
                newHidden =
                    if Set.member routeId model.hiddenJumpRouteIds then
                        Set.remove routeId model.hiddenJumpRouteIds

                    else
                        Set.insert routeId model.hiddenJumpRouteIds
            in
            ( withTime { model | hiddenJumpRouteIds = newHidden }
            , storeHiddenJumpRouteIds (Codec.encodeToValue JumpRouteLayer.hiddenIdsCodec newHidden)
            )

        StartEditJumpRouteLayer routeId ->
            case model.jumpRouteLayers |> List.filter (\r -> r.id == routeId) |> List.head of
                Just route ->
                    if route.routeType == "network" then
                        ( withTime
                            { model
                                | jumpRouteLayerEditor = Just (JumpRouteLayerEditor.init route)
                                , showJumpRouteLayersMenu = False
                                , pendingDeleteJumpRouteId = Nothing
                            }
                        , Cmd.none
                        )

                    else
                        ( withTime { model | showJumpRouteLayersMenu = False, pendingDeleteJumpRouteId = Nothing }
                        , navigateToUrlSameTab (jumpRouteEditUrl model.hostConfig routeId)
                        )

                Nothing ->
                    ( withTime model, Cmd.none )

        RequestDeleteJumpRouteLayer routeId ->
            ( withTime { model | pendingDeleteJumpRouteId = Just routeId }, Cmd.none )

        CancelDeleteJumpRouteLayer ->
            ( withTime { model | pendingDeleteJumpRouteId = Nothing }, Cmd.none )

        DeleteJumpRouteLayer routeId ->
            ( withTime { model | pendingDeleteJumpRouteId = Nothing }
            , sendDeleteJumpRouteRequest model.hostConfig routeId
            )

        DeletedJumpRouteLayer routeId (Ok ()) ->
            let
                newHidden =
                    Set.remove routeId model.hiddenJumpRouteIds
            in
            ( withTime
                { model
                    | jumpRouteLayers = List.filter (\r -> r.id /= routeId) model.jumpRouteLayers
                    , hiddenJumpRouteIds = newHidden
                }
            , Cmd.batch
                [ sendJumpRouteLinksRequest model.hostConfig
                , storeHiddenJumpRouteIds (Codec.encodeToValue JumpRouteLayer.hiddenIdsCodec newHidden)
                ]
            )

        DeletedJumpRouteLayer _ (Err _) ->
            ( withTime model, Cmd.none )

        JumpRouteLayerEditorMsg editorMsg ->
            case model.jumpRouteLayerEditor of
                Nothing ->
                    ( withTime model, Cmd.none )

                Just editorModel ->
                    case editorMsg of
                        JumpRouteLayerEditor.Cancel ->
                            ( withTime { model | jumpRouteLayerEditor = Nothing }, Cmd.none )

                        JumpRouteLayerEditor.GotSaveResult (Ok savedRoute) ->
                            let
                                newLayers =
                                    List.map
                                        (\r ->
                                            if r.id == savedRoute.id then
                                                savedRoute

                                            else
                                                r
                                        )
                                        model.jumpRouteLayers
                            in
                            ( withTime { model | jumpRouteLayerEditor = Nothing, jumpRouteLayers = newLayers }
                            , sendJumpRouteLinksRequest model.hostConfig
                            )

                        _ ->
                            let
                                ( newEditor, editorCmd ) =
                                    JumpRouteLayerEditor.update (jumpRouteLayerEditorConfig model) editorMsg editorModel
                            in
                            ( withTime { model | jumpRouteLayerEditor = Just newEditor }
                            , Cmd.map JumpRouteLayerEditorMsg editorCmd
                            )

        DownloadedJumpRouteLayers (Ok routes) ->
            ( withTime { model | jumpRouteLayers = routes }, Cmd.none )

        DownloadedJumpRouteLayers (Err _) ->
            ( withTime model, Cmd.none )

        RoutePlanFormMsg subMsg ->
            case model.routePlanForm of
                Nothing ->
                    ( withTime model, Cmd.none )

                Just formModel ->
                    case subMsg of
                        RoutePlanForm.Cancel ->
                            ( withTime { model | routePlanForm = Nothing }, Cmd.none )

                        RoutePlanForm.GotSaveResult (Ok _) ->
                            ( withTime { model | routePlanForm = Nothing }
                            , sendJumpRouteLinksRequest model.hostConfig
                            )

                        RoutePlanForm.GotPlanResult (Ok planResult) ->
                            let
                                ( newForm, formCmd ) =
                                    RoutePlanForm.update (routePlanFormConfig model) subMsg formModel

                                ( newActiveRoutePlan, storeCmd ) =
                                    if not model.isReferee && planResult.found then
                                        let
                                            stored =
                                                { result = planResult, colour = playerRoutePlanColour }
                                        in
                                        ( Just stored, storeRoutePlan (Codec.encodeToValue RoutePlan.storedRoutePlanCodec stored) )

                                    else
                                        ( model.activeRoutePlan, Cmd.none )
                            in
                            ( withTime { model | routePlanForm = Just newForm, activeRoutePlan = newActiveRoutePlan }
                            , Cmd.batch [ Cmd.map RoutePlanFormMsg formCmd, storeCmd ]
                            )

                        _ ->
                            let
                                ( newForm, formCmd ) =
                                    RoutePlanForm.update (routePlanFormConfig model) subMsg formModel
                            in
                            ( withTime { model | routePlanForm = Just newForm }, Cmd.map RoutePlanFormMsg formCmd )

        ToggleHexmap ->
            update
                (SetViewMode
                    (if model.viewMode == HexMap then
                        FullJourney

                     else
                        HexMap
                    )
                )
                ( time, model )

        JourneyMsg journeyMsg ->
            updateJourney journeyMsg <| withTime model

        ViewObjectAnalysisDetail stellarObject ->
            let
                rnd digits =
                    Round.round digits

                rndm digits def =
                    Maybe.withDefault def
                        >> Round.round digits

                fromKelvin k =
                    rnd 0 <| Maybe.withDefault 0 k - 273.15

                analysisDetail : AnalysisDetail
                analysisDetail =
                    let
                        showName =
                            case model.selectedSystem of
                                Just sys ->
                                    model.isReferee || sys.surveyIndex >= 10

                                Nothing ->
                                    model.isReferee

                        header : AnalysisDetailHeader
                        header =
                            let
                                orbitSeq =
                                    getStellarOrbit stellarObject |> .orbitSequence
                            in
                            { header =
                                case stellarObject of
                                    TerrestrialPlanet pdata ->
                                        if showName then
                                            pdata.name |> Maybe.withDefault orbitSeq

                                        else
                                            orbitSeq

                                    Planetoid pdata ->
                                        if showName then
                                            pdata.name |> Maybe.withDefault orbitSeq

                                        else
                                            orbitSeq

                                    PlanetoidBelt pdata ->
                                        if showName then
                                            pdata.name |> Maybe.withDefault orbitSeq

                                        else
                                            orbitSeq

                                    GasGiant ggdata ->
                                        if showName then
                                            ggdata.name |> Maybe.withDefault (orbitSeq ++ " [" ++ ggdata.code ++ "]")

                                        else
                                            orbitSeq ++ " [" ++ ggdata.code ++ "]"

                                    Star _ ->
                                        orbitSeq ++ " [" ++ getProfileString stellarObject ++ "]"
                            }

                        buildStringGasGiant : GasGiantData -> AnalyisDetailGasGiantData
                        buildStringGasGiant ggdata =
                            { code = ggdata.code
                            , jumpShadowKm = ggdata.jumpShadow
                            , physical =
                                { au = rnd 2 ggdata.au
                                , period = rnd 2 (ggdata.period / 365.25)
                                , inclination = rnd 0 ggdata.inclination ++ "°"
                                , eccentricity = rnd 2 ggdata.eccentricity
                                , mass = rndm 2 0 ggdata.mass
                                , diameter = format { usLocale | decimals = Exact 0, thousandSeparator = " " } ggdata.diameter
                                , axialTilt = rnd 2 ggdata.axialTilt ++ "°"
                                , moons = String.fromInt <| List.length ggdata.moons
                                , hasRing =
                                    if ggdata.hasRing then
                                        "Yes"

                                    else
                                        "No"
                                }
                            }

                        buildStringPlanetoidBelt : PlanetoidBeltData -> AnalyisDetailPlanetoidBeltData
                        buildStringPlanetoidBelt pdata =
                            let
                                rr =
                                    round pdata.resourceRating

                                parsedUwp =
                                    Parser.run uwp pdata.uwp

                                uwpField accessor describer =
                                    case parsedUwp of
                                        Ok u ->
                                            describer (accessor u)

                                        Err _ ->
                                            "—"

                                fmtCodeAndDesc maybeItem =
                                    case maybeItem of
                                        Just item ->
                                            item.code ++ " – " ++ item.description

                                        Nothing ->
                                            ""

                                fmtIntCodeAndDesc maybeItem =
                                    case maybeItem of
                                        Just item ->
                                            toEHexChar item.code ++ " – " ++ item.description

                                        Nothing ->
                                            ""

                                fmtBool maybeBool =
                                    case maybeBool of
                                        Just True ->
                                            "Yes"

                                        Just False ->
                                            "No"

                                        Nothing ->
                                            ""

                                fmtTechCap maybeCap =
                                    case maybeCap of
                                        Just cap ->
                                            toEHexChar cap.code ++ " – " ++ cap.description

                                        Nothing ->
                                            ""

                                govType =
                                    pdata.governmentDetail
                                        |> Maybe.andThen .type_
                                        |> Maybe.withDefault ""

                                govDescription =
                                    pdata.governmentDetail
                                        |> Maybe.andThen .description
                                        |> Maybe.withDefault ""

                                govStructure =
                                    pdata.governmentDetail
                                        |> Maybe.andThen .structure

                                govChars =
                                    pdata.governmentDetail
                                        |> Maybe.andThen .characteristics

                                lawSubs =
                                    pdata.lawLevelDetail
                                        |> Maybe.andThen .subClassifications

                                lawChars =
                                    pdata.lawLevelDetail
                                        |> Maybe.andThen .characteristics

                                tlDetail =
                                    pdata.techLevelDetail

                                uwpChar i =
                                    String.slice i (i + 1) pdata.uwp

                                withCode i accessor describer =
                                    case parsedUwp of
                                        Ok u ->
                                            uwpChar i ++ " – " ++ describer (accessor u)

                                        Err _ ->
                                            "—"

                                spCode =
                                    String.slice 0 1 pdata.uwp

                                atm =
                                    pdata.atmosphere
                                        |> Maybe.withDefault
                                            { code = 0
                                            , irritant = Nothing
                                            , taint = { subtype = "", code = "", severity = 0, persistence = 0 }
                                            , characteristic = Nothing
                                            , bar = 0.0
                                            , gasType = Nothing
                                            , density = Nothing
                                            , hazardCode = Nothing
                                            }

                                planet : AnalyisDetailPlanetoidData
                                planet =
                                    { uwp = pdata.uwp
                                    , jumpShadowKm = pdata.jumpShadow
                                    , physical =
                                        { au = rnd 2 pdata.au
                                        , period = rnd 2 (pdata.period / 365.25)
                                        , inclination = rnd 0 pdata.inclination ++ "°"
                                        , eccentricity = rnd 2 pdata.eccentricity
                                        , mass = "—"
                                        , density = "—"
                                        , gravity = "—"
                                        , diameter = "—"
                                        , meanTemperature = fromKelvin pdata.meanTemperature
                                        , albedo = "—"
                                        , axialTilt = "—"
                                        , greenhouse = "—"
                                        , sizeCode = uwpChar 1
                                        , rotation = "—"
                                        }
                                    , orbital =
                                        { orbit = rnd 2 pdata.orbit
                                        , retrograde =
                                            if pdata.retrograde then
                                                "Yes"

                                            else
                                                "No"
                                        , effectiveHZCODeviation = rnd 2 pdata.effectiveHZCODeviation
                                        }
                                    , atmosphere =
                                        { type_ = toEHexChar atm.code ++ " – " ++ atmosphereDescriptionEx atm.code
                                        , hazardCode = atmosphereHazardDescription atm.hazardCode
                                        , bar = rnd 1 atm.bar
                                        , taint =
                                            { subtype = taintSubtypeDescription atm.taint.code
                                            , severity = taintSeverityDescription atm.taint.severity
                                            , persistence = taintPersistenceDescription atm.taint.persistence
                                            }
                                        }
                                    , hydrographics =
                                        { percentage =
                                            pdata.hydrographics
                                                |> Maybe.map (.code >> hydrographicsPercentageDescription)
                                                |> Maybe.withDefault "N/A"
                                        , liquid =
                                            pdata.hydrographics
                                                |> Maybe.andThen .liquid
                                                |> Maybe.withDefault ""
                                        , surfaceDistribution =
                                            pdata.hydrographics
                                                |> Maybe.map (.distribution >> surfaceDistributionDescription)
                                                |> Maybe.withDefault "N/A"
                                        }
                                    , life =
                                        { biomass = biomassDescription pdata.biomassRating
                                        , biocomplexity = biocomplexityDescription pdata.biocomplexityCode
                                        , biodiversity = biodiversityDescription pdata.biodiversityRating
                                        , compatibility = bioChemistryCompatibilityDescription pdata.compatibilityRating
                                        , habitability = habitabilityDescription pdata.habitabilityRating
                                        , sophonts =
                                            if pdata.nativeSophont then
                                                "Yes"

                                            else
                                                "No"
                                        }
                                    , social =
                                        { population = withCode 4 .population populationDescription
                                        , concentrationRating = pdata.population |> Maybe.andThen .concentrationRating
                                        , urbanizationPercentage = pdata.population |> Maybe.andThen .urbanizationPercentage
                                        , majorCities = pdata.population |> Maybe.andThen .majorCities
                                        , government =
                                            if uwpChar 4 == "0" then
                                                "—"

                                            else
                                                withCode 5 .government Government.description
                                        , lawLevel =
                                            if uwpChar 4 == "0" then
                                                "—"

                                            else
                                                withCode 6 .lawLevel LawLevel.description
                                        , techLevel =
                                            if uwpChar 4 == "0" then
                                                "—"

                                            else
                                                withCode 8 .techLevel TechLevel.description
                                        }
                                    , cultureTrait =
                                        pdata.population
                                            |> Maybe.map .cultureTrait
                                            |> Maybe.withDefault []
                                            |> List.map
                                                (\ct ->
                                                    { label = ct.label
                                                    , value = ct.value
                                                    , min = ct.min
                                                    , max = ct.max
                                                    , lowLabel = ct.lowLabel
                                                    , highLabel = ct.highLabel
                                                    }
                                                )
                                    , government =
                                        { type_ = govType
                                        , description = govDescription
                                        , judicial = govStructure |> Maybe.andThen .judicial |> fmtCodeAndDesc
                                        , executive = govStructure |> Maybe.andThen .executive |> fmtCodeAndDesc
                                        , legislative = govStructure |> Maybe.andThen .legislative |> fmtCodeAndDesc
                                        , authority = govChars |> Maybe.andThen .authority |> fmtCodeAndDesc
                                        , centralisation = govChars |> Maybe.andThen .centralisation |> fmtCodeAndDesc
                                        }
                                    , lawSubClassifications =
                                        { weaponsAndArmour = lawSubs |> Maybe.andThen .weaponsAndArmour |> fmtIntCodeAndDesc
                                        , criminalLaw = lawSubs |> Maybe.andThen .criminalLaw |> fmtIntCodeAndDesc
                                        , economicLaw = lawSubs |> Maybe.andThen .economicLaw |> fmtIntCodeAndDesc
                                        , privateLaw = lawSubs |> Maybe.andThen .privateLaw |> fmtIntCodeAndDesc
                                        , personalRights = lawSubs |> Maybe.andThen .personalRights |> fmtIntCodeAndDesc
                                        }
                                    , lawCharacteristics =
                                        { uniformity = lawChars |> Maybe.andThen .uniformity |> fmtCodeAndDesc
                                        , judicialSystem = lawChars |> Maybe.andThen .judicialSystem |> fmtCodeAndDesc
                                        , deathPenalty = lawChars |> Maybe.andThen .deathPenalty |> fmtBool
                                        , presumedInnocence = lawChars |> Maybe.andThen .presumedInnocence |> fmtBool
                                        , econometricInfractionsAdministrative = lawChars |> Maybe.andThen .econometricInfractionsAdministrative |> fmtBool
                                        }
                                    , techDetail =
                                        { descriptor = tlDetail |> Maybe.andThen .descriptor |> Maybe.withDefault ""
                                        , energy = tlDetail |> Maybe.andThen .energy |> fmtTechCap
                                        , electronics = tlDetail |> Maybe.andThen .electronics |> fmtTechCap
                                        , manufacturing = tlDetail |> Maybe.andThen .manufacturing |> fmtTechCap
                                        , medical = tlDetail |> Maybe.andThen .medical |> fmtTechCap
                                        , environmental = tlDetail |> Maybe.andThen .environmental |> fmtTechCap
                                        , land = tlDetail |> Maybe.andThen .land |> fmtTechCap
                                        , sea = tlDetail |> Maybe.andThen .sea |> fmtTechCap
                                        , air = tlDetail |> Maybe.andThen .air |> fmtTechCap
                                        , space = tlDetail |> Maybe.andThen .space |> fmtTechCap
                                        , personalMilitary = tlDetail |> Maybe.andThen .personalMilitary |> fmtTechCap
                                        , heavyMilitary = tlDetail |> Maybe.andThen .heavyMilitary |> fmtTechCap
                                        }
                                    , starport =
                                        case spCode of
                                            "A" ->
                                                { code = "A", quality = "Excellent", fuel = "Refined fuel", facilities = "Shipyard (all), Repair" }

                                            "B" ->
                                                { code = "B", quality = "Good", fuel = "Refined fuel", facilities = "Shipyard (spacecraft), Repair" }

                                            "C" ->
                                                { code = "C", quality = "Routine", fuel = "Unrefined fuel", facilities = "Shipyard (small craft), Repair" }

                                            "D" ->
                                                { code = "D", quality = "Poor", fuel = "Unrefined fuel", facilities = "Limited Repair" }

                                            "E" ->
                                                { code = "E", quality = "Frontier", fuel = "None", facilities = "None" }

                                            _ ->
                                                { code = "X", quality = "No Starport", fuel = "None", facilities = "None" }
                                    }
                            in
                            { planet = planet
                            , composition =
                                { mType = rnd 0 pdata.mType ++ "%"
                                , sType = rnd 0 pdata.sType ++ "%"
                                , cType = rnd 0 pdata.cType ++ "%"
                                , oType = rnd 0 pdata.oType ++ "%"
                                }
                            , belt =
                                { resourceRating = toEHexChar rr ++ " – " ++ resourceRatingDescription rr
                                , bulk = rnd 0 pdata.bulk
                                , span = rnd 2 pdata.span
                                }
                            }

                        buildStringPlanet : SharedPData -> AnalyisDetailPlanetoidData
                        buildStringPlanet pdata =
                            let
                                parsedUwp =
                                    Parser.run uwp pdata.uwp

                                uwpField accessor describer =
                                    case parsedUwp of
                                        Ok u ->
                                            describer (accessor u)

                                        Err _ ->
                                            "—"

                                fmtCodeAndDesc maybeItem =
                                    case maybeItem of
                                        Just item ->
                                            item.code ++ " – " ++ item.description

                                        Nothing ->
                                            ""

                                fmtIntCodeAndDesc maybeItem =
                                    case maybeItem of
                                        Just item ->
                                            toEHexChar item.code ++ " – " ++ item.description

                                        Nothing ->
                                            ""

                                fmtBool maybeBool =
                                    case maybeBool of
                                        Just True ->
                                            "Yes"

                                        Just False ->
                                            "No"

                                        Nothing ->
                                            ""

                                fmtTechCap maybeCap =
                                    case maybeCap of
                                        Just cap ->
                                            toEHexChar cap.code ++ " – " ++ cap.description

                                        Nothing ->
                                            ""

                                govType =
                                    pdata.governmentDetail
                                        |> Maybe.andThen .type_
                                        |> Maybe.withDefault ""

                                govDescription =
                                    pdata.governmentDetail
                                        |> Maybe.andThen .description
                                        |> Maybe.withDefault ""

                                govStructure =
                                    pdata.governmentDetail
                                        |> Maybe.andThen .structure

                                govChars =
                                    pdata.governmentDetail
                                        |> Maybe.andThen .characteristics

                                lawSubs =
                                    pdata.lawLevelDetail
                                        |> Maybe.andThen .subClassifications

                                lawChars =
                                    pdata.lawLevelDetail
                                        |> Maybe.andThen .characteristics

                                tlDetail =
                                    pdata.techLevelDetail
                            in
                            { uwp = pdata.uwp
                            , jumpShadowKm = pdata.jumpShadow
                            , physical =
                                { au = rnd 2 pdata.au
                                , period =
                                    case pdata.period of
                                        Just p ->
                                            rnd 2 (p / 365.25)

                                        Nothing ->
                                            "—"
                                , inclination = rnd 0 pdata.inclination ++ "°"
                                , eccentricity = rnd 2 pdata.eccentricity
                                , mass = rndm 2 0 pdata.mass
                                , density = rndm 2 0 pdata.density
                                , gravity = rndm 2 0 pdata.gravity
                                , diameter = rnd 0 pdata.diameter
                                , meanTemperature = fromKelvin pdata.meanTemperature
                                , albedo = rnd 2 pdata.albedo
                                , axialTilt = rnd 2 pdata.axialTilt ++ "°"
                                , greenhouse = rndm 2 0 pdata.greenhouse
                                , sizeCode = pdata.size
                                , rotation = pdata.rotation |> Maybe.map (\r -> rnd 2 r ++ " hours") |> Maybe.withDefault "—"
                                }
                            , orbital =
                                { orbit = rnd 2 pdata.orbit
                                , retrograde =
                                    if pdata.retrograde then
                                        "Yes"

                                    else
                                        "No"
                                , effectiveHZCODeviation = rnd 2 pdata.effectiveHZCODeviation
                                }
                            , atmosphere =
                                { type_ = toEHexChar pdata.atmosphere.code ++ " – " ++ atmosphereDescriptionEx pdata.atmosphere.code
                                , hazardCode = atmosphereHazardDescription pdata.atmosphere.hazardCode
                                , bar = rnd 1 <| pdata.atmosphere.bar
                                , taint =
                                    { subtype = taintSubtypeDescription pdata.atmosphere.taint.code
                                    , severity = taintSeverityDescription pdata.atmosphere.taint.severity
                                    , persistence = taintPersistenceDescription pdata.atmosphere.taint.persistence
                                    }
                                }
                            , hydrographics =
                                { percentage =
                                    pdata.hydrographics
                                        |> Maybe.map (.code >> hydrographicsPercentageDescription)
                                        |> Maybe.withDefault "N/A"
                                , liquid =
                                    pdata.hydrographics
                                        |> Maybe.andThen .liquid
                                        |> Maybe.withDefault ""
                                , surfaceDistribution =
                                    pdata.hydrographics
                                        |> Maybe.map (.distribution >> surfaceDistributionDescription)
                                        |> Maybe.withDefault "N/A"
                                }
                            , life =
                                { biomass = biomassDescription pdata.biomassRating
                                , biocomplexity = biocomplexityDescription pdata.biocomplexityCode
                                , biodiversity = biodiversityDescription pdata.biodiversityRating
                                , compatibility = bioChemistryCompatibilityDescription pdata.compatibilityRating
                                , habitability = habitabilityDescription pdata.habitabilityRating
                                , sophonts =
                                    if pdata.nativeSophont then
                                        "Yes"

                                    else
                                        "No"
                                }
                            , social =
                                let
                                    uwpChar i =
                                        String.slice i (i + 1) pdata.uwp

                                    withCode i accessor describer =
                                        case parsedUwp of
                                            Ok u ->
                                                uwpChar i ++ " – " ++ describer (accessor u)

                                            Err _ ->
                                                "—"
                                in
                                { population = withCode 4 .population populationDescription
                                , concentrationRating = pdata.population |> Maybe.andThen .concentrationRating
                                , urbanizationPercentage = pdata.population |> Maybe.andThen .urbanizationPercentage
                                , majorCities = pdata.population |> Maybe.andThen .majorCities
                                , government =
                                    if uwpChar 4 == "0" then
                                        "—"

                                    else
                                        withCode 5 .government Government.description
                                , lawLevel =
                                    if uwpChar 4 == "0" then
                                        "—"

                                    else
                                        withCode 6 .lawLevel LawLevel.description
                                , techLevel =
                                    if uwpChar 4 == "0" then
                                        "—"

                                    else
                                        withCode 8 .techLevel TechLevel.description
                                }
                            , cultureTrait =
                                pdata.population
                                    |> Maybe.map .cultureTrait
                                    |> Maybe.withDefault []
                                    |> List.map
                                        (\ct ->
                                            { label = ct.label
                                            , value = ct.value
                                            , min = ct.min
                                            , max = ct.max
                                            , lowLabel = ct.lowLabel
                                            , highLabel = ct.highLabel
                                            }
                                        )
                            , government =
                                { type_ = govType
                                , description = govDescription
                                , judicial = govStructure |> Maybe.andThen .judicial |> fmtCodeAndDesc
                                , executive = govStructure |> Maybe.andThen .executive |> fmtCodeAndDesc
                                , legislative = govStructure |> Maybe.andThen .legislative |> fmtCodeAndDesc
                                , authority = govChars |> Maybe.andThen .authority |> fmtCodeAndDesc
                                , centralisation = govChars |> Maybe.andThen .centralisation |> fmtCodeAndDesc
                                }
                            , lawSubClassifications =
                                { weaponsAndArmour = lawSubs |> Maybe.andThen .weaponsAndArmour |> fmtIntCodeAndDesc
                                , criminalLaw = lawSubs |> Maybe.andThen .criminalLaw |> fmtIntCodeAndDesc
                                , economicLaw = lawSubs |> Maybe.andThen .economicLaw |> fmtIntCodeAndDesc
                                , privateLaw = lawSubs |> Maybe.andThen .privateLaw |> fmtIntCodeAndDesc
                                , personalRights = lawSubs |> Maybe.andThen .personalRights |> fmtIntCodeAndDesc
                                }
                            , lawCharacteristics =
                                { uniformity = lawChars |> Maybe.andThen .uniformity |> fmtCodeAndDesc
                                , judicialSystem = lawChars |> Maybe.andThen .judicialSystem |> fmtCodeAndDesc
                                , deathPenalty = lawChars |> Maybe.andThen .deathPenalty |> fmtBool
                                , presumedInnocence = lawChars |> Maybe.andThen .presumedInnocence |> fmtBool
                                , econometricInfractionsAdministrative = lawChars |> Maybe.andThen .econometricInfractionsAdministrative |> fmtBool
                                }
                            , techDetail =
                                { descriptor = tlDetail |> Maybe.andThen .descriptor |> Maybe.withDefault ""
                                , energy = tlDetail |> Maybe.andThen .energy |> fmtTechCap
                                , electronics = tlDetail |> Maybe.andThen .electronics |> fmtTechCap
                                , manufacturing = tlDetail |> Maybe.andThen .manufacturing |> fmtTechCap
                                , medical = tlDetail |> Maybe.andThen .medical |> fmtTechCap
                                , environmental = tlDetail |> Maybe.andThen .environmental |> fmtTechCap
                                , land = tlDetail |> Maybe.andThen .land |> fmtTechCap
                                , sea = tlDetail |> Maybe.andThen .sea |> fmtTechCap
                                , air = tlDetail |> Maybe.andThen .air |> fmtTechCap
                                , space = tlDetail |> Maybe.andThen .space |> fmtTechCap
                                , personalMilitary = tlDetail |> Maybe.andThen .personalMilitary |> fmtTechCap
                                , heavyMilitary = tlDetail |> Maybe.andThen .heavyMilitary |> fmtTechCap
                                }
                            , starport =
                                let
                                    spCode =
                                        String.slice 0 1 pdata.uwp
                                in
                                case spCode of
                                    "A" ->
                                        { code = "A", quality = "Excellent", fuel = "Refined fuel", facilities = "Shipyard (all), Repair" }

                                    "B" ->
                                        { code = "B", quality = "Good", fuel = "Refined fuel", facilities = "Shipyard (spacecraft), Repair" }

                                    "C" ->
                                        { code = "C", quality = "Routine", fuel = "Unrefined fuel", facilities = "Shipyard (small craft), Repair" }

                                    "D" ->
                                        { code = "D", quality = "Poor", fuel = "Unrefined fuel", facilities = "Limited Repair" }

                                    "E" ->
                                        { code = "E", quality = "Frontier", fuel = "None", facilities = "None" }

                                    _ ->
                                        { code = "X", quality = "No Starport", fuel = "None", facilities = "None" }
                            }
                    in
                    case stellarObject of
                        GasGiant gasGiantData ->
                            AnalyisDetailGasGiant header <| buildStringGasGiant gasGiantData

                        TerrestrialPlanet pdata ->
                            AnalyisDetailPlanetoid header <| buildStringPlanet pdata

                        PlanetoidBelt planetoidBeltData ->
                            AnalyisDetailPlanetoidBelt header <| buildStringPlanetoidBelt planetoidBeltData

                        Planetoid pdata ->
                            AnalyisDetailPlanetoid header <| buildStringPlanet pdata

                        Star (StarDataWrap starDataConfig) ->
                            let
                                surveyIndex =
                                    model.selectedSystem |> Maybe.map .surveyIndex |> Maybe.withDefault 0

                                starDetailData : AnalyisDetailStarData
                                starDetailData =
                                    { spectralType = starDataConfig.stellarType
                                    , subtype = starDataConfig.subtype |> Maybe.map String.fromInt |> Maybe.withDefault "—"
                                    , class_ = starDataConfig.stellarClass
                                    , temperature = starDataConfig.temperature |> Maybe.map (\t -> String.fromInt t ++ " K") |> Maybe.withDefault "—"
                                    , age = rnd 2 starDataConfig.age ++ " Gyr"
                                    , mass = rndm 3 0 starDataConfig.mass ++ " ☉"
                                    , diameter = rndm 3 0 starDataConfig.diameter ++ " ☉"
                                    , luminosity = rndm 4 0 starDataConfig.luminosity ++ " ☉"
                                    , minimumOrbit = rndm 3 0 starDataConfig.minimumAllowableOrbit
                                    , hzco = rndm 3 0 starDataConfig.hzco
                                    , jumpShadow = starDataConfig.jumpShadow |> Maybe.map (\js -> format { usLocale | decimals = Exact 0, thousandSeparator = " " } js ++ " km") |> Maybe.withDefault "—"
                                    , showNames = showName
                                    , primaryStarData = StarDataWrap starDataConfig
                                    , children = StarOrbitMap.buildChildren surveyIndex starDataConfig.companion starDataConfig.stellarObjects
                                    }
                            in
                            AnalyisDetailStar header starDetailData
            in
            ( withTime
                { model
                    | objectToBeAnalyzed = { stellarObject = stellarObject, data = analysisDetail } :: model.objectToBeAnalyzed
                    , timeOpened = time
                }
            , Cmd.none
            )

        CloseObjectAnalysis ->
            ( withTime
                { model
                    | objectToBeAnalyzed = List.drop 1 model.objectToBeAnalyzed
                    , analysisTab = "orbital"
                    , starMapResizeDrag = Nothing
                }
            , Cmd.none
            )

        SetAnalysisTab tab ->
            ( withTime { model | analysisTab = tab, timeOpened = time }
            , Cmd.none
            )

        StarMapResizeStart { startX, startY } ->
            ( withTime
                { model
                    | starMapResizeDrag =
                        Just
                            { startX = startX
                            , startY = startY
                            , startWidth = model.starMapModalSize.width
                            , startHeight = model.starMapModalSize.height
                            }
                }
            , Cmd.none
            )

        StarMapResizeMove ( clientX, clientY ) ->
            case model.starMapResizeDrag of
                Just drag ->
                    let
                        newWidth =
                            clamp starMapMinWidth starMapMaxWidth (drag.startWidth + (clientX - drag.startX))

                        newHeight =
                            clamp starMapMinHeight starMapMaxHeight (drag.startHeight + (clientY - drag.startY))
                    in
                    ( withTime { model | starMapModalSize = { width = newWidth, height = newHeight } }
                    , Cmd.none
                    )

                Nothing ->
                    ( withTime model, Cmd.none )

        StarMapResizeEnd ->
            ( withTime { model | starMapResizeDrag = Nothing }
            , Cmd.none
            )

        CloseSidebar ->
            ( withTime { model | sidebarOpen = False }
            , Cmd.none
            )

        DownloadedRogues _ (Ok items) ->
            let
                grouped =
                    List.foldl
                        (\item acc ->
                            Dict.update (HexAddress.toKey { x = item.x, y = item.y })
                                (\existing ->
                                    case existing of
                                        Just data ->
                                            Just { data | objects = item.detail :: data.objects }

                                        Nothing ->
                                            Just { surveyIndex = item.surveyIndex, playerVisible = item.playerVisible, objects = [ item.detail ] }
                                )
                                acc
                        )
                        Dict.empty
                        items

                newEntries =
                    Dict.toList grouped
                        |> List.filterMap
                            (\( key, data ) ->
                                case Dict.get key model.solarSystems of
                                    Just (LoadedSolarSystem _) ->
                                        Nothing

                                    _ ->
                                        Just ( key, LoadedRogueHex data )
                            )

                newSolarSystems =
                    List.foldl (\( k, v ) d -> Dict.insert k v d) model.solarSystems newEntries
            in
            ( withTime { model | solarSystems = newSolarSystems }, Cmd.none )

        DownloadedRogues _ (Err _) ->
            ( withTime model, Cmd.none )

        ClearSelectedRogueObjects ->
            ( withTime { model | selectedRogueObjects = Nothing }, Cmd.none )


stripDataFromRemoteData : RemoteData err data -> RemoteData err ()
stripDataFromRemoteData remoteData =
    case remoteData of
        RemoteData.Success _ ->
            RemoteData.Success ()

        RemoteData.Failure err ->
            RemoteData.Failure err

        RemoteData.NotAsked ->
            RemoteData.NotAsked

        RemoteData.Loading ->
            RemoteData.Loading


cacheLimit : Int
cacheLimit =
    500


{-| Removes entries furthest from centre (Chebyshev distance) when the dict
exceeds cacheLimit. Hexes currently inside hexRect are never evicted, regardless
of distance, so visible content is never blanked mid-render.
-}
evictDistantEntries : HexAddress -> HexRect -> SolarSystemDict -> SolarSystemDict
evictDistantEntries centre hexRect dict =
    if Dict.size dict <= cacheLimit then
        dict

    else
        let
            -- Build a lookup of all keys currently in the viewport so we can
            -- protect them from eviction.
            viewportKeys =
                HexAddress.between hexRect.upperLeftHex hexRect.lowerRightHex
                    |> List.map (\h -> ( HexAddress.toKey h, () ))
                    |> Dict.fromList

            chebyshevDistance key =
                case String.split "." key of
                    [ xStr, yStr ] ->
                        case ( String.toInt xStr, String.toInt yStr ) of
                            ( Just x, Just y ) ->
                                max (abs (x - centre.x)) (abs (y - centre.y))

                            _ ->
                                0

                    _ ->
                        0

            keysToRemove =
                Dict.keys dict
                    |> List.filter (\k -> not (Dict.member k viewportKeys))
                    |> List.sortBy chebyshevDistance
                    |> List.reverse
                    |> List.take (max 0 (Dict.size dict - cacheLimit))
        in
        List.foldl Dict.remove dict keysToRemove


markRequestComplete : RequestEntry -> RemoteData Http.Error () -> RequestHistory -> RequestHistory
markRequestComplete requestEntry remoteData requestHistory =
    requestHistory
        |> List.map
            (\entry ->
                if entry.requestNum == requestEntry.requestNum then
                    { entry | status = stripDataFromRemoteData remoteData }

                else
                    entry
            )


sendSectorRequest : RequestEntry -> HostConfig -> Cmd Msg
sendSectorRequest requestEntry hostConfig =
    let
        sectorDecoder : JsDecode.Decoder (List Sector)
        sectorDecoder =
            Codec.list codec
                |> Codec.decoder

        ( urlHostRoot, urlHostPath ) =
            hostConfig

        url =
            Url.Builder.crossOrigin
                urlHostRoot
                (urlHostPath ++ [ "sectors" ])
                []

        requestCmd =
            -- using Http.request instead of Http.get, to allow setting a timeout
            Http.request
                { method = "GET"
                , headers = []
                , url = url
                , body = Http.emptyBody
                , expect = Http.expectJson (DownloadedSectors ( requestEntry, url )) sectorDecoder
                , timeout = Just 15000
                , tracker = Nothing
                }
    in
    requestCmd


sendRegionRequest : RequestEntry -> HostConfig -> Cmd Msg
sendRegionRequest requestEntry hostConfig =
    let
        regionsDecoder : JsDecode.Decoder (List Region)
        regionsDecoder =
            Codec.list Region.codec
                |> Codec.decoder

        ( urlHostRoot, urlHostPath ) =
            hostConfig

        url =
            Url.Builder.crossOrigin
                urlHostRoot
                (urlHostPath ++ [ "regions" ])
                []

        requestCmd =
            Http.request
                { method = "GET"
                , headers = []
                , url = url
                , body = Http.emptyBody
                , expect = Http.expectJson (DownloadedRegions ( requestEntry, url )) regionsDecoder
                , timeout = Just 15000
                , tracker = Nothing
                }
    in
    requestCmd


sendJumpRouteLinksRequest : HostConfig -> Cmd Msg
sendJumpRouteLinksRequest hostConfig =
    let
        ( urlHostRoot, urlHostPath ) =
            hostConfig

        url =
            Url.Builder.crossOrigin
                urlHostRoot
                (urlHostPath ++ [ "jump_route_links" ])
                []
    in
    Http.request
        { method = "GET"
        , headers = []
        , url = url
        , body = Http.emptyBody
        , expect = Http.expectJson DownloadedJumpRouteLinks (JsDecode.list jumpRouteLinkDecoder)
        , timeout = Just 15000
        , tracker = Nothing
        }


sendTravelZonesRequest : HostConfig -> Cmd Msg
sendTravelZonesRequest hostConfig =
    let
        ( urlHostRoot, urlHostPath ) =
            hostConfig

        url =
            Url.Builder.crossOrigin
                urlHostRoot
                (urlHostPath ++ [ "travel_zones" ])
                []
    in
    Http.request
        { method = "GET"
        , headers = []
        , url = url
        , body = Http.emptyBody
        , expect = Http.expectJson DownloadedTravelZones (JsDecode.list RoutePlan.travelZoneOptionDecoder)
        , timeout = Just 15000
        , tracker = Nothing
        }


sendJumpRouteLayersRequest : HostConfig -> Cmd Msg
sendJumpRouteLayersRequest ( urlHostRoot, urlHostPath ) =
    Http.request
        { method = "GET"
        , headers = []
        , url = Url.Builder.crossOrigin urlHostRoot (urlHostPath ++ [ "jump_routes" ]) []
        , body = Http.emptyBody
        , expect = Http.expectJson DownloadedJumpRouteLayers JumpRouteLayer.routesDecoder
        , timeout = Just 15000
        , tracker = Nothing
        }


{-| Survey overlays are a referee-only, DB-backed tool (players keep their
own private set in `localStorage` instead) - this is only ever called for a
referee session, and the server enforces that too.
-}
sendSurveyOverlaysRequest : HostConfig -> Cmd Msg
sendSurveyOverlaysRequest ( urlHostRoot, urlHostPath ) =
    Http.request
        { method = "GET"
        , headers = []
        , url = Url.Builder.crossOrigin urlHostRoot (urlHostPath ++ [ "survey_overlays" ]) []
        , body = Http.emptyBody
        , expect = Http.expectJson GotSurveyOverlays HighlightRule.apiRulesDecoder
        , timeout = Just 15000
        , tracker = Nothing
        }


{-| After any referee mutation (create/update/delete/reorder) succeeds, the
full list is re-fetched from the server rather than patched optimistically,
so the client never drifts from the DB's id/ordering.
-}
sendCreateSurveyOverlayRequest : HostConfig -> HighlightRule.Rule -> Cmd Msg
sendCreateSurveyOverlayRequest ( urlHostRoot, urlHostPath ) rule =
    Http.request
        { method = "POST"
        , headers = []
        , url = Url.Builder.crossOrigin urlHostRoot (urlHostPath ++ [ "survey_overlays" ]) []
        , body = Http.jsonBody (HighlightRule.apiRuleEncodeBody rule)
        , expect = Http.expectWhatever SurveyOverlayMutated
        , timeout = Just 15000
        , tracker = Nothing
        }


sendUpdateSurveyOverlayRequest : HostConfig -> Int -> HighlightRule.Rule -> Cmd Msg
sendUpdateSurveyOverlayRequest ( urlHostRoot, urlHostPath ) id rule =
    Http.request
        { method = "PATCH"
        , headers = []
        , url = Url.Builder.crossOrigin urlHostRoot (urlHostPath ++ [ "survey_overlays", String.fromInt id ]) []
        , body = Http.jsonBody (HighlightRule.apiRuleEncodeBody rule)
        , expect = Http.expectWhatever SurveyOverlayMutated
        , timeout = Just 15000
        , tracker = Nothing
        }


sendDeleteSurveyOverlayRequest : HostConfig -> Int -> Cmd Msg
sendDeleteSurveyOverlayRequest ( urlHostRoot, urlHostPath ) id =
    Http.request
        { method = "DELETE"
        , headers = []
        , url = Url.Builder.crossOrigin urlHostRoot (urlHostPath ++ [ "survey_overlays", String.fromInt id ]) []
        , body = Http.emptyBody
        , expect = Http.expectWhatever SurveyOverlayMutated
        , timeout = Just 15000
        , tracker = Nothing
        }


sendMoveSurveyOverlayRequest : HostConfig -> Int -> Bool -> Cmd Msg
sendMoveSurveyOverlayRequest ( urlHostRoot, urlHostPath ) id moveUp =
    Http.request
        { method = "PATCH"
        , headers = []
        , url = Url.Builder.crossOrigin urlHostRoot (urlHostPath ++ [ "survey_overlays", String.fromInt id, moveAction moveUp ]) []
        , body = Http.emptyBody
        , expect = Http.expectWhatever SurveyOverlayMutated
        , timeout = Just 15000
        , tracker = Nothing
        }


moveAction : Bool -> String
moveAction moveUp =
    if moveUp then
        "move_up"

    else
        "move_down"


sendDeleteJumpRouteRequest : HostConfig -> Int -> Cmd Msg
sendDeleteJumpRouteRequest ( urlHostRoot, urlHostPath ) routeId =
    Http.request
        { method = "DELETE"
        , headers = []
        , url = Url.Builder.crossOrigin urlHostRoot (urlHostPath ++ [ "jump_routes", String.fromInt routeId ]) []
        , body = Http.emptyBody
        , expect = Http.expectWhatever (DeletedJumpRouteLayer routeId)
        , timeout = Just 15000
        , tracker = Nothing
        }
