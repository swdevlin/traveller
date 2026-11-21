module Traveller.TradeSynergyPanel exposing (Config, Model, Msg(..), init, update, view)

{-| A referee-only modal showing which neighbouring worlds make good trade
partners for the selected system. The jump range is chosen here, and the
result can be viewed as a table (with per-good detail rows) or as a hex map. All scoring is done by `Api::TradeSynergiesController`; this module only
fetches and displays.

Like `Traveller.CommerceForm`, this module owns its own HTTP round trip, so
`update` returns a `Cmd Msg` and the parent wires it in with `Cmd.map`. The
parent handles `Cancel` (close) and `ZoomTo` (close and centre the map).

-}

import HostConfig exposing (HostConfig)
import Html exposing (Html)
import Html.Attributes as HtmlAttrs
import Html.Events as HtmlEvents
import Http
import Json.Decode as JsDecode
import RemoteData exposing (RemoteData(..))
import Set exposing (Set)
import Traveller.TradeSynergy as TradeSynergy exposing (Good, Partner, SystemInfo, TradeSynergies)
import Url.Builder


type alias Config =
    { hostConfig : HostConfig
    , defaultJump : Int

    -- Draws the map with the main map's hex renderer; the argument is the
    -- selected partner's system id.
    , renderMap : TradeSynergies -> Maybe Int -> Html Msg
    }


type ViewMode
    = TableView
    | MapView


type SortKey
    = SortDefault
    | SortName
    | SortDistance
    | SortWtn
    | SortOutCount
    | SortInCount
    | SortBtn


type alias Model =
    { systemId : Int
    , jump : Int
    , viewMode : ViewMode
    , result : RemoteData Http.Error TradeSynergies
    , expanded : Set Int
    , selected : Maybe Int
    , sortKey : SortKey
    , sortDescending : Bool
    }


type Msg
    = NoOp
    | Cancel
    | ZoomTo { x : Int, y : Int } -- universal hex address
    | SetJump Int
    | SetViewMode ViewMode
    | GotResult (Result Http.Error TradeSynergies)
    | ToggleRow Int
    | SelectPartner (Maybe Int)
    | SortBy SortKey


maxJump : Int
maxJump =
    6


init : Config -> Int -> ( Model, Cmd Msg )
init config systemId =
    let
        jump =
            clamp 1 maxJump config.defaultJump
    in
    ( { systemId = systemId
      , jump = jump
      , viewMode = TableView
      , result = Loading
      , expanded = Set.empty
      , selected = Nothing
      , sortKey = SortDefault
      , sortDescending = False
      }
    , sendRequest config.hostConfig systemId jump
    )


sendRequest : HostConfig -> Int -> Int -> Cmd Msg
sendRequest ( urlRoot, urlPath ) systemId jump =
    Http.request
        { method = "GET"
        , headers = []
        , url =
            Url.Builder.crossOrigin urlRoot
                (urlPath ++ [ "star_systems", String.fromInt systemId, "trade_synergies" ])
                (TradeSynergy.query jump)
        , body = Http.emptyBody
        , expect = Http.expectJson GotResult TradeSynergy.tradeSynergiesDecoder
        , timeout = Just 15000
        , tracker = Nothing
        }


update : Config -> Msg -> Model -> ( Model, Cmd Msg )
update config msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        Cancel ->
            ( model, Cmd.none )

        ZoomTo _ ->
            ( model, Cmd.none )

        SetJump jump ->
            if jump == model.jump then
                ( model, Cmd.none )

            else
                ( { model | jump = jump, result = Loading, expanded = Set.empty, selected = Nothing }
                , sendRequest config.hostConfig model.systemId jump
                )

        SetViewMode mode ->
            ( { model | viewMode = mode }, Cmd.none )

        GotResult result ->
            ( { model | result = RemoteData.fromResult result }, Cmd.none )

        ToggleRow id ->
            ( { model
                | expanded =
                    if Set.member id model.expanded then
                        Set.remove id model.expanded

                    else
                        Set.insert id model.expanded
              }
            , Cmd.none
            )

        SelectPartner selected ->
            ( { model | selected = selected }, Cmd.none )

        SortBy key ->
            if model.sortKey == key then
                ( { model | sortDescending = not model.sortDescending }, Cmd.none )

            else
                ( { model | sortKey = key, sortDescending = key /= SortName && key /= SortDistance }, Cmd.none )



-- VIEW


