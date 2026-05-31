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
import Element.Background as Background
import Element.Border as Border
import Element.Events as Events
import Element.Font as Font
import Html
import Html.Attributes as HtmlAttrs
import Html.Events
import Json.Decode
import Traveller.SolarSystem exposing (SolarSystem)
import Traveller.StarSystemMap exposing (MapNode, systemNodes)
import Traveller.StellarObject exposing (getStellarOrbit)
import Traveller.TravelCalculations exposing (calcDistance2F, travelTimeHoursDays, travelTimeInSeconds)
import Traveller.UI
    exposing
        ( uiDeepnightColorFontColour
        , zeroEach
        )


type alias Msgs msg =
    { setMDrive : Int -> msg
    , close : msg
    , noOp : msg
    }


view : Msgs msg -> Int -> SolarSystem -> Element msg
view _ mDrive solarSystem =
    viewGrid (systemNodes True solarSystem) mDrive


viewModal : Msgs msg -> Int -> SolarSystem -> Element msg
viewModal msgs mDrive solarSystem =
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
            , Element.htmlAttribute (HtmlAttrs.style "background-color" "rgba(245, 250, 255, 0.92)")
            , Element.htmlAttribute (HtmlAttrs.style "backdrop-filter" "blur(16px)")
            , Element.htmlAttribute (HtmlAttrs.style "-webkit-backdrop-filter" "blur(16px)")
            , Element.padding 20
            , Border.rounded 6
            , Border.width 1
            , Border.color (Element.rgba 0.17 0.42 0.55 0.3)
            , Border.shadow { offset = ( 0, 8 ), size = 0, blur = 32, color = Element.rgba 0 0 0 0.25 }
            ]
            [ row
                [ width fill
                , Element.paddingEach { zeroEach | bottom = 12 }
                , Border.widthEach { zeroEach | bottom = 1 }
                , Border.color (Element.rgba 0.17 0.42 0.55 0.15)
                ]
                [ el [ Font.size 16, uiDeepnightColorFontColour, Font.bold ] (text "Travel Times")
                , el
                    [ Element.alignRight
                    , Events.onClick msgs.close
                    , Element.htmlAttribute (HtmlAttrs.style "cursor" "pointer")
                    , Font.size 14
                    , Font.color (Element.rgba 0.17 0.42 0.55 0.6)
                    ]
                    (text "✕")
                ]
            , column
                [ Element.paddingEach { zeroEach | top = 12 }
                , Element.spacing 12
                ]
                [ viewMDriveSelector msgs mDrive
                , view msgs mDrive solarSystem
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
                        Element.rgba 0.87 0.50 0.20 0.85

                    else
                        Element.rgba 0.17 0.42 0.55 0.12

                fontColour =
                    if isActive then
                        Element.rgb 1 1 1

                    else
                        Element.rgba 0.17 0.42 0.55 0.8
            in
            el
                [ Element.padding 4
                , Element.width (Element.px 24)
                , Background.color bgColour
                , Border.rounded 3
                , Font.size 13
                , Font.color fontColour
                , Font.center
                , Events.onClick (msgs.setMDrive n)
                , Element.htmlAttribute <| HtmlAttrs.style "cursor" "pointer"
                ]
                (text (String.fromInt n))
    in
    row [ Element.spacing 6, Element.centerY ]
        (el [ Font.size 13, Font.color (Element.rgba 0.17 0.42 0.55 0.7) ] (text "M-Drive")
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
