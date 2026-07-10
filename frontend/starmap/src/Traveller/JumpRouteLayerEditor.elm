module Traveller.JumpRouteLayerEditor exposing (Config, Model, Msg(..), init, update, view)

{-| The quick edit modal for an existing "network" jump route, opened from the
Jump Route Layers panel in `Traveller.elm`. Covers only the quick-edit field
subset accepted by `Api::JumpRoutesController` - name, colour, line style,
line width, known and notes. Editing a "plotted" route, or any field outside
this set, is handled by `Traveller.elm` linking out to the existing Rails
`/jump_routes/:id/edit` page instead of opening this modal. New jump routes
are always created through the Route Planner (`Traveller.RoutePlanForm`),
not here - this module only ever edits a route that already exists.

Unlike `Traveller.HighlightRuleEditor` (which is pure, since it only edits a
draft the parent later merges), `Save` here is a real HTTP round trip, so
`update` returns a `Cmd Msg` and the parent wires it in with `Cmd.map`,
following the same shape as `Traveller.RoutePlanForm`.

-}

import HostConfig exposing (HostConfig)
import Html exposing (Html)
import Html.Attributes as HtmlAttrs
import Html.Events as HtmlEvents
import Http
import Json.Decode as JsDecode
import RemoteData exposing (RemoteData(..))
import Traveller.JumpRouteLayer as JumpRouteLayer exposing (DraftFields, Route)
import Traveller.ToggleSwitch as ToggleSwitch
import Url.Builder


type alias Config =
    { hostConfig : HostConfig }


type alias Model =
    { id : Int
    , name : String
    , colour : String
    , lineStyle : String
    , lineWidth : Int
    , known : Bool
    , notes : String
    , saveState : RemoteData Http.Error Route
    }


init : Route -> Model
init route =
    { id = route.id
    , name = route.name
    , colour = route.colour
    , lineStyle = route.lineStyle
    , lineWidth = route.lineWidth
    , known = route.known
    , notes = Maybe.withDefault "" route.notes
    , saveState = NotAsked
    }


lineStyles : List String
lineStyles =
    [ "solid", "dashed", "dotted", "dash_dot", "dash_dot_dot", "long_dash", "short_dash" ]


lineStyleLabel : String -> String
lineStyleLabel style =
    case style of
        "dash_dot" ->
            "Dash-dot"

        "dash_dot_dot" ->
            "Dash-dot-dot"

        "long_dash" ->
            "Long dash"

        "short_dash" ->
            "Short dash"

        other ->
            String.left 1 (String.toUpper other) ++ String.dropLeft 1 other


type Msg
    = NoOp
    | Cancel
    | SetName String
    | SetColour String
    | SetLineStyle String
    | SetLineWidth Int
    | SetKnown Bool
    | SetNotes String
    | Save
    | GotSaveResult (Result Http.Error Route)



-- UPDATE


update : Config -> Msg -> Model -> ( Model, Cmd Msg )
update config msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        Cancel ->
            ( model, Cmd.none )

        SetName name ->
            ( { model | name = name }, Cmd.none )

        SetColour colour ->
            ( { model | colour = colour }, Cmd.none )

        SetLineStyle lineStyle ->
            ( { model | lineStyle = lineStyle }, Cmd.none )

        SetLineWidth lineWidth ->
            ( { model | lineWidth = lineWidth }, Cmd.none )

        SetKnown known ->
            ( { model | known = known }, Cmd.none )

        SetNotes notes ->
            ( { model | notes = notes }, Cmd.none )

        Save ->
            ( { model | saveState = Loading }
            , sendUpdateRequest config.hostConfig model.id (draftFields model)
            )

        GotSaveResult result ->
            ( { model | saveState = RemoteData.fromResult result }, Cmd.none )


draftFields : Model -> DraftFields
draftFields model =
    { name = model.name
    , colour = model.colour
    , lineStyle = model.lineStyle
    , lineWidth = model.lineWidth
    , known = model.known
    , notes = model.notes
    }



-- HTTP


sendUpdateRequest : HostConfig -> Int -> DraftFields -> Cmd Msg
sendUpdateRequest ( urlRoot, urlPath ) id draft =
    Http.request
        { method = "PATCH"
        , headers = []
        , url = Url.Builder.crossOrigin urlRoot (urlPath ++ [ "jump_routes", String.fromInt id ]) []
        , body = Http.jsonBody (JumpRouteLayer.draftBody draft)
        , expect = Http.expectJson GotSaveResult JumpRouteLayer.routeDecoder
        , timeout = Just 15000
        , tracker = Nothing
        }



-- VIEW


