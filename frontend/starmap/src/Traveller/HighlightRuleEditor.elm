module Traveller.HighlightRuleEditor exposing (Model, Msg(..), init, update, view)

import Color exposing (Color)
import Color.Convert exposing (colorToHex, hexToColor)
import Element exposing (Element)
import Html exposing (Html)
import Html.Attributes as HtmlAttrs
import Html.Events as HtmlEvents
import Json.Decode as JsDecode
import List.Extra
import Traveller.HighlightRule as HighlightRule exposing (Condition, Field, Group, Operator, Rule)
import Traveller.ToggleSwitch as ToggleSwitch


type alias Model =
    { draft : Rule
    , openPicker : Maybe ( Int, Int )
    }


init : Rule -> Model
init rule =
    { draft = rule, openPicker = Nothing }


type Msg
    = NoOp
    | Cancel
    | Save
    | SetName String
    | SetColour String
    | SetEnabled Bool
    | AddGroup
    | RemoveGroup Int
    | AddCondition Int
    | RemoveCondition Int Int
    | SetField Int Int Field
    | SetOperator Int Int Operator
    | SetSingleValue Int Int String
    | SetBetweenValue Int Int Bool String
    | ToggleOneOfValue Int Int String
    | SetNegate Int Int Bool
    | ToggleValuePicker Int Int
    | CloseValuePicker



-- UPDATE


update : List HighlightRule.FacilityOption -> Msg -> Model -> Model
update facilities msg model =
    let
        draft =
            model.draft
    in
    case msg of
        NoOp ->
            model

        Cancel ->
            model

        Save ->
            model

        SetName name ->
            { model | draft = { draft | name = name } }

        SetColour hex ->
            case hexToColor hex of
                Ok colour ->
                    { model | draft = { draft | colour = colour } }

                Err _ ->
                    model

        SetEnabled enabled ->
            { model | draft = { draft | enabled = enabled } }

        AddGroup ->
            { model | draft = { draft | groups = draft.groups ++ [ [ HighlightRule.newCondition HighlightRule.Starport ] ] } }

        RemoveGroup groupIdx ->
            if List.length draft.groups <= 1 then
                model

            else
                { model | draft = { draft | groups = List.Extra.removeAt groupIdx draft.groups }, openPicker = Nothing }

        AddCondition groupIdx ->
            { model | draft = { draft | groups = updateGroupAt groupIdx (\g -> g ++ [ HighlightRule.newCondition HighlightRule.Starport ]) draft.groups } }

        RemoveCondition groupIdx condIdx ->
            { model
                | draft =
                    { draft
                        | groups =
                            updateGroupAt groupIdx
                                (\g ->
                                    if List.length g <= 1 then
                                        g

                                    else
                                        List.Extra.removeAt condIdx g
                                )
                                draft.groups
                    }
                , openPicker = Nothing
            }

        SetField groupIdx condIdx field ->
            { model
                | draft =
                    updateConditionAt groupIdx
                        condIdx
                        (\c ->
                            let
                                operator =
                                    List.head (HighlightRule.operatorsFor field) |> Maybe.withDefault HighlightRule.Eq
                            in
                            { c | field = field, operator = operator, values = defaultValuesForOperator facilities field operator }
                        )
                        draft
                , openPicker = Nothing
            }

        SetOperator groupIdx condIdx operator ->
            { model
                | draft =
                    updateConditionAt groupIdx
                        condIdx
                        (\c -> { c | operator = operator, values = defaultValuesForOperator facilities c.field operator })
                        draft
                , openPicker = Nothing
            }

        SetSingleValue groupIdx condIdx value ->
            { model | draft = updateConditionAt groupIdx condIdx (\c -> { c | values = [ value ] }) draft }

        SetBetweenValue groupIdx condIdx isLow value ->
            { model
                | draft =
                    updateConditionAt groupIdx
                        condIdx
                        (\c ->
                            case c.values of
                                [ lo, hi ] ->
                                    { c
                                        | values =
                                            if isLow then
                                                [ value, hi ]

                                            else
                                                [ lo, value ]
                                    }

                                _ ->
                                    { c | values = [ value, value ] }
                        )
                        draft
            }

        ToggleOneOfValue groupIdx condIdx code ->
            { model
                | draft =
                    updateConditionAt groupIdx
                        condIdx
                        (\c ->
                            if List.member code c.values then
                                { c | values = List.filter ((/=) code) c.values }

                            else
                                { c | values = c.values ++ [ code ] }
                        )
                        draft
            }

        SetNegate groupIdx condIdx negate ->
            { model | draft = updateConditionAt groupIdx condIdx (\c -> { c | negate = negate }) draft }

        ToggleValuePicker groupIdx condIdx ->
            { model
                | openPicker =
                    if model.openPicker == Just ( groupIdx, condIdx ) then
                        Nothing

                    else
                        Just ( groupIdx, condIdx )
            }

        CloseValuePicker ->
            { model | openPicker = Nothing }


