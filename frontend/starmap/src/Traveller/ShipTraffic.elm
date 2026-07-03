module Traveller.ShipTraffic exposing (Msgs, ShipTraffic, codec, viewModal)

import Codec
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
import Html.Attributes as HtmlAttrs
import Html.Events
import Http
import Json.Decode
import RemoteData exposing (RemoteData(..))
import Traveller.UI
    exposing
        ( uiDeepnightColorFontColour
        , zeroEach
        )


type alias ShipTraffic =
    { result : Int
    , effectiveImportance : Int
    , tierLabel : String
    , modifiers : List String
    }


codec : Codec.Codec ShipTraffic
codec =
    Codec.object ShipTraffic
        |> Codec.field "result" .result Codec.int
        |> Codec.field "effective_importance" .effectiveImportance Codec.int
        |> Codec.field "tier_label" .tierLabel Codec.string
        |> Codec.field "modifiers" .modifiers (Codec.list Codec.string)
        |> Codec.buildObject


{-| Message constructors needed by the ship traffic modal.
-}
type alias Msgs msg =
    { close : msg
    , noOp : msg
    , reroll : msg
    , toggleFrontier : msg
    }


viewModal : Msgs msg -> RemoteData Http.Error ShipTraffic -> Bool -> Element msg
viewModal msgs remoteTraffic frontier =
    el
        [ width fill
        , height fill
        , Events.onClick msgs.close
        ]
    <|
        column
            [ Element.centerX
            , Element.centerY
            , Element.width (Element.px 340)
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
                [ el [ Font.size 16, uiDeepnightColorFontColour, Font.bold ] (text "Ship Traffic")
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
                , Element.spacing 14
                , width fill
                ]
                [ viewBody remoteTraffic
                , viewFrontierToggle msgs frontier
                ]
            ]


viewBody : RemoteData Http.Error ShipTraffic -> Element msg
viewBody remoteTraffic =
    case remoteTraffic of
        NotAsked ->
            el [ Font.size 13, Font.color (Element.rgba 0.17 0.42 0.55 0.6) ] (text "—")

        Loading ->
            el
                [ Element.centerX
                , Element.paddingXY 0 24
                , Font.size 13
                , Font.color (Element.rgba 0.17 0.42 0.55 0.6)
                ]
                (text "Rolling…")

        Failure _ ->
            el
                [ Element.centerX
                , Element.paddingXY 0 24
                , Font.size 13
                , Font.color (Element.rgb 0.75 0.2 0.2)
                ]
                (text "Failed to compute ship traffic.")

        Success traffic ->
            column [ width fill, Element.spacing 10 ]
                [ el [ Element.centerX, Font.size 40, Font.bold, uiDeepnightColorFontColour ]
                    (text (String.fromInt traffic.result))
                , el [ Element.centerX, Font.size 11, Font.color (Element.rgba 0.17 0.42 0.55 0.6) ]
                    (text "ships / day")
                , row [ width fill, Element.spacing 12 ]
                    [ viewDataField "Effective Importance" (String.fromInt traffic.effectiveImportance)
                    , viewDataField "Tier" traffic.tierLabel
                    ]
                , if List.isEmpty traffic.modifiers then
                    Element.none

                  else
                    column [ Element.spacing 2 ]
                        (List.map
                            (\m -> el [ Font.size 11, Font.color (Element.rgba 0.17 0.42 0.55 0.6) ] (text ("• " ++ m)))
                            traffic.modifiers
                        )
                ]


viewDataField : String -> String -> Element msg
viewDataField lbl val =
    column [ width fill, Element.spacing 2 ]
        [ el [ Font.size 10, uiDeepnightColorFontColour, Font.bold ] (text (String.toUpper lbl))
        , el [ Font.size 13 ] (text val)
        ]


viewFrontierToggle : Msgs msg -> Bool -> Element msg
viewFrontierToggle msgs frontier =
    row
        [ width fill
        , Element.paddingEach { zeroEach | top = 8 }
        , Border.widthEach { zeroEach | top = 1 }
        , Border.color (Element.rgba 0.17 0.42 0.55 0.15)
        , Element.spacing 10
        ]
        [ el
            [ Events.onClick msgs.toggleFrontier
            , Element.htmlAttribute (HtmlAttrs.style "cursor" "pointer")
            , Font.size 12
            , Font.color
                (if frontier then
                    Element.rgba 0.87 0.50 0.20 1.0

                 else
                    Element.rgba 0.17 0.42 0.55 0.7
                )
            ]
            (row [ Element.spacing 6 ]
                [ el
                    [ Element.width (Element.px 14)
                    , Element.height (Element.px 14)
                    , Border.width 1
                    , Border.rounded 3
                    , Border.color (Element.rgba 0.17 0.42 0.55 0.5)
                    , Background.color
                        (if frontier then
                            Element.rgba 0.87 0.50 0.20 0.85

                         else
                            Element.rgba 0 0 0 0
                        )
                    ]
                    Element.none
                , text "Frontier world"
                ]
            )
        , el
            [ Element.alignRight
            , Events.onClick msgs.reroll
            , Element.htmlAttribute (HtmlAttrs.style "cursor" "pointer")
            , Element.padding 6
            , Border.rounded 4
            , Background.color (Element.rgba 0.17 0.42 0.55 0.12)
            , Font.size 12
            , Font.color (Element.rgba 0.17 0.42 0.55 0.8)
            ]
            (text "Roll Again")
        ]