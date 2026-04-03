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
        , sidebarWidth
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


refereeSI =
    99


gasGiantSI =
    5


terrestrialSI =
    6


planetoidSI =
    6


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
            let
                markSolarSystemLoadingIfNotFound maybeSolarSystem =
                    case maybeSolarSystem of
                        Just existingSolarSystem ->
                            Just existingSolarSystem

                        Nothing ->
                            Just LoadingSolarSystem
            in
            HexAddress.between upperLeftHex lowerRightHex
                |> List.foldl
                    (\hexAddr solarSystemDict ->
                        Dict.update (HexAddress.toKey hexAddr)
                            markSolarSystemLoadingIfNotFound
                            solarSystemDict
                    )
                    oldSolarSystemDict
    in
    ( requestEntry, ( newSolarSystemDict, requestEntry :: requestHistory ) )


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
    , currentAddress : HexAddress
    , hostConfig : HostConfig.HostConfig
    , route : RouteList
    , regions : RegionDict
    , regionLabels : Dict.Dict String String
    , hexColours : Dict.Dict String Color
    , isReferee : Bool
    , objectToBeAnalyzed : Maybe { stellarObject : StellarObject, data : AnalysisDetail }
    , timeOpened : Time.Posix
    , campaignName : String
    , shipName : String
    , allSectorsMapUrl : Maybe String
    , nativeSophontColour : Maybe String
    , extinctSophontColour : Maybe String
    }


type ZoomType
    = ZoomIn
    | ZoomOut
    | ZoomSet Float


type Msg
    = NoOpMsg
    | Tick Time.Posix
    | DownloadSolarSystems
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
    | MapMouseUp
    | MapMouseMove ( Float, Float )
    | MapMouseLeave
    | DownloadedRoute ( RequestEntry, String ) (Result Http.Error (List Route))
    | SetHexSize Float
    | ToggleHexmap
    | JumpToShip
    | ZoomToHex HexAddress Bool
    | JourneyMsg JourneyMsg
    | ViewObjectAnalysisDetail StellarObject
    | OpenedObjectAnalysisTime Time.Posix
    | CloseObjectAnalysis
    | PanMap { deltaX : Int, deltaY : Int }


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

        stepH =
            if ctrl then halfH else 1

        stepV =
            if ctrl then halfV else 1
    in
    case ( model.objectToBeAnalyzed, model.viewMode, key ) of
        ( Just _, _, "Escape" ) ->
            CloseObjectAnalysis

        ( Nothing, HexMap, "ArrowRight" ) ->
            PanMap { deltaX = stepH, deltaY = 0 }

        ( Nothing, HexMap, "ArrowLeft" ) ->
            PanMap { deltaX = -stepH, deltaY = 0 }

        ( Nothing, HexMap, "ArrowUp" ) ->
            PanMap { deltaX = 0, deltaY = -stepV }

        ( Nothing, HexMap, "ArrowDown" ) ->
            PanMap { deltaX = 0, deltaY = stepV }

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
    , shipName : Maybe String
    , allSectorsMapUrl : Maybe String
    , nativeSophontColour : Maybe String
    , extinctSophontColour : Maybe String
    , viewMode : Maybe String
    }