defaultValuesForOperator : List HighlightRule.FacilityOption -> Field -> Operator -> List String
defaultValuesForOperator facilities field operator =
    case field of
        HighlightRule.Bases ->
            case List.head facilities of
                Just facility ->
                    [ facility.code ]

                Nothing ->
                    []

        _ ->
            let
                options =
                    HighlightRule.fieldOptions field |> List.map .code

                first =
                    List.head options |> Maybe.withDefault ""

                second =
                    List.drop 1 options |> List.head |> Maybe.withDefault first
            in
            case operator of
                HighlightRule.Between ->
                    [ first, second ]

                _ ->
                    [ first ]


updateGroupAt : Int -> (Group -> Group) -> List Group -> List Group
updateGroupAt idx f groups =
    List.indexedMap
        (\i g ->
            if i == idx then
                f g

            else
                g
        )
        groups


updateConditionAt : Int -> Int -> (Condition -> Condition) -> Rule -> Rule
updateConditionAt groupIdx condIdx f rule =
    { rule
        | groups =
            updateGroupAt groupIdx
                (List.indexedMap
                    (\i c ->
                        if i == condIdx then
                            f c

                        else
                            c
                    )
                )
                rule.groups
    }


fieldFromLabel : String -> Field
fieldFromLabel label =
    HighlightRule.allFields
        |> List.filter (\f -> HighlightRule.fieldLabel f == label)
        |> List.head
        |> Maybe.withDefault HighlightRule.Starport


operatorFromLabel : Field -> String -> Operator
operatorFromLabel field label =
    HighlightRule.operatorsFor field
        |> List.filter (\op -> HighlightRule.operatorLabel op == label)
        |> List.head
        |> Maybe.withDefault HighlightRule.Eq



{- VIEW

   Built as a single raw `Html` tree rather than elm-ui `Element`s. This form is
   almost entirely native controls (selects, checkboxes, a colour input,
   buttons), and elm-ui's layout/spacing model doesn't reliably cooperate with
   native elements embedded via `Element.html` - see `Traveller/Sidebar.elm`'s
   `viewSurveyControls` for the same tradeoff made the same way.
-}


view : List HighlightRule.FacilityOption -> Model -> Element Msg
view facilities model =
    Element.html (viewHtml facilities model)


viewHtml : List HighlightRule.FacilityOption -> Model -> Html Msg
viewHtml facilities model =
    let
        draft =
            model.draft
    in
    Html.div
        [ HtmlAttrs.style "position" "fixed"
        , HtmlAttrs.style "inset" "0"
        , HtmlAttrs.style "z-index" "50"
        , HtmlAttrs.style "display" "flex"
        , HtmlAttrs.style "align-items" "center"
        , HtmlAttrs.style "justify-content" "center"
        , HtmlAttrs.style "background-color" "color-mix(in srgb, var(--color-bg) 30%, transparent)"
        , HtmlEvents.onClick Cancel
        ]
        [ Html.div
            [ HtmlAttrs.class "starmap-glass-panel"
            , HtmlEvents.stopPropagationOn "click" (JsDecode.succeed ( NoOp, True ))
            , HtmlAttrs.style "display" "flex"
            , HtmlAttrs.style "flex-direction" "column"
            , HtmlAttrs.style "gap" "12px"
            , HtmlAttrs.style "border-radius" "6px"
            , HtmlAttrs.style "box-shadow" "0 8px 32px rgba(0, 0, 0, 0.25)"
            , HtmlAttrs.style "padding" "20px"
            , HtmlAttrs.style "width" "100%"
            , HtmlAttrs.style "max-width" "760px"
            ]
            [ headerRow
            , nameRow draft.name
            , colourAndEnabledRow draft.colour draft.enabled
            , Html.div
                [ HtmlAttrs.style "display" "flex"
                , HtmlAttrs.style "flex-direction" "column"
                , HtmlAttrs.style "gap" "10px"
                ]
                (groupViews facilities model.openPicker draft.groups)
            , linkButton AddGroup "+ Add OR group"
            , actionsRow
            ]
        ]


headerRow : Html Msg
headerRow =
    Html.div
        [ HtmlAttrs.style "display" "flex"
        , HtmlAttrs.style "align-items" "center"
        , HtmlAttrs.style "justify-content" "space-between"
        , HtmlAttrs.style "padding-bottom" "12px"
        , HtmlAttrs.style "border-bottom" "1px solid color-mix(in srgb, var(--color-outline) 15%, transparent)"
        ]
        [ Html.span [ HtmlAttrs.class "text-sm font-bold text-fg-bright" ] [ Html.text "Survey Overlay" ]
        , Html.span
            [ HtmlAttrs.class "starmap-modal-close cursor-pointer text-fg-muted"
            , HtmlEvents.onClick Cancel
            ]
            [ Html.text "✕" ]
        ]


nameRow : String -> Html Msg
nameRow name =
    Html.div [ HtmlAttrs.style "display" "flex", HtmlAttrs.style "align-items" "center", HtmlAttrs.style "gap" "10px" ]
        [ Html.label [ HtmlAttrs.class "edit-label" ] [ Html.text "Name" ]
        , Html.input
            [ HtmlAttrs.type_ "text"
            , HtmlAttrs.class "edit-base text-sm py-1 flex-1"
            , HtmlAttrs.value name
            , HtmlEvents.onInput SetName
            ]
            []
        ]


colourAndEnabledRow : Color -> Bool -> Html Msg
colourAndEnabledRow colour enabled =
    Html.div [ HtmlAttrs.style "display" "flex", HtmlAttrs.style "align-items" "center", HtmlAttrs.style "gap" "24px" ]
        [ Html.div [ HtmlAttrs.style "display" "flex", HtmlAttrs.style "align-items" "center", HtmlAttrs.style "gap" "10px" ]
            [ Html.label [ HtmlAttrs.class "edit-label" ] [ Html.text "Colour" ]
            , Html.input
                [ HtmlAttrs.type_ "color"
                , HtmlAttrs.value (colorToHex colour)
                , HtmlEvents.onInput SetColour
                ]
                []
            ]
        , Html.div [ HtmlAttrs.style "display" "flex", HtmlAttrs.style "align-items" "center", HtmlAttrs.style "gap" "10px" ]
            [ Html.label [ HtmlAttrs.class "edit-label" ] [ Html.text "Enabled" ]
            , ToggleSwitch.view ToggleSwitch.Small enabled (HtmlEvents.onClick (SetEnabled (not enabled)))
            ]
        ]


groupViews : List HighlightRule.FacilityOption -> Maybe ( Int, Int ) -> List Group -> List (Html Msg)
groupViews facilities openPicker groups =
    groups
        |> List.indexedMap (\i g -> ( i, g ))
        |> List.concatMap
            (\( groupIdx, group ) ->
                (if groupIdx > 0 then
                    [ Html.div [ HtmlAttrs.class "text-xs font-bold text-fg-bright", HtmlAttrs.style "text-align" "center" ] [ Html.text "OR" ] ]

                 else
                    []
                )
                    ++ [ groupView facilities openPicker groupIdx group ]
            )


groupView : List HighlightRule.FacilityOption -> Maybe ( Int, Int ) -> Int -> Group -> Html Msg
groupView facilities openPicker groupIdx group =
    Html.div
        [ HtmlAttrs.style "display" "flex"
        , HtmlAttrs.style "flex-direction" "column"
        , HtmlAttrs.style "gap" "12px"
        , HtmlAttrs.style "padding" "10px"
        , HtmlAttrs.style "border" "1px solid color-mix(in srgb, var(--color-outline) 20%, transparent)"
        , HtmlAttrs.style "border-radius" "4px"
        ]
        (List.indexedMap (conditionRow facilities openPicker groupIdx) group
            ++ [ Html.div [ HtmlAttrs.style "display" "flex", HtmlAttrs.style "gap" "16px" ]
                    [ linkButton (AddCondition groupIdx) "+ Add AND condition"
                    , linkButton (RemoveGroup groupIdx) "Remove group"
                    ]
               ]
        )


{-| A text-styled `<button>` for click actions that should read as inline
links (per the project's link convention: underline on hover only).
-}
linkButton : msg -> String -> Html msg
linkButton msg label =
    Html.button
        [ HtmlAttrs.type_ "button"
        , HtmlEvents.onClick msg
        , HtmlAttrs.class "text-xs text-link no-underline hover:text-link-hover hover:underline hover:underline-offset-2 cursor-pointer bg-transparent border-0 p-0"
        ]
        [ Html.text label ]


conditionRow : List HighlightRule.FacilityOption -> Maybe ( Int, Int ) -> Int -> Int -> Condition -> Html Msg
conditionRow facilities openPicker groupIdx condIdx condition =
    Html.div
        [ HtmlAttrs.style "display" "flex"
        , HtmlAttrs.style "flex-wrap" "wrap"
        , HtmlAttrs.style "align-items" "center"
        , HtmlAttrs.style "gap" "14px"
        ]
        [ htmlSelect
            (\label -> SetField groupIdx condIdx (fieldFromLabel label))
            (HighlightRule.fieldLabel condition.field)
            (HighlightRule.allFields |> List.map (\f -> ( HighlightRule.fieldLabel f, HighlightRule.fieldLabel f )))
        , negateCheckbox groupIdx condIdx condition.negate
        , htmlSelect
            (\label -> SetOperator groupIdx condIdx (operatorFromLabel condition.field label))
            (HighlightRule.operatorLabel condition.operator)
            (HighlightRule.operatorsFor condition.field |> List.map (\op -> ( HighlightRule.operatorLabel op, HighlightRule.operatorLabel op )))
        , valuePicker facilities (openPicker == Just ( groupIdx, condIdx )) groupIdx condIdx condition
        , Html.button
            [ HtmlAttrs.type_ "button"
            , HtmlEvents.onClick (RemoveCondition groupIdx condIdx)
            , HtmlAttrs.class "cursor-pointer bg-transparent border-0 text-fg-muted"
            , HtmlAttrs.style "font-size" "14px"
            ]
            [ Html.text "✕" ]
        ]


negateCheckbox : Int -> Int -> Bool -> Html Msg
negateCheckbox groupIdx condIdx negate =
    Html.div
        [ HtmlAttrs.class "flex items-center gap-1 text-xs text-fg"
        , HtmlAttrs.title "Negate this condition"
        ]
        [ ToggleSwitch.view ToggleSwitch.Small
            negate
            (HtmlEvents.onClick (SetNegate groupIdx condIdx (not negate)))
        , Html.text "not"
        ]


htmlSelect : (String -> msg) -> String -> List ( String, String ) -> Html msg
htmlSelect toMsg selected options =
    Html.select
        [ HtmlEvents.onInput toMsg
        , HtmlAttrs.value selected
        , HtmlAttrs.class "edit-base text-xs py-1"
        , HtmlAttrs.style "min-width" "72px"
        ]
        (options
            |> List.map
                (\( value, label ) ->
                    Html.option
                        [ HtmlAttrs.value value, HtmlAttrs.selected (value == selected) ]
                        [ Html.text label ]
                )
        )


valuePicker : List HighlightRule.FacilityOption -> Bool -> Int -> Int -> Condition -> Html Msg
valuePicker facilities isOpen groupIdx condIdx condition =
    let
        options =
            case condition.field of
                HighlightRule.Bases ->
                    facilities |> List.map (\f -> { code = f.code, label = f.name })

                _ ->
                    HighlightRule.fieldOptions condition.field
    in
    case condition.operator of
        HighlightRule.Between ->
            case condition.values of
                [ lo, hi ] ->
                    Html.div [ HtmlAttrs.style "display" "flex", HtmlAttrs.style "align-items" "center", HtmlAttrs.style "gap" "6px" ]
                        [ htmlSelect (SetBetweenValue groupIdx condIdx True) lo (options |> List.map (\o -> ( o.code, o.label )))
                        , Html.span [ HtmlAttrs.class "text-xs text-fg" ] [ Html.text "and" ]
                        , htmlSelect (SetBetweenValue groupIdx condIdx False) hi (options |> List.map (\o -> ( o.code, o.label )))
                        ]

                _ ->
                    Html.text ""

        HighlightRule.OneOf ->
            checklistDropdown isOpen groupIdx condIdx condition options

        HighlightRule.HasOneOf ->
            checklistDropdown isOpen groupIdx condIdx condition options

        _ ->
            htmlSelect
                (SetSingleValue groupIdx condIdx)
                (List.head condition.values |> Maybe.withDefault "")
                (options |> List.map (\o -> ( o.code, o.label )))


{-| A closed-by-default dropdown for "one of" / "has one of" against a field
with potentially dozens of options (e.g. Bases). Showing every checklist
open at once (one per condition) made the dialog grow tall fast, so instead
this renders as a single summary button - like `htmlSelect`'s dropdown -
that expands into the scrollable checklist only while open. `Model.openPicker`
tracks at most one open picker at a time, keyed by `(groupIdx, condIdx)`, so
opening one closes any other.

A native `<select multiple>` was avoided as it needs ctrl/cmd-click and a
fragile `HTMLOptionsCollection` decoder to read back the selection.

The invisible full-screen catcher closes the popup on an outside click. It
sits after the popup in the same wrapper (a sibling, not an ancestor), so
clicks inside the popup never bubble into it and don't need
`stopPropagationOn`.

-}
checklistDropdown : Bool -> Int -> Int -> Condition -> List { code : String, label : String } -> Html Msg
checklistDropdown isOpen groupIdx condIdx condition options =
    let
        selectedLabels =
            options |> List.filter (\o -> List.member o.code condition.values) |> List.map .label

        summary =
            case selectedLabels of
                [] ->
                    "Select…"

                [ only ] ->
                    only

                [ a, b ] ->
                    a ++ ", " ++ b

                _ ->
                    String.fromInt (List.length selectedLabels) ++ " selected"
    in
    Html.div [ HtmlAttrs.style "position" "relative" ]
        ([ Html.button
            [ HtmlAttrs.type_ "button"
            , HtmlEvents.onClick (ToggleValuePicker groupIdx condIdx)
            , HtmlAttrs.class "edit-base text-xs py-1 cursor-pointer flex items-center gap-2"
            , HtmlAttrs.style "min-width" "160px"
            ]
            [ Html.span
                [ HtmlAttrs.style "flex" "1"
                , HtmlAttrs.style "overflow" "hidden"
                , HtmlAttrs.style "text-overflow" "ellipsis"
                , HtmlAttrs.style "white-space" "nowrap"
                , HtmlAttrs.style "text-align" "left"
                ]
                [ Html.text summary ]
            , Html.i [ HtmlAttrs.class "fa-solid fa-caret-down text-fg-muted", HtmlAttrs.style "font-size" "10px" ] []
            ]
         ]
            ++ (if isOpen then
                    [ Html.div
                        [ HtmlAttrs.style "position" "fixed"
                        , HtmlAttrs.style "inset" "0"
                        , HtmlAttrs.style "z-index" "60"
                        , HtmlEvents.onClick CloseValuePicker
                        ]
                        []
                    , Html.div
                        [ HtmlAttrs.class "starmap-glass-panel"
                        , HtmlAttrs.style "position" "absolute"
                        , HtmlAttrs.style "top" "100%"
                        , HtmlAttrs.style "left" "0"
                        , HtmlAttrs.style "margin-top" "4px"
                        , HtmlAttrs.style "z-index" "61"
                        , HtmlAttrs.style "display" "flex"
                        , HtmlAttrs.style "flex-direction" "column"
                        , HtmlAttrs.style "max-height" "180px"
                        , HtmlAttrs.style "overflow-y" "auto"
                        , HtmlAttrs.style "min-width" "160px"
                        , HtmlAttrs.style "border-radius" "4px"
                        , HtmlAttrs.style "padding" "4px"
                        ]
                        (checklistRows groupIdx condIdx condition options)
                    ]

                else
                    []
               )
        )


checklistRows : Int -> Int -> Condition -> List { code : String, label : String } -> List (Html Msg)
checklistRows groupIdx condIdx condition options =
    options
        |> List.map
            (\o ->
                let
                    selected =
                        List.member o.code condition.values
                in
                Html.label
                    [ HtmlAttrs.class "flex items-center gap-2 text-xs text-fg cursor-pointer select-none"
                    , HtmlAttrs.style "padding" "3px 4px"
                    , HtmlEvents.onClick (ToggleOneOfValue groupIdx condIdx o.code)
                    ]
                    [ Html.span
                        [ HtmlAttrs.class
                            ("flex items-center justify-center rounded border flex-shrink-0 "
                                ++ (if selected then
                                        "bg-highlight border-highlight"

                                    else
                                        "border-outline"
                                   )
                            )
                        , HtmlAttrs.style "width" "14px"
                        , HtmlAttrs.style "height" "14px"
                        ]
                        [ if selected then
                            Html.i [ HtmlAttrs.class "fa-solid fa-check", HtmlAttrs.style "font-size" "9px", HtmlAttrs.style "color" "var(--color-bg)" ] []

                          else
                            Html.text ""
                        ]
                    , Html.text o.label
                    ]
            )


actionsRow : Html Msg
actionsRow =
    Html.div [ HtmlAttrs.style "display" "flex", HtmlAttrs.style "gap" "8px", HtmlAttrs.style "justify-content" "flex-end" ]
        [ Html.button
            [ HtmlAttrs.type_ "button"
            , HtmlAttrs.class "btn btn-sm"
            , HtmlEvents.onClick Cancel
            ]
            [ Html.text "Cancel" ]
        , Html.button
            [ HtmlAttrs.type_ "button"
            , HtmlAttrs.class "btn btn-primary btn-sm"
            , HtmlEvents.onClick Save
            ]
            [ Html.text "Save" ]
        ]
