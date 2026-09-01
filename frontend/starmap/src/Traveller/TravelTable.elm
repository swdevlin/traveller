module Traveller.TravelTable exposing (Msgs, view, viewModal)

import Element
    exposing
        ( Element
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
import Html
import Html.Attributes as HtmlAttrs
import Html.Events
import Json.Decode
import Traveller.StarSystemDetail exposing (StarSystemDetail)
import Traveller.StarSystemMap exposing (MapNode, systemNodes)
import Traveller.StellarObject exposing (getStellarOrbit)
import Traveller.TravelCalculations exposing (calcDistance2F, travelTimeHoursDays, travelTimeInSeconds)
import Traveller.UI
    exposing
        ( fontVar
        , zeroEach
        )


type alias Msgs msg =
    { setMDrive : Int -> msg
    , close : msg
    , noOp : msg
    }


view : Msgs msg -> Int -> StarSystemDetail -> Element msg
view _ mDrive starSystemDetail =
    viewGrid (systemNodes True starSystemDetail) mDrive


viewModal : Msgs msg -> Int -> StarSystemDetail -> Element msg
viewModal msgs mDrive starSystemDetail =
    el
        [ width fill
        , height fill
        , Events.onClick msgs.close
        ]
    <|
        column
            [ Element.centerX
            , Element.centerY
            , Element.htmlAttribute (Html.Events.stopPropagationOn "click" (Json.Decode.succeed ( msgs.noOp, True )))
            , Element.htmlAttribute (HtmlAttrs.class "starmap-glass-panel")
            , Element.padding 20
            , Border.rounded 6
            , Border.shadow { offset = ( 0, 8 ), size = 0, blur = 32, color = Element.rgba 0 0 0 0.25 }
            ]
            [ row
                [ width fill
                , Element.paddingEach { zeroEach | bottom = 12 }
                , Border.widthEach { zeroEach | bottom = 1 }
                , Element.htmlAttribute (HtmlAttrs.style "border-color" "var(--color-outline)")
                ]
                [ el [ Font.size 16, fontVar "--color-fg-bright", Font.bold ] (text "Travel Times")
                , el
                    [ Element.alignRight
                    , Events.onClick msgs.close
                    , Element.htmlAttribute (HtmlAttrs.style "cursor" "pointer")
                    , Font.size 14
                    , fontVar "--color-fg-muted"
                    , Element.htmlAttribute (HtmlAttrs.class "starmap-modal-close")
                    ]
                    (text "✕")
                ]
            , column
                [ Element.paddingEach { zeroEach | top = 12 }
                , Element.spacing 12
                ]
                [ viewMDriveSelector msgs mDrive
                , view msgs mDrive starSystemDetail
                ]
            ]


viewMDriveSelector : Msgs msg -> Int -> Element msg
viewMDriveSelector msgs currentMDrive =
    let
        driveButton n =
            let
                isActive =
                    n == currentMDrive

                bgColour =
                    if isActive then
                        "var(--color-button-primary)"

                    else
                        "color-mix(in srgb, var(--color-outline) 12%, transparent)"

                fontColour =
                    if isActive then
                        "var(--color-fg-bright)"

                    else
                        "var(--color-fg)"
            in
            el
                [ Element.padding 4
                , Element.width (Element.px 24)
                , Element.htmlAttribute (HtmlAttrs.style "background-color" bgColour)
                , Border.rounded 3
                , Font.size 13
                , Element.htmlAttribute (HtmlAttrs.style "color" fontColour)
                , Font.center
                , Events.onClick (msgs.setMDrive n)
                , Element.htmlAttribute <| HtmlAttrs.style "cursor" "pointer"
                ]
                (text (String.fromInt n))
    in
    row [ Element.spacing 6, Element.centerY ]
        (el [ Font.size 13, fontVar "--color-fg-muted" ] (text "M-Drive")
            :: List.map driveButton (List.range 1 10)
        )


viewGrid : List MapNode -> Int -> Element msg
viewGrid nodes mDrive =
    Element.html <|
        Html.table
            [ HtmlAttrs.class "travel-table" ]
            [ Html.thead []
                [ Html.tr [] <|
                    Html.th [ HtmlAttrs.class "travel-table-corner" ] []
                        :: List.map
                            (\node ->
                                Html.th
                                    [ HtmlAttrs.class "travel-table-header" ]
                                    [ Html.text (getStellarOrbit node.stellarObject).orbitSequence ]
                            )
                            nodes
                ]
            , Html.tbody [] <|
                List.map
                    (\rowNode ->
                        let
                            rowOrbit =
                                (getStellarOrbit rowNode.stellarObject).orbitSequence
                        in
                        Html.tr [] <|
                            Html.th
                                [ HtmlAttrs.class "travel-table-row-header" ]
                                [ Html.text rowOrbit ]
                                :: List.map
                                    (\colNode ->
                                        if rowNode.stellarObject == colNode.stellarObject then
                                            Html.td [ HtmlAttrs.class "travel-table-cell travel-table-diagonal" ] [ Html.text "—" ]

                                        else
                                            let
                                                dist =
                                                    calcDistance2F
                                                        (getStellarOrbit rowNode.stellarObject).orbitPosition
                                                        (getStellarOrbit colNode.stellarObject).orbitPosition

                                                secs =
                                                    travelTimeInSeconds dist mDrive
                                            in
                                            Html.td [ HtmlAttrs.class "travel-table-cell" ] [ Html.text (travelTimeHoursDays secs) ]
                                    )
                                    nodes
                    )
                    nodes
            ]
