module Traveller.RulebookSearch exposing
    ( ExcerptSegment
    , Model
    , Msg(..)
    , RulebookGroup
    , RulebookHit
    , groupCodec
    , init
    , update
    , view
    )

{-| Rulebook full-text search — a slide-in panel, independent of hex/system
selection, backed by the Rails app's campaign-scoped `/c/:campaign_slug/api/rulebooks/search`
endpoint. Only rulebooks the campaign's referee has enabled are ever returned;
if this panel is opened while not logged in as that campaign's referee, only
the subset also marked player-searchable comes back.
-}

import Codec exposing (Codec)
import HostConfig exposing (HostConfig)
import Html exposing (Html)
import Html.Attributes as HtmlAttrs
import Html.Events
import Http
import Json.Decode as JsDecode
import RemoteData exposing (RemoteData(..))
import Set exposing (Set)
import Url.Builder



-- ── DATA ─────────────────────────────────────────────────────────────────────


type alias ExcerptSegment =
    { text : String
    , highlighted : Bool
    }


excerptSegmentCodec : Codec ExcerptSegment
excerptSegmentCodec =
    Codec.object ExcerptSegment
        |> Codec.field "text" .text Codec.string
        |> Codec.field "highlighted" .highlighted Codec.bool
        |> Codec.buildObject


type alias RulebookHit =
    { printedPageLabel : String
    , rank : Float
    , headingSegments : List ExcerptSegment
    , excerptSegments : List ExcerptSegment
    }


hitCodec : Codec RulebookHit
hitCodec =
    Codec.object RulebookHit
        |> Codec.field "printed_page_label" .printedPageLabel Codec.string
        |> Codec.field "rank" .rank Codec.float
        |> Codec.field "heading_segments" .headingSegments (Codec.list excerptSegmentCodec)
        |> Codec.field "excerpt_segments" .excerptSegments (Codec.list excerptSegmentCodec)
        |> Codec.buildObject


type alias RulebookGroup =
    { rulebookId : Int
    , title : String
    , shortTitle : Maybe String
    , edition : Maybe String
    , category : String
    , totalMatches : Int
    , hits : List RulebookHit
    }


groupCodec : Codec RulebookGroup
groupCodec =
    Codec.object RulebookGroup
        |> Codec.field "rulebook_id" .rulebookId Codec.int
        |> Codec.field "title" .title Codec.string
        |> Codec.field "short_title" .shortTitle (Codec.maybe Codec.string)
        |> Codec.field "edition" .edition (Codec.maybe Codec.string)
        |> Codec.field "category" .category Codec.string
        |> Codec.field "total_matches" .totalMatches Codec.int
        |> Codec.field "hits" .hits (Codec.list hitCodec)
        |> Codec.buildObject



-- ── MODEL ────────────────────────────────────────────────────────────────────


type alias Model =
    { isOpen : Bool
    , query : String
    , results : RemoteData Http.Error (List RulebookGroup)
    , expandedRulebookIds : Set Int
    }


{-| Every group starts closed, matching the Rails HTML search page.
-}
init : Model
init =
    { isOpen = False
    , query = ""
    , results = NotAsked
    , expandedRulebookIds = Set.empty
    }



-- ── UPDATE ───────────────────────────────────────────────────────────────────


type Msg
    = ToggleOpen
    | QueryChanged String
    | RunSearch
    | SearchResultsReceived (Result Http.Error (List RulebookGroup))
    | ToggleGroup Int


{-| Fetched with a slightly larger per-rulebook limit than the Rails HTML page's
initial view, so "show more" can reveal already-fetched hits locally rather than
triggering a second HTTP round trip per panel interaction.
-}
perRulebookLimit : Int
perRulebookLimit =
    5


update : HostConfig -> Msg -> Model -> ( Model, Cmd Msg )
update hostConfig msg model =
    case msg of
        ToggleOpen ->
            ( { model | isOpen = not model.isOpen }, Cmd.none )

        QueryChanged query ->
            ( { model | query = query }, Cmd.none )

        RunSearch ->
            if String.trim model.query == "" then
                ( { model | results = NotAsked, expandedRulebookIds = Set.empty }, Cmd.none )

            else
                ( { model | results = Loading, expandedRulebookIds = Set.empty }, sendSearchRequest hostConfig model.query )

        SearchResultsReceived (Ok groups) ->
            ( { model | results = Success groups }, Cmd.none )

        SearchResultsReceived (Err err) ->
            ( { model | results = Failure err }, Cmd.none )

        ToggleGroup rulebookId ->
            let
                toggle =
                    if Set.member rulebookId model.expandedRulebookIds then
                        Set.remove rulebookId

                    else
                        Set.insert rulebookId
            in
            ( { model | expandedRulebookIds = toggle model.expandedRulebookIds }, Cmd.none )


