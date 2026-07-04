module Traveller.Sidebar exposing
    ( SidebarMsgs
    , sidebarWidth
    , viewSidebarColumn
    , viewSidebarFooter
    , viewSystemDetailsSidebar
    )

{-| Sidebar view components for the Traveller application.
-}

import Color exposing (Color)
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
import Element.Border as Border
import Element.Events as Events
import Element.Font as Font
import Element.Lazy
import Html
import Html.Attributes as HtmlAttrs
import Parser
import Traveller.Atmosphere as Atmosphere
import Traveller.TravelCalculations as TravelCalc
import Traveller.Government as Government
import Traveller.HexAddress as HexAddress exposing (HexAddress)
import Traveller.LawLevel as LawLevel
import Traveller.Parser exposing (UWP, uwp)
import Traveller.Population as Population
import Traveller.Sector exposing (SectorDict)
import Traveller.SolarSystem exposing (BaseFacility, MainWorldProfile, SolarSystem)
import Traveller.StellarObject exposing (StellarObject)
import Traveller.StarSystemMap exposing (viewStarSystemMap)
import Traveller.StellarObjectView
    exposing
        ( StellarObjectMsgs
        , convertColor
        )
import Traveller.TechLevel as TechLevel
import Traveller.UI
    exposing
        ( fontVar
        , profileFieldDisplay
        , uiDeepnightColorFontColour
        , zeroEach
        )


{-| Width of the sidebar in pixels.
-}
sidebarWidth : number
sidebarWidth =
    320


{-| Message constructors needed by sidebar view functions.
-}
type alias SidebarMsgs msg =
    { viewDetail : StellarObject -> msg
    , closeSidebar : msg
    , toggleTravelTable : msg
    , openShipTraffic : msg
    }


{-| Render a FontAwesome icon.
-}
renderFAIcon : String -> Int -> Element msg
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


{-| A pill-shaped call-to-action button used in the sidebar (e.g. Travel Times, Ship Traffic).
-}
viewSidebarButton : { active : Bool, icon : String, label : String, onClick : msg } -> Element msg
viewSidebarButton { active, icon, label, onClick } =
    el
        [ Element.paddingXY 12 6
        , Border.rounded 6
        , Border.width 1
        , Element.htmlAttribute
            (HtmlAttrs.style "border-color"
                (if active then
                    "var(--color-button-primary)"

                 else
                    "color-mix(in srgb, var(--color-outline) 35%, transparent)"
                )
            )
        , Element.htmlAttribute
            (HtmlAttrs.style "background-color"
                (if active then
                    "var(--color-button-primary)"

                 else
                    "color-mix(in srgb, var(--color-outline) 10%, transparent)"
                )
            )
        , Element.htmlAttribute (HtmlAttrs.class "starmap-sidebar-btn")
        , Element.htmlAttribute <| HtmlAttrs.style "cursor" "pointer"
        , Element.htmlAttribute <| HtmlAttrs.style "transition" "background-color 0.15s ease, border-color 0.15s ease"
        , Font.size 13
        , Element.htmlAttribute
            (HtmlAttrs.style "color"
                (if active then
                    "#fff"

                 else
                    "var(--color-fg-muted)"
                )
            )
        , Events.onClick onClick
        ]
        (row [ Element.spacing 6, Element.centerY ]
            [ renderFAIcon icon 13
            , text label
            ]
        )


{-| Get the universal hex label from sectors dictionary.
-}
universalHexLabel : SectorDict -> HexAddress -> String
universalHexLabel sectors hexAddress =
    case Dict.get (HexAddress.toSectorKey <| HexAddress.toSectorAddress hexAddress) sectors of
        Nothing ->
            " "

        Just sector ->
            sector.name ++ " " ++ HexAddress.hexLabel hexAddress


