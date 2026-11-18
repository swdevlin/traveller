module Traveller.ShipTraffic exposing (Msgs, ShipTraffic, codec, viewModal)

import Codec
import Element exposing (Element)
import Html exposing (Html)
import Html.Attributes as HtmlAttrs
import Html.Events
import Http
import Json.Decode
import RemoteData exposing (RemoteData(..))


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
    Element.html <|
        Html.div
            [ HtmlAttrs.class "analysis-backdrop"
            , HtmlAttrs.style "position" "fixed"
            , HtmlAttrs.style "inset" "0"
            , HtmlAttrs.style "z-index" "200"
            , HtmlAttrs.style "display" "flex"
            , HtmlAttrs.style "align-items" "center"
            , HtmlAttrs.style "justify-content" "center"
            , Html.Events.onClick msgs.close
            ]
            [ Html.div
                [ HtmlAttrs.class "analysis-console traffic-console"
                , HtmlAttrs.attribute "role" "dialog"
                , HtmlAttrs.attribute "aria-modal" "true"
                , HtmlAttrs.attribute "aria-label" "Ship Traffic"
                , Html.Events.stopPropagationOn "click" (Json.Decode.succeed ( msgs.noOp, True ))
                ]
                [ Html.div [ HtmlAttrs.class "analysis-header" ]
                    [ Html.div []
                        [ Html.h2 [ HtmlAttrs.class "analysis-title" ] [ Html.text "Ship Traffic" ] ]
                    , Html.button
                        [ HtmlAttrs.type_ "button"
                        , HtmlAttrs.class "analysis-close"
                        , HtmlAttrs.attribute "aria-label" "Close ship traffic"
                        , Html.Events.onClick msgs.close
                        ]
                        [ Html.i [ HtmlAttrs.class "fa-solid fa-xmark", HtmlAttrs.attribute "aria-hidden" "true" ] [] ]
                    ]
                , Html.div [ HtmlAttrs.class "traffic-body" ]
                    [ viewBody remoteTraffic
                    , viewFrontierToggle msgs frontier
                    ]
                ]
            ]


viewBody : RemoteData Http.Error ShipTraffic -> Html msg
viewBody remoteTraffic =
    case remoteTraffic of
        NotAsked ->
            Html.div [ HtmlAttrs.class "traffic-note" ] [ Html.text "—" ]

        Loading ->
            Html.div [ HtmlAttrs.class "traffic-note" ] [ Html.text "Rolling…" ]

        Failure _ ->
            Html.div [ HtmlAttrs.class "traffic-note is-error" ] [ Html.text "Failed to compute ship traffic." ]

        Success traffic ->
            Html.div []
                [ Html.div [ HtmlAttrs.class "traffic-result" ]
                    [ Html.div [ HtmlAttrs.class "traffic-count" ] [ Html.text (String.fromInt traffic.result) ]
                    , Html.div [ HtmlAttrs.class "traffic-unit" ] [ Html.text "ships / day" ]
                    ]
                , Html.div [ HtmlAttrs.class "trade-readout" ]
                    [ viewDataField "Effective importance" (String.fromInt traffic.effectiveImportance)
                    , viewDataField "Tier" traffic.tierLabel
                    ]
                , if List.isEmpty traffic.modifiers then
                    Html.text ""

                  else
                    Html.ul [ HtmlAttrs.class "traffic-modifiers" ]
                        (List.map (\m -> Html.li [] [ Html.text m ]) traffic.modifiers)
                ]


viewDataField : String -> String -> Html msg
viewDataField lbl val =
    Html.div [ HtmlAttrs.class "trade-field" ]
        [ Html.span [ HtmlAttrs.class "trade-field-label" ] [ Html.text lbl ]
        , Html.span [ HtmlAttrs.class "trade-field-value" ] [ Html.text val ]
        ]


viewFrontierToggle : Msgs msg -> Bool -> Html msg
viewFrontierToggle msgs frontier =
    Html.div [ HtmlAttrs.class "traffic-actions" ]
        [ Html.button
            [ HtmlAttrs.type_ "button"
            , HtmlAttrs.class "traffic-check"
            , HtmlAttrs.attribute "role" "checkbox"
            , HtmlAttrs.attribute "aria-checked"
                (if frontier then
                    "true"

                 else
                    "false"
                )
            , Html.Events.onClick msgs.toggleFrontier
            ]
            [ Html.span [ HtmlAttrs.class "traffic-box" ] []
            , Html.text "Frontier world"
            ]
        , Html.button
            [ HtmlAttrs.type_ "button"
            , HtmlAttrs.class "traffic-rescan"
            , Html.Events.onClick msgs.reroll
            ]
            [ Html.text "Scan again" ]
        ]