view : Config -> Model -> Html Msg
view config model =
    Html.div
        [ HtmlAttrs.class "analysis-backdrop"
        , HtmlAttrs.style "position" "fixed"
        , HtmlAttrs.style "inset" "0"
        , HtmlAttrs.style "z-index" "200"
        , HtmlAttrs.style "display" "flex"
        , HtmlAttrs.style "align-items" "center"
        , HtmlAttrs.style "justify-content" "center"
        , HtmlEvents.onClick Cancel
        ]
        [ Html.div
            [ HtmlAttrs.class "analysis-console trade-console"
            , HtmlAttrs.attribute "role" "dialog"
            , HtmlAttrs.attribute "aria-modal" "true"
            , HtmlAttrs.attribute "aria-label" "Trade"
            , HtmlEvents.stopPropagationOn "click" (JsDecode.succeed ( NoOp, True ))
            ]
            [ viewHeader model
            , viewOrigin model
            , viewControls model
            , Html.div [ HtmlAttrs.class "trade-body" ] [ viewBody config model ]
            ]
        ]


viewHeader : Model -> Html Msg
viewHeader model =
    let
        title =
            case model.result of
                Success data ->
                    systemName data.origin ++ " Trade"

                _ ->
                    "Trade"
    in
    Html.div [ HtmlAttrs.class "analysis-header" ]
        [ Html.h2 [ HtmlAttrs.class "analysis-title" ] [ Html.text title ]
        , Html.button
            [ HtmlAttrs.type_ "button"
            , HtmlAttrs.class "analysis-close"
            , HtmlAttrs.attribute "aria-label" "Close trade"
            , HtmlEvents.onClick Cancel
            ]
            [ icon "fa-solid fa-xmark" ]
        ]


viewOrigin : Model -> Html Msg
viewOrigin model =
    case model.result of
        Success data ->
            Html.div [ HtmlAttrs.class "trade-readout" ]
                [ readoutField "Hex" [ Html.text (data.origin.sector ++ " " ++ data.origin.hex) ]
                , readoutField "UWP" [ Html.text (Maybe.withDefault "" data.origin.uwp) ]
                , readoutField "WTN" [ Html.text (wtnLabel data.origin.wtn) ]
                , readoutField "Trade codes" [ tradeCodeChips data.origin.tradeCodes ]
                ]

        _ ->
            Html.text ""


readoutField : String -> List (Html Msg) -> Html Msg
readoutField label children =
    Html.div [ HtmlAttrs.class "trade-field" ]
        [ Html.span [ HtmlAttrs.class "trade-field-label" ] [ Html.text label ]
        , Html.span [ HtmlAttrs.class "trade-field-value" ] children
        ]


tradeCodeChips : List String -> Html Msg
tradeCodeChips codes =
    if List.isEmpty codes then
        Html.span [ HtmlAttrs.class "trade-none" ] [ Html.text "none" ]

    else
        Html.span [ HtmlAttrs.class "trade-codes" ]
            (List.map (\code -> Html.span [ HtmlAttrs.class "trade-code" ] [ Html.text code ]) codes)


viewControls : Model -> Html Msg
viewControls model =
    Html.div [ HtmlAttrs.class "trade-controls" ]
        [ Html.div [ HtmlAttrs.class "trade-segment", HtmlAttrs.attribute "role" "group", HtmlAttrs.attribute "aria-label" "Jump range" ]
            (Html.span [ HtmlAttrs.class "trade-segment-label" ] [ Html.text "Jump range" ]
                :: List.map (\n -> toggleButton ("J" ++ String.fromInt n) (n == model.jump) (SetJump n)) (List.range 1 maxJump)
            )
        , Html.div [ HtmlAttrs.class "trade-segment", HtmlAttrs.attribute "role" "group", HtmlAttrs.attribute "aria-label" "View" ]
            [ toggleButton "Table" (model.viewMode == TableView) (SetViewMode TableView)
            , toggleButton "Map" (model.viewMode == MapView) (SetViewMode MapView)
            ]
        ]


toggleButton : String -> Bool -> Msg -> Html Msg
toggleButton label active msg =
    Html.button
        [ HtmlAttrs.type_ "button"
        , HtmlEvents.onClick msg
        , HtmlAttrs.attribute "aria-pressed"
            (if active then
                "true"

             else
                "false"
            )
        ]
        [ Html.text label ]