{-| Renders the main world profile block above the star system map.
-}
viewMainWorldProfile : MainWorldProfile -> Element msg
viewMainWorldProfile profile =
    let
        mParsed =
            Parser.run uwp profile.uwp

        uwpChar i =
            String.slice i (i + 1) profile.uwp

        withUwp i accessor describer =
            case mParsed of
                Ok parsed ->
                    uwpChar i ++ " – " ++ describer (accessor parsed)

                Err _ ->
                    "—"

        spCode =
            uwpChar 0

        spQuality =
            case spCode of
                "A" -> "Excellent"
                "B" -> "Good"
                "C" -> "Routine"
                "D" -> "Poor"
                "E" -> "Frontier"
                _ -> "None"

        gravityStr =
            profile.gravity
                |> Maybe.map (\g -> String.fromFloat (toFloat (round (g * 100)) / 100) ++ "g")
                |> Maybe.withDefault "—"

        tempStr =
            profile.temperature
                |> Maybe.map (\t -> String.fromInt (round (t - 273.15)) ++ "°C")
                |> Maybe.withDefault "—"

        sophontStr =
            if profile.nativeSophont then
                "Extant"

            else if profile.extinctSophont then
                "Extinct"

            else
                "None"

        profileHeader title =
            row
                [ width fill
                , Element.spacing 8
                , Element.paddingEach { zeroEach | top = 8, bottom = 4 }
                ]
                [ el [ uiDeepnightColorFontColour, Font.size 10, Font.bold ] (text (String.toUpper title))
                , el
                    [ width fill
                    , height (Element.px 1)
                    , Element.htmlAttribute (HtmlAttrs.style "background-color" "color-mix(in srgb, var(--color-outline) 30%, transparent)")
                    , Element.centerY
                    ]
                    Element.none
                ]
    in
    column
        [ width fill
        , Element.paddingXY 8 4
        ]
        [ profileHeader "Main World Profile"
        , profileFieldDisplay "Starport" (spCode ++ " – " ++ spQuality)
        , profileFieldDisplay "Gravity" gravityStr
        , profileFieldDisplay "Temperature" tempStr
        , profileFieldDisplay "Survival" profile.survivalRequirement
        , profileFieldDisplay "Atmosphere" (withUwp 2 .atmosphere Atmosphere.atmosphereDescription)
        , profileFieldDisplay "Population" (withUwp 4 .population Population.populationDescription)
        , profileFieldDisplay "Government" (withUwp 5 .government Government.description)
        , profileFieldDisplay "Law Level" (withUwp 6 .lawLevel LawLevel.description)
        , profileFieldDisplay "Tech Level" (withUwp 8 .techLevel TechLevel.description)
        , profileFieldDisplay "Sophonts" sophontStr
        ]


viewSidebarJumpTable : Maybe Float -> Element msg
viewSidebarJumpTable maybeKm =
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
                        el ([ width fill, Element.paddingXY 0 3, Element.centerX ] ++ attrs) child

                    headerCell m =
                        cell
                            [ uiDeepnightColorFontColour
                            , Font.size 10
                            , Font.bold
                            , Border.widthEach { zeroEach | bottom = 1 }
                            , Element.htmlAttribute (HtmlAttrs.style "border-color" "color-mix(in srgb, var(--color-outline) 15%, transparent)")
                            ]
                            (el [ Element.centerX ] (text ("M" ++ String.fromInt m)))

                    timeCell m =
                        let
                            secs =
                                TravelCalc.travelTimeInSeconds km m

                            t =
                                TravelCalc.travelTimeHoursDays secs
                        in
                        cell [ Font.size 11, Font.family [ Font.monospace ] ]
                            (el [ Element.centerX ] (text t))

                    sectionRow title =
                        row
                            [ width fill
                            , Element.spacing 8
                            , Element.paddingEach { zeroEach | top = 6, bottom = 2 }
                            ]
                            [ el [ uiDeepnightColorFontColour, Font.size 10, Font.bold ] (text (String.toUpper title))
                            , el
                                [ width fill
                                , height (Element.px 1)
                                , Element.htmlAttribute (HtmlAttrs.style "background-color" "color-mix(in srgb, var(--color-outline) 30%, transparent)")
                                , Element.centerY
                                ]
                                Element.none
                            ]
                in
                column
                    [ width fill
                    , Element.paddingXY 8 4
                    , Border.widthEach { zeroEach | bottom = 1 }
                    , Element.htmlAttribute (HtmlAttrs.style "border-color" "color-mix(in srgb, var(--color-outline) 15%, transparent)")
                    ]
                    [ sectionRow "Safe Jump Distance"
                    , row [ width fill ] (List.map headerCell mDrives)
                    , row [ width fill ] (List.map timeCell mDrives)
                    ]


