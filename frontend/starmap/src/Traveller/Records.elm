module Traveller.Records exposing (Records, empty, fromHtml, view, viewForReferee, withTags, viewTags, viewEditor)

{-| Survey Records (player notes) and Classified Records (referee notes) for a body.
Both arrive from the server as sanitised Markdown HTML. The server only sends the
classified records to the referee, so the view simply shows whichever are present.
-}

import Html exposing (Html, text)
import Html.Attributes as HtmlAttrs
import Url


type alias Records =
    { surveyHtml : Maybe String
    , tags : List String
    , classifiedHtml : Maybe String
    }


empty : Records
empty =
    { surveyHtml = Nothing, classifiedHtml = Nothing, tags = [] }


fromHtml : Maybe String -> Maybe String -> Records
fromHtml survey classified =
    { surveyHtml = survey, classifiedHtml = classified, tags = [] }


withTags : Maybe (List String) -> Records -> Records
withTags tags records =
    { records | tags = Maybe.withDefault [] tags }


{-| The notes tab content. Survey Records always shows (with a placeholder when empty);
Classified Records only shows when the server sent it.
-}
view : Records -> Html msg
view records =
    viewForReferee False records


{-| Referees see both sections even when no classified text has been entered.
The API remains responsible for withholding classified text from players.
-}
viewForReferee : Bool -> Records -> Html msg
viewForReferee isReferee records =
    Html.div [ HtmlAttrs.style "display" "flex", HtmlAttrs.style "flex-direction" "column", HtmlAttrs.style "gap" "16px" ]
        ( (if isReferee then viewTags records else text "")
            :: viewSection "Survey Records" True records.surveyHtml
            :: (if isReferee || records.classifiedHtml /= Nothing then
                    [ viewSection "Classified Records" True records.classifiedHtml ]

                else
                    []
               )
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


viewTags : Records -> Html msg
viewTags records =
    Html.div [ HtmlAttrs.class "flex flex-wrap gap-2", HtmlAttrs.attribute "aria-label" "Tags" ]
        (List.map (\tag -> Html.a [ HtmlAttrs.class "tag-chip", HtmlAttrs.target "_self", HtmlAttrs.href ("tags/show?name=" ++ Url.percentEncode tag) ] [ Html.i [ HtmlAttrs.class "fa-regular fa-tag tag-chip-icon", HtmlAttrs.attribute "aria-hidden" "true" ] [], Html.span [] [ text tag ] ]) (List.sortBy String.toLower records.tags))


viewEditor : String -> Int -> String -> Html msg
viewEditor recordType recordId context =
    Html.node "turbo-frame"
        [ HtmlAttrs.id ("starmap_tags_" ++ recordType ++ "_" ++ String.fromInt recordId ++ "_" ++ context)
        , HtmlAttrs.attribute "src" ("object_tags?record_type=" ++ Url.percentEncode recordType ++ "&record_id=" ++ String.fromInt recordId ++ "&tag_context=" ++ context)
        ]
        []