viewBody : Config -> Model -> Html Msg
viewBody config model =
    case model.result of
        NotAsked ->
            Html.text ""

        Loading ->
            note "" "Calculating trade synergies…"

        Failure _ ->
            note "is-error" "Could not load trade synergies. Please try again."

        Success data ->
            if List.isEmpty data.partners then
                note "" ("No other systems with a main world within Jump " ++ String.fromInt data.jump ++ ".")

            else
                case model.viewMode of
                    TableView ->
                        if List.any hasSynergy data.partners then
                            viewTable model data

                        else
                            note "" ("No trade synergies with any system within Jump " ++ String.fromInt data.jump ++ ".")

                    MapView ->
                        viewMap config model data


wtnLabel : Maybe Float -> String
wtnLabel wtn =
    case wtn of
        Just value ->
            String.fromFloat (toFloat (round (value * 10)) / 10)

        Nothing ->
            ""


showBtn : TradeSynergies -> Bool
showBtn data =
    List.any (\p -> p.btn /= Nothing) data.partners


{-| The Bilateral Trade Number as a pill, with its classification as plain
text beside it (not part of the pill).
-}
btnPill : TradeSynergy.Btn -> Html Msg
btnPill btn =
    Html.span
        [ HtmlAttrs.class "trade-btn"
        , HtmlAttrs.title "Bilateral Trade Number"
        ]
        [ Html.span [ HtmlAttrs.class "trade-btn-value" ] [ Html.text (String.fromInt btn.value) ]
        , Html.span [ HtmlAttrs.class "trade-btn-label" ] [ Html.text btn.classification ]
        ]


{-| Link to the Rails help page for the BTN house rule; only offered when the
campaign has the rule on.
-}
btnHelpLink : TradeSynergies -> Html Msg
btnHelpLink data =
    case data.btnHelpUrl of
        Just url ->
            Html.a
                [ HtmlAttrs.class "trade-help"
                , HtmlAttrs.href url
                , HtmlAttrs.target "_blank"
                , HtmlAttrs.rel "noopener"
                ]
                [ icon "fa-regular fa-circle-question", Html.text " How BTN is calculated" ]

        Nothing ->
            Html.text ""


hasSynergy : Partner -> Bool
hasSynergy partner =
    partner.system.wtn /= Nothing && partner.outboundCount + partner.inboundCount > 0


note : String -> String -> Html Msg
note extraClass text =
    Html.div [ HtmlAttrs.class ("trade-note " ++ extraClass) ] [ Html.text text ]


systemName : SystemInfo -> String
systemName info =
    info.name |> Maybe.withDefault (info.sector ++ " " ++ info.hex)



-- TABLE


viewTable : Model -> TradeSynergies -> Html Msg
viewTable model data =
    Html.div [ HtmlAttrs.class "trade-scroll" ]
        [ btnHelpLink data
        , Html.table [ HtmlAttrs.class "trade-table" ]
            [ Html.thead []
                [ Html.tr []
                    (List.concat
                        [ [ headerCell False "Name" (Just SortName) model
                          , headerCell False "Hex" Nothing model
                          , headerCell True "Distance" (Just SortDistance) model
                          , headerCell False "UWP" Nothing model
                          ]
                        , if showBtn data then
                            [ headerCell False "BTN" (Just SortBtn) model ]

                          else
                            []
                        , [ headerCell True "WTN" (Just SortWtn) model
                          , headerCell False "Trade codes" Nothing model
                          , headerCell False "Zone" Nothing model
                          , headerCell True "Exports" (Just SortOutCount) model
                          , headerCell True "Imports" (Just SortInCount) model
                          , headerCell True "" Nothing model
                          ]
                        ]
                    )
                ]
            , Html.tbody [] (List.concatMap (viewRow model data.origin) (sortPartners model (List.filter hasSynergy data.partners)))
            ]
        ]


sortPartners : Model -> List Partner -> List Partner
sortPartners model partners =
    let
        sorted =
            case model.sortKey of
                SortDefault ->
                    partners

                SortName ->
                    List.sortBy (\p -> String.toLower (systemName p.system)) partners

                SortDistance ->
                    List.sortBy .distance partners

                SortOutCount ->
                    List.sortBy .outboundCount partners

                SortWtn ->
                    List.sortBy (\p -> Maybe.withDefault 0 p.system.wtn) partners

                SortInCount ->
                    List.sortBy .inboundCount partners

                SortBtn ->
                    List.sortBy (\p -> p.btn |> Maybe.map .value |> Maybe.withDefault 0) partners
    in
    if model.sortDescending && model.sortKey /= SortDefault then
        List.reverse sorted

    else
        sorted


