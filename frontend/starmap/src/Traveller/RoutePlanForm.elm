module Traveller.RoutePlanForm exposing (Config, Model, Msg(..), init, update, view)

{-| A self-contained route-planning modal: pick a from/to system, a jump
range, a refuelling filter and any excluded travel zones, plan the route
against `Api::RoutePlansController#plan`, and (referees only) save the result
as a plotted `JumpRoute` via `Api::RoutePlansController#save`.

Unlike `Traveller.HighlightRuleEditor` (which is pure, since it only edits a
draft the parent later merges), this module owns three HTTP round trips
itself (two system searches and the plan/save requests), so `update` returns
a `Cmd Msg` and the parent wires it in with `Cmd.map`.

-}

import Browser.Dom
import HostConfig exposing (HostConfig)
import Html exposing (Html)
import Html.Attributes as HtmlAttrs
import Html.Events as HtmlEvents
import Http
import Json.Decode as JsDecode
import RemoteData exposing (RemoteData(..))
import Set exposing (Set)
import Task
import Traveller.RoutePlan as RoutePlan
    exposing
        ( RoutePlanEndpoint
        , RoutePlanResult
        , RoutePlanSystemResult
        , TravelZoneOption
        )
import Traveller.TravelCalculations as TravelCalc
import Url.Builder


{-| DOM id of the "From" input, focused when the modal opens.
-}
fromInputId : String
fromInputId =
    "route-plan-from-input"


type alias Config =
    { hostConfig : HostConfig
    , isReferee : Bool
    , travelZoneOptions : List TravelZoneOption
    , mDrive : Maybe Int
    }


refuelingOptions : List String
refuelingOptions =
    [ "any", "commercial", "refined", "wilderness" ]


refuelingLabel : String -> String
refuelingLabel refueling =
    case refueling of
        "commercial" ->
            "Commercial (starport A-D)"

        "refined" ->
            "Refined fuel only (starport A-B)"

        "wilderness" ->
            "Wilderness (gas giant present)"

        _ ->
            "Any"


type alias PickerState =
    { query : String
    , selected : Maybe RoutePlanEndpoint
    , results : RemoteData Http.Error (List RoutePlanSystemResult)
    , dropdownOpen : Bool
    }


emptyPicker : PickerState
emptyPicker =
    { query = "", selected = Nothing, results = NotAsked, dropdownOpen = False }


type alias Model =
    { fromPicker : PickerState
    , toPicker : PickerState
    , jumpRange : Int
    , refueling : String
    , excludedZoneIds : Set Int
    , mDrive : Int
    , planResult : RemoteData Http.Error RoutePlanResult
    , saveName : String
    , saveColour : String
    , saveState : RemoteData Http.Error { id : Int }
    }


init : Config -> ( Model, Cmd Msg )
init config =
    ( { fromPicker = emptyPicker
      , toPicker = emptyPicker
      , jumpRange = 2
      , refueling = "any"
      , excludedZoneIds = Set.empty
      , mDrive = Maybe.withDefault 1 config.mDrive
      , planResult = NotAsked
      , saveName = ""
      , saveColour = "#E87040"
      , saveState = NotAsked
      }
    , Task.attempt (\_ -> NoOp) (Browser.Dom.focus fromInputId)
    )


type Msg
    = NoOp
    | Cancel
    | Save
    | SetFromQuery String
    | GotFromResults (Result Http.Error (List RoutePlanSystemResult))
    | PickFrom RoutePlanSystemResult
    | CloseFromDropdown
    | SetToQuery String
    | GotToResults (Result Http.Error (List RoutePlanSystemResult))
    | PickTo RoutePlanSystemResult
    | CloseToDropdown
    | SetJumpRange Int
    | SetMDrive Int
    | SetRefueling String
    | ToggleExcludedZone Int
    | SubmitPlan
    | GotPlanResult (Result Http.Error RoutePlanResult)
    | SetSaveName String
    | SetSaveColour String
    | GotSaveResult (Result Http.Error { id : Int })



-- UPDATE


