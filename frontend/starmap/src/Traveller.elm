port module Traveller exposing (Model, ModelData, Msg(..), init, subscriptions, update, view)

import Browser.Dom
import Browser.Events
import Browser.Navigation
import Codec
import Color exposing (Color)
import Color.Convert
import Color.Manipulate
import Dict
import Set
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
import Parser
import RemoteData exposing (RemoteData(..))
import Result.Extra as Result
import Round
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
        , rawHexagonPoint
        , rawHexagonPoints
        , rotatePoint
        , scaleAttr
        )
import Traveller.Hydrographics exposing (hydrographicsPercentageDescription, surfaceDistributionDescription)
import Traveller.LawLevel as LawLevel
import Traveller.Lifeforms exposing (bioChemistryCompatibilityDescription, biocomplexityDescription, biodiversityDescription, biomassDescription, habitabilityDescription)
import Traveller.Parser exposing (UWP, hydrosphereDescription, sizeDescription, uwp)
import Traveller.Population exposing (concentration_rating_description, populationDescription)
import Traveller.Region as Region exposing (Region, RegionDict)
import Traveller.Route as Route exposing (Route, RouteList)
import Traveller.Sector exposing (Sector, SectorDict, codec, sectorKey)
import Traveller.Sidebar
    exposing
        ( SidebarMsgs
        , viewSidebarColumn
        )
import Traveller.TravelTable as TravelTable
import Traveller.SolarSystem as SolarSystem exposing (SolarSystem)
import Traveller.SolarSystemStars exposing (FallibleStarSystem, StarSystem, StarType, StarTypeData, StrategicData, fallibleStarSystemDecoder, getStarTypeData, isBrownDwarfType)
import Traveller.StarColour exposing (starColourName, starColourRGB)
import Traveller.Starport as Starport
import Traveller.StellarObject exposing (GasGiantData, InnerStarData, PlanetoidBeltData, PlanetoidData, SharedPData, StarData(..), StellarObject(..), getInnerStarData, getProfileString, getStarData, getStellarOrbit, isBrownDwarf)
import Traveller.StellarObjectView
    exposing
        ( JumpShadowChecker
        , JumpShadowCheckers
        , StellarObjectMsgs
        , convertColor
        )
import Traveller.Ship exposing (Ship)
import Traveller.StellarTaint exposing (taintPersistenceDescription, taintSeverityDescription, taintSubtypeDescription)
import Traveller.TechLevel as TechLevel
import Traveller.UI
    exposing
        ( colorToElementColor
        , deepnightColor
        , deepnightGray
        , fontTextColor
        , monospaceText
        , uiDeepnightColorFontColour
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
    }