sendSearchRequest : HostConfig -> String -> Cmd Msg
sendSearchRequest hostConfig query =
    let
        ( urlHostRoot, urlHostPath ) =
            hostConfig

        url =
            Url.Builder.crossOrigin
                urlHostRoot
                (urlHostPath ++ [ "rulebooks", "search" ])
                [ Url.Builder.string "q" query
                , Url.Builder.int "per_rulebook_limit" perRulebookLimit
                ]

        decoder : JsDecode.Decoder (List RulebookGroup)
        decoder =
            Codec.list groupCodec |> Codec.decoder
    in
    Http.request
        { method = "GET"
        , headers = []
        , url = url
        , body = Http.emptyBody
        , expect = Http.expectJson SearchResultsReceived decoder
        , timeout = Just 10000
        , tracker = Nothing
        }



-- ── VIEW ─────────────────────────────────────────────────────────────────────


view : Model -> Html Msg
view model =
    if not model.isOpen then
        Html.text ""

    else
        Html.div
            [ HtmlAttrs.class "sidebar-panel"
            , HtmlAttrs.style "position" "fixed"
            , HtmlAttrs.style "top" "0"
            , HtmlAttrs.style "left" "0"
            , HtmlAttrs.style "bottom" "0"
            , HtmlAttrs.style "width" "380px"
            , HtmlAttrs.style "background-color" "var(--color-panel)"
            , HtmlAttrs.style "border-right" "1px solid var(--color-outline)"
            , HtmlAttrs.style "z-index" "300"
            , HtmlAttrs.style "display" "flex"
            , HtmlAttrs.style "flex-direction" "column"
            , HtmlAttrs.style "overflow-y" "auto"
            ]
            [ viewHeader
            , viewSearchBox model.query
            , viewResults model.expandedRulebookIds model.results
            ]


viewHeader : Html Msg
viewHeader =
    Html.div
        [ HtmlAttrs.style "display" "flex"
        , HtmlAttrs.style "align-items" "center"
        , HtmlAttrs.style "justify-content" "space-between"
        , HtmlAttrs.style "padding" "12px"
        , HtmlAttrs.style "border-bottom" "1px solid var(--color-outline)"
        ]
        [ Html.span
            [ HtmlAttrs.style "font-size" "16px"
            , HtmlAttrs.style "color" "var(--color-highlight)"
            , HtmlAttrs.style "font-weight" "700"
            ]
            [ Html.i [ HtmlAttrs.class "fa-regular fa-book", HtmlAttrs.style "margin-right" "8px" ] []
            , Html.text "Reference"
            ]
        , Html.span
            [ HtmlAttrs.style "cursor" "pointer"
            , HtmlAttrs.style "color" "var(--color-fg-muted)"
            , Html.Events.onClick ToggleOpen
            ]
            [ Html.i [ HtmlAttrs.class "fa-regular fa-xmark", HtmlAttrs.style "font-size" "16px" ] [] ]
        ]


viewSearchBox : String -> Html Msg
viewSearchBox query =
    Html.div
        [ HtmlAttrs.style "display" "flex"
        , HtmlAttrs.style "gap" "6px"
        , HtmlAttrs.style "padding" "12px"
        ]
        [ Html.input
            [ HtmlAttrs.type_ "text"
            , HtmlAttrs.value query
            , HtmlAttrs.placeholder "Search rulebooks…"
            , HtmlAttrs.style "flex" "1"
            , HtmlAttrs.style "font-size" "13px"
            , HtmlAttrs.style "color" "var(--color-fg-bright)"
            , HtmlAttrs.style "background-color" "var(--color-panel-muted)"
            , HtmlAttrs.style "border" "1px solid var(--color-outline)"
            , HtmlAttrs.style "border-radius" "4px"
            , HtmlAttrs.style "padding" "6px 8px"
            , Html.Events.onInput QueryChanged
            , Html.Events.stopPropagationOn "keydown"
                (JsDecode.field "key" JsDecode.string
                    |> JsDecode.map
                        (\key ->
                            if key == "Enter" then
                                ( RunSearch, True )

                            else
                                ( QueryChanged query, False )
                        )
                )
            ]
            []
        , Html.button
            [ HtmlAttrs.style "font-size" "13px"
            , HtmlAttrs.style "color" "var(--color-fg-bright)"
            , HtmlAttrs.style "background-color" "var(--color-button-primary)"
            , HtmlAttrs.style "border" "none"
            , HtmlAttrs.style "border-radius" "4px"
            , HtmlAttrs.style "padding" "6px 10px"
            , HtmlAttrs.style "cursor" "pointer"
            , Html.Events.onClick RunSearch
            ]
            [ Html.i [ HtmlAttrs.class "fa-regular fa-magnifying-glass" ] [] ]
        ]