update : Config -> Msg -> Model -> ( Model, Cmd Msg )
update config msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        Cancel ->
            ( model, Cmd.none )

        SetFromQuery query ->
            let
                picker =
                    model.fromPicker

                newPicker =
                    { picker
                        | query = query
                        , selected = Nothing
                        , dropdownOpen = String.length query >= 3
                        , results =
                            if String.length query >= 3 then
                                Loading

                            else
                                NotAsked
                    }
            in
            ( clearPlan { model | fromPicker = newPicker }
            , if String.length query >= 3 then
                sendSystemsRequest config.hostConfig query GotFromResults

              else
                Cmd.none
            )

        GotFromResults result ->
            ( { model | fromPicker = applyResults model.fromPicker result }, Cmd.none )

        PickFrom result ->
            ( clearPlan
                { model
                    | fromPicker =
                        { emptyPicker | query = result.name, selected = Just { id = result.id, name = result.name } }
                }
            , Cmd.none
            )

        CloseFromDropdown ->
            let
                picker =
                    model.fromPicker
            in
            ( { model | fromPicker = { picker | dropdownOpen = False } }, Cmd.none )

        SetToQuery query ->
            let
                picker =
                    model.toPicker

                newPicker =
                    { picker
                        | query = query
                        , selected = Nothing
                        , dropdownOpen = String.length query >= 3
                        , results =
                            if String.length query >= 3 then
                                Loading

                            else
                                NotAsked
                    }
            in
            ( clearPlan { model | toPicker = newPicker }
            , if String.length query >= 3 then
                sendSystemsRequest config.hostConfig query GotToResults

              else
                Cmd.none
            )

        GotToResults result ->
            ( { model | toPicker = applyResults model.toPicker result }, Cmd.none )

        PickTo result ->
            ( clearPlan
                { model
                    | toPicker =
                        { emptyPicker | query = result.name, selected = Just { id = result.id, name = result.name } }
                }
            , Cmd.none
            )

        CloseToDropdown ->
            let
                picker =
                    model.toPicker
            in
            ( { model | toPicker = { picker | dropdownOpen = False } }, Cmd.none )

        SetJumpRange jumpRange ->
            ( clearPlan { model | jumpRange = jumpRange }, Cmd.none )

        SetMDrive mDrive ->
            ( clearPlan { model | mDrive = mDrive }, Cmd.none )

        SetRefueling refueling ->
            ( clearPlan { model | refueling = refueling }, Cmd.none )

        ToggleExcludedZone zoneId ->
            let
                newZoneIds =
                    if Set.member zoneId model.excludedZoneIds then
                        Set.remove zoneId model.excludedZoneIds

                    else
                        Set.insert zoneId model.excludedZoneIds
            in
            ( clearPlan { model | excludedZoneIds = newZoneIds }, Cmd.none )

        SubmitPlan ->
            case ( model.fromPicker.selected, model.toPicker.selected ) of
                ( Just from, Just to ) ->
                    ( { model | planResult = Loading }
                    , sendPlanRequest config.hostConfig
                        { fromId = from.id
                        , toId = to.id
                        , jumpRange = model.jumpRange
                        , refueling = model.refueling
                        , excludedTravelZoneIds = Set.toList model.excludedZoneIds
                        , mDrive = model.mDrive
                        }
                    )

                _ ->
                    ( model, Cmd.none )

        GotPlanResult result ->
            ( { model | planResult = RemoteData.fromResult result }, Cmd.none )

        SetSaveName name ->
            ( { model | saveName = name }, Cmd.none )

        SetSaveColour colour ->
            ( { model | saveColour = colour }, Cmd.none )

        Save ->
            case ( model.fromPicker.selected, model.toPicker.selected, model.planResult ) of
                ( Just from, Just to, Success planResult ) ->
                    if planResult.found then
                        ( { model | saveState = Loading }
                        , sendSaveRequest config.hostConfig
                            { name = model.saveName
                            , colour = model.saveColour
                            , jumpRange = model.jumpRange
                            , refueling = model.refueling
                            , fromId = from.id
                            , toId = to.id
                            , excludedTravelZoneIds = Set.toList model.excludedZoneIds
                            , systemIds = List.map (.system >> .id) planResult.hops
                            , mDrive = model.mDrive
                            }
                        )

                    else
                        ( model, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        GotSaveResult result ->
            ( { model | saveState = RemoteData.fromResult result }, Cmd.none )


clearPlan : Model -> Model
clearPlan model =
    { model | planResult = NotAsked, saveState = NotAsked }


applyResults : PickerState -> Result Http.Error (List RoutePlanSystemResult) -> PickerState
applyResults picker result =
    case result of
        Ok results ->
            let
                stillValid =
                    String.length picker.query >= 3
            in
            { picker
                | results =
                    if stillValid then
                        Success results

                    else
                        NotAsked
                , dropdownOpen = stillValid && not (List.isEmpty results)
            }

        Err err ->
            { picker | results = Failure err, dropdownOpen = False }



-- HTTP


sendSystemsRequest : HostConfig -> String -> (Result Http.Error (List RoutePlanSystemResult) -> Msg) -> Cmd Msg
sendSystemsRequest ( urlRoot, urlPath ) query toMsg =
    Http.request
        { method = "GET"
        , headers = []
        , url =
            Url.Builder.crossOrigin urlRoot
                (urlPath ++ [ "route_plan", "systems" ])
                [ Url.Builder.string "q" query ]
        , body = Http.emptyBody
        , expect = Http.expectJson toMsg (JsDecode.list RoutePlan.routePlanSystemResultDecoder)
        , timeout = Just 15000
        , tracker = Nothing
        }


sendPlanRequest :
    HostConfig
    -> { fromId : Int, toId : Int, jumpRange : Int, refueling : String, excludedTravelZoneIds : List Int, mDrive : Int }
    -> Cmd Msg
sendPlanRequest ( urlRoot, urlPath ) params =
    Http.request
        { method = "GET"
        , headers = []
        , url =
            Url.Builder.crossOrigin urlRoot
                (urlPath ++ [ "route_plan" ])
                (RoutePlan.planQuery params)
        , body = Http.emptyBody
        , expect = Http.expectJson GotPlanResult RoutePlan.routePlanResultDecoder
        , timeout = Just 15000
        , tracker = Nothing
        }


sendSaveRequest :
    HostConfig
    ->
        { name : String
        , colour : String
        , jumpRange : Int
        , refueling : String
        , fromId : Int
        , toId : Int
        , excludedTravelZoneIds : List Int
        , systemIds : List Int
        , mDrive : Int
        }
    -> Cmd Msg
sendSaveRequest ( urlRoot, urlPath ) params =
    Http.request
        { method = "POST"
        , headers = []
        , url = Url.Builder.crossOrigin urlRoot (urlPath ++ [ "route_plan", "save" ]) []
        , body = Http.jsonBody (RoutePlan.saveBody params)
        , expect =
            Http.expectJson GotSaveResult
                (JsDecode.map (\id -> { id = id }) (JsDecode.field "id" JsDecode.int))
        , timeout = Just 15000
        , tracker = Nothing
        }



-- VIEW


view : Config -> Model -> Html Msg
view config model =
    Html.div
        [ HtmlAttrs.style "position" "fixed"
        , HtmlAttrs.style "inset" "0"
        , HtmlAttrs.style "z-index" "200"
        , HtmlAttrs.style "display" "flex"
        , HtmlAttrs.style "align-items" "center"
        , HtmlAttrs.style "justify-content" "center"
        , HtmlAttrs.style "background-color" "rgba(0, 0, 0, 0.35)"
        , HtmlEvents.onClick Cancel
        ]
        [ Html.div
            [ HtmlAttrs.class "starmap-glass-panel"
            , HtmlAttrs.style "width" "min(760px, 94vw)"
            , HtmlAttrs.style "max-height" "85vh"
            , HtmlAttrs.style "overflow-y" "auto"
            , HtmlAttrs.style "border-radius" "6px"
            , HtmlAttrs.style "padding" "20px"
            , stopPropagation
            ]
            [ viewHeader
            , viewPickerField "From" model.fromPicker SetFromQuery PickFrom CloseFromDropdown
            , viewPickerField "To" model.toPicker SetToQuery PickTo CloseToDropdown
            , viewJumpRangeAndMDrive model.jumpRange model.mDrive
            , viewRefueling model.refueling
            , viewTravelZones config.travelZoneOptions model.excludedZoneIds
            , viewSubmit model
            , viewPlanResult config model
            ]
        ]


{-| Stops a click inside the panel from bubbling up to the backdrop's
`Cancel` handler. Dispatches `NoOp` (not `Cancel`) - `stopPropagationOn`
always sends its message, it only suppresses bubbling, so using `Cancel`
here would close the modal on every inner click.
-}
stopPropagation : Html.Attribute Msg
stopPropagation =
    HtmlEvents.stopPropagationOn "click" (JsDecode.succeed ( NoOp, True ))


viewHeader : Html Msg
viewHeader =
    Html.div
        [ HtmlAttrs.style "display" "flex"
        , HtmlAttrs.style "justify-content" "space-between"
        , HtmlAttrs.style "align-items" "center"
        , HtmlAttrs.style "margin-bottom" "14px"
        ]
        [ Html.span [ HtmlAttrs.style "font-size" "16px", HtmlAttrs.style "font-weight" "bold", HtmlAttrs.style "color" "var(--color-fg-bright)" ]
            [ Html.text "Plan a Route" ]
        , Html.span
            [ HtmlAttrs.style "cursor" "pointer"
            , HtmlAttrs.style "color" "var(--color-fg-muted)"
            , HtmlEvents.onClick Cancel
            ]
            [ Html.text "✕" ]
        ]


fieldLabel : String -> Html msg
fieldLabel label =
    Html.div
        [ HtmlAttrs.style "font-size" "11px"
        , HtmlAttrs.style "text-transform" "uppercase"
        , HtmlAttrs.style "letter-spacing" "0.15em"
        , HtmlAttrs.style "color" "var(--color-fg-muted)"
        , HtmlAttrs.style "margin-bottom" "4px"
        ]
        [ Html.text label ]


viewPickerField : String -> PickerState -> (String -> Msg) -> (RoutePlanSystemResult -> Msg) -> Msg -> Html Msg
viewPickerField label picker onQuery onPick onClose =
    Html.div
        [ HtmlAttrs.style "margin-bottom" "12px", HtmlAttrs.style "position" "relative" ]
        [ fieldLabel label
        , Html.input
            ([ HtmlAttrs.type_ "text"
             , HtmlAttrs.value picker.query
             , HtmlAttrs.placeholder "Search for a system…"
             , HtmlAttrs.style "width" "100%"
             , HtmlAttrs.style "box-sizing" "border-box"
             , HtmlAttrs.style "font-size" "13px"
             , HtmlAttrs.style "color" "var(--color-fg-bright)"
             , HtmlAttrs.style "background-color" "var(--color-panel)"
             , HtmlAttrs.style "border" "1px solid var(--color-outline)"
             , HtmlAttrs.style "border-radius" "4px"
             , HtmlAttrs.style "padding" "6px"
             , HtmlEvents.onInput onQuery
             , HtmlEvents.stopPropagationOn "keydown"
                (JsDecode.field "key" JsDecode.string
                    |> JsDecode.map
                        (\key ->
                            if key == "Escape" then
                                ( onClose, True )

                            else
                                ( NoOp, True )
                        )
                )
             ]
                ++ (if label == "From" then
                        [ HtmlAttrs.id fromInputId ]

                    else
                        []
                   )
            )
            []
        , if picker.dropdownOpen then
            viewPickerDropdown picker onPick onClose

          else
            Html.text ""
        ]


viewPickerDropdown : PickerState -> (RoutePlanSystemResult -> Msg) -> Msg -> Html Msg
viewPickerDropdown picker onPick onClose =
    Html.div
        [ HtmlAttrs.class "starmap-glass-panel"
        , HtmlAttrs.style "position" "absolute"
        , HtmlAttrs.style "top" "100%"
        , HtmlAttrs.style "left" "0"
        , HtmlAttrs.style "right" "0"
        , HtmlAttrs.style "margin-top" "4px"
        , HtmlAttrs.style "border-radius" "4px"
        , HtmlAttrs.style "padding" "4px"
        , HtmlAttrs.style "z-index" "10"
        , HtmlAttrs.style "max-height" "220px"
        , HtmlAttrs.style "overflow-y" "auto"
        ]
        (case picker.results of
            Loading ->
                [ Html.div [ HtmlAttrs.style "font-size" "12px", HtmlAttrs.style "color" "var(--color-fg-muted)", HtmlAttrs.style "padding" "8px" ]
                    [ Html.text "Searching…" ]
                ]

            Success [] ->
                [ Html.div [ HtmlAttrs.style "font-size" "12px", HtmlAttrs.style "color" "var(--color-fg-muted)", HtmlAttrs.style "padding" "8px" ]
                    [ Html.text "No matches" ]
                ]

            Success results ->
                List.map (viewPickerResultRow onPick) results

            Failure _ ->
                [ Html.div [ HtmlAttrs.style "font-size" "12px", HtmlAttrs.style "color" "var(--color-danger)", HtmlAttrs.style "padding" "8px" ]
                    [ Html.text "Search failed" ]
                ]

            NotAsked ->
                []
        )


viewPickerResultRow : (RoutePlanSystemResult -> Msg) -> RoutePlanSystemResult -> Html Msg
viewPickerResultRow onPick result =
    Html.div
        [ HtmlAttrs.style "padding" "6px 8px"
        , HtmlAttrs.style "cursor" "pointer"
        , HtmlAttrs.style "border-radius" "3px"
        , HtmlAttrs.class "starmap-search-result"
        , HtmlEvents.onMouseDown (onPick result)
        ]
        [ Html.div [ HtmlAttrs.style "font-size" "13px", HtmlAttrs.style "color" "var(--color-fg-bright)" ] [ Html.text result.name ]
        , Html.div [ HtmlAttrs.style "font-size" "11px", HtmlAttrs.style "color" "var(--color-fg-muted)" ] [ Html.text result.meta ]
        ]


viewJumpRangeAndMDrive : Int -> Int -> Html Msg
viewJumpRangeAndMDrive jumpRange mDrive =
    Html.div
        [ HtmlAttrs.style "display" "grid"
        , HtmlAttrs.style "grid-template-columns" "1fr 1fr"
        , HtmlAttrs.style "gap" "12px"
        , HtmlAttrs.style "margin-bottom" "12px"
        ]
        [ viewJumpRange jumpRange
        , viewMDrive mDrive
        ]


viewJumpRange : Int -> Html Msg
viewJumpRange jumpRange =
    Html.div []
        [ fieldLabel "Jump Range"
        , Html.select
            [ HtmlAttrs.style "width" "100%"
            , HtmlAttrs.style "font-size" "13px"
            , HtmlAttrs.style "color" "var(--color-fg-bright)"
            , HtmlAttrs.style "background-color" "var(--color-panel)"
            , HtmlAttrs.style "border" "1px solid var(--color-outline)"
            , HtmlAttrs.style "border-radius" "4px"
            , HtmlAttrs.style "padding" "4px 8px"
            , HtmlEvents.onInput (\s -> SetJumpRange (String.toInt s |> Maybe.withDefault jumpRange))
            ]
            (List.range 1 6
                |> List.map
                    (\n ->
                        Html.option [ HtmlAttrs.value (String.fromInt n), HtmlAttrs.selected (n == jumpRange) ]
                            [ Html.text ("J-" ++ String.fromInt n) ]
                    )
            )
        ]


viewMDrive : Int -> Html Msg
viewMDrive mDrive =
    Html.div []
        [ fieldLabel "M-Drive"
        , Html.select
            [ HtmlAttrs.style "width" "100%"
            , HtmlAttrs.style "font-size" "13px"
            , HtmlAttrs.style "color" "var(--color-fg-bright)"
            , HtmlAttrs.style "background-color" "var(--color-panel)"
            , HtmlAttrs.style "border" "1px solid var(--color-outline)"
            , HtmlAttrs.style "border-radius" "4px"
            , HtmlAttrs.style "padding" "4px 8px"
            , HtmlEvents.onInput (\s -> SetMDrive (String.toInt s |> Maybe.withDefault mDrive))
            ]
            (List.range 1 6
                |> List.map
                    (\n ->
                        Html.option [ HtmlAttrs.value (String.fromInt n), HtmlAttrs.selected (n == mDrive) ]
                            [ Html.text (String.fromInt n) ]
                    )
            )
        ]


viewRefueling : String -> Html Msg
viewRefueling refueling =
    Html.div [ HtmlAttrs.style "margin-bottom" "12px" ]
        (fieldLabel "Refuelling"
            :: List.map
                (\option ->
                    Html.label
                        [ HtmlAttrs.style "display" "flex"
                        , HtmlAttrs.style "align-items" "center"
                        , HtmlAttrs.style "gap" "6px"
                        , HtmlAttrs.style "font-size" "13px"
                        , HtmlAttrs.style "color" "var(--color-fg)"
                        , HtmlAttrs.style "padding" "2px 0"
                        ]
                        [ Html.input
                            [ HtmlAttrs.type_ "radio"
                            , HtmlAttrs.name "route-plan-refueling"
                            , HtmlAttrs.checked (option == refueling)
                            , HtmlEvents.onClick (SetRefueling option)
                            ]
                            []
                        , Html.text (refuelingLabel option)
                        ]
                )
                refuelingOptions
        )


viewTravelZones : List TravelZoneOption -> Set Int -> Html Msg
viewTravelZones zones excludedZoneIds =
    if List.isEmpty zones then
        Html.text ""

    else
        Html.div [ HtmlAttrs.style "margin-bottom" "12px" ]
            (fieldLabel "Exclude Travel Zones"
                :: List.map
                    (\zone ->
                        Html.label
                            [ HtmlAttrs.style "display" "flex"
                            , HtmlAttrs.style "align-items" "center"
                            , HtmlAttrs.style "gap" "6px"
                            , HtmlAttrs.style "font-size" "13px"
                            , HtmlAttrs.style "color" "var(--color-fg)"
                            , HtmlAttrs.style "padding" "2px 0"
                            ]
                            [ Html.input
                                [ HtmlAttrs.type_ "checkbox"
                                , HtmlAttrs.checked (Set.member zone.id excludedZoneIds)
                                , HtmlEvents.onClick (ToggleExcludedZone zone.id)
                                ]
                                []
                            , Html.span
                                [ HtmlAttrs.style "display" "inline-block"
                                , HtmlAttrs.style "width" "10px"
                                , HtmlAttrs.style "height" "10px"
                                , HtmlAttrs.style "border-radius" "2px"
                                , HtmlAttrs.style "background-color" zone.colour
                                ]
                                []
                            , Html.text zone.name
                            ]
                    )
                    zones
            )


viewSubmit : Model -> Html Msg
viewSubmit model =
    let
        canSubmit =
            model.fromPicker.selected /= Nothing && model.toPicker.selected /= Nothing
    in
    Html.button
        [ HtmlAttrs.class "btn btn-primary"
        , HtmlAttrs.style "width" "100%"
        , HtmlAttrs.style "padding" "8px"
        , HtmlAttrs.style "margin-bottom" "12px"
        , HtmlAttrs.disabled (not canSubmit)
        , HtmlEvents.onClick SubmitPlan
        ]
        [ Html.text "Plot Route" ]


viewPlanResult : Config -> Model -> Html Msg
viewPlanResult config model =
    case model.planResult of
        NotAsked ->
            Html.text ""

        Loading ->
            Html.div [ HtmlAttrs.style "font-size" "13px", HtmlAttrs.style "color" "var(--color-fg-muted)" ]
                [ Html.text "Plotting…" ]

        Failure _ ->
            Html.div [ HtmlAttrs.style "font-size" "13px", HtmlAttrs.style "color" "var(--color-danger)" ]
                [ Html.text "Could not plan a route. Please try again." ]

        Success result ->
            if result.found then
                viewFoundRoute config model result

            else
                viewNoRouteFound config


viewNoRouteFound : Config -> Html Msg
viewNoRouteFound config =
    Html.div [ HtmlAttrs.style "font-size" "13px", HtmlAttrs.style "color" "var(--color-fg-muted)" ]
        [ Html.p [] [ Html.text "No known route satisfies these filters." ]
        , if config.isReferee then
            Html.text ""

          else
            Html.p [] [ Html.text "You may not have surveyed all the intervening systems." ]
        ]


viewFoundRoute : Config -> Model -> RoutePlanResult -> Html Msg
viewFoundRoute config model result =
    let
        jumps =
            max 0 (List.length result.hops - 1)
    in
    Html.div []
        [ viewStatRow
            [ ( "Jumps", String.fromInt jumps )
            , ( "Jump Distance", String.fromInt (Maybe.withDefault 0 result.totalDistance) )
            , ( "Parsec Distance", String.fromInt (Maybe.withDefault 0 result.parsecDistance) )
            ]
        , viewStatRow
            [ ( "Total Time", viewTotalTimeText result )
            , ( "Jump Time", viewTotalJumpTimeText result )
            , ( "Transit Time", viewTotalTransitTimeText result )
            ]
        , viewHopTable result.hops
        , if config.isReferee then
            viewSaveForm model

          else
            Html.text ""
        ]


viewStatRow : List ( String, String ) -> Html Msg
viewStatRow stats =
    Html.div
        [ HtmlAttrs.style "display" "grid"
        , HtmlAttrs.style "grid-template-columns" ("repeat(" ++ String.fromInt (List.length stats) ++ ", 1fr)")
        , HtmlAttrs.style "gap" "8px 16px"
        , HtmlAttrs.style "text-align" "center"
        , HtmlAttrs.style "margin-bottom" "10px"
        ]
        (List.map viewStatTile stats)


viewStatTile : ( String, String ) -> Html Msg
viewStatTile ( label, value ) =
    Html.div []
        [ Html.div
            [ HtmlAttrs.style "font-size" "10px"
            , HtmlAttrs.style "text-transform" "uppercase"
            , HtmlAttrs.style "letter-spacing" "0.08em"
            , HtmlAttrs.style "color" "var(--color-fg-muted)"
            , HtmlAttrs.style "margin-bottom" "2px"
            ]
            [ Html.text label ]
        , Html.div
            [ HtmlAttrs.style "font-size" "13px"
            , HtmlAttrs.style "font-weight" "600"
            , HtmlAttrs.style "color" "var(--color-fg-bright)"
            ]
            [ Html.text value ]
        ]


viewTotalTimeText : RoutePlanResult -> String
viewTotalTimeText result =
    case ( result.totalMinHours, result.totalAvgHours, result.totalMaxHours ) of
        ( Just min, Just avg, Just max ) ->
            TravelCalc.formatDurationRange { min = min, avg = avg, max = max }

        _ ->
            "—"


viewTotalJumpTimeText : RoutePlanResult -> String
viewTotalJumpTimeText result =
    case ( result.totalJumpMinHours, result.totalJumpAvgHours, result.totalJumpMaxHours ) of
        ( Just min, Just avg, Just max ) ->
            TravelCalc.formatDurationRange { min = min, avg = avg, max = max }

        _ ->
            "—"


viewTotalTransitTimeText : RoutePlanResult -> String
viewTotalTransitTimeText result =
    case result.totalTransitHours of
        Just hours ->
            TravelCalc.formatDurationHours hours

        Nothing ->
            "—"


viewHopTable : List RoutePlan.Hop -> Html Msg
viewHopTable hops =
    let
        lastIndex =
            List.length hops - 1
    in
    Html.table
        [ HtmlAttrs.style "width" "100%"
        , HtmlAttrs.style "border-collapse" "collapse"
        , HtmlAttrs.style "font-size" "13px"
        , HtmlAttrs.style "margin-bottom" "12px"
        ]
        [ Html.thead []
            [ Html.tr
                [ HtmlAttrs.style "border-bottom" "1px solid var(--color-outline)"
                ]
                [ hopHeaderCell "right" "Jump"
                , hopHeaderCell "left" "System"
                , hopHeaderCell "right" "Transit Time (one-way)"
                , hopHeaderCell "right" "Elapsed"
                ]
            ]
        , Html.tbody []
            (List.indexedMap (viewHopTableRow lastIndex) hops)
        ]


hopHeaderCell : String -> String -> Html Msg
hopHeaderCell align label =
    Html.th
        [ HtmlAttrs.style "text-align" align
        , HtmlAttrs.style "padding" "0 8px 6px 8px"
        , HtmlAttrs.style "font-size" "11px"
        , HtmlAttrs.style "text-transform" "uppercase"
        , HtmlAttrs.style "letter-spacing" "0.05em"
        , HtmlAttrs.style "color" "var(--color-fg-muted)"
        , HtmlAttrs.style "white-space" "nowrap"
        ]
        [ Html.text label ]


viewHopTableRow : Int -> Int -> RoutePlan.Hop -> Html Msg
viewHopTableRow lastIndex index hop =
    let
        isEndpoint =
            index == 0 || index == lastIndex

        rowColour =
            if isEndpoint then
                "var(--color-highlight)"

            else
                "var(--color-fg)"
    in
    Html.tr
        [ HtmlAttrs.style "border-bottom" "1px solid color-mix(in srgb, var(--color-outline) 30%, transparent)"
        , HtmlAttrs.style "color" rowColour
        ]
        [ Html.td
            [ HtmlAttrs.style "text-align" "right"
            , HtmlAttrs.style "padding" "6px 8px"
            , HtmlAttrs.style "color" "var(--color-fg-muted)"
            , HtmlAttrs.style "white-space" "nowrap"
            ]
            [ Html.text
                (if index > 0 then
                    "J-" ++ String.fromInt hop.distance

                 else
                    ""
                )
            ]
        , Html.td
            [ HtmlAttrs.style "padding" "6px 8px"
            ]
            [ Html.div [] [ Html.text hop.system.name ]
            , Html.div
                [ HtmlAttrs.style "font-size" "11px"
                , HtmlAttrs.style "color" "var(--color-fg-muted)"
                ]
                [ Html.text hop.system.hexLabel ]
            ]
        , Html.td
            [ HtmlAttrs.style "text-align" "right"
            , HtmlAttrs.style "padding" "6px 8px"
            , HtmlAttrs.style "color" "var(--color-fg-muted)"
            , HtmlAttrs.style "white-space" "nowrap"
            ]
            [ Html.text (TravelCalc.formatDurationHours hop.transitHours) ]
        , Html.td
            [ HtmlAttrs.style "text-align" "right"
            , HtmlAttrs.style "padding" "6px 8px"
            , HtmlAttrs.style "color" "var(--color-fg-muted)"
            , HtmlAttrs.style "white-space" "nowrap"
            ]
            [ Html.text (TravelCalc.formatDurationHours hop.elapsedAvgHours) ]
        ]


viewSaveForm : Model -> Html Msg
viewSaveForm model =
    Html.div
        [ HtmlAttrs.style "border-top" "1px solid color-mix(in srgb, var(--color-outline) 15%, transparent)"
        , HtmlAttrs.style "padding-top" "12px"
        ]
        [ fieldLabel "Save to Map"
        , Html.div [ HtmlAttrs.style "display" "flex", HtmlAttrs.style "gap" "8px", HtmlAttrs.style "margin-bottom" "8px" ]
            [ Html.input
                [ HtmlAttrs.type_ "text"
                , HtmlAttrs.placeholder "Route name"
                , HtmlAttrs.value model.saveName
                , HtmlAttrs.style "flex" "1"
                , HtmlAttrs.style "font-size" "13px"
                , HtmlAttrs.style "color" "var(--color-fg-bright)"
                , HtmlAttrs.style "background-color" "var(--color-panel)"
                , HtmlAttrs.style "border" "1px solid var(--color-outline)"
                , HtmlAttrs.style "border-radius" "4px"
                , HtmlAttrs.style "padding" "6px"
                , HtmlEvents.onInput SetSaveName
                ]
                []
            , Html.input
                [ HtmlAttrs.type_ "color"
                , HtmlAttrs.value model.saveColour
                , HtmlEvents.onInput SetSaveColour
                ]
                []
            ]
        , Html.button
            [ HtmlAttrs.class "btn btn-primary"
            , HtmlAttrs.style "width" "100%"
            , HtmlAttrs.style "padding" "8px"
            , HtmlAttrs.disabled (model.saveState == Loading)
            , HtmlEvents.onClick Save
            ]
            [ Html.text
                (case model.saveState of
                    Loading ->
                        "Saving…"

                    _ ->
                        "Save to Map"
                )
            ]
        , case model.saveState of
            Failure _ ->
                Html.div [ HtmlAttrs.style "font-size" "12px", HtmlAttrs.style "color" "var(--color-danger)", HtmlAttrs.style "margin-top" "6px" ]
                    [ Html.text "Could not save this route. Please try again." ]

            _ ->
                Html.text ""
        ]