jumpRouteLinkDecoder : JsDecode.Decoder JumpRouteLink
jumpRouteLinkDecoder =
    JsDecode.map8
        (\id colour known fromSI toSI fromX fromY toX -> JumpRouteLink id colour known fromSI toSI fromX fromY toX)
        (JsDecode.field "id" JsDecode.int)
        (JsDecode.field "colour" (JsDecode.oneOf [ JsDecode.string, JsDecode.null "#888888" ])
            |> JsDecode.map (\s -> if String.isEmpty s then "#888888" else s)
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
    , objectToBeAnalyzed : Maybe { stellarObject : StellarObject, data : AnalysisDetail }
    , analysisTab : String
    , selectedRogueObjects : Maybe (List RogueObjectDetail)
    , timeOpened : Time.Posix
    , campaignName : String
    , allSectorsMapUrl : Maybe String
    , nativeSophontColour : Maybe String
    , extinctSophontColour : Maybe String
    , sidebarOpen : Bool
    , jumpRouteLinks : List JumpRouteLink
    , rogueObjectPathData : Maybe String
    , displayMode : DisplayMode
    , regionDisplay : RegionDisplay
    , showDisplaySettings : Bool
    , showSectorLines : Bool
    , showSubsectorLines : Bool
    , showBackgroundNames : Bool
    , searchState : SearchState
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
    | PanMap { deltaX : Int, deltaY : Int }
    | PanPixels { dx : Float, dy : Float }
    | HexMapWheelZoom Float
    | CloseSidebar
    | DownloadedRogues String (Result Http.Error (List RogueResponseItem))
    | ClearSelectedRogueObjects
    | SetDisplayMode DisplayMode
    | SetRegionDisplay RegionDisplay
    | ToggleDisplaySettings
    | ToggleSectorLines
    | ToggleSubsectorLines
    | ToggleBackgroundNames
    | SearchInput String
    | GotSearchResults (Result Http.Error (List SearchResult))
    | SelectSearchResult SearchResult
    | FocusSearch
    | CloseSearchDropdown


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
        ( Just _, _, "Escape" ) ->
            CloseObjectAnalysis

        ( Nothing, _, "Escape" ) ->
            if model.searchState.dropdownOpen then
                CloseSearchDropdown

            else if model.sidebarOpen then
                CloseSidebar

            else
                NoOpMsg

        ( Nothing, _, "/" ) ->
            FocusSearch

        ( Nothing, HexMap, "ArrowRight" ) ->
            if ctrl then
                PanMap { deltaX = halfH, deltaY = 0 }

            else
                PanPixels { dx = panStep, dy = 0 }

        ( Nothing, HexMap, "ArrowLeft" ) ->
            if ctrl then
                PanMap { deltaX = -halfH, deltaY = 0 }

            else
                PanPixels { dx = -panStep, dy = 0 }

        ( Nothing, HexMap, "ArrowUp" ) ->
            if ctrl then
                PanMap { deltaX = 0, deltaY = -halfV }

            else
                PanPixels { dx = 0, dy = -panStep }

        ( Nothing, HexMap, "ArrowDown" ) ->
            if ctrl then
                PanMap { deltaX = 0, deltaY = halfV }

            else
                PanPixels { dx = 0, dy = panStep }

        ( Nothing, FullJourney, "ArrowRight" ) ->
            JourneyMsg (Pan ( -50, 0 ))

        ( Nothing, FullJourney, "ArrowLeft" ) ->
            JourneyMsg (Pan ( 50, 0 ))

        ( Nothing, FullJourney, "ArrowUp" ) ->
            JourneyMsg (Pan ( 0, 50 ))

        ( Nothing, FullJourney, "ArrowDown" ) ->
            JourneyMsg (Pan ( 0, -50 ))

        _ ->
            NoOpMsg


subscriptions : Time.Posix -> ModelData -> Sub Msg
subscriptions time model =
    Sub.batch
        [ Browser.Events.onResize GotResize
        , Browser.Events.onKeyDown (keyDecoder model)
        , Time.every ((1 / 30) * 1000) Tick
        ]


type alias Flags =
    { upperLeft : Maybe ( Int, Int )
    , hexSize : Float
    , campaignName : Maybe String
    , ship : Maybe Ship
    , allSectorsMapUrl : Maybe String
    , nativeSophontColour : Maybe String
    , extinctSophontColour : Maybe String
    , viewMode : Maybe String
    , journeyState : Maybe String
    , centerOn : Maybe ( Int, Int )
    , rogueObjectPathData : Maybe String
    , shipLocation : Maybe ( Int, Int )
    , displayMode : Maybe String
    , regionDisplay : Maybe String
    , showSectorLines : Maybe Bool
    , showSubsectorLines : Maybe Bool
    , showBackgroundNames : Maybe Bool
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
            , hexRect = hexRect
            , panOffset = { x = 0, y = 0 }
            , hostConfig = hostConfig
            , sectors = Dict.empty
            , route = []
            , currentAddress = toUniversalAddress { sectorX = -10, sectorY = -2, x = 31, y = 24 }
            , regions = Dict.empty
            , regionLabels = Dict.empty
            , hexColours = Dict.empty
            , isReferee = referee
            , pendingCtrlNavigation = False
            , objectToBeAnalyzed = Nothing
            , analysisTab = "orbital"
            , selectedRogueObjects = Nothing
            , timeOpened = Time.millisToPosix 0
            , campaignName = settings.campaignName |> Maybe.withDefault "Navigation"
            , ship = settings.ship
            , allSectorsMapUrl = settings.allSectorsMapUrl
            , nativeSophontColour = settings.nativeSophontColour
            , extinctSophontColour = settings.extinctSophontColour
            , displayMode = initialDisplayMode
            , regionDisplay = initialRegionDisplay
            , showDisplaySettings = False
            , showSectorLines = initialShowSectorLines
            , showSubsectorLines = initialShowSubsectorLines
            , showBackgroundNames = initialShowBackgroundNames
            , sidebarOpen = False
            , jumpRouteLinks = []
            , rogueObjectPathData = settings.rogueObjectPathData
            , searchState = { query = "", results = RemoteData.NotAsked, dropdownOpen = False }
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


hexAddressLabel : Int -> Int -> Float -> HexAddress -> Svg msg
hexAddressLabel x y size hexAddress =
    if size <= 15 then
        Svg.text ""

    else
        Svg.text_
            [ SvgAttrs.x <| String.fromInt x
            , SvgAttrs.y <| String.fromInt <| y - (floor <| size * 0.65) + (if size > 30 then 1 else 2)
            , SvgAttrs.fontSize "9"
            , SvgAttrs.textAnchor "middle"
            , SvgAttrs.fontFamily "Tomorrow"
            , SvgAttrs.fontWeight "400"
            , SvgAttrs.fill "#2A6A8A"
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
                , SvgAttrs.fill "#2A6A8A"
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
        , hexAddressLabel x y size hexAddress
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
        , hexAddressLabel x y size hexAddress
        , if showComet && size > 15 then drawCometIcon (toFloat x) (toFloat y) size else Svg.text ""
        , if showGasGiant && size > 15 then drawRogueGasGiant (toFloat x) (toFloat y) size else Svg.text ""
        , if showOther && size > 15 then drawRogueOther rogueObjectPathData (toFloat x) (toFloat y) size else Svg.text ""
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
    in
    Svg.polygon
        [ points points_
        , SvgAttrs.fill hexColour
        , SvgAttrs.stroke "#cccccc"
        , SvgAttrs.strokeWidth "0.5"
        , SvgAttrs.pointerEvents "visiblePainted"
        , SvgAttrs.class "hex-hover"
        ]
        []


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


drawStar : Float -> Float -> Int -> Float -> String -> Svg Msg
drawStar starX starY radius size starColor =
    Svg.circle
        [ SvgAttrs.cx <| String.fromFloat <| starX
        , SvgAttrs.cy <| String.fromFloat <| starY
        , SvgAttrs.r <| String.fromFloat <| scaleAttr size radius
        , SvgAttrs.fill starColor
        , SvgAttrs.style "filter: drop-shadow(0 0 3px rgba(0,0,0,0.55))"
        ]
        []


drawUnknownSlot : Float -> Float -> Float -> Svg Msg
drawUnknownSlot iconX iconY size =
    let
        r =
            scaleAttr size 5
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
            , SvgAttrs.fontSize "9"
            , SvgAttrs.textAnchor "middle"
            , SvgAttrs.dominantBaseline "central"
            , SvgAttrs.fontFamily "Tomorrow"
            , SvgAttrs.fontWeight "400"
            , SvgAttrs.fill "#2A6A8A"
            ]
            [ Svg.text "?" ]
        ]


drawPlanetoidBelt : Int -> Int -> Float -> Svg Msg
drawPlanetoidBelt cx cy size =
    let
        iconX =
            toFloat cx - size * 0.38

        iconY =
            toFloat cy - size * 0.45

        scale =
            scaleAttr size 7 / 16
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
        [ Svg.polygon [ SvgAttrs.points "-12,-6 -7,-10 -3,-5 -6,-1 -10,-2", SvgAttrs.fill "#475569" ] []
        , Svg.polygon [ SvgAttrs.points "4,-11 10,-9 8,-4 3,-6", SvgAttrs.fill "#64748b" ] []
        , Svg.polygon [ SvgAttrs.points "-10,4 -5,2 -2,7 -7,10", SvgAttrs.fill "#1e293b" ] []
        , Svg.polygon [ SvgAttrs.points "2,1 8,-1 11,5 7,8 3,6", SvgAttrs.fill "#475569" ] []
        , Svg.polygon [ SvgAttrs.points "-1,9 4,11 1,14 -3,12", SvgAttrs.fill "#64748b" ] []
        ]


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


drawGasGiant : Int -> Int -> Float -> Svg Msg
drawGasGiant cx cy size =
    let
        iconX =
            toFloat cx + size * 0.38

        iconY =
            toFloat cy - size * 0.45

        r =
            scaleAttr size 5
    in
    Svg.g []
        [ Svg.circle
            [ SvgAttrs.cx <| String.fromFloat iconX
            , SvgAttrs.cy <| String.fromFloat iconY
            , SvgAttrs.r <| String.fromFloat r
            , SvgAttrs.fill "#222222"
            ]
            []
        , Svg.ellipse
            [ SvgAttrs.cx <| String.fromFloat iconX
            , SvgAttrs.cy <| String.fromFloat iconY
            , SvgAttrs.rx <| String.fromFloat (r * 1.8)
            , SvgAttrs.ry <| String.fromFloat (r * 0.55)
            , SvgAttrs.fill "none"
            , SvgAttrs.stroke "#222222"
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
    , displayMode : DisplayMode
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


viewBarRow : Float -> Float -> Float -> String -> Int -> Svg Msg
viewBarRow size cx rowY label tier =
    let
        segW =
            size * 0.15

        segH =
            size * 0.10

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
                x0 = sx
                x1 = sx + segW
                y0 = rowY + segH / 2
                y1 = rowY - segH / 2
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
            , SvgAttrs.fill "#1e3a5f"
            , SvgAttrs.fontSize (String.fromFloat (size * 0.20))
            , SvgAttrs.fontFamily "Oxanium, sans-serif"
            , SvgAttrs.fontWeight "600"
            ]
            [ Svg.text label ]
            :: List.map segment (List.range 0 (numSegs - 1))
        )


viewRoleBadge : Float -> Float -> Float -> String -> Svg Msg
viewRoleBadge size cx rowY role =
    let
        textColour =
            case role of
                "market" ->
                    "#1e5a8a"

                "supplier" ->
                    "#1e6b3f"

                "extractor" ->
                    "#7a4010"

                "deficit" ->
                    "#7a1010"

                _ ->
                    "#3a3a3a"
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
renderHexContent { starSystem, hexAddrX, hexAddrY, vox, voy, size, isReferee, displayMode } =
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

        showUnknownGasGiant =
            showStar && not isReferee && si < gasGiantSI

        showUnknownPlanetoidBelt =
            showStar && not isReferee && si < planetoidSI

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

        hexCentreText : String -> Svg Msg
        hexCentreText txt =
            Svg.text_
                [ SvgAttrs.x (String.fromInt vox)
                , SvgAttrs.y (String.fromInt voy)
                , SvgAttrs.textAnchor "middle"
                , SvgAttrs.dominantBaseline "middle"
                , SvgAttrs.fill "#0f2d42"
                , SvgAttrs.fontSize (String.fromFloat (size * 0.28))
                , SvgAttrs.fontFamily "Oxanium, sans-serif"
                , SvgAttrs.fontWeight "600"
                , SvgAttrs.pointerEvents "none"
                ]
                [ Svg.text txt ]

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
        [ hexAddressLabel vox voy size hexAddress
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
                    , travelZoneRing
                    ]

            ShowImportance ->
                Svg.g [ SvgAttrs.pointerEvents "none" ]
                    [ case starSystem.importance of
                        Just imp ->
                            hexCentreText
                                ("{" ++ (if imp >= 0 then "+" else "") ++ String.fromInt imp ++ "}")

                        Nothing ->
                            Svg.text ""
                    , travelZoneRing
                    ]

            ShowStrategic ->
                case starSystem.strategic of
                    Just strat ->
                        if size >= 30 then
                            Svg.g [ SvgAttrs.pointerEvents "none" ]
                                [ viewBarRow size (toFloat vox) (toFloat voy - size * 0.28) "Ix" strat.importanceTier
                                , viewBarRow size (toFloat vox) (toFloat voy - size * 0.09) "RU" strat.resourceUnitsTier
                                , viewBarRow size (toFloat vox) (toFloat voy + size * 0.10) "Rs" strat.resourceTier
                                , viewBarRow size (toFloat vox) (toFloat voy + size * 0.29) "Td" strat.tradeEaseTier
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
                                        viewRoleBadge size (toFloat vox) (toFloat voy - size * 0.36) role

                                    Nothing ->
                                        Svg.text ""
                                , viewBarRow size (toFloat vox) (toFloat voy - size * 0.07) "Ix" strat.importanceTier
                                , viewBarRow size (toFloat vox) (toFloat voy + size * 0.15) "Td" strat.tradeEaseTier
                                , travelZoneRing
                                ]

                        else
                            Svg.text ""

                    Nothing ->
                        Svg.text ""

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
                                            rotatePoint size (idx + 2) primaryPos 60 20
                                in
                                case starData.companion of
                                    Just companion ->
                                        let
                                            ( cx, cy ) =
                                                ( sx - 5, sy )

                                            compStarData =
                                                getStarTypeData companion
                                        in
                                        Svg.g []
                                            [ Svg.Lazy.lazy5 drawStar sx sy 7 size <| starColourRGB starData.colour
                                            , Svg.Lazy.lazy5 drawStar cx cy 3 size <| starColourRGB compStarData.colour
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
                        drawGasGiant vox voy size

                      else
                        Svg.text ""
                    , if showPlanetoidBelt && size > 15 then
                        drawPlanetoidBelt vox voy size

                      else
                        Svg.text ""
                    , if showUnknownGasGiant && size > 15 then
                        drawUnknownSlot (toFloat vox + size * 0.38) (toFloat voy - size * 0.45) size

                      else
                        Svg.text ""
                    , if showUnknownPlanetoidBelt && size > 15 then
                        drawUnknownSlot (toFloat vox - size * 0.38) (toFloat voy - size * 0.45) size

                      else
                        Svg.text ""
                    , travelZoneRing
                    ]
        ]