{-| Render the list of bases present in a system, each with its facility icon (if configured) and name.
-}
viewBasesList : List BaseFacility -> Element msg
viewBasesList bases =
    if List.isEmpty bases then
        Element.none

    else
        column [ width fill, Element.paddingXY 8 4, Element.spacing 4 ]
            (row [ uiDeepnightColorFontColour, Font.size 10, Font.bold ] [ text "BASES" ]
                :: List.map viewBaseRow bases
            )


viewBaseRow : BaseFacility -> Element msg
viewBaseRow base =
    row [ width fill, Element.spacing 6, Font.size 12 ]
        [ case base.iconClass of
            Just iconClass ->
                renderFAIcon iconClass 12

            Nothing ->
                Element.none
        , text base.name
        ]


{-| View the system details in the sidebar.
-}
viewSystemDetailsSidebar :
    SidebarMsgs msg
    -> SolarSystem
    -> { isReferee : Bool, mDrive : Maybe Int, showTravelTable : Bool }
    -> Element msg
viewSystemDetailsSidebar msgs solarSystem opts =
    let
        stellarObjectMsgs : StellarObjectMsgs msg
        stellarObjectMsgs =
            { onViewDetail = msgs.viewDetail
            }
    in
    column [ Element.width Element.fill, Element.spacing 6 ]
        [ if opts.isReferee || solarSystem.known || solarSystem.surveyIndex >= 10 then
            column [ width fill ]
                [ viewBasesList solarSystem.bases
                , case solarSystem.mainWorldProfile of
                    Just profile ->
                        column [ width fill ]
                            [ viewMainWorldProfile profile
                            , if List.isEmpty solarSystem.tradeCodes then
                                Element.none

                              else
                                column [ width fill, Element.paddingXY 8 4 ]
                                    [ profileFieldDisplay "Trade Codes" (String.join " " solarSystem.tradeCodes) ]
                            , viewSidebarJumpTable profile.jumpShadow
                            ]

                    Nothing ->
                        Element.none
                ]

          else
            Element.none
        , viewStarSystemMap stellarObjectMsgs solarSystem opts.isReferee opts.mDrive
        , el [ centerX, Element.paddingXY 0 4 ]
            (viewSidebarButton
                { active = opts.showTravelTable
                , icon = "fa-solid fa-gauge-high"
                , label = "Travel Times"
                , onClick = msgs.toggleTravelTable
                }
            )
        ]


{-| View the main sidebar column.

The `solarSystemStatus` field should contain a status message for the selected hex,
or Nothing if there's no status to display.

The `isHexMapMode` and `isFullJourneyMode` fields indicate which view mode is active.

-}
viewSidebarColumn :
    SidebarMsgs msg
    ->
        { a
            | selectedHex : Maybe HexAddress
            , solarSystemStatus : Maybe String
            , sectors : SectorDict
            , regions : Dict.Dict k { b | hexes : List HexAddress, name : String, colour : Color }
            , selectedSystem : Maybe SolarSystem
            , isReferee : Bool
            , allSectorsMapUrl : Maybe String
            , mDrive : Maybe Int
            , showTravelTable : Bool
            , rogueContent : Maybe (Element msg)
        }
    -> Element msg