defaultHexRectSize : Int
defaultHexRectSize =
    30


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
                upperLeftHex =
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

                hexmapWidth =
                    viewport.viewport.width - toFloat (sidebarWidth + 15)

                hexmapHeight =
                    viewport.viewport.height - consoleTitleHeight

                deltaX =
                    (hexmapWidth / hexWidth settings.hexSize |> ceiling) + 2

                deltaY =
                    (hexmapHeight / hexHeight settings.hexSize |> ceiling) + 2

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
            { zoomScale = 1.0
            , zoomOffset = ( 0, 0 )
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
            , hostConfig = hostConfig
            , sectors = Dict.empty
            , route = []
            , currentAddress = toUniversalAddress { sectorX = -10, sectorY = -2, x = 31, y = 24 }
            , regions = Dict.empty
            , regionLabels = Dict.empty
            , hexColours = Dict.empty
            , isReferee = referee
            , objectToBeAnalyzed = Nothing
            , timeOpened = Time.millisToPosix 0
            , campaignName = settings.campaignName |> Maybe.withDefault "Navigation"
            , shipName = settings.shipName |> Maybe.withDefault "Ship"
            , allSectorsMapUrl = settings.allSectorsMapUrl
            , nativeSophontColour = settings.nativeSophontColour
            , extinctSophontColour = settings.extinctSophontColour
            }
    in
    ( ( Time.millisToPosix 0
      , model
      )
    , Cmd.batch
        [ sendSolarSystemRequest ssReqEntry model.hostConfig model.hexRect
        , sendSectorRequest secReqEntry model.hostConfig
        , sendRegionRequest secReqEntry model.hostConfig -- Josh to fix later
        , sendRouteRequest routeReqEntry model.hostConfig
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
                ]
                [ Svg.text childSvgTxt ]
    in
    Svg.g
        [ SvgEvents.onMouseOver (HoveringHex hexAddress)
        , SvgEvents.onClick (ViewingHex hexAddress)
        , SvgEvents.onMouseUp MapMouseUp
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
        , SvgAttrs.stroke "#CCCCCC"
        , SvgAttrs.strokeWidth "1"
        , SvgAttrs.pointerEvents "visiblePainted"
        , SvgAttrs.class "hex-hover"
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
           JsDecode.map (\evt -> onDownMsg evt.offsetPos)


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


mouseUpDecoder : (( Float, Float ) -> msg) -> JsDecode.Decoder msg
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
           JsDecode.map (\evt -> onDownMsg evt.offsetPos)


mouseMoveDecoder : (( Float, Float ) -> msg) -> JsDecode.Decoder msg
mouseMoveDecoder onMoveMsg =
    Html.Events.Extra.Mouse.eventDecoder
        |> JsDecode.map (.offsetPos >> onMoveMsg)


drawStar : Float -> Float -> Int -> Float -> String -> Svg Msg
drawStar starX starY radius size starColor =
    Svg.circle
        [ SvgAttrs.cx <| String.fromFloat <| starX
        , SvgAttrs.cy <| String.fromFloat <| starY
        , SvgAttrs.r <| String.fromFloat <| scaleAttr size radius
        , SvgAttrs.fill starColor
        , SvgAttrs.style "filter: drop-shadow( 2px 2px 2px rgba(0, 0, 0, .25))"
        ]
        []


renderHexWithStar : StarSystem -> String -> Int -> Int -> Int -> Int -> Float -> String -> Svg Msg
renderHexWithStar starSystem hexColour hexAddrX hexAddrY vox voy size hexapointsStr =
    let
        hexAddress =
            HexAddress hexAddrX hexAddrY

        si =
            starSystem.surveyIndex

        showStar =
            starSystem.surveyIndex > 0
    in
    Svg.g
        [ SvgEvents.onMouseOver (HoveringHex hexAddress)
        , SvgEvents.onClick (ViewingHex hexAddress)
        , SvgEvents.onMouseUp MapMouseUp
        , -- listens for the JS 'mousedown' event and then runs the `downDecoder` on the JS Event, returning the Msg
          SvgEvents.on "mousedown" <| mouseDownDecoder MapMouseDown
        , SvgEvents.on "mousemove" <| mouseMoveDecoder MapMouseMove
        , SvgAttrs.style "cursor: pointer; user-select: none"
        ]
        [ -- background hex
          Svg.Lazy.lazy2 renderPolygon hexapointsStr hexColour
        , -- center star
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
            Svg.g []
                [ hexAddressLabel vox voy size hexAddress
                , if size <= 15 then
                    Svg.text ""

                  else
                    Svg.text_
                        [ SvgAttrs.x <| String.fromInt <| vox
                        , SvgAttrs.y <| String.fromInt <| voy + (floor <| size * 0.8) - 1
                        , SvgAttrs.fontSize "10"
                        , SvgAttrs.textAnchor "middle"
                        , SvgAttrs.style "letter-spacing: 3px"
                        ]
                    (let
                        showIfKnown req value =
                            if si >= req then
                                toEHexChar value

                            else
                                "?"
                     in
                     [ Svg.tspan [ SvgAttrs.fill "#68B976", SvgAttrs.fontWeight "800" ]
                        [ Svg.text <| showIfKnown terrestrialSI starSystem.terrestrialPlanetCount ]
                     , Svg.tspan [ SvgAttrs.fill "#68B976", SvgAttrs.fontWeight "800" ]
                        [ Svg.text <| showIfKnown planetoidSI starSystem.planetoidBeltCount ]
                     , Svg.tspan [ SvgAttrs.fill "#68B976", SvgAttrs.fontWeight "800" ]
                        [ Svg.text <| showIfKnown gasGiantSI starSystem.gasGiantCount ]
                     ]
                    )
                ]

          else
            Svg.text ""
        ]


defaultHexBg =
    "#f5f5f5"


selectedHexBg =
    "#a5f5a5"


routeHexBg =
    "#FCD299"


nativeSophontHexBg =
    "#B0E0E6"


extinctSophontHexBg =
    "#EEE8AA"


currentAddressHexBg =
    "#fe5a1d"


allegianceColours : Dict.Dict String String
allegianceColours =
    Dict.fromList
        [ ( "C", "#F0FFFF" )
        , ( "GR", "#FFDAB9" )
        , ( "AL", "#D2691E" )
        ]


viewHex :
    Float
    -> SolarSystemDict
    -> HexAddress
    -> Int
    -> Int
    -> String
    -> List ( Float, Float )
    -> Svg Msg
viewHex hexSize solarSystemDict hexAddress vox voy hexColour rawHexaPoints =
    let
        remoteSolarSystem =
            Dict.get (HexAddress.toKey hexAddress) solarSystemDict

        viewEmptyHelper txt =
            Svg.Lazy.lazy7 viewHexEmpty hexAddress.x hexAddress.y vox voy hexSize txt hexColour

        hexSVG =
            case remoteSolarSystem of
                Just (LoadedSolarSystem loadedSystem) ->
                    let
                        hexapointsStr =
                            convertRawHexagonPoints ( toFloat vox, toFloat voy ) rawHexaPoints
                    in
                    Svg.Lazy.lazy8 renderHexWithStar
                        loadedSystem
                        hexColour
                        -- hex address
                        hexAddress.x
                        hexAddress.y
                        -- visual origin
                        vox
                        voy
                        hexSize
                        hexapointsStr

                Just LoadingSolarSystem ->
                    viewEmptyHelper "Loading..."

                Just (FailedSolarSystem httpError) ->
                    viewEmptyHelper "Failed."

                Just LoadedEmptyHex ->
                    viewEmptyHelper ""

                Just (FailedStarsSolarSystem failedSolarSystem) ->
                    Svg.Lazy.lazy7 viewHexEmpty hexAddress.x hexAddress.y vox voy hexSize "Star Failed." "#aaaaaa"

                Nothing ->
                    viewEmptyHelper ""
    in
    hexSVG


type RemoteSolarSystem
    = LoadedSolarSystem StarSystem
    | LoadedEmptyHex
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
        , SvgAttrs.stroke "#0a0a0a40"
        , SvgAttrs.fill "none"
        , SvgAttrs.strokeWidth "3"
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
        , SvgAttrs.fill "#0A0A0A"
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
    -> Html Msg
viewHexes ( { upperLeftHex, lowerRightHex }, rawHexaPoints ) { svgWidth, svgHeight, maxAcross, maxTall } { solarSystemDict, hexColours, regionLabels, regions } ( route, currentAddress ) hexSize maybeSelectedHex isReferee nativeSophontColour extinctSophontColour =
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
                in
                ( hexSvgsWithHexAddress, labels )
           )
        |> (\( hexSvgsWithHexAddress, labels ) ->
                let
                    singlePolyHex =
                        renderCurrentAddressOutline currentAddress

                    keyedHexes : Svg Msg
                    keyedHexes =
                        hexSvgsWithHexAddress
                            |> List.map
                                (\( addr, hex ) ->
                                    ( HexAddress.toKey addr, hex )
                                )
                            |> Svg.Keyed.node "g" []
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
                [ keyedHexes ]
                    ++ sectorOutlines
                    ++ regionBorderLines
                    ++ [ singlePolyHex ]
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
                , viewBox <|
                    toViewBox hexSize upperLeftHex
                        ++ " "
                        ++ widthString
                        ++ " "
                        ++ heightString
                ]
           )


toViewBox : Float -> HexAddress -> String
toViewBox hexScale { x, y } =
    calcVisualOrigin hexScale { col = x, row = y }
        |> (\( x_, y_ ) ->
                String.fromFloat (toFloat x_)
                    ++ " "
                    ++ String.fromFloat (toFloat y_)
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
        ( maxWidth, maxHeight ) =
            let
                availableWidth =
                    viewport.viewport.width - sidebarWidth - 50

                availableHeight =
                    viewport.viewport.height - consoleTitleHeight

                aspectRatio =
                    fullJourneyImageHeight / fullJourneyImageWidth

                heightFromWidth =
                    availableWidth * aspectRatio
            in
            if heightFromWidth <= availableHeight then
                ( availableWidth, heightFromWidth )

            else
                ( availableHeight / aspectRatio, availableHeight )

        ( imageSizeWidth, imageSizeHeight ) =
            ( maxWidth * model.zoomScale
            , maxHeight * model.zoomScale
            )

        ( offsetLeft, offsetTop ) =
            model.zoomOffset
    in
    el
        [ Element.alignTop
        , width <| Element.px <| floor maxWidth
        , height <| Element.px <| floor maxHeight
        , Element.clip
        , Element.htmlAttribute <| Html.Events.on "mousemove" <| mouseMoveDecoder (JourneyMsg << MouseMove)
        , Element.htmlAttribute <| Html.Events.on "mousedown" <| mouseDownDecoder (JourneyMsg << MouseDown)
        , Element.htmlAttribute <| Html.Events.on "mouseup" <| mouseUpDecoder (JourneyMsg << MouseUp)
        , Events.onMouseLeave (JourneyMsg MouseLeave)
        , Element.htmlAttribute <| Html.Events.preventDefaultOn "wheel" <|
            JsDecode.map (\dy -> ( JourneyMsg (WheelZoom dy), True )) (JsDecode.field "deltaY" JsDecode.float)
        , Background.color <| Element.rgb 1.0 0.498 0.0
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
                                        ( 5, 1 )
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
                    [ -- hovered hex
                      el
                        [ uiDeepnightColorFontColour
                        , Font.size 14
                        , Element.spacing 5
                        , Element.pointer
                        , Events.onClick DownloadSolarSystems
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
                        [ text model.shipName
                        , renderFAIcon "fa-regular fa-crosshairs-simple" 14
                        , text <|
                            (universalHexLabelMaybe model.sectors model.currentAddress
                                |> Maybe.withDefault "???"
                            )
                        ]
                    ]

                FullJourney ->
                    []
    in
    Element.wrappedRow [ Element.spacing 8, Element.width Element.fill, Element.paddingEach { zeroEach | bottom = 8 } ] <|
        (el [ Font.size 20, uiDeepnightColorFontColour ] <|
            text <|
                model.campaignName
        )
            :: extras


viewHexMap : ModelData -> Element Msg
viewHexMap model =
    let
        svgHeight =
            model.viewport.viewport.viewport.height - consoleTitleHeight

        svgWidth =
            model.viewport.viewport.viewport.width - (sidebarWidth + 15)

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
        |> Element.html


view : Model -> Element.Element Msg
view ( time, model ) =
    let
        sidebarMsgs : SidebarMsgs Msg
        sidebarMsgs =
            { setHexSize = SetHexSize
            , toggleHexmap = ToggleHexmap
            , focusInSidebar = FocusInSidebar
            , viewDetail = ViewObjectAnalysisDetail
            }

        solarSystemStatus =
            case model.selectedHex of
                Just viewingAddress ->
                    case model.solarSystems |> Dict.get (HexAddress.toKey viewingAddress) of
                        Just LoadingSolarSystem ->
                            Just "loading..."

                        Just (FailedSolarSystem _) ->
                            Just "failed."

                        Just (FailedStarsSolarSystem _) ->
                            Just "decoding a star failed"

                        Nothing ->
                            Just "No solar system data found for system."

                        _ ->
                            Nothing

                Nothing ->
                    Nothing

        sidebarData =
            { hexScale = model.hexScale
            , isHexMapMode = model.viewMode == HexMap
            , isFullJourneyMode = model.viewMode == FullJourney
            , selectedHex = model.selectedHex
            , solarSystemStatus = solarSystemStatus
            , sectors = model.sectors
            , regions = model.regions
            , selectedSystem = model.selectedSystem
            , selectedStellarObject = model.selectedStellarObject
            , isReferee = model.isReferee
            , allSectorsMapUrl = model.allSectorsMapUrl
            }

        sidebarColumn =
            Element.Lazy.lazy2 viewSidebarColumn sidebarMsgs sidebarData

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
        , Background.color (Element.rgb255 33 37 41)
        , Element.paddingEach { zeroEach | left = 15 }
        , case model.objectToBeAnalyzed of
            Just analysisDetail ->
                Element.inFront <| viewObjectAnalysisDetail timeChars CloseObjectAnalysis NoOpMsg analysisDetail.data

            Nothing ->
                Element.htmlAttribute <| HtmlAttrs.class ""
        ]
        [ el [ Element.height fill, Element.width <| Element.px sidebarWidth, Element.alignTop, Element.alignLeft, Element.scrollbarY ] <|
            sidebarColumn
        , column [ width fill, Element.alignTop ]
            [ viewStatusRow model
            , el [ Element.alignTop ] contentColumn
            ]
        , Element.html <| errorDialog model.newSolarSystemErrors
        ]


sendSolarSystemRequest : RequestEntry -> HostConfig -> HexRect -> Cmd Msg
sendSolarSystemRequest requestEntry hostConfig { upperLeftHex, lowerRightHex } =
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
                [ Url.Builder.int "ulx" upperLeftHex.x
                , Url.Builder.int "uly" upperLeftHex.y
                , Url.Builder.int "lrx" lowerRightHex.x
                , Url.Builder.int "lry" lowerRightHex.y
                ]

        requestCmd =
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
    in
    requestCmd


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


saveHexSize : Float -> Cmd Msg
saveHexSize size =
    storeHexSize size


port storeHexSize : Float -> Cmd msg


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
            ( setJourneyModel newJourneyModel, Cmd.none )

        Pan ( dx, dy ) ->
            let
                ( maxWidth, maxHeight ) =
                    ( model.viewport.viewport.viewport.width - sidebarWidth - 50
                    , model.viewport.viewport.viewport.height
                    )

                ( curImgWidth, curImgHeight ) =
                    ( maxWidth * journeyModel.zoomScale
                    , maxHeight * journeyModel.zoomScale
                    )

                ( oldX, oldY ) =
                    journeyModel.zoomOffset
            in
            ( setJourneyModel
                { journeyModel
                    | zoomOffset =
                        ( clamp (maxWidth - curImgWidth) 0 (oldX + dx)
                        , clamp (maxHeight - curImgHeight) 0 (oldY + dy)
                        )
                }
            , Cmd.none
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

                ( maxWidth, maxHeight ) =
                    ( model.viewport.viewport.viewport.width - sidebarWidth - 50
                    , model.viewport.viewport.viewport.height
                    )

                ( curImgWidth, curImgHeight ) =
                    ( maxWidth * newZoomScale
                    , maxHeight * newZoomScale
                    )

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
                                    maxWidth / 2

                                cy =
                                    maxHeight / 2
                            in
                            ( cx - (cx - ox) * actualFactor
                            , cy - (cy - oy) * actualFactor
                            )
            in
            ( setJourneyModel
                { journeyModel
                    | zoomScale = newZoomScale
                    , zoomOffset =
                        ( clamp (maxWidth - curImgWidth) 0 newOx
                        , clamp (maxHeight - curImgHeight) 0 newOy
                        )
                }
            , Cmd.none
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

                        ( maxWidth, maxHeight ) =
                            ( model.viewport.viewport.viewport.width - sidebarWidth - 50
                            , model.viewport.viewport.viewport.height
                            )

                        ( oldX, oldY ) =
                            journeyModel.zoomOffset

                        ( curImgWidth, curImgHeight ) =
                            ( maxWidth * journeyModel.zoomScale
                            , maxHeight * journeyModel.zoomScale
                            )

                        newModel =
                            { journeyModel
                                | dragMode = IsDragging { start = start, last = ( newX, newY ) }
                                , zoomOffset =
                                    ( clamp (maxWidth - curImgWidth) 0 (oldX + xDelta)
                                    , clamp (maxHeight - curImgHeight) 0 (oldY + yDelta)
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
                                ( maxWidth, maxHeight ) =
                                    let
                                        scaledWidth =
                                            model.viewport.viewport.viewport.width - sidebarWidth - 50
                                    in
                                    ( scaledWidth
                                    , scaledWidth * (fullJourneyImageHeight / fullJourneyImageWidth)
                                    )

                                imageSize =
                                    { width = maxWidth * journeyModel.zoomScale, height = maxHeight * journeyModel.zoomScale }

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
                                    }
                            in
                            update DownloadSolarSystems ( time, newModel )
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

        DownloadSolarSystems ->
            let
                ( nextRequestEntry, ( newSolarSystemDict, newRequestHistory ) ) =
                    prepNextRequest ( model.solarSystems, model.requestHistory ) model.hexRect
            in
            ( withTime
                { model
                    | requestHistory = newRequestHistory
                    , solarSystems = newSolarSystemDict
                }
            , sendSolarSystemRequest nextRequestEntry model.hostConfig model.hexRect
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
                                , Dict.get addrKey sortedSolarSystems |> Maybe.withDefault LoadedEmptyHex
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

                solarSystemDict =
                    rangeAsPairs
                        |> Dict.fromList
                        |> (\newDict ->
                                -- `Dict.union` merges the dict, preferring the left arg's to resolve dupes, so we want to prefer the new one
                                Dict.union newDict existingDict
                           )

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

        FetchedSolarSystem (Ok solarSystem) ->
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
            ( withTime { model | newSolarSystemErrors = model.newSolarSystemErrors ++ [ ( Http.BadBody err, "foo" ) ] }, Cmd.none )

        FetchedSolarSystem (Err err) ->
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
            in
            ( withTime { model | viewport = { oldViewport | hexmapViewport = Just hexmapOrErr } }, Cmd.none )

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

                ( newModel, downloadCmds ) =
                    update DownloadSolarSystems
                        (withTime { model | hexRect = newHexRect })
            in
            ( newModel
            , Cmd.batch [ saveMapCoords newHexRect.upperLeftHex, downloadCmds ]
            )

        MapMouseUp ->
            case model.dragMode of
                IsDragging { start, last } ->
                    if start /= last then
                        let
                            ( nextRequestEntry, ( newSolarSystemDict, newRequestHistory ) ) =
                                prepNextRequest ( model.solarSystems, model.requestHistory ) model.hexRect
                        in
                        ( withTime
                            { model
                                | dragMode = NoDragging
                                , requestHistory = newRequestHistory
                                , solarSystems = newSolarSystemDict
                            }
                        , sendSolarSystemRequest nextRequestEntry model.hostConfig model.hexRect
                        )

                    else
                        ( withTime
                            { model
                                | dragMode = NoDragging
                            }
                        , Cmd.none
                        )

                _ ->
                    ( withTime
                        { model
                            | dragMode = NoDragging
                        }
                    , Cmd.none
                    )

        MapMouseMove ( newX, newY ) ->
            case model.dragMode of
                IsDragging { start, last } ->
                    let
                        ( originX, originY ) =
                            last

                        xDelta =
                            truncate <| (originX - newX) / model.hexScale

                        yDelta =
                            truncate <| (originY - newY) / model.hexScale

                        shiftAddress hex =
                            HexAddress.shiftAddressBy
                                { deltaX = xDelta, deltaY = yDelta }
                                hex

                        newHexRect =
                            { lowerRightHex = shiftAddress model.hexRect.lowerRightHex
                            , upperLeftHex = shiftAddress model.hexRect.upperLeftHex
                            }

                        newModel =
                            { model
                                | dragMode = IsDragging { start = start, last = ( newX, newY ) }
                                , hexRect = newHexRect
                            }
                    in
                    if xDelta /= 0 || yDelta /= 0 then
                        ( withTime newModel
                        , saveMapCoords newModel.hexRect.upperLeftHex
                        )

                    else
                        ( withTime model, Cmd.none )

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

                ( nextRequestEntry, ( newSolarSystemDict, newRequestHistory ) ) =
                    prepNextRequest ( model.solarSystems, model.requestHistory ) newHexRect
            in
            ( withTime
                { model
                    | hexRect = newHexRect
                    , requestHistory = newRequestHistory
                    , solarSystems = newSolarSystemDict
                }
            , Cmd.batch
                [ saveMapCoords newHexRect.upperLeftHex
                , sendSolarSystemRequest nextRequestEntry model.hostConfig newHexRect
                ]
            )

        ToggleHexmap ->
            let
                newViewMode =
                    if model.viewMode == HexMap then
                        FullJourney

                    else
                        HexMap

                viewModeString =
                    case newViewMode of
                        FullJourney ->
                            "FullJourney"

                        HexMap ->
                            "HexMap"
            in
            ( withTime { model | viewMode = newViewMode }, storeViewMode viewModeString )

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
                                , government = withCode 5 .government Government.description
                                , lawLevel = withCode 6 .lawLevel LawLevel.description
                                , techLevel = withCode 8 .techLevel TechLevel.description
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