headerCell : Bool -> String -> Maybe SortKey -> Model -> Html Msg
headerCell numeric label sortKey model =
    let
        indicator =
            case sortKey of
                Just key ->
                    if key == model.sortKey then
                        Html.span [ HtmlAttrs.class "trade-sort" ]
                            [ icon
                                (if model.sortDescending then
                                    "fa-solid fa-sort-down"

                                 else
                                    "fa-solid fa-sort-up"
                                )
                            ]

                    else
                        Html.text ""

                Nothing ->
                    Html.text ""

        sortAttrs =
            case sortKey of
                Just key ->
                    [ HtmlEvents.onClick (SortBy key), HtmlAttrs.class "is-sortable" ]

                Nothing ->
                    []
    in
    Html.th
        (HtmlAttrs.classList [ ( "num", numeric ) ] :: sortAttrs)
        [ Html.text label, indicator ]


viewRow : Model -> SystemInfo -> Partner -> List (Html Msg)
viewRow model origin partner =
    let
        isOpen =
            Set.member partner.system.id model.expanded

        mainRow =
            Html.tr
                [ HtmlEvents.onClick (ToggleRow partner.system.id)
                , HtmlAttrs.class "trade-row"
                , HtmlAttrs.classList [ ( "is-open", isOpen ) ]
                ]
                (List.concat
                    [ [ cell False
                            [ Html.span
                                [ HtmlAttrs.class "trade-name"
                                , HtmlAttrs.title "Centre the map on this system"
                                , HtmlEvents.stopPropagationOn "click"
                                    (JsDecode.succeed ( ZoomTo { x = partner.system.originX, y = partner.system.originY }, True ))
                                ]
                                [ Html.text (systemName partner.system) ]
                            ]
                      , cell False [ Html.text partner.system.hex ]
                      , cell True [ Html.text (String.fromInt partner.distance) ]
                      , cell False [ Html.text (Maybe.withDefault "" partner.system.uwp) ]
                      ]
                    , case partner.btn of
                        Just btn ->
                            [ cell False [ btnPill btn ] ]

                        Nothing ->
                            []
                    , [ cell True [ Html.text (wtnLabel partner.system.wtn) ]
                      , cell False [ tradeCodeChips partner.system.tradeCodes ]
                      , cell False [ Html.text (zoneLabel partner.system.travelZone) ]
                      , cell True [ countAndBonus partner.outboundCount partner.outboundBonus ]
                      , cell True [ countAndBonus partner.inboundCount partner.inboundBonus ]
                      , cell True
                            [ Html.span
                                [ HtmlAttrs.class "trade-toggle"
                                , HtmlAttrs.attribute "role" "button"
                                , HtmlAttrs.attribute "aria-expanded"
                                    (if isOpen then
                                        "true"

                                     else
                                        "false"
                                    )
                                , HtmlAttrs.attribute "aria-label" "Show goods"
                                ]
                                [ icon
                                    (if isOpen then
                                        "fa-regular fa-square-chevron-up"

                                     else
                                        "fa-regular fa-square-chevron-down"
                                    )
                                ]
                            ]
                      ]
                    ]
                )
    in
    if isOpen then
        [ mainRow
        , Html.tr [ HtmlAttrs.class "trade-detail" ]
            [ Html.td [ HtmlAttrs.colspan (if partner.btn == Nothing then 10 else 11) ] [ viewGoodsLists origin partner ] ]
        ]

    else
        [ mainRow ]


zoneLabel : Maybe String -> String
zoneLabel zone =
    case zone of
        Just "A" ->
            "Amber"

        Just "R" ->
            "Red"

        _ ->
            ""


{-| "count / bonus", with each number right-aligned in a box as wide as a
two-digit number, so the digits and the slashes line up down the table. Styled
inline so the alignment does not depend on the stylesheet.
-}
countAndBonus : Int -> Int -> Html Msg
countAndBonus count bonus =
    let
        box chars text =
            Html.span
                [ HtmlAttrs.style "display" "inline-block"
                , HtmlAttrs.style "min-width" (String.fromInt chars ++ "ch")
                , HtmlAttrs.style "text-align" "right"
                ]
                [ Html.text text ]
    in
    Html.span [ HtmlAttrs.style "white-space" "pre" ]
        [ box 2 (String.fromInt count)
        , Html.text " / "
        , box 3 (signed bonus)
        ]


cell : Bool -> List (Html Msg) -> Html Msg
cell numeric children =
    Html.td [ HtmlAttrs.classList [ ( "num", numeric ) ] ] children


