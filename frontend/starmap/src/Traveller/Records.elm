module Traveller.Records exposing (Records, empty, fromHtml, view)

{-| Survey Records (player notes) and Classified Records (referee notes) for a body.
Both arrive from the server as sanitised Markdown HTML. The server only sends the
classified records to the referee, so the view simply shows whichever are present.
-}

import Html exposing (Html, text)
import Html.Attributes as HtmlAttrs


type alias Records =
    { surveyHtml : Maybe String
    , classifiedHtml : Maybe String
    }


empty : Records
empty =
    { surveyHtml = Nothing, classifiedHtml = Nothing }


fromHtml : Maybe String -> Maybe String -> Records
fromHtml survey classified =
    { surveyHtml = survey, classifiedHtml = classified }


{-| The notes tab content. Survey Records always shows (with a placeholder when empty);
Classified Records only shows when the server sent it.
-}
view : Records -> Html msg
view records =
    Html.div [ HtmlAttrs.style "display" "flex", HtmlAttrs.style "flex-direction" "column", HtmlAttrs.style "gap" "16px" ]
        (viewSection "Survey Records" True records.surveyHtml
            :: List.filterMap identity
                [ records.classifiedHtml
                    |> Maybe.map (\html -> viewSection "Classified Records" False (Just html))
                ]
        )


viewSection : String -> Bool -> Maybe String -> Html msg
viewSection heading showPlaceholder maybeHtml =
    let
        body =
            case Maybe.map String.trim maybeHtml of
                Just html ->
                    if String.isEmpty html then
                        placeholder showPlaceholder

                    else
                        Html.node "html-content"
                            [ HtmlAttrs.class "prose text-sm text-fg-bright"
                            , HtmlAttrs.style "display" "block"
                            , HtmlAttrs.attribute "html" html
                            ]
                            []

                Nothing ->
                    placeholder showPlaceholder
    in
    Html.div []
        [ Html.div
            [ HtmlAttrs.class "text-xs uppercase"
            , HtmlAttrs.style "letter-spacing" "0.18em"
            , HtmlAttrs.style "color" "var(--color-fg-muted)"
            , HtmlAttrs.style "padding-bottom" "6px"
            ]
            [ text heading ]
        , body
        ]


placeholder : Bool -> Html msg
placeholder show =
    if show then
        Html.span [ HtmlAttrs.class "text-xs text-fg-muted italic" ] [ text "No findings reported." ]

    else
        text ""