renderHexSystemLabels : HexRenderOpts -> Svg Msg
renderHexSystemLabels { starSystem, vox, voy, size, isReferee } =
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
                            , SvgAttrs.fill "#333333"
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
                    , SvgAttrs.fill "#333333"
                    ]
                    [ Svg.text starSystem.name ]

              else
                Svg.text ""
            ]


defaultHexBg =
    "#FFFFFF"


selectedHexBg =
    "#B8E0F0"


routeHexBg =
    "#FFE8C0"


nativeSophontHexBg =
    "#C8F0E8"


extinctSophontHexBg =
    "#F0ECC8"


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
                , SvgAttrs.fill "#2A6A8A"
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
        , hexAddressLabel x y size hexAddress
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
    -> DisplayMode
    -> ( Svg Msg, Svg Msg )
viewHex hexSize solarSystemDict hexAddress vox voy hexColour rawHexaPoints isReferee rogueObjectPathData displayMode =
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
                    , displayMode = displayMode
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
backgroundNameLabel : Int -> Int -> Int -> String -> Svg msg
backgroundNameLabel fontSize cx cy name =
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
                        , SvgAttrs.dy (String.fromFloat (if i == 0 then firstDy else lineHeightEm) ++ "em")
                        ]
                        [ Svg.text word ]
                )
                words
    in
    Svg.text_
        [ SvgAttrs.x (String.fromInt cx)
        , SvgAttrs.y (String.fromInt cy)
        , SvgAttrs.textAnchor "middle"
        , SvgAttrs.dominantBaseline "middle"
        , SvgAttrs.fontFamily "Tomorrow"
        , SvgAttrs.fontWeight "500"
        , SvgAttrs.fontSize (String.fromInt fontSize)
        , SvgAttrs.fill "#D3D3D3"
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


hexBackgroundColour : Bool -> String -> SolarSystemDict -> Maybe String -> Maybe String -> String
hexBackgroundColour referee hexKey solarSystemDict nativeSophontColour extinctSophontColour =
    if referee then
        case Dict.get hexKey solarSystemDict of
            Just rss ->
                case rss of
                    LoadedSolarSystem system ->
                        case system.allegiance of
                            Just allegiance ->
                                case Dict.get allegiance allegianceColours of
                                    Just color ->
                                        color

                                    Nothing ->
                                        defaultHexBg

                            Nothing ->
                                if system.nativeSophont then
                                    nativeSophontColour |> Maybe.withDefault defaultHexBg

                                else if system.extinctSophont then
                                    extinctSophontColour |> Maybe.withDefault defaultHexBg

                                else
                                    defaultHexBg

                    _ ->
                        defaultHexBg

            Nothing ->
                defaultHexBg

    else
        defaultHexBg


viewHexes :
    ( HexRect, List ( Float, Float ) )
    -> { svgWidth : Float, svgHeight : Float, maxAcross : Int, maxTall : Int }
    -> { solarSystemDict : SolarSystemDict, hexColours : HexColorDict, regionLabels : RegionLabelDict, regions : RegionDict, regionDisplay : RegionDisplay, showSectorLines : Bool, showSubsectorLines : Bool, sectors : SectorDict, showBackgroundNames : Bool }
    -> ( RouteList, HexAddress )
    -> Float
    -> Maybe HexAddress
    -> Bool
    -> Maybe String
    -> Maybe String
    -> { x : Float, y : Float }
    -> List JumpRouteLink
    -> Maybe String
    -> DisplayMode
    -> Html Msg
viewHexes ( { upperLeftHex, lowerRightHex }, rawHexaPoints ) { svgWidth, svgHeight, maxAcross, maxTall } { solarSystemDict, hexColours, regionLabels, regions, regionDisplay, showSectorLines, showSubsectorLines, sectors, showBackgroundNames } ( route, currentAddress ) hexSize maybeSelectedHex isReferee nativeSophontColour extinctSophontColour panOffset jumpRouteLinks rogueObjectPathData displayMode =
    let
        renderCurrentAddressOutline : HexAddress -> Svg Msg
        renderCurrentAddressOutline ca =
            let
                locationOrigin =
                    calcVisualOrigin hexSize
                        { row = ca.y, col = ca.x }
                        |> Tuple.mapBoth toFloat toFloat

                pointsStr =
                    hexagonPoints locationOrigin hexSize
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
                (HexAddress.shiftAddressBy { deltaX = -1, deltaY = -1 } upperLeftHex)
                lowerRightHex
                { maxAcross = maxAcross, maxTall = maxTall }

        viewSingleHex hexAddr =
            let
                hexKey =
                    HexAddress.toKey hexAddr

                ( vox, voy ) =
                    calcVisualOrigin hexSize
                        { row = hexAddr.y, col = hexAddr.x }

                hexColour =
                    if hexAddr == currentAddress then
                        currentAddressHexBg

                    else if isOnRoute route hexAddr then
                        routeHexBg

                    else
                        let
                            regionFill =
                                case regionDisplay of
                                    ShowRegionsFill ->
                                        Dict.get hexKey hexColours

                                    ShowRegionsBoth ->
                                        Dict.get hexKey hexColours

                                    _ ->
                                        Nothing
                        in
                        case regionFill of
                            Just color ->
                                Color.Convert.colorToHex color

                            Nothing ->
                                case maybeSelectedHex of
                                    Just selectedHex ->
                                        if selectedHex == hexAddr then
                                            selectedHexBg

                                        else
                                            hexBackgroundColour isReferee hexKey solarSystemDict nativeSophontColour extinctSophontColour

                                    Nothing ->
                                        hexBackgroundColour isReferee hexKey solarSystemDict nativeSophontColour extinctSophontColour
            in
            ( hexAddr
            , viewHex
                hexSize
                solarSystemDict
                hexAddr
                vox
                voy
                hexColour
                rawHexaPoints
                isReferee
                rogueObjectPathData
                displayMode
            )
    in
    hexRange
        |> List.map viewSingleHex
        |> (\hexSvgsWithHexAddress ->
                let
                    labelPos hexAddr =
                        calcVisualOrigin hexSize
                            { row = hexAddr.y, col = hexAddr.x }

                    renderRegionLabel : HexAddress -> Maybe (Svg.Svg msg)
                    renderRegionLabel hexAddress =
                        case regionDisplay of
                            HideRegions ->
                                Nothing

                            _ ->
                                regionLabels
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
                                calcVisualOrigin hexSize
                                    { row = hexAddr.y, col = hexAddr.x }
                        in
                        case Dict.get hexKey solarSystemDict of
                            Just (LoadedSolarSystem loadedSystem) ->
                                renderHexSystemLabels
                                    { starSystem = loadedSystem
                                    , hexColour = ""
                                    , hexAddrX = hexAddr.x
                                    , hexAddrY = hexAddr.y
                                    , vox = vox
                                    , voy = voy
                                    , size = hexSize
                                    , hexapointsStr = ""
                                    , isReferee = isReferee
                                    , displayMode = displayMode
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
                        renderCurrentAddressOutline currentAddress

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
                                            calcVisualOrigin hexSize { row = hexAddr.y, col = hexAddr.x }

                                        hexapointsStr =
                                            convertRawHexagonPoints ( toFloat vox, toFloat voy ) rawHexaPoints
                                    in
                                    ( HexAddress.toKey hexAddr
                                    , Svg.Lazy.lazy renderHexBorderStroke hexapointsStr
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
                        HexAddress.toSectorAddress upperLeftHex

                    lrSector =
                        HexAddress.toSectorAddress lowerRightHex

                    sectorOutlines =
                        if showSectorLines then
                            List.range (min ulSector.sectorX lrSector.sectorX) (max ulSector.sectorX lrSector.sectorX)
                                |> List.concatMap
                                    (\sx ->
                                        List.range (min ulSector.sectorY lrSector.sectorY) (max ulSector.sectorY lrSector.sectorY)
                                            |> List.map
                                                (\sy ->
                                                    renderSectorOutline hexSize { ulSector | sectorX = sx, sectorY = sy }
                                                )
                                    )

                        else
                            []

                    subsectorLinesList =
                        if showSubsectorLines then
                            List.range (min ulSector.sectorX lrSector.sectorX) (max ulSector.sectorX lrSector.sectorX)
                                |> List.concatMap
                                    (\sx ->
                                        List.range (min ulSector.sectorY lrSector.sectorY) (max ulSector.sectorY lrSector.sectorY)
                                            |> List.concatMap
                                                (\sy ->
                                                    renderSubsectorLines hexSize { ulSector | sectorX = sx, sectorY = sy }
                                                )
                                    )

                        else
                            []

                    backgroundNameLabels =
                        if not showBackgroundNames || hexSize > maxHexSizeForBackgroundNames then
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
                                    round (hexSize * 2.2)

                                sectorFontSize =
                                    round (toFloat subsectorFontSize * 2.5)

                                labelsForSector sx sy =
                                    let
                                        hex =
                                            { ulSector | sectorX = sx, sectorY = sy }
                                    in
                                    case Dict.get (HexAddress.toSectorKey hex) sectors of
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
                                                                sectorCellCenterPixel hexSize hex { x = 0, y = 0 } { x = 32, y = 40 }
                                                        in
                                                        [ backgroundNameLabel sectorFontSize cx cy name ]

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
                                                                                            sectorCellCenterPixel hexSize
                                                                                                hex
                                                                                                { x = (subCol - 1) * 8, y = (subRow - 1) * 10 }
                                                                                                { x = subCol * 8, y = subRow * 10 }
                                                                                    in
                                                                                    backgroundNameLabel subsectorFontSize cx cy name
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
                                                calcVisualOrigin hexSize { row = hexAddr.y, col = hexAddr.x }

                                            verts =
                                                rawHexaPoints
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
                        case regionDisplay of
                            HideRegions ->
                                []

                            ShowRegionsFill ->
                                []

                            _ ->
                                regions |> Dict.values |> List.filterMap renderBorderRegion
                in
                let
                    visibleLinks =
                        List.filter
                            (\link ->
                                isReferee
                                    || link.known
                                    || (link.routeType == "network"
                                            && (link.fromSurveyIndex >= 10 || link.toSurveyIndex >= 10)
                                       )
                            )
                            jumpRouteLinks

                    jumpRouteLinkLines =
                        List.map
                            (\link ->
                                let
                                    ( fx, fy ) =
                                        calcVisualOrigin hexSize { row = link.fromY, col = link.fromX }

                                    ( tx, ty ) =
                                        calcVisualOrigin hexSize { row = link.toY, col = link.toX }
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
                    ++ [ keyedHexBorders ]
                    ++ [ singlePolyHex ]
                    ++ [ Svg.g [ SvgAttrs.pointerEvents "none" ] jumpRouteLinkLines ]
                    ++ [ keyedHexForegrounds ]
                    ++ subsectorLinesList
                    ++ sectorOutlines
                    ++ regionBorderLines
                    ++ [ Svg.g [ SvgAttrs.pointerEvents "none", SvgAttrs.style "transform: translateZ(0)" ] systemLabels ]
                    ++ labels
           )
        |> (let
                widthString =
                    String.fromFloat <| svgWidth

                heightString =
                    String.fromFloat <| svgHeight
            in
            Svg.svg
                [ SvgAttrs.width <| widthString
                , SvgAttrs.height <| heightString
                , SvgAttrs.id "hexmap"
                , SvgEvents.onMouseOut MapMouseLeave
                , Html.Events.preventDefaultOn "wheel"
                    (JsDecode.map (\dy -> ( HexMapWheelZoom dy, True )) (JsDecode.field "deltaY" JsDecode.float))
                , viewBox <|
                    toViewBox hexSize upperLeftHex panOffset
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
                [ Background.color <| colorToElementColor deepnightGray
                , Element.width <| Element.px 300
                , Element.moveDown 20
                , Element.padding 1
                , Border.rounded 3
                , Border.widthEach { zeroEach | top = 2 }
                , Border.color <| colorToElementColor deepnightColor
                , Border.glow (Element.rgba255 0 0 0 100) 6
                , Font.color <| Element.rgb 1 1 1
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
                , Element.mouseOver [ Background.color <| Element.rgb 0.5 0.5 0.5 ]
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
                            [ Element.mouseOver [ Font.color <| colorToElementColor Color.green ]
                            , Font.italic
                            , Font.color <| colorToElementColor Color.grey
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
                , Font.color <| Element.rgb 1 1 1
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


renderFAIcon : String -> Int -> Element.Element Msg
renderFAIcon icon size =
    Element.el
        [ Element.width (Element.px size)
        , Element.height (Element.px size)
        ]
    <|
        Element.html <|
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
        , Element.htmlAttribute <| Html.Events.preventDefaultOn "wheel" <|
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


viewSearchField : ModelData -> List (Element.Element Msg)
viewSearchField model =
    if model.viewMode /= HexMap then
        []

    else
        [ el
            [ Element.below
                (if model.searchState.dropdownOpen then
                    viewSearchDropdown model.searchState

                 else
                    Element.none
                )
            ]
            (Input.text
                [ Element.width (Element.px 220)
                , Font.size 13
                , Font.color (Element.rgb 0.1 0.1 0.1)
                , Background.color (Element.rgb 1 1 1)
                , Border.color (Element.rgb 0.4 0.4 0.4)
                , Border.width 1
                , Border.rounded 4
                , Element.padding 6
                , Element.htmlAttribute (HtmlAttrs.id "starmap-search")
                , Element.htmlAttribute
                    (Html.Events.stopPropagationOn "keydown"
                        (JsDecode.field "key" JsDecode.string
                            |> JsDecode.map
                                (\k ->
                                    if k == "Escape" then
                                        ( CloseSearchDropdown, True )

                                    else
                                        ( NoOpMsg, True )
                                )
                        )
                    )
                ]
                { onChange = SearchInput
                , text = model.searchState.query
                , placeholder =
                    Just
                        (Input.placeholder
                            [ Font.color (Element.rgba 0.4 0.4 0.4 0.8)
                            , Font.size 12
                            ]
                            (text "Search… [/]")
                        )
                , label = Input.labelHidden "Search starmap"
                }
            )
        ]


viewSearchDropdown : SearchState -> Element.Element Msg
viewSearchDropdown searchState =
    el
        [ Background.color (Element.rgba 0.05 0.05 0.1 0.95)
        , Border.color (Element.rgba 0.17 0.42 0.55 0.5)
        , Border.width 1
        , Border.rounded 4
        , Element.width (Element.px 340)
        , Element.padding 4
        , Element.htmlAttribute (HtmlAttrs.style "z-index" "100")
        ]
        (case searchState.results of
            RemoteData.Loading ->
                el [ Font.size 12, Font.color (Element.rgba 1 1 1 0.45), Element.padding 8 ]
                    (text "Searching…")

            RemoteData.Success [] ->
                el [ Font.size 12, Font.color (Element.rgba 1 1 1 0.45), Element.padding 8 ]
                    (text "No matches")

            RemoteData.Success results ->
                column [ Element.width Element.fill, Element.spacing 2 ]
                    (List.map viewSearchResultRow results)

            RemoteData.Failure _ ->
                el [ Font.size 12, Font.color (Element.rgba 1 0.3 0.3 0.8), Element.padding 8 ]
                    (text "Search failed")

            RemoteData.NotAsked ->
                Element.none
        )


viewSearchResultRow : SearchResult -> Element.Element Msg
viewSearchResultRow result =
    column
        [ Element.width Element.fill
        , Element.padding 8
        , Element.spacing 3
        , Element.pointer
        , Element.htmlAttribute (Html.Events.onMouseDown (SelectSearchResult result))
        , Element.mouseOver [ Background.color (Element.rgba 0.17 0.42 0.55 0.3) ]
        , Border.rounded 3
        ]
        [ row [ Element.width Element.fill, Element.spacing 8 ]
            [ el
                [ Font.size 14
                , Font.color (Element.rgb 0.9 0.9 0.9)
                , Element.width Element.fill
                ]
                (text result.name)
            , el
                [ Font.size 10
                , Font.color (Element.rgba 1 1 1 0.45)
                , Element.alignRight
                ]
                (text (String.toUpper result.displayType))
            ]
        , el [ Font.size 12, Font.color (Element.rgba 1 1 1 0.5) ]
            (text result.meta)
        ]


viewStatusRow : ModelData -> Element.Element Msg
viewStatusRow model =
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

        extras =
            case model.viewMode of
                HexMap ->
                    [ el
                        [ uiDeepnightColorFontColour
                        , Font.size 14
                        , Element.pointer
                        , Events.onClick (SetHexSize (clamp minHexSize maxHexSize (model.hexScale * 1.1)))
                        , Element.centerY
                        , Element.htmlAttribute <| HtmlAttrs.title "Zoom in"
                        , Element.mouseOver
                            [ Font.color <| convertColor (Color.Manipulate.lighten 0.25 deepnightColor)
                            ]
                        ]
                      <|
                        renderFAIcon "fa-regular fa-magnifying-glass-plus" 14
                    , el
                        [ uiDeepnightColorFontColour
                        , Font.size 14
                        , Element.pointer
                        , Events.onClick (SetHexSize (clamp minHexSize maxHexSize (model.hexScale / 1.1)))
                        , Element.centerY
                        , Element.htmlAttribute <| HtmlAttrs.title "Zoom out"
                        , Element.mouseOver
                            [ Font.color <| convertColor (Color.Manipulate.lighten 0.25 deepnightColor)
                            ]
                        ]
                      <|
                        renderFAIcon "fa-regular fa-magnifying-glass-minus" 14
                    , -- hovered hex
                      el
                        [ uiDeepnightColorFontColour
                        , Font.size 14
                        , Element.spacing 5
                        , Element.pointer
                        , Events.onClick RefreshMap
                        , Element.centerY
                        , Element.htmlAttribute <| HtmlAttrs.title "Refresh map"
                        , Element.mouseOver
                            [ Font.color <| convertColor (Color.Manipulate.lighten 0.25 deepnightColor)
                            ]
                        ]
                      <|
                        renderFAIcon "fa-regular fa-refresh" 14
                    , if displayModeLabel /= "" then
                        el [ uiDeepnightColorFontColour, Font.size 12, Element.centerY ] (text displayModeLabel)

                      else
                        Element.none
                    , el
                        [ uiDeepnightColorFontColour
                        , Font.family [ Font.monospace ]
                        , Font.size 14
                        , Element.centerY
                        , Element.width <| Element.minimum 10 Element.shrink
                        ]
                      <|
                        case model.hoveringHex of
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
                                text displayText

                            Nothing ->
                                Element.none
                    , -- hex rect display
                      el [ Element.centerY, Font.size 14, uiDeepnightColorFontColour, Element.centerX ] <|
                        text <|
                            let
                                first =
                                    shiftAddressBy { deltaX = 1, deltaY = 1 } model.hexRect.upperLeftHex

                                last =
                                    shiftAddressBy { deltaX = -3, deltaY = -1 } model.hexRect.lowerRightHex
                            in
                            (universalHexLabelMaybe model.sectors first
                                |> Maybe.withDefault "???"
                            )
                                ++ " – "
                                ++ (universalHexLabelMaybe model.sectors last
                                        |> Maybe.withDefault "???"
                                   )
                    , -- player location display
                      row
                        [ uiDeepnightColorFontColour
                        , Font.size 14
                        , Element.spacing 5
                        , Element.pointer
                        , Events.onClick JumpToShip
                        , Element.centerY
                        , Element.mouseOver
                            [ Font.color <| convertColor (Color.Manipulate.lighten 0.25 deepnightColor)
                            ]
                        ]
                        [ text (model.ship |> Maybe.map .name |> Maybe.withDefault "Ship")
                        , renderFAIcon "fa-regular fa-crosshairs-simple" 14
                        , text <|
                            (universalHexLabelMaybe model.sectors model.currentAddress
                                |> Maybe.withDefault "???"
                            )
                        ]
                    ]

                FullJourney ->
                    [ el
                        [ uiDeepnightColorFontColour
                        , Font.size 14
                        , Element.pointer
                        , Events.onClick (JourneyMsg (Zoom ZoomIn))
                        , Element.centerY
                        , Element.htmlAttribute <| HtmlAttrs.title "Zoom in"
                        , Element.mouseOver
                            [ Font.color <| convertColor (Color.Manipulate.lighten 0.25 deepnightColor)
                            ]
                        ]
                      <|
                        renderFAIcon "fa-regular fa-magnifying-glass-plus" 14
                    , el
                        [ uiDeepnightColorFontColour
                        , Font.size 14
                        , Element.pointer
                        , Events.onClick (JourneyMsg (Zoom ZoomOut))
                        , Element.centerY
                        , Element.htmlAttribute <| HtmlAttrs.title "Zoom out"
                        , Element.mouseOver
                            [ Font.color <| convertColor (Color.Manipulate.lighten 0.25 deepnightColor)
                            ]
                        ]
                      <|
                        renderFAIcon "fa-regular fa-magnifying-glass-minus" 14
                    ]
    in
    let
        viewModeIcon : ViewMode -> String -> Element.Element Msg
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
                        uiDeepnightColorFontColour

                    else
                        Font.color <| convertColor (Color.Manipulate.darken 0.2 deepnightColor)
            in
            el
                [ colour
                , Element.pointer
                , Events.onClick (SetViewMode targetMode)
                , Element.mouseOver [ Font.color <| convertColor (Color.Manipulate.lighten 0.25 deepnightColor) ]
                , Element.centerY
                ]
            <|
                renderFAIcon (iconStyle ++ " " ++ iconName) 16
        displaySettingsGear =
            if model.viewMode == HexMap then
                [ el
                    [ uiDeepnightColorFontColour
                    , Element.pointer
                    , Events.onClick ToggleDisplaySettings
                    , Element.centerY
                    , Element.htmlAttribute (HtmlAttrs.title "Map display settings")
                    , Element.mouseOver [ Font.color <| convertColor (Color.Manipulate.lighten 0.25 deepnightColor) ]
                    ]
                    (renderFAIcon "fa-regular fa-gear" 14)
                ]

            else
                []
    in
    Element.row
        [ Element.spacing 8
        , Element.width Element.fill
        , Element.paddingEach { zeroEach | bottom = 10, top = 10, right = 8 }
        ]
        ([ el [ Font.size 20, uiDeepnightColorFontColour, Element.paddingEach { zeroEach | left = 8 } ] <| text model.campaignName
         , viewModeIcon HexMap "fa-hexagon"
         , viewModeIcon FullJourney "fa-map"
         ]
            ++ displaySettingsGear
            ++ viewSearchField model
            ++ extras
        )


viewDisplaySettingsModal : DisplayMode -> RegionDisplay -> Bool -> Bool -> Bool -> Bool -> Element Msg
viewDisplaySettingsModal currentMode currentRegionDisplay isReferee showSectorLines_ showSubsectorLines_ showBackgroundNames_ =
    let
        radioButton : Bool -> Element Msg
        radioButton isActive =
            el
                [ width (Element.px 16)
                , height (Element.px 16)
                , Border.width 2
                , Border.rounded 8
                , Border.color
                    (if isActive then
                        Element.rgba 0.17 0.42 0.55 0.9

                     else
                        Element.rgba 0.17 0.42 0.55 0.35
                    )
                , Element.centerY
                ]
            <|
                if isActive then
                    el
                        [ width (Element.px 8)
                        , height (Element.px 8)
                        , Border.rounded 4
                        , Background.color (Element.rgba 0.17 0.42 0.55 0.9)
                        , Element.centerX
                        , Element.centerY
                        ]
                        Element.none

                else
                    Element.none

        modeOption : DisplayMode -> String -> String -> Element Msg
        modeOption mode label description =
            let
                isActive =
                    currentMode == mode
            in
            el
                [ width fill
                , Element.pointer
                , Events.onClick (SetDisplayMode mode)
                , Element.paddingXY 6 8
                , Border.rounded 4
                , Background.color
                    (if isActive then
                        Element.rgba 0.17 0.42 0.55 0.1

                     else
                        Element.rgba 0 0 0 0
                    )
                , Element.mouseOver [ Background.color (Element.rgba 0.17 0.42 0.55 0.06) ]
                ]
            <|
                row [ Element.spacing 10, width fill ]
                    [ radioButton isActive
                    , column [ Element.spacing 2, width fill ]
                        [ el [ Font.size 13, Font.bold, Font.color (Element.rgba 0.1 0.25 0.4 0.9) ] (text label)
                        , Element.paragraph [ Font.size 11, Font.color (Element.rgba 0.1 0.25 0.4 0.55) ] [ text description ]
                        ]
                    ]

        regionOption : RegionDisplay -> String -> String -> Element Msg
        regionOption mode label description =
            let
                isActive =
                    currentRegionDisplay == mode
            in
            el
                [ width fill
                , Element.pointer
                , Events.onClick (SetRegionDisplay mode)
                , Element.paddingXY 6 8
                , Border.rounded 4
                , Background.color
                    (if isActive then
                        Element.rgba 0.17 0.42 0.55 0.1

                     else
                        Element.rgba 0 0 0 0
                    )
                , Element.mouseOver [ Background.color (Element.rgba 0.17 0.42 0.55 0.06) ]
                ]
            <|
                row [ Element.spacing 10, width fill ]
                    [ radioButton isActive
                    , column [ Element.spacing 2 ]
                        [ el [ Font.size 13, Font.bold, Font.color (Element.rgba 0.1 0.25 0.4 0.9) ] (text label)
                        , el [ Font.size 11, Font.color (Element.rgba 0.1 0.25 0.4 0.55) ] (text description)
                        ]
                    ]

        options =
            [ modeOption ShowStars "Stars" "Primary stars in each system"
            , modeOption ShowMainWorld "Main World" "Planet image for the main world"
            , modeOption ShowTradeCodes "Trade Codes" "Abbreviated trade classification codes"
            ]
                ++ (if isReferee then
                        [ modeOption ShowWTN "WTN" "World Trade Number"
                        , modeOption ShowGWP "GWP" "Gross World Product"
                        , modeOption ShowImportance "Importance" "Economic importance rating"
                        , modeOption ShowStrategic "Strategic" "Tiered bars: Importance, Resource Units, Resource Factor, Trade Ease"
                        , modeOption ShowResource "Resource" "Tiered bars: Importance, Trade Ease, plus route role badge"
                        ]

                    else
                        []
                   )

        regionOptions =
            [ regionOption HideRegions "Hidden" "Regions not shown"
            , regionOption ShowRegionsFill "Fill" "Hex colour fill only"
            , regionOption ShowRegionsBorder "Border" "Region border lines only"
            , regionOption ShowRegionsBoth "Fill & Border" "Hex colour fill with border lines"
            ]

        sectionDivider =
            row
                [ width fill
                , Element.paddingEach { zeroEach | top = 12, bottom = 12 }
                , Border.widthEach { zeroEach | bottom = 1 }
                , Border.color (Element.rgba 0.17 0.42 0.55 0.15)
                ]
                [ el [ Font.size 12, Font.bold, Font.color (Element.rgba 0.1 0.25 0.4 0.55) ] (text "REGIONS") ]

        overlayDivider =
            row
                [ width fill
                , Element.paddingEach { zeroEach | top = 12, bottom = 12 }
                , Border.widthEach { zeroEach | bottom = 1 }
                , Border.color (Element.rgba 0.17 0.42 0.55 0.15)
                ]
                [ el [ Font.size 12, Font.bold, Font.color (Element.rgba 0.1 0.25 0.4 0.55) ] (text "OVERLAY LINES") ]

        checkboxButton : Bool -> Element Msg
        checkboxButton isActive =
            el
                [ width (Element.px 16)
                , height (Element.px 16)
                , Border.width 2
                , Border.rounded 3
                , Border.color
                    (if isActive then
                        Element.rgba 0.17 0.42 0.55 0.9

                     else
                        Element.rgba 0.17 0.42 0.55 0.35
                    )
                , Element.centerY
                ]
            <|
                if isActive then
                    el
                        [ width (Element.px 8)
                        , height (Element.px 8)
                        , Border.rounded 1
                        , Background.color (Element.rgba 0.17 0.42 0.55 0.9)
                        , Element.centerX
                        , Element.centerY
                        ]
                        Element.none

                else
                    Element.none

        toggleOption : Bool -> String -> String -> Msg -> Element Msg
        toggleOption isActive label description msg =
            el
                [ width fill
                , Element.pointer
                , Events.onClick msg
                , Element.paddingXY 6 8
                , Border.rounded 4
                , Background.color
                    (if isActive then
                        Element.rgba 0.17 0.42 0.55 0.1

                     else
                        Element.rgba 0 0 0 0
                    )
                , Element.mouseOver [ Background.color (Element.rgba 0.17 0.42 0.55 0.06) ]
                ]
            <|
                row [ Element.spacing 10, width fill ]
                    [ checkboxButton isActive
                    , column [ Element.spacing 2 ]
                        [ el [ Font.size 13, Font.bold, Font.color (Element.rgba 0.1 0.25 0.4 0.9) ] (text label)
                        , el [ Font.size 11, Font.color (Element.rgba 0.1 0.25 0.4 0.55) ] (text description)
                        ]
                    ]

        overlayOptions =
            [ toggleOption showSectorLines_ "Sector Lines" "Sector boundary outlines" ToggleSectorLines
            , toggleOption showSubsectorLines_ "Subsector Lines" "Subsector grid within each sector" ToggleSubsectorLines
            , toggleOption showBackgroundNames_ "Sector / Subsector Names" "Faint background watermark of the sector or subsector name" ToggleBackgroundNames
            ]
    in
    el
        [ width fill
        , height fill
        , Events.onClick ToggleDisplaySettings
        , Background.color (Element.rgba 0 0 0 0.3)
        ]
    <|
        el
            [ Element.centerX
            , Element.centerY
            , Element.htmlAttribute (Html.Events.stopPropagationOn "click" (JsDecode.succeed ( NoOpMsg, True )))
            , Background.color (Element.rgba 0.95 0.97 1.0 0.95)
            , Element.htmlAttribute (HtmlAttrs.style "backdrop-filter" "blur(16px)")
            , Element.htmlAttribute (HtmlAttrs.style "-webkit-backdrop-filter" "blur(16px)")
            , Element.padding 20
            , Border.rounded 6
            , Border.width 1
            , Border.color (Element.rgba 0.17 0.42 0.55 0.3)
            , Border.shadow { offset = ( 0, 8 ), size = 0, blur = 32, color = Element.rgba 0 0 0 0.25 }
            , width (Element.px 480)
            ]
        <|
            column [ width fill, Element.spacing 8 ]
                [ row
                    [ width fill
                    , Element.paddingEach { zeroEach | bottom = 12 }
                    , Border.widthEach { zeroEach | bottom = 1 }
                    , Border.color (Element.rgba 0.17 0.42 0.55 0.15)
                    ]
                    [ el [ Font.size 14, Font.bold, Font.color (Element.rgba 0.1 0.25 0.4 0.9) ] (text "Map Display")
                    , el
                        [ Element.alignRight
                        , Events.onClick ToggleDisplaySettings
                        , Element.pointer
                        , Font.size 14
                        , Font.color (Element.rgba 0.17 0.42 0.55 0.6)
                        , Element.mouseOver [ Font.color (Element.rgba 0.17 0.42 0.55 0.9) ]
                        ]
                        (text "✕")
                    ]
                , let
                    half =
                        (List.length options + 1) // 2
                  in
                  row [ width fill, Element.spacing 6 ]
                    [ column [ width (Element.fillPortion 1), Element.spacing 6 ] (List.take half options)
                    , column [ width (Element.fillPortion 1), Element.spacing 6 ] (List.drop half options)
                    ]
                , sectionDivider
                , column [ width fill, Element.spacing 6 ] regionOptions
                , overlayDivider
                , column [ width fill, Element.spacing 6 ] overlayOptions
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
        ( model.hexRect, model.rawHexaPoints )
        { svgWidth = svgWidth, svgHeight = svgHeight, maxAcross = maxAcross, maxTall = maxTall }
        { solarSystemDict = model.solarSystems, hexColours = model.hexColours, regionLabels = model.regionLabels, regions = model.regions, regionDisplay = model.regionDisplay, showSectorLines = model.showSectorLines, showSubsectorLines = model.showSubsectorLines, sectors = model.sectors, showBackgroundNames = model.showBackgroundNames }
        ( model.route, model.currentAddress )
        model.hexScale
        model.selectedHex
        model.isReferee
        model.nativeSophontColour
        model.extinctSophontColour
        model.panOffset
        model.jumpRouteLinks
        model.rogueObjectPathData
        model.displayMode
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
                [ uiDeepnightColorFontColour
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
                , Border.color (Element.rgba 0.17 0.42 0.55 0.3)
                ]
                [ el [ Font.size 11, Font.bold, uiDeepnightColorFontColour, Element.width (Element.px 120) ] (text "Type")
                , el [ Font.size 11, Font.bold, uiDeepnightColorFontColour ] (text "Name")
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

        sidebarColumn =
            Element.Lazy.lazy2 viewSidebarColumn sidebarMsgs sidebarData

        sidebarOverlay =
            el
                [ Element.height Element.fill
                , Element.width (Element.px 320)
                , Element.alignLeft
                , Font.size 14
                , Element.htmlAttribute (HtmlAttrs.style "background-color" "rgba(245, 250, 255, 0.45)")
                , Element.htmlAttribute (HtmlAttrs.style "backdrop-filter" "blur(16px)")
                , Element.htmlAttribute (HtmlAttrs.style "-webkit-backdrop-filter" "blur(16px)")
                , Border.widthEach { zeroEach | right = 1 }
                , Border.color (Element.rgba 0.17 0.42 0.55 0.4)
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
    in
    row
        [ width fill
        , height fill
        , Font.size 20
        , Font.color <| fontTextColor
        , Background.color (Element.rgb255 238 244 249)
        , case model.objectToBeAnalyzed of
            Just analysisDetail ->
                Element.inFront <| viewObjectAnalysisDetail timeChars CloseObjectAnalysis NoOpMsg model.analysisTab SetAnalysisTab model.isReferee analysisDetail.data

            Nothing ->
                Element.htmlAttribute <| HtmlAttrs.class ""
        , Element.htmlAttribute <| HtmlAttrs.class ""
        , case ( model.showTravelTable, model.selectedSystem ) of
            ( True, Just solarSystem ) ->
                Element.inFront <| TravelTable.viewModal travelTableMsgs model.travelTableMDrive solarSystem

            _ ->
                Element.htmlAttribute <| HtmlAttrs.class ""
        , if model.showDisplaySettings then
            Element.inFront <| viewDisplaySettingsModal model.displayMode model.regionDisplay model.isReferee model.showSectorLines model.showSubsectorLines model.showBackgroundNames

          else
            Element.htmlAttribute <| HtmlAttrs.class ""
        ]
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


port navigateToUrl : String -> Cmd msg


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
                            ( updatedModel, Cmd.batch [ storeViewMode "HexMap", saveMapCoords newHexRect.upperLeftHex, downloadCmds ] )
                    in
                    if dist > 2 then
                        ( setJourneyModel { journeyModel | dragMode = NoDragging }
                        , Cmd.none
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

                ( newModel, downloadCmds ) =
                    update DownloadSolarSystems
                        (withTime { model | hexRect = newHexRect, panOffset = { x = 0, y = model.panOffset.y + yCompensation } })
            in
            ( newModel
            , Cmd.batch [ saveMapCoords newHexRect.upperLeftHex, downloadCmds ]
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

                newModel =
                    withTime { model | hexRect = newHexRect, panOffset = { x = remainderX, y = remainderY + yCompensation } }
            in
            if hexDeltaX /= 0 || hexDeltaY /= 0 then
                let
                    ( updatedModel, downloadCmds ) =
                        update DownloadSolarSystems newModel
                in
                ( updatedModel, Cmd.batch [ saveMapCoords newHexRect.upperLeftHex, downloadCmds ] )

            else
                ( newModel, Cmd.none )

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
                        , cmds
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
            ( withTime { model | hoveringHex = Nothing }, Cmd.none )

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
            in
            ( withTime { model | displayMode = mode }
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
            ( withTime { model | regionDisplay = mode }
            , storeRegionDisplay modeString
            )

        ToggleDisplaySettings ->
            ( withTime { model | showDisplaySettings = not model.showDisplaySettings }
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

        ToggleHexmap ->
            update (SetViewMode (if model.viewMode == HexMap then FullJourney else HexMap)) ( time, model )

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
                                            "A" -> { code = "A", quality = "Excellent", fuel = "Refined fuel", facilities = "Shipyard (all), Repair" }
                                            "B" -> { code = "B", quality = "Good", fuel = "Refined fuel", facilities = "Shipyard (spacecraft), Repair" }
                                            "C" -> { code = "C", quality = "Routine", fuel = "Unrefined fuel", facilities = "Shipyard (small craft), Repair" }
                                            "D" -> { code = "D", quality = "Poor", fuel = "Unrefined fuel", facilities = "Limited Repair" }
                                            "E" -> { code = "E", quality = "Frontier", fuel = "None", facilities = "None" }
                                            _ -> { code = "X", quality = "No Starport", fuel = "None", facilities = "None" }
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
                                , period = rnd 2 (pdata.period / 365.25)
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
                                    "A" -> { code = "A", quality = "Excellent", fuel = "Refined fuel", facilities = "Shipyard (all), Repair" }
                                    "B" -> { code = "B", quality = "Good", fuel = "Refined fuel", facilities = "Shipyard (spacecraft), Repair" }
                                    "C" -> { code = "C", quality = "Routine", fuel = "Unrefined fuel", facilities = "Shipyard (small craft), Repair" }
                                    "D" -> { code = "D", quality = "Poor", fuel = "Unrefined fuel", facilities = "Limited Repair" }
                                    "E" -> { code = "E", quality = "Frontier", fuel = "None", facilities = "None" }
                                    _ -> { code = "X", quality = "No Starport", fuel = "None", facilities = "None" }
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
                                starDetailData : AnalyisDetailStarData
                                starDetailData =
                                    { spectralType = starDataConfig.stellarType
                                    , subtype = starDataConfig.subtype |> Maybe.map String.fromInt |> Maybe.withDefault "—"
                                    , class_ = starDataConfig.stellarClass
                                    , colour = starColourName starDataConfig.colour
                                    , temperature = starDataConfig.temperature |> Maybe.map (\t -> String.fromInt t ++ " K") |> Maybe.withDefault "—"
                                    , age = rnd 2 starDataConfig.age ++ " Gyr"
                                    , mass = rndm 3 0 starDataConfig.mass ++ " ☉"
                                    , diameter = rndm 3 0 starDataConfig.diameter ++ " ☉"
                                    , luminosity = rndm 4 0 starDataConfig.luminosity ++ " ☉"
                                    , minimumOrbit = rndm 3 0 starDataConfig.minimumAllowableOrbit
                                    , hzco = rndm 3 0 starDataConfig.hzco
                                    , jumpShadow = starDataConfig.jumpShadow |> Maybe.map (\js -> format { usLocale | decimals = Exact 0, thousandSeparator = " " } js ++ " km") |> Maybe.withDefault "—"
                                    }
                            in
                            AnalyisDetailStar header starDetailData
            in
            ( withTime { model | objectToBeAnalyzed = Just { stellarObject = stellarObject, data = analysisDetail }, timeOpened = time }
            , Cmd.none
            )

        CloseObjectAnalysis ->
            ( withTime { model | objectToBeAnalyzed = Nothing, analysisTab = "orbital" }
            , Cmd.none
            )

        SetAnalysisTab tab ->
            ( withTime { model | analysisTab = tab, timeOpened = time }
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
