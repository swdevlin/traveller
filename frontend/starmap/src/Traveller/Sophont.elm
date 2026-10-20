module Traveller.Sophont exposing (Sophont, codec, view, viewModal)

{-| A native species of a world. Clicking the name opens a modal with its notes:
the referee receives both note fields from the server, players only the player
notes, so the modal simply shows whichever are present.
-}

import Codec exposing (Codec)
import Html exposing (Html, text)
import Html.Attributes as HtmlAttrs
import Html.Events
import Json.Decode as JsDecode


type alias Sophont =
    { id : Int
    , name : String
    , playerNotesHtml : Maybe String
    , refereeNotesHtml : Maybe String
    , pictureUrl : Maybe String
    , referenceUrl : Maybe String
    }


codec : Codec Sophont
codec =
    Codec.object Sophont
        |> Codec.field "id" .id Codec.int
        |> Codec.field "name" .name Codec.string
        |> Codec.optionalNullableField "player_notes_html" .playerNotesHtml Codec.string
        |> Codec.optionalNullableField "referee_notes_html" .refereeNotesHtml Codec.string
        |> Codec.optionalNullableField "picture_url" .pictureUrl Codec.string
        |> Codec.optionalNullableField "reference_url" .referenceUrl Codec.string
        |> Codec.buildObject


{-| The sophont's name, as a link-styled button that asks for its modal to open.
-}
view : (Sophont -> msg) -> Sophont -> Html msg
view onOpen sophont =
    Html.button
        [ HtmlAttrs.type_ "button"
        , HtmlAttrs.class "cursor-pointer text-left"
        , HtmlAttrs.style "background" "none"
        , HtmlAttrs.style "border" "none"
        , HtmlAttrs.style "padding" "0"
        , HtmlAttrs.style "color" "inherit"
        , HtmlAttrs.style "font" "inherit"
        , HtmlAttrs.style "text-decoration" "underline dotted"
        , Html.Events.onClick (onOpen sophont)
        ]
        [ text sophont.name ]


{-| The notes modal, in the same visual style as the other starmap modals
(dimmed backdrop, centred glass panel, backdrop click closes).
-}
viewModal : msg -> msg -> Sophont -> Html msg
viewModal closeMsg noOpMsg sophont =
    let
        notes =
            case List.filterMap identity [ viewNotes "Referee notes" sophont.refereeNotesHtml, viewNotes "Player notes" sophont.playerNotesHtml ] of
                [] ->
                    [ Html.span [ HtmlAttrs.class "text-xs text-fg-muted" ] [ text "No notes recorded." ] ]

                found ->
                    found

        wide =
            sophont.pictureUrl /= Nothing
    in
    Html.div
        [ HtmlAttrs.style "position" "fixed"
        , HtmlAttrs.style "inset" "0"
        , HtmlAttrs.style "z-index" "1500"
        , HtmlAttrs.style "display" "flex"
        , HtmlAttrs.style "align-items" "center"
        , HtmlAttrs.style "justify-content" "center"
        , HtmlAttrs.style "background-color" "color-mix(in srgb, var(--color-bg) 30%, transparent)"
        , Html.Events.onClick closeMsg
        ]
        [ Html.div
            [ HtmlAttrs.class "starmap-glass-panel"
            , Html.Events.stopPropagationOn "click" (JsDecode.succeed ( noOpMsg, True ))
            , HtmlAttrs.style "display" "flex"
            , HtmlAttrs.style "flex-direction" "column"
            , HtmlAttrs.style "gap" "12px"
            , HtmlAttrs.style "border-radius" "6px"
            , HtmlAttrs.style "box-shadow" "0 8px 32px rgba(0, 0, 0, 0.25)"
            , HtmlAttrs.style "padding" "20px"
            , HtmlAttrs.style "width" "100%"
            , HtmlAttrs.style "max-width"
                (if wide then
                    "760px"

                 else
                    "480px"
                )
            , HtmlAttrs.style "max-height" "80vh"
            , HtmlAttrs.style "overflow-y" "auto"
            ]
            [ Html.div [ HtmlAttrs.style "display" "flex", HtmlAttrs.style "justify-content" "space-between", HtmlAttrs.style "align-items" "center" ]
                [ Html.span [ HtmlAttrs.class "text-sm font-bold text-fg-bright" ] [ text sophont.name ]
                , Html.button
                    [ HtmlAttrs.type_ "button"
                    , HtmlAttrs.class "starmap-modal-close cursor-pointer text-fg-muted"
                    , Html.Events.onClick closeMsg
                    ]
                    [ text "✕" ]
                ]
            , Html.div
                [ HtmlAttrs.style "display" "grid"
                , HtmlAttrs.style "grid-template-columns"
                    (if sophont.pictureUrl == Nothing then
                        "1fr"

                     else
                        "minmax(0, 1fr) minmax(0, 1fr)"
                    )
                , HtmlAttrs.style "gap" "16px"
                , HtmlAttrs.style "align-items" "start"
                ]
                (Html.div [ HtmlAttrs.style "display" "flex", HtmlAttrs.style "flex-direction" "column", HtmlAttrs.style "gap" "12px" ]
                    (notes ++ viewReference sophont.referenceUrl)
                    :: (case sophont.pictureUrl of
                            Just url ->
                                [ Html.a
                                    [ HtmlAttrs.href url
                                    , HtmlAttrs.target "_blank"
                                    , HtmlAttrs.rel "noopener"
                                    , HtmlAttrs.title "Open the full size picture in a new window"
                                    , HtmlAttrs.style "display" "block"
                                    , HtmlAttrs.style "cursor" "zoom-in"
                                    ]
                                    [ Html.img
                                        [ HtmlAttrs.src url
                                        , HtmlAttrs.alt sophont.name
                                        , HtmlAttrs.style "display" "block"
                                        , HtmlAttrs.style "width" "100%"
                                        , HtmlAttrs.style "max-height" "50vh"
                                        , HtmlAttrs.style "object-fit" "contain"
                                        , HtmlAttrs.style "border-radius" "4px"
                                        ]
                                        []
                                    ]
                                ]

                            Nothing ->
                                []
                       )
                )
            ]
        ]


{-| `html` is server-rendered, sanitised Markdown (see `sophonts/_sophont.json.jbuilder`), set via
the `html-content` custom element defined in `app/javascript/starmap.js`.
-}
viewNotes : String -> Maybe String -> Maybe (Html msg)
viewNotes heading maybeHtml =
    maybeHtml
        |> Maybe.map String.trim
        |> Maybe.andThen
            (\html ->
                if String.isEmpty html then
                    Nothing

                else
                    Just
                        (Html.div []
                            [ Html.div
                                [ HtmlAttrs.class "text-xs"
                                , HtmlAttrs.style "font-size" "11px"
                                , HtmlAttrs.style "font-weight" "bold"
                                , HtmlAttrs.style "color" "var(--color-fg-muted)"
                                ]
                                [ text heading ]
                            , Html.node "html-content"
                                [ HtmlAttrs.class "prose text-sm text-fg-bright"
                                , HtmlAttrs.style "display" "block"
                                , HtmlAttrs.attribute "html" html
                                ]
                                []
                            ]
                        )
            )


viewReference : Maybe String -> List (Html msg)
viewReference maybeUrl =
    case maybeUrl of
        Just url ->
            [ Html.a
                [ HtmlAttrs.href url
                , HtmlAttrs.target "_blank"
                , HtmlAttrs.rel "noopener"
                , HtmlAttrs.class "text-xs link-traveller"
                ]
                [ text "Reference" ]
            ]

        Nothing ->
            []