viewSidebarColumn msgs { selectedHex, solarSystemStatus, sectors, regions, selectedSystem, isReferee, allSectorsMapUrl, mDrive, showTravelTable, rogueContent } =
    column [ Element.spacing 4, Element.centerX, Element.height Element.fill ]
        [ row [ Element.width Element.fill, Element.paddingXY 8 6 ]
            [ el
                [ Element.alignRight
                , Events.onClick msgs.closeSidebar
                , Element.htmlAttribute <| HtmlAttrs.style "cursor" "pointer"
                , Font.size 14
                , fontVar "--color-fg-muted"
                ]
                (text "✕")
            ]
        , column [ Element.width Element.fill, Element.height Element.fill, Element.scrollbarY ]
            [ case selectedHex of
                Just viewingAddress ->
                    column [ Element.paddingXY 0 4, width fill, centerX ]
                        [ case solarSystemStatus of
                            Just status ->
                                el [ centerX, Element.htmlAttribute <| HtmlAttrs.class "status-scan" ] (text status)

                            Nothing ->
                                Element.none
                        , column [ centerX, Element.spacing 2 ]
                            [ case selectedSystem |> Maybe.andThen (\sys -> if isReferee || sys.surveyIndex >= 10 then sys.name else Nothing) of
                                Just sysName ->
                                    column [ centerX, Element.spacing 2 ]
                                        [ el [ centerX, uiDeepnightColorFontColour, Font.size 18, Font.bold ] (text sysName)
                                        , el [ centerX, Font.size 12, fontVar "--color-fg-muted" ] (text <| universalHexLabel sectors viewingAddress)
                                        ]

                                Nothing ->
                                    el [ centerX, uiDeepnightColorFontColour, Font.size 18, Font.bold ] (text <| universalHexLabel sectors viewingAddress)
                            , case selectedSystem of
                                Just sys ->
                                    if isReferee || sys.surveyIndex >= 10 then
                                        case sys.mainWorldProfile |> Maybe.map .uwp of
                                            Just uwpStr ->
                                                el [ centerX, Font.size 12, fontVar "--color-fg" ] (text uwpStr)

                                            Nothing ->
                                                Element.none

                                    else
                                        Element.none

                                Nothing ->
                                    Element.none
                            , case selectedSystem of
                                Just sys ->
                                    if isReferee || sys.surveyIndex >= 10 then
                                        case sys.allegiance of
                                            Just code ->
                                                let
                                                    label =
                                                        case sys.allegianceName of
                                                            Just aName ->
                                                                aName ++ " (" ++ code ++ ")"

                                                            Nothing ->
                                                                code
                                                in
                                                el [ centerX, Font.size 12, fontVar "--color-fg-bright" ] (text label)

                                            Nothing ->
                                                Element.none

                                    else
                                        Element.none

                                Nothing ->
                                    Element.none
                            , case selectedSystem of
                                Just sys ->
                                    if isReferee && sys.mainWorldProfile /= Nothing then
                                        el
                                            [ centerX
                                            , Element.paddingEach { zeroEach | top = 8 }
                                            ]
                                            (viewSidebarButton
                                                { active = False
                                                , icon = "fa-solid fa-rocket"
                                                , label = "Ship Traffic"
                                                , onClick = msgs.openShipTraffic
                                                }
                                            )

                                    else
                                        Element.none

                                Nothing ->
                                    Element.none
                            , let
                                allegianceName =
                                    selectedSystem |> Maybe.andThen .allegianceName
                              in
                              regions
                                |> Dict.values
                                |> List.filterMap
                                    (\region ->
                                        let
                                            isAllegianceRegion =
                                                case allegianceName of
                                                    Just aName -> region.name == aName
                                                    Nothing -> False
                                        in
                                        if List.member viewingAddress region.hexes && not isAllegianceRegion then
                                            text region.name
                                                |> el [ Font.size 12, Font.color <| convertColor region.colour, centerX ]
                                                |> Just

                                        else
                                            Nothing
                                    )
                                |> column [ centerX ]
                            ]
                        ]

                Nothing ->
                    column [ centerX, Font.size 10 ]
                        [ text "Select hex in console to view parsec details."
                        ]
            , case selectedSystem of
                Just solarSystem ->
                    Element.Lazy.lazy3 viewSystemDetailsSidebar
                        msgs
                        solarSystem
                        { isReferee = isReferee
                        , mDrive = mDrive
                        , showTravelTable = showTravelTable
                        }

                Nothing ->
                    case rogueContent of
                        Just content ->
                            content

                        Nothing ->
                            column [ centerX, Font.size 10 ]
                                [ text "Click a hex to view system details."
                                ]
            ]
        , Element.Lazy.lazy viewSidebarFooter selectedHex
        ]


viewSidebarFooter : Maybe HexAddress -> Element msg
viewSidebarFooter _ =
    Element.none