view : Model -> Html Msg
view model =
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
            , HtmlAttrs.style "width" "360px"
            , HtmlAttrs.style "max-height" "85vh"
            , HtmlAttrs.style "overflow-y" "auto"
            , HtmlAttrs.style "border-radius" "6px"
            , HtmlAttrs.style "padding" "20px"
            , stopPropagation
            ]
            [ viewHeader
            , viewNameField model.name
            , viewColourAndKnown model
            , viewLineStyle model.lineStyle
            , viewLineWidth model.lineWidth
            , viewNotes model.notes
            , viewSaveState model.saveState
            , viewActions model
            ]
        ]


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
        [ Html.span
            [ HtmlAttrs.style "font-size" "16px"
            , HtmlAttrs.style "font-weight" "bold"
            , HtmlAttrs.style "color" "var(--color-fg-bright)"
            ]
            [ Html.text "Edit Jump Route" ]
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


textInputStyles : List (Html.Attribute msg)
textInputStyles =
    [ HtmlAttrs.style "width" "100%"
    , HtmlAttrs.style "box-sizing" "border-box"
    , HtmlAttrs.style "font-size" "13px"
    , HtmlAttrs.style "color" "var(--color-fg-bright)"
    , HtmlAttrs.style "background-color" "var(--color-panel)"
    , HtmlAttrs.style "border" "1px solid var(--color-outline)"
    , HtmlAttrs.style "border-radius" "4px"
    , HtmlAttrs.style "padding" "6px"
    ]


viewNameField : String -> Html Msg
viewNameField name =
    Html.div [ HtmlAttrs.style "margin-bottom" "12px" ]
        [ fieldLabel "Name"
        , Html.input
            (HtmlAttrs.type_ "text"
                :: HtmlAttrs.value name
                :: HtmlEvents.onInput SetName
                :: textInputStyles
            )
            []
        ]


viewColourAndKnown : Model -> Html Msg
viewColourAndKnown model =
    Html.div
        [ HtmlAttrs.style "display" "flex"
        , HtmlAttrs.style "align-items" "center"
        , HtmlAttrs.style "gap" "16px"
        , HtmlAttrs.style "margin-bottom" "12px"
        ]
        [ Html.div []
            [ fieldLabel "Colour"
            , Html.input
                [ HtmlAttrs.type_ "color"
                , HtmlAttrs.value model.colour
                , HtmlEvents.onInput SetColour
                ]
                []
            ]
        , Html.div []
            [ fieldLabel "Known to players"
            , ToggleSwitch.view ToggleSwitch.Regular model.known (HtmlEvents.onClick (SetKnown (not model.known)))
            ]
        ]


viewLineStyle : String -> Html Msg
viewLineStyle lineStyle =
    Html.div [ HtmlAttrs.style "margin-bottom" "12px" ]
        [ fieldLabel "Line Style"
        , Html.select
            (HtmlEvents.onInput SetLineStyle :: textInputStyles)
            (List.map
                (\style ->
                    Html.option [ HtmlAttrs.value style, HtmlAttrs.selected (style == lineStyle) ]
                        [ Html.text (lineStyleLabel style) ]
                )
                lineStyles
            )
        ]


viewLineWidth : Int -> Html Msg
viewLineWidth lineWidth =
    Html.div [ HtmlAttrs.style "margin-bottom" "12px" ]
        [ fieldLabel "Line Width"
        , Html.input
            (HtmlAttrs.type_ "number"
                :: HtmlAttrs.min "1"
                :: HtmlAttrs.max "12"
                :: HtmlAttrs.value (String.fromInt lineWidth)
                :: HtmlEvents.onInput (\s -> SetLineWidth (String.toInt s |> Maybe.withDefault lineWidth))
                :: textInputStyles
            )
            []
        ]


viewNotes : String -> Html Msg
viewNotes notes =
    Html.div [ HtmlAttrs.style "margin-bottom" "12px" ]
        [ fieldLabel "Notes"
        , Html.textarea
            (HtmlAttrs.rows 3
                :: HtmlAttrs.value notes
                :: HtmlEvents.onInput SetNotes
                :: textInputStyles
            )
            []
        ]


viewSaveState : RemoteData Http.Error Route -> Html Msg
viewSaveState saveState =
    case saveState of
        Failure _ ->
            Html.div
                [ HtmlAttrs.style "font-size" "13px"
                , HtmlAttrs.style "color" "var(--color-danger)"
                , HtmlAttrs.style "margin-bottom" "8px"
                ]
                [ Html.text "Could not save this jump route. Please try again." ]

        _ ->
            Html.text ""


viewActions : Model -> Html Msg
viewActions model =
    Html.div
        [ HtmlAttrs.style "display" "flex", HtmlAttrs.style "gap" "8px" ]
        [ Html.button
            [ HtmlAttrs.class "btn"
            , HtmlAttrs.style "flex" "1"
            , HtmlAttrs.style "padding" "8px"
            , HtmlEvents.onClick Cancel
            ]
            [ Html.text "Cancel" ]
        , Html.button
            [ HtmlAttrs.class "btn btn-primary"
            , HtmlAttrs.style "flex" "1"
            , HtmlAttrs.style "padding" "8px"
            , HtmlAttrs.disabled (model.saveState == Loading || String.isEmpty (String.trim model.name))
            , HtmlEvents.onClick Save
            ]
            [ Html.text
                (if model.saveState == Loading then
                    "Saving…"

                 else
                    "Save"
                )
            ]
        ]