viewResults : Set Int -> RemoteData Http.Error (List RulebookGroup) -> Html Msg
viewResults expandedRulebookIds results =
    Html.div
        [ HtmlAttrs.style "padding" "0 12px 12px 12px"
        , HtmlAttrs.style "display" "flex"
        , HtmlAttrs.style "flex-direction" "column"
        , HtmlAttrs.style "gap" "12px"
        ]
        (case results of
            NotAsked ->
                [ viewHint "Enter a search term to search every imported rulebook." ]

            Loading ->
                [ viewHint "Searching…" ]

            Failure _ ->
                [ viewHint "Search failed. Try again." ]

            Success [] ->
                [ viewHint "No matches. Try different terms." ]

            Success groups ->
                List.map (viewGroup expandedRulebookIds) groups
        )


viewHint : String -> Html Msg
viewHint message =
    Html.div
        [ HtmlAttrs.style "font-size" "12px"
        , HtmlAttrs.style "color" "var(--color-fg-muted)"
        , HtmlAttrs.style "padding" "8px 0"
        ]
        [ Html.text message ]


viewGroup : Set Int -> RulebookGroup -> Html Msg
viewGroup expandedRulebookIds group =
    let
        isExpanded =
            Set.member group.rulebookId expandedRulebookIds
    in
    Html.div
        [ HtmlAttrs.style "border" "1px solid var(--color-outline)"
        , HtmlAttrs.style "border-radius" "8px"
        , HtmlAttrs.style "overflow" "hidden"
        ]
        [ Html.div
            [ HtmlAttrs.style "display" "flex"
            , HtmlAttrs.style "align-items" "center"
            , HtmlAttrs.style "justify-content" "space-between"
            , HtmlAttrs.style "padding" "8px 10px"
            , HtmlAttrs.style "background-color" "var(--color-panel-muted)"
            , HtmlAttrs.style "font-size" "13px"
            , HtmlAttrs.style "color" "var(--color-fg-bright)"
            , HtmlAttrs.style "cursor" "pointer"
            , Html.Events.onClick (ToggleGroup group.rulebookId)
            ]
            [ Html.span []
                (Html.text group.title
                    :: (case Maybe.map String.trim group.edition of
                            Just edition ->
                                if String.isEmpty edition then
                                    []

                                else
                                    [ Html.text (" (" ++ edition ++ ")") ]

                            Nothing ->
                                []
                       )
                )
            , Html.span
                [ HtmlAttrs.style "display" "flex"
                , HtmlAttrs.style "align-items" "center"
                , HtmlAttrs.style "gap" "8px"
                ]
                [ Html.span
                    [ HtmlAttrs.style "font-size" "11px", HtmlAttrs.style "color" "var(--color-fg-muted)" ]
                    [ Html.text (String.fromInt group.totalMatches ++ " match" ++ pluralSuffix group.totalMatches) ]
                , Html.i
                    [ HtmlAttrs.class
                        (if isExpanded then
                            "fa-regular fa-square-chevron-up"

                         else
                            "fa-regular fa-square-chevron-down"
                        )
                    ]
                    []
                ]
            ]
        , if isExpanded then
            Html.div [] (List.map viewHit group.hits)

          else
            Html.text ""
        ]


pluralSuffix : Int -> String
pluralSuffix count =
    if count == 1 then
        ""

    else
        "es"


viewHit : RulebookHit -> Html Msg
viewHit hit =
    Html.div
        [ HtmlAttrs.style "padding" "8px 10px"
        , HtmlAttrs.style "border-top" "1px solid var(--color-outline)"
        ]
        [ Html.div
            [ HtmlAttrs.style "font-size" "11px"
            , HtmlAttrs.style "color" "var(--color-fg-muted)"
            , HtmlAttrs.style "margin-bottom" "4px"
            ]
            [ Html.i [ HtmlAttrs.class "fa-regular fa-file-lines", HtmlAttrs.style "margin-right" "6px" ] []
            , Html.text hit.printedPageLabel
            ]
        , if List.isEmpty hit.headingSegments then
            Html.text ""

          else
            Html.p
                [ HtmlAttrs.style "font-size" "11px"
                , HtmlAttrs.style "font-weight" "600"
                , HtmlAttrs.style "text-transform" "uppercase"
                , HtmlAttrs.style "letter-spacing" "0.03em"
                , HtmlAttrs.style "color" "var(--color-fg-muted)"
                , HtmlAttrs.style "margin" "0 0 2px 0"
                ]
                (List.map viewExcerptSegment hit.headingSegments)
        , Html.p
            [ HtmlAttrs.style "font-size" "12px"
            , HtmlAttrs.style "color" "var(--color-fg)"
            , HtmlAttrs.style "line-height" "1.5"
            , HtmlAttrs.style "margin" "0"
            ]
            (List.map viewExcerptSegment hit.excerptSegments)
        ]


viewExcerptSegment : ExcerptSegment -> Html Msg
viewExcerptSegment segment =
    if segment.highlighted then
        Html.mark
            [ HtmlAttrs.style "background-color" "transparent"
            , HtmlAttrs.style "color" "var(--color-highlight)"
            , HtmlAttrs.style "font-weight" "600"
            ]
            [ Html.text segment.text ]

    else
        Html.text segment.text