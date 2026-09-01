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
import FormatNumber exposing (format)
import FormatNumber.Locales exposing (Decimals(..), usLocale)
import Html exposing (Html)
import Html.Attributes as HtmlAttrs
import Html.Events
import Html.Lazy
import Parser
import Traveller.Atmosphere as Atmosphere
import Traveller.Government as Government
import Traveller.HexAddress as HexAddress exposing (HexAddress)
import Traveller.LawLevel as LawLevel
import Traveller.Parser exposing (UWP, uwp)
import Traveller.Population as Population
import Traveller.Sector exposing (SectorDict)
import Traveller.StarSystemDetail exposing (BaseFacility, MainWorldProfile, StarSystemDetail)
import Traveller.StarSystemMap exposing (viewStarSystemMap)
import Traveller.StellarObject exposing (StellarObject)
import Traveller.StellarObjectView exposing (StellarObjectMsgs)
import Traveller.TechLevel as TechLevel
import Traveller.ToggleSwitch as ToggleSwitch
import Traveller.TravelCalculations as TravelCalc



-- ── HTML LAYOUT HELPERS ──────────────────────────────────────────────────────
--
-- Small elm-ui-flavoured wrappers kept local to this module rather than
-- shared via Traveller.UI, which is still elm-ui and used by other
-- not-yet-converted modules (StellarObjectView, ShipTraffic, TravelTable).
-- Named to match their elm-ui counterparts so the view code below reads
-- close to its previous shape. See Traveller/AnalysisDetail.elm for the
-- precedent this mirrors.


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


{-| Centers a flex item along its parent's cross axis — matches elm-ui's
`centerX`/`centerY`, which position an element relative to its own parent
rather than aligning that element's children.
-}
centerX : Html.Attribute msg
centerX =
    HtmlAttrs.style "align-self" "center"


centerY : Html.Attribute msg
centerY =
    HtmlAttrs.style "align-self" "center"


pointerCursor : Html.Attribute msg
pointerCursor =
    HtmlAttrs.style "cursor" "pointer"


scrollY : Html.Attribute msg
scrollY =
    HtmlAttrs.style "overflow-y" "auto"


{-| Aligns a flex item to the start of its parent's cross axis (e.g. the top
of a `row`), so a wrapping value doesn't get vertically centered against a
single-line label.
-}
alignTop : Html.Attribute msg
alignTop =
    HtmlAttrs.style "align-self" "flex-start"


{-| Reserves exactly this many pixels in a flex row and never grows or
shrinks — for a fixed-width label sitting next to a wrapping value.
-}
fixedFlex : Int -> Html.Attribute msg
fixedFlex n =
    HtmlAttrs.style "flex" ("0 0 " ++ px n)


{-| Grows to fill the remaining space in a flex row, alongside `shrinkable`
so long text can still wrap instead of overflowing (flex items default to a
content-based minimum size that ignores `width`).
-}
growFlex : Html.Attribute msg
growFlex =
    HtmlAttrs.style "flex" "1 1 0%"


shrinkable : Html.Attribute msg
shrinkable =
    HtmlAttrs.style "min-width" "0"


fontSize : Int -> Html.Attribute msg
fontSize n =
    HtmlAttrs.style "font-size" (px n)


bold : Html.Attribute msg
bold =
    HtmlAttrs.class "font-bold"


{-| A CSS custom-property-backed attribute, e.g. `fontVar "--color-fg"`, so
the value can react to the Rails `data-theme` attribute at runtime.
-}
fontVar : String -> Html.Attribute msg
fontVar varName =
    HtmlAttrs.style "color" ("var(" ++ varName ++ ")")


{-| Colour for section headings and other accent text. Matches Rails'
`.dg-subsection .label`.
-}
accentHeadingColour : Html.Attribute msg
accentHeadingColour =
    fontVar "--color-highlight"


profileFieldDisplay : String -> String -> Html msg
profileFieldDisplay lbl val =
    profileFieldDisplayAttrs lbl val []


{-| Like `profileFieldDisplay`, but with extra attributes on the value —
e.g. a `title` tooltip for a field with no dedicated help page to explain it.
-}
profileFieldDisplayAttrs : String -> String -> List (Html.Attribute msg) -> Html msg
profileFieldDisplayAttrs lbl val extraAttrs =
    row [ width fill, paddingEach { zeroEach | top = 3 } ]
        [ el [ fixedFlex 80, fontVar "--color-fg-muted", fontSize 11, bold, alignTop ] (text lbl)
        , Html.p ([ HtmlAttrs.style "margin" "0", growFlex, shrinkable, fontSize 12, alignTop, fontVar "--color-fg-bright" ] ++ extraAttrs) [ text val ]
        ]


{-| Like `profileFieldDisplay`, but the value is an external link.
-}
profileFieldLinkDisplay : String -> String -> String -> Html msg
profileFieldLinkDisplay lbl linkText url =
    row [ width fill, paddingEach { zeroEach | top = 3 } ]
        [ el [ fixedFlex 80, fontVar "--color-fg-muted", fontSize 11, bold, alignTop ] (text lbl)
        , Html.a
            [ HtmlAttrs.href url
            , HtmlAttrs.target "_blank"
            , HtmlAttrs.rel "noopener"
            , HtmlAttrs.style "margin" "0"
            , growFlex
            , shrinkable
            , fontSize 12
            , alignTop
            , fontVar "--color-fg-bright"
            ]
            [ text linkText ]
        ]



-- ── SIDEBAR ──────────────────────────────────────────────────────────────────


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
    , openCommerce : msg
    , setKnown : Bool -> msg
    , setSurveyIndex : Int -> msg
    }


{-| Render a FontAwesome icon.
-}
renderFAIcon : String -> Int -> Html msg
renderFAIcon icon size =
    Html.i [ HtmlAttrs.class icon, HtmlAttrs.style "font-size" (px size) ] []


{-| A pill-shaped call-to-action button used in the sidebar (e.g. Travel Times, Ship Traffic).
-}
viewSidebarButton : { active : Bool, icon : String, label : String, onClick : msg } -> Html msg
viewSidebarButton { active, icon, label, onClick } =
    el
        [ paddingXY 12 6
        , HtmlAttrs.style "border-radius" (px 6)
        , HtmlAttrs.style "border-style" "solid"
        , HtmlAttrs.style "border-width" "1px"
        , HtmlAttrs.style "border-color"
            (if active then
                "var(--color-button-primary)"

             else
                "color-mix(in srgb, var(--color-outline) 35%, transparent)"
            )
        , HtmlAttrs.style "background-color"
            (if active then
                "var(--color-button-primary)"

             else
                "color-mix(in srgb, var(--color-outline) 10%, transparent)"
            )
        , HtmlAttrs.class "starmap-sidebar-btn"
        , pointerCursor
        , HtmlAttrs.style "transition" "background-color 0.15s ease, border-color 0.15s ease"
        , fontSize 13
        , HtmlAttrs.style "color"
            (if active then
                "var(--color-fg-bright)"

             else
                "var(--color-fg-muted)"
            )
        , Html.Events.onClick onClick
        ]
        (row [ spacing 6, centerY ]
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
viewMainWorldProfile : MainWorldProfile -> Html msg
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

        noPopulation =
            Population.isNoneCode (uwpChar 4)

        noGovernment =
            noPopulation && Population.isNoneCode (uwpChar 5)

        noLawLevel =
            noPopulation && Population.isNoneCode (uwpChar 6)

        noTechLevel =
            noPopulation && Population.isNoneCode (uwpChar 8)

        populationStr =
            case profile.censusPopulation of
                Just census ->
                    uwpChar 4 ++ " – " ++ format { usLocale | decimals = Exact 0, thousandSeparator = " " } (toFloat census)

                Nothing ->
                    withUwp 4 .population Population.populationDescription

        spCode =
            uwpChar 0

        spQuality =
            case spCode of
                "A" ->
                    "Excellent"

                "B" ->
                    "Good"

                "C" ->
                    "Routine"

                "D" ->
                    "Poor"

                "E" ->
                    "Frontier"

                _ ->
                    "None"

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

        creditsStr =
            Maybe.map (\v -> "Cr" ++ String.fromInt v) >> Maybe.withDefault "—"

        fuelFigure =
            Maybe.map (\v -> "Cr" ++ String.fromInt v) >> Maybe.withDefault "—"

        fuelCostStr =
            -- Unlabelled, refined first then unrefined — see the Fuel Cost help entry.
            -- A missing grade shows as a dash in its own position rather than being
            -- dropped, so a single remaining figure can't be misread as the other grade.
            if profile.refinedFuelCost == Nothing && profile.unrefinedFuelCost == Nothing then
                "—"

            else
                fuelFigure profile.refinedFuelCost ++ " · " ++ fuelFigure profile.unrefinedFuelCost

        fuelCostTooltip =
            if profile.refinedFuelCost == Nothing && profile.unrefinedFuelCost /= Nothing then
                "unrefined fuel only"

            else
                "refined · unrefined"

        profileHeader title =
            row
                [ width fill
                , spacing 8
                , paddingEach { zeroEach | top = 8, bottom = 4 }
                ]
                [ el [ accentHeadingColour, fontSize 10, bold ] (text (String.toUpper title))
                , el
                    [ width fill
                    , height (px 1)
                    , HtmlAttrs.style "background-color" "var(--color-outline)"
                    , centerY
                    ]
                    none
                ]
    in
    column
        [ width fill
        , paddingXY 8 4
        ]
        [ profileHeader "Main World Profile"
        , profileFieldDisplay "Starport" (spCode ++ " – " ++ spQuality)
        , profileFieldDisplay "Berthing Cost" (creditsStr profile.berthingCost)
        , profileFieldDisplayAttrs "Fuel Cost"
            fuelCostStr
            [ HtmlAttrs.title fuelCostTooltip
            , HtmlAttrs.style "cursor" "help"
            ]
        , profileFieldDisplay "Gravity" gravityStr
        , profileFieldDisplay "Temperature" tempStr
        , profileFieldDisplay "Survival" profile.survivalRequirement
        , profileFieldDisplay "Atmosphere" (withUwp 2 .atmosphere Atmosphere.atmosphereDescription)
        , profileFieldDisplay "Population" populationStr
        , profileFieldDisplay "Government"
            (if noGovernment then
                "—"

             else
                withUwp 5 .government Government.description
            )
        , profileFieldDisplay "Law Level"
            (if noLawLevel then
                "—"

             else
                withUwp 6 .lawLevel LawLevel.description
            )
        , profileFieldDisplay "Tech Level"
            (if noTechLevel then
                "—"

             else
                withUwp 8 .techLevel TechLevel.description
            )
        , profileFieldDisplay "Sophonts" sophontStr
        ]


viewSidebarJumpTable : Maybe Float -> Html msg
viewSidebarJumpTable maybeKm =
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
                            ([ growFlex
                             , paddingXY 0 3
                             , HtmlAttrs.style "text-align" "center"
                             , HtmlAttrs.style "white-space" "nowrap"
                             ]
                                ++ attrs
                            )
                            child

                    headerCell m =
                        cell
                            [ fontVar "--color-fg"
                            , fontSize 10
                            , bold
                            , HtmlAttrs.style "border-bottom" "1px solid var(--color-outline)"
                            ]
                            (text ("M" ++ String.fromInt m))

                    timeCell m =
                        let
                            secs =
                                TravelCalc.travelTimeInSeconds km m

                            t =
                                TravelCalc.travelTimeHoursDays secs
                        in
                        cell [ fontSize 11, HtmlAttrs.class "font-mono" ]
                            (text t)

                    sectionRow title =
                        row
                            [ width fill
                            , spacing 8
                            , paddingEach { zeroEach | top = 6, bottom = 2 }
                            ]
                            [ el [ accentHeadingColour, fontSize 10, bold ] (text (String.toUpper title))
                            , el
                                [ width fill
                                , height (px 1)
                                , HtmlAttrs.style "background-color" "var(--color-outline)"
                                , centerY
                                ]
                                none
                            ]
                in
                column
                    [ width fill
                    , paddingXY 8 4
                    , HtmlAttrs.style "border-bottom" "1px solid var(--color-outline)"
                    ]
                    [ sectionRow "Safe Jump Distance"
                    , row [ width fill ] (List.map headerCell mDrives)
                    , row [ width fill ] (List.map timeCell mDrives)
                    ]


{-| Referee-editable known/survey-index controls, or a read-only survey index for players.

Rendered unconditionally (unlike the rest of the system details) so players can see survey
progress even on systems that aren't otherwise visible yet. Built as a single raw `Html` tree
so it matches the Rails "Survey Index"/"Known" fields pixel-for-pixel
(`app/views/star_systems/_star_system.html.erb`, `app/views/star_systems/_known_toggle.html.erb`).

-}
viewSurveyControls : SidebarMsgs msg -> Bool -> StarSystemDetail -> Html msg
viewSurveyControls msgs isReferee starSystemDetail =
    if isReferee then
        Html.div [ HtmlAttrs.class "flex items-start gap-6 px-2 py-1" ]
            [ Html.div [ HtmlAttrs.class "min-w-0" ]
                [ Html.div [ HtmlAttrs.class "text-xs uppercase tracking-[0.22em] text-fg-muted" ] [ Html.text "Survey Index" ]
                , Html.div [ HtmlAttrs.class "mt-2 text-fg-bright" ]
                    [ Html.select
                        [ HtmlAttrs.class "edit-base w-20 text-xs py-1 leading-normal"
                        , Html.Events.onInput
                            (\str -> msgs.setSurveyIndex (String.toInt str |> Maybe.withDefault starSystemDetail.actualSurveyIndex))
                        ]
                        (List.range 0 12
                            |> List.map
                                (\i ->
                                    Html.option
                                        [ HtmlAttrs.value (String.fromInt i)
                                        , HtmlAttrs.selected (i == starSystemDetail.actualSurveyIndex)
                                        ]
                                        [ Html.text (String.fromInt i) ]
                                )
                        )
                    ]
                ]
            , Html.div [ HtmlAttrs.class "min-w-0" ]
                [ Html.div [ HtmlAttrs.class "text-xs uppercase tracking-[0.22em] text-fg-muted" ] [ Html.text "Known" ]
                , Html.div [ HtmlAttrs.class "mt-2 flex items-center gap-3" ]
                    [ ToggleSwitch.view ToggleSwitch.Regular starSystemDetail.known (Html.Events.onClick (msgs.setKnown (not starSystemDetail.known)))
                    ]
                ]
            ]

    else
        el [ width fill, paddingXY 8 4 ] (profileFieldDisplay "Survey Index" (String.fromInt starSystemDetail.actualSurveyIndex))


{-| Render the list of bases present in a system, each with its facility icon (if configured) and name.
-}
viewBasesList : List BaseFacility -> Html msg
viewBasesList bases =
    if List.isEmpty bases then
        none

    else
        column [ width fill, paddingXY 8 4, spacing 4 ]
            (row [ accentHeadingColour, fontSize 10, bold ] [ text "BASES" ]
                :: List.map viewBaseRow bases
            )


viewBaseRow : BaseFacility -> Html msg
viewBaseRow base =
    row [ width fill, spacing 6, fontSize 12 ]
        [ case base.iconClass of
            Just iconClass ->
                renderFAIcon iconClass 12

            Nothing ->
                none
        , text base.name
        ]


{-| View the system details in the sidebar.
-}
viewSystemDetailsSidebar :
    SidebarMsgs msg
    -> StarSystemDetail
    -> { isReferee : Bool, mDrive : Maybe Int, showTravelTable : Bool }
    -> Html msg
viewSystemDetailsSidebar msgs starSystemDetail opts =
    let
        stellarObjectMsgs : StellarObjectMsgs msg
        stellarObjectMsgs =
            { onViewDetail = msgs.viewDetail
            }
    in
    column [ width fill, spacing 6 ]
        [ viewSurveyControls msgs opts.isReferee starSystemDetail
        , if opts.isReferee || starSystemDetail.known || starSystemDetail.surveyIndex >= 10 then
            column [ width fill ]
                [ viewBasesList starSystemDetail.bases
                , case starSystemDetail.referenceUrl of
                    Just url ->
                        column [ width fill, paddingXY 8 4 ]
                            [ profileFieldLinkDisplay "Library Data" "Reference" url ]

                    Nothing ->
                        none
                , case starSystemDetail.mainWorldProfile of
                    Just profile ->
                        column [ width fill ]
                            [ viewMainWorldProfile profile
                            , if List.isEmpty starSystemDetail.tradeCodes then
                                none

                              else
                                column [ width fill, paddingXY 8 4 ]
                                    [ profileFieldDisplay "Trade Codes" (String.join " " starSystemDetail.tradeCodes) ]
                            , viewSidebarJumpTable profile.jumpShadow
                            ]

                    Nothing ->
                        none
                ]

          else
            none
        , viewStarSystemMap stellarObjectMsgs starSystemDetail opts.isReferee opts.mDrive
        , row [ centerX, spacing 8, paddingXY 0 4 ]
            [ viewSidebarButton
                { active = opts.showTravelTable
                , icon = "fa-solid fa-gauge-high"
                , label = "Travel Times"
                , onClick = msgs.toggleTravelTable
                }
            ]
        ]


{-| View the main sidebar column.

The `starSystemStatus` field should contain a status message for the selected hex,
or Nothing if there's no status to display.

The `isHexMapMode` and `isFullJourneyMode` fields indicate which view mode is active.

-}
viewSidebarColumn :
    SidebarMsgs msg
    ->
        { a
            | selectedHex : Maybe HexAddress
            , starSystemStatus : Maybe String
            , sectors : SectorDict
            , regions : Dict.Dict k { b | hexes : List HexAddress, name : String, colour : Maybe Color }
            , selectedSystem : Maybe StarSystemDetail
            , isReferee : Bool
            , allSectorsMapUrl : Maybe String
            , mDrive : Maybe Int
            , showTravelTable : Bool
            , rogueContent : Maybe (Html msg)
        }
    -> Html msg
viewSidebarColumn msgs { selectedHex, starSystemStatus, sectors, regions, selectedSystem, isReferee, allSectorsMapUrl, mDrive, showTravelTable, rogueContent } =
    column [ width fill, spacing 4, centerX, height fill, HtmlAttrs.style "position" "relative" ]
        [ el
            [ HtmlAttrs.style "position" "absolute"
            , HtmlAttrs.style "top" "48px"
            , HtmlAttrs.style "right" "8px"
            , Html.Events.onClick msgs.closeSidebar
            , pointerCursor
            , fontSize 14
            , fontVar "--color-fg-muted"
            ]
            (text "✕")
        , column [ width fill, height fill, scrollY, paddingEach { zeroEach | top = 48 } ]
            [ case selectedHex of
                Just viewingAddress ->
                    column [ paddingXY 0 4, width fill, centerX ]
                        [ case starSystemStatus of
                            Just status ->
                                el [ centerX, HtmlAttrs.class "status-scan" ] (text status)

                            Nothing ->
                                none
                        , column [ centerX, spacing 2 ]
                            [ case
                                selectedSystem
                                    |> Maybe.andThen
                                        (\sys ->
                                            if isReferee || sys.surveyIndex >= 10 then
                                                sys.name

                                            else
                                                Nothing
                                        )
                              of
                                Just sysName ->
                                    column [ centerX, spacing 2 ]
                                        [ el [ centerX, accentHeadingColour, fontSize 18, bold ] (text sysName)
                                        , el [ centerX, fontSize 12, fontVar "--color-fg-muted" ] (text <| universalHexLabel sectors viewingAddress)
                                        ]

                                Nothing ->
                                    el [ centerX, accentHeadingColour, fontSize 18, bold ] (text <| universalHexLabel sectors viewingAddress)
                            , case selectedSystem of
                                Just sys ->
                                    if isReferee || sys.surveyIndex >= 10 then
                                        case sys.mainWorldProfile |> Maybe.map .uwp of
                                            Just uwpStr ->
                                                el [ centerX, fontSize 12, fontVar "--color-fg" ] (text uwpStr)

                                            Nothing ->
                                                none

                                    else
                                        none

                                Nothing ->
                                    none
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
                                                el [ centerX, fontSize 12, fontVar "--color-fg-bright" ] (text label)

                                            Nothing ->
                                                none

                                    else
                                        none

                                Nothing ->
                                    none
                            , case selectedSystem of
                                Just sys ->
                                    if isReferee && sys.mainWorldProfile /= Nothing then
                                        row
                                            [ centerX
                                            , spacing 8
                                            , paddingEach { zeroEach | top = 8 }
                                            ]
                                            [ viewSidebarButton
                                                { active = False
                                                , icon = "fa-solid fa-rocket"
                                                , label = "Ship Traffic"
                                                , onClick = msgs.openShipTraffic
                                                }
                                            , viewSidebarButton
                                                { active = False
                                                , icon = "fa-solid fa-cart-shopping"
                                                , label = "Commerce"
                                                , onClick = msgs.openCommerce
                                                }
                                            ]

                                    else
                                        none

                                Nothing ->
                                    none
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
                                                    Just aName ->
                                                        region.name == aName

                                                    Nothing ->
                                                        False
                                        in
                                        if List.member viewingAddress region.hexes && not isAllegianceRegion then
                                            let
                                                colourAttrs =
                                                    case region.colour of
                                                        Just colour ->
                                                            [ HtmlAttrs.style "color" (Color.toCssString colour) ]

                                                        Nothing ->
                                                            []
                                            in
                                            text region.name
                                                |> el (fontSize 12 :: centerX :: colourAttrs)
                                                |> Just

                                        else
                                            Nothing
                                    )
                                |> column [ centerX ]
                            ]
                        ]

                Nothing ->
                    column [ centerX, fontSize 10 ]
                        [ text "Select hex in console to view parsec details."
                        ]
            , case selectedSystem of
                Just starSystemDetail ->
                    Html.Lazy.lazy3 viewSystemDetailsSidebar
                        msgs
                        starSystemDetail
                        { isReferee = isReferee
                        , mDrive = mDrive
                        , showTravelTable = showTravelTable
                        }

                Nothing ->
                    case rogueContent of
                        Just content ->
                            content

                        Nothing ->
                            column [ centerX, fontSize 10 ]
                                [ text "Click a hex to view system details."
                                ]
            ]
        , Html.Lazy.lazy viewSidebarFooter selectedHex
        ]


viewSidebarFooter : Maybe HexAddress -> Html msg
viewSidebarFooter _ =
    none