viewGoodsLists : SystemInfo -> Partner -> Html Msg
viewGoodsLists origin partner =
    Html.div [ HtmlAttrs.class "trade-goods" ]
        [ goodsList (systemName origin) (systemName partner.system) partner.outboundGoods
        , goodsList (systemName partner.system) (systemName origin) partner.inboundGoods
        ]


goodsList : String -> String -> List Good -> Html Msg
goodsList from to goods =
    Html.div []
        [ Html.div
            [ HtmlAttrs.class "trade-goods-title"
            , HtmlAttrs.title ("Each good shows +buy/+sell: the buy DM at " ++ from ++ " (purchase DM less sale DM) and the sell DM at " ++ to ++ " (sale DM less purchase DM). Only goods where the two add up to more than zero are listed.")
            ]
            [ Html.text from, icon "fa-solid fa-arrow-right", Html.text to ]
        , if List.isEmpty goods then
            Html.div [ HtmlAttrs.class "trade-none" ] [ Html.text "No profitable goods" ]

          else
            let
                legal =
                    List.filter (\good -> good.category /= "illegal") goods

                illegal =
                    List.filter (\good -> good.category == "illegal") goods
            in
            Html.ul []
                (List.map (goodItem False) legal
                    ++ List.indexedMap (\index good -> goodItem (index == 0) good) illegal
                )
        ]


signed : Int -> String
signed n =
    if n >= 0 then
        "+" ++ String.fromInt n

    else
        String.fromInt n


goodItem : Bool -> Good -> Html Msg
goodItem firstIllegal good =
    let
        isIllegal =
            good.category == "illegal"
    in
    Html.li [ HtmlAttrs.classList [ ( "is-first-illegal", firstIllegal ) ] ]
        [ Html.span [ HtmlAttrs.class "trade-good-name" ]
            [ Html.span [ HtmlAttrs.class "trade-good-mark" ]
                [ if isIllegal then
                    illegalIcon

                  else
                    Html.text ""
                ]
            , Html.span [] [ Html.text good.name ]
            ]
        , Html.span [ HtmlAttrs.class "trade-bonus" ]
            [ Html.text (signed good.buyDm ++ "/" ++ signed good.sellDm) ]
        ]


{-| Box with a cross, marking an illegal trade good.
-}
illegalIcon : Html Msg
illegalIcon =
    Html.span
        [ HtmlAttrs.class "trade-illegal"
        , HtmlAttrs.title "Illegal trade good"
        , HtmlAttrs.attribute "role" "img"
        , HtmlAttrs.attribute "aria-label" "Illegal trade good"
        ]
        [ icon "fa-kit fa-box-isometric-xmark" ]



-- MAP


{-| The hex grid itself is drawn by the parent with the standard map renderer
(`Config.renderMap`); this adds the legend and the selected system's goods.
-}
viewMap : Config -> Model -> TradeSynergies -> Html Msg
viewMap config model data =
    let
        selectedPartner =
            model.selected
                |> Maybe.andThen (\id -> List.filter (\p -> p.system.id == id) data.partners |> List.head)
    in
    Html.div [ HtmlAttrs.class "trade-map-layout" ]
        [ Html.div [ HtmlAttrs.class "trade-map-pane" ]
            [ config.renderMap data model.selected
            , Html.div [ HtmlAttrs.class "trade-legend" ]
                [ Html.text "Centre: exports / imports, with their total bonus beneath." ]
            ]
        , case selectedPartner of
            Just partner ->
                Html.div [ HtmlAttrs.class "trade-selected" ]
                    [ Html.div [ HtmlAttrs.class "trade-selected-title" ]
                        [ Html.span [] [ Html.text (systemName partner.system) ]
                        , Html.span [ HtmlAttrs.class "trade-category" ]
                            [ Html.text (" · " ++ partner.system.hex ++ " · Jump " ++ String.fromInt partner.distance ++ " · " ++ Maybe.withDefault "" partner.system.uwp) ]
                        , partner.btn |> Maybe.map btnPill |> Maybe.withDefault (Html.text "")
                        , tradeCodeChips partner.system.tradeCodes
                        , btnHelpLink data
                        ]
                    , viewGoodsLists data.origin partner
                    ]

            Nothing ->
                Html.div [ HtmlAttrs.class "trade-selected" ]
                    [ Html.div [ HtmlAttrs.class "trade-none" ] [ Html.text "Select a system on the map to list its goods." ] ]
        ]


icon : String -> Html msg
icon classes =
    Html.i [ HtmlAttrs.class classes, HtmlAttrs.attribute "aria-hidden" "true" ] []
