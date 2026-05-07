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
import Traveller.SolarSystem as SolarSystem exposing (SolarSystem)
import Traveller.SolarSystemStars exposing (FallibleStarSystem, StarSystem, StarType, StarTypeData, fallibleStarSystemDecoder, getStarTypeData, isBrownDwarfType)
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


type alias NetworkLink =
    { id : Int
    , colour : String
    , known : Bool
    , fromSurveyIndex : Int
    , toSurveyIndex : Int
    , fromX : Int
    , fromY : Int
    , toX : Int
    , toY : Int
    }


networkLinkDecoder : JsDecode.Decoder NetworkLink
networkLinkDecoder =
    JsDecode.map8
        (\id colour known fromSI toSI fromX fromY toX -> NetworkLink id colour known fromSI toSI fromX fromY toX)
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
    46


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
    , selectedStellarObject : Maybe StellarObject
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
    , rogueDetailModal : Maybe (List RogueObjectDetail)
    , timeOpened : Time.Posix
    , campaignName : String
    , allSectorsMapUrl : Maybe String
    , nativeSophontColour : Maybe String
    , extinctSophontColour : Maybe String
    , sidebarOpen : Bool
    , networkLinks : List NetworkLink
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
    | FocusInSidebar StellarObject
    | MapMouseDown ( Float, Float )
    | MapMouseUp (Maybe HexAddress) ( Float, Float ) Bool
    | MapMouseMove ( Float, Float )
    | MapMouseLeave
    | DownloadedRoute ( RequestEntry, String ) (Result Http.Error (List Route))
    | DownloadedNetworkLinks (Result Http.Error (List NetworkLink))
    | SetHexSize Float
    | ToggleHexmap
    | SetViewMode ViewMode
    | JumpToShip
    | ZoomToHex HexAddress Bool
    | JourneyMsg JourneyMsg
    | ViewObjectAnalysisDetail StellarObject
    | OpenedObjectAnalysisTime Time.Posix
    | CloseObjectAnalysis
    | PanMap { deltaX : Int, deltaY : Int }
    | PanPixels { dx : Float, dy : Float }
    | HexMapWheelZoom Float
    | CloseSidebar
    | DownloadedRogues String (Result Http.Error (List RogueResponseItem))
    | CloseRogueDetail


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
            if model.sidebarOpen then
                CloseSidebar

            else
                NoOpMsg

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
    }


defaultHexRectSize : Int
defaultHexRectSize =
    30


minHexSize : Float
minHexSize =
    10


maxHexSize : Float
maxHexSize =
    120


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
            , selectedStellarObject = Nothing
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
            , rogueDetailModal = Nothing
            , timeOpened = Time.millisToPosix 0
            , campaignName = settings.campaignName |> Maybe.withDefault "Navigation"
            , ship = settings.ship
            , allSectorsMapUrl = settings.allSectorsMapUrl
            , nativeSophontColour = settings.nativeSophontColour
            , extinctSophontColour = settings.extinctSophontColour
            , sidebarOpen = False
            , networkLinks = []
            }
    in
    ( ( Time.millisToPosix 0
      , model
      )
    , Cmd.batch
        [ sendSolarSystemRequest ssReqEntry model.hostConfig
        , sendSectorRequest secReqEntry model.hostConfig
        , sendRegionRequest secReqEntry model.hostConfig -- Josh to fix later
        , sendRouteRequest routeReqEntry model.hostConfig
        , sendNetworkLinksRequest model.hostConfig
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


viewHexRogue : HexAddress -> Int -> Int -> Float -> String -> Bool -> RogueHexData -> Svg Msg
viewHexRogue hexAddress x y size hexColour isReferee { surveyIndex, objects } =
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

        showComet =
            hasComet && (isReferee || surveyIndex >= cometSI)

        showGasGiant =
            hasGasGiant && (isReferee || surveyIndex >= gasGiantSI)
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


renderHexContent : HexRenderOpts -> Svg Msg
renderHexContent { starSystem, hexAddrX, hexAddrY, vox, voy, size, isReferee } =
    let
        hexAddress =
            HexAddress hexAddrX hexAddrY

        si =
            starSystem.surveyIndex

        showStar =
            starSystem.surveyIndex > 0

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
    in
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
            hexAddressLabel vox voy size hexAddress
        , if showStar then
            hexAddressLabel vox voy size hexAddress

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
        , if showTravelZone && size > 15 then
            case starSystem.travelZone of
                Just tz ->
                    drawTravelZoneRing (toFloat vox) (toFloat voy) size tz.colour

                Nothing ->
                    Svg.text ""

          else
            Svg.text ""
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
            [ if isReferee || si >= uwpSI then
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
    "#F5F9FC"


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
    -> ( Svg Msg, Svg Msg )
viewHex hexSize solarSystemDict hexAddress vox voy hexColour rawHexaPoints isReferee =
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
            ( viewHexRogue hexAddress vox voy hexSize hexColour isReferee rogueData
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
    | RogueOtherDetail { name : String, typeName : String }


type alias RogueHexData =
    { surveyIndex : Int
    , objects : List RogueObjectDetail
    }


type alias RogueResponseItem =
    { detail : RogueObjectDetail
    , x : Int
    , y : Int
    , surveyIndex : Int
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
                        JsDecode.map
                            (\n -> RogueOtherDetail { name = n, typeName = objType })
                            (JsDecode.field "name" (JsDecode.oneOf [ JsDecode.string, JsDecode.null "" ]))
            )


rogueResponseItemDecoder : JsDecode.Decoder RogueResponseItem
rogueResponseItemDecoder =
    JsDecode.map4 RogueResponseItem
        rogueObjectDetailDecoder
        (JsDecode.field "x" JsDecode.int)
        (JsDecode.field "y" JsDecode.int)
        (JsDecode.field "survey_index" JsDecode.int)


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
    -> { solarSystemDict : SolarSystemDict, hexColours : HexColorDict, regionLabels : RegionLabelDict, regions : RegionDict }
    -> ( RouteList, HexAddress )
    -> Float
    -> Maybe HexAddress
    -> Bool
    -> Maybe String
    -> Maybe String
    -> { x : Float, y : Float }
    -> List NetworkLink
    -> Html Msg
viewHexes ( { upperLeftHex, lowerRightHex }, rawHexaPoints ) { svgWidth, svgHeight, maxAcross, maxTall } { solarSystemDict, hexColours, regionLabels, regions } ( route, currentAddress ) hexSize maybeSelectedHex isReferee nativeSophontColour extinctSophontColour panOffset networkLinks =
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
                        case Dict.get hexKey hexColours of
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
                        List.range (min ulSector.sectorX lrSector.sectorX) (max ulSector.sectorX lrSector.sectorX)
                            |> List.concatMap
                                (\sx ->
                                    List.range (min ulSector.sectorY lrSector.sectorY) (max ulSector.sectorY lrSector.sectorY)
                                        |> List.map
                                            (\sy ->
                                                renderSectorOutline hexSize { ulSector | sectorX = sx, sectorY = sy }
                                            )
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
                        regions |> Dict.values |> List.filterMap renderBorderRegion
                in
                let
                    visibleLinks =
                        List.filter
                            (\link ->
                                isReferee
                                    || link.fromSurveyIndex >= 10
                                    || link.toSurveyIndex >= 10
                                    || link.known
                            )
                            networkLinks

                    networkLinkLines =
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
                                    , SvgAttrs.strokeWidth "4"
                                    , SvgAttrs.strokeOpacity "0.7"
                                    , SvgAttrs.strokeLinecap "round"
                                    , SvgAttrs.pointerEvents "none"
                                    ]
                                    []
                            )
                            visibleLinks
                in
                [ keyedHexBackgrounds ]
                    ++ [ keyedHexBorders ]
                    ++ [ singlePolyHex ]
                    ++ [ Svg.g [ SvgAttrs.pointerEvents "none" ] networkLinkLines ]
                    ++ [ keyedHexForegrounds ]
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


viewStatusRow : ModelData -> Element.Element Msg
viewStatusRow model =
    let
        extras =
            case model.viewMode of
                HexMap ->
                    [ el
                        [ uiDeepnightColorFontColour
                        , Font.size 14
                        , Element.pointer
                        , Events.onClick (SetHexSize (clamp minHexSize maxHexSize (model.hexScale * 1.1)))
                        , Element.alignBottom
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
                        , Element.alignBottom
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
                        , Element.alignBottom
                        , Element.htmlAttribute <| HtmlAttrs.title "Refresh map"
                        , Element.mouseOver
                            [ Font.color <| convertColor (Color.Manipulate.lighten 0.25 deepnightColor)
                            ]
                        ]
                      <|
                        renderFAIcon "fa-regular fa-refresh" 14
                    , el
                        [ uiDeepnightColorFontColour
                        , Font.family [ Font.monospace ]
                        , Font.size 14
                        , Element.alignBottom
                        , Element.width <| Element.minimum 10 Element.shrink
                        ]
                      <|
                        case model.hoveringHex of
                            Just hoveringHex ->
                                text <| universalHexLabel model.sectors hoveringHex

                            Nothing ->
                                Element.none
                    , -- hex rect display
                      el [ Element.alignBottom, Font.size 14, uiDeepnightColorFontColour, Element.centerX ] <|
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
                        , Element.alignBottom
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
                        , Element.alignBottom
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
                        , Element.alignBottom
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
                , Element.alignBottom
                ]
            <|
                renderFAIcon (iconStyle ++ " " ++ iconName) 16
    in
    Element.wrappedRow [ Element.spacing 8, Element.width Element.fill, Element.paddingEach { zeroEach | bottom = 8 } ] <|
        [ el [ Font.size 20, uiDeepnightColorFontColour ] <| text model.campaignName
        , viewModeIcon HexMap "fa-hexagon"
        , viewModeIcon FullJourney "fa-map"
        ]
            ++ extras


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
        { solarSystemDict = model.solarSystems, hexColours = model.hexColours, regionLabels = model.regionLabels, regions = model.regions }
        ( model.route, model.currentAddress )
        model.hexScale
        model.selectedHex
        model.isReferee
        model.nativeSophontColour
        model.extinctSophontColour
        model.panOffset
        model.networkLinks
        |> Element.html


viewRogueDetailModal : Msg -> List RogueObjectDetail -> Element Msg
viewRogueDetailModal closeMsg objects =
    el
        [ width fill
        , height fill
        , Events.onClick closeMsg
        ]
    <|
        column
            [ centerX
            , centerY
            , Element.htmlAttribute (Html.Events.stopPropagationOn "click" (JsDecode.succeed ( NoOpMsg, True )))
            , Element.htmlAttribute (HtmlAttrs.style "background-color" "rgba(245, 250, 255, 0.45)")
            , Element.htmlAttribute (HtmlAttrs.style "backdrop-filter" "blur(16px)")
            , Element.htmlAttribute (HtmlAttrs.style "-webkit-backdrop-filter" "blur(16px)")
            , width <| Element.px 400
            , Element.padding 20
            , Border.rounded 6
            , Border.width 1
            , Border.color <| Element.rgba 0.17 0.42 0.55 0.3
            , Border.shadow { offset = ( 0, 8 ), size = 0, blur = 32, color = Element.rgba 0 0 0 0.25 }
            , Element.spacing 16
            ]
            (List.map (viewRogueObject closeMsg) objects)


viewRogueObject : Msg -> RogueObjectDetail -> Element Msg
viewRogueObject closeMsg detail =
    let
        ( header, fields ) =
            case detail of
                RogueCometDetail d ->
                    ( "Comet"
                    , [ ( "Name", d.name )
                      , ( "Type", cometTypeDescription d.cometType )
                      ]
                    )

                RogueGasGiantDetail d ->
                    ( "Gas Giant"
                    , [ ( "Name", d.name )
                      , ( "Size", d.code )
                      , ( "Diameter (km)", format { usLocale | decimals = Exact 0, thousandSeparator = " " } d.diameter )
                      , ( "Mass (earths)", d.mass |> Maybe.map (Round.round 2) |> Maybe.withDefault "—" )
                      ]
                    )

                RogueOtherDetail d ->
                    ( d.typeName
                    , [ ( "Name", d.name ) ]
                    )
    in
    column [ Element.spacing 4 ]
        (row
            [ width fill
            , Element.paddingEach { top = 0, right = 0, bottom = 8, left = 0 }
            , Border.widthEach { top = 0, right = 0, bottom = 1, left = 0 }
            , Border.color <| Element.rgba 0.17 0.42 0.55 0.15
            ]
            [ el [ Font.size 18, uiDeepnightColorFontColour, Font.bold ] (text header)
            , el
                [ Element.alignRight
                , Element.pointer
                , Element.mouseOver [ Font.color <| Element.rgb 0 0 0 ]
                , Font.size 16
                , Font.color <| Element.rgba 0.17 0.42 0.55 0.7
                , Events.onClick closeMsg
                ]
                (text "✕")
            ]
            :: List.map
                (\( label, value ) ->
                    row [ Element.spacing 8 ]
                        [ el [ Font.size 12, Font.color <| Element.rgba 0.17 0.42 0.55 0.7, Element.width (Element.px 120) ] (text label)
                        , el [ Font.size 12 ] (text value)
                        ]
                )
                fields
        )


cometTypeDescription : String -> String
cometTypeDescription cometType =
    case cometType of
        "tiny" ->
            "Tiny, ice-bearing suitable for one refuelling only"

        "medium" ->
            "Ice-bearing suitable for multiple refuellings"

        "large" ->
            "Large"

        "inhabited" ->
            "Inhabited"

        _ ->
            cometType


view : Model -> Element.Element Msg
view ( time, model ) =
    let
        sidebarMsgs : SidebarMsgs Msg
        sidebarMsgs =
            { focusInSidebar = FocusInSidebar
            , viewDetail = ViewObjectAnalysisDetail
            , closeSidebar = CloseSidebar
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
            , selectedStellarObject = model.selectedStellarObject
            , isReferee = model.isReferee
            , allSectorsMapUrl = model.allSectorsMapUrl
            , mDrive = model.ship |> Maybe.andThen .mDrive
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
            (Time.posixToMillis time - Time.posixToMillis model.timeOpened) // 20
    in
    row
        [ width fill
        , height fill
        , Font.size 20
        , Font.color <| fontTextColor
        , Background.color (Element.rgb255 238 244 249)
        , case model.objectToBeAnalyzed of
            Just analysisDetail ->
                Element.inFront <| viewObjectAnalysisDetail timeChars CloseObjectAnalysis NoOpMsg analysisDetail.data

            Nothing ->
                Element.htmlAttribute <| HtmlAttrs.class ""
        , case model.rogueDetailModal of
            Just rogueObjects ->
                Element.inFront <| viewRogueDetailModal CloseRogueDetail rogueObjects

            Nothing ->
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
                (urlHostPath ++ [ "stars" ])
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

                lr =
                    HexAddress.shiftAddressBy
                        { deltaX = hh, deltaY = vh }
                        model.hexRect.upperLeftHex

                newHexRect =
                    { upperLeftHex = model.hexRect.upperLeftHex
                    , lowerRightHex = lr
                    }

                ( newModel, newCmds ) =
                    let
                        ( newModel_, newCmds_ ) =
                            ( { model
                                | hexScale = newSize
                                , rawHexaPoints = rawHexagonPoints newSize
                                , hexRect = newHexRect
                                , viewMode = HexMap
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

        DownloadedNetworkLinks (Ok links) ->
            ( withTime { model | networkLinks = links }, Cmd.none )

        DownloadedNetworkLinks (Err _) ->
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
                    , selectedStellarObject = Nothing
                    , selectedSystem = Nothing
                    , newSolarSystemErrors = focusedErrors
                    , sidebarOpen = True
                }
            , fetchSingleSolarSystemRequest model.hostConfig <| toSectorAddress hexAddress
            )

        FocusInSidebar stellarObject ->
            ( withTime { model | selectedStellarObject = Just stellarObject }
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
                                            , selectedStellarObject = Nothing
                                            , selectedSystem = Nothing
                                            , rogueDetailModal = rogueObjects
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
                        header : AnalysisDetailHeader
                        header =
                            { header =
                                (getStellarOrbit stellarObject |> .orbitSequence)
                                    ++ " ["
                                    ++ getProfileString stellarObject
                                    ++ "]"
                            }

                        buildStringGasGiant : GasGiantData -> AnalyisDetailGasGiantData
                        buildStringGasGiant ggdata =
                            { physical =
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
                            in
                            { uwp = pdata.uwp
                            , orbital =
                                { orbit = rnd 2 pdata.orbit
                                , au = rnd 2 pdata.au
                                , period = rnd 2 (pdata.period / 365.25) ++ " yrs"
                                , effectiveHZCODeviation = rnd 2 pdata.effectiveHZCODeviation
                                , retrograde =
                                    if pdata.retrograde then
                                        "Yes"

                                    else
                                        "No"
                                , inclination = rnd 0 pdata.inclination ++ "°"
                                , eccentricity = rnd 2 pdata.eccentricity
                                }
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
                            in
                            { physical =
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
                                        |> Maybe.map
                                            (.code
                                                >> hydrographicsPercentageDescription
                                            )
                                        |> Maybe.withDefault "N/A"
                                , surfaceDistribution =
                                    pdata.hydrographics
                                        |> Maybe.map
                                            (.distribution
                                                >> surfaceDistributionDescription
                                            )
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
            ( withTime { model | objectToBeAnalyzed = Just { stellarObject = stellarObject, data = analysisDetail } }
            , Task.perform OpenedObjectAnalysisTime Time.now
            )

        OpenedObjectAnalysisTime openedTime ->
            ( withTime { model | timeOpened = openedTime }, Cmd.none )

        CloseObjectAnalysis ->
            ( withTime { model | objectToBeAnalyzed = Nothing }
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
                                            Just { surveyIndex = item.surveyIndex, objects = [ item.detail ] }
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

        CloseRogueDetail ->
            ( withTime { model | rogueDetailModal = Nothing }, Cmd.none )


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


sendNetworkLinksRequest : HostConfig -> Cmd Msg
sendNetworkLinksRequest hostConfig =
    let
        ( urlHostRoot, urlHostPath ) =
            hostConfig

        url =
            Url.Builder.crossOrigin
                urlHostRoot
                (urlHostPath ++ [ "network_links" ])
                []
    in
    Http.request
        { method = "GET"
        , headers = []
        , url = url
        , body = Http.emptyBody
        , expect = Http.expectJson DownloadedNetworkLinks (JsDecode.list networkLinkDecoder)
        , timeout = Just 15000
        , tracker = Nothing
        }
