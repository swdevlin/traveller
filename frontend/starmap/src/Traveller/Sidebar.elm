module Traveller.Sidebar exposing
    ( SidebarMsgs
    , sidebarWidth
    , viewSidebarColumn
    , viewSidebarFooter
    , viewSystemDetailsSidebar
    )

{-| Sidebar view components for the Traveller application.
-}

import Color exposing (Color)
import Color.Manipulate
import Dict
import Element
    exposing
        ( Element
        , centerX
        , centerY
        , column
        , el
        , fill
        , height
        , row
        , text
        , width
        )
import Element.Events as Events
import Element.Font as Font
import Element.Lazy
import Html
import Html.Attributes as HtmlAttrs
import Traveller.HexAddress as HexAddress exposing (HexAddress)
import Traveller.Sector exposing (SectorDict)
import Traveller.SolarSystem exposing (SolarSystem)
import Traveller.StellarObject exposing (InnerStarData, StarData, StellarObject(..), getInnerStarData, getStarData, getStellarOrbit)
import Traveller.StellarObjectView
    exposing
        ( JumpShadowCheckers
        , StellarObjectMsgs
        , convertColor
        , displayStarDetails
        )
import Traveller.TravelCalculations exposing (auToKMs, calcDistance2F, travelTimeInSeconds)
import Traveller.UI
    exposing
        ( deepnightColor
        , textColor
        , uiDeepnightColorFontColour
        )


{-| Width of the sidebar in pixels.
-}
sidebarWidth : number
sidebarWidth =
    400


{-| Message constructors needed by sidebar view functions.
-}
type alias SidebarMsgs msg =
    { setHexSize : Float -> msg
    , toggleHexmap : msg
    , focusInSidebar : StellarObject -> msg
    , viewDetail : StellarObject -> msg
    }


{-| Render a FontAwesome icon.
-}
renderFAIcon : String -> Int -> Element msg
renderFAIcon icon size =
    Element.el
        [ Element.width (Element.px size)
        , Element.height (Element.px size)
        ]
    <|
        Element.html <|
            Html.i
                [ HtmlAttrs.style "font-size" (String.fromInt size ++ "px"), HtmlAttrs.class icon ]
                []


{-| Get the universal hex label from sectors dictionary.
-}
universalHexLabel : SectorDict -> HexAddress -> String
universalHexLabel sectors hexAddress =
    case Dict.get (HexAddress.toSectorKey <| HexAddress.toSectorAddress hexAddress) sectors of
        Nothing ->
            " "

        Just sector ->
            sector.name ++ " " ++ HexAddress.hexLabel hexAddress


{-| View the system details in the sidebar.
-}
viewSystemDetailsSidebar : SidebarMsgs msg -> SolarSystem -> Maybe StellarObject -> Bool -> Element msg
viewSystemDetailsSidebar msgs solarSystem selectedStellarObject isReferee =
    let
        jumpShadowCheckers : JumpShadowCheckers
        jumpShadowCheckers =
            List.filterMap
                (getStarData >> Maybe.map getInnerStarData)
                (Star solarSystem.primaryStar :: (getInnerStarData solarSystem.primaryStar).stellarObjects)
                |> List.map
                    (\star so ->
                        let
                            objToStarKMs =
                                calcDistance2F star.orbitPosition (getStellarOrbit so).orbitPosition

                            jumpShadowDistanceKMs =
                                Maybe.withDefault 0 star.jumpShadow
                        in
                        if objToStarKMs > jumpShadowDistanceKMs then
                            Nothing

                        else
                            Just <| travelTimeInSeconds (jumpShadowDistanceKMs - objToStarKMs) 4
                    )

        stellarObjectMsgs : StellarObjectMsgs msg
        stellarObjectMsgs =
            { onFocusInSidebar = msgs.focusInSidebar
            , onViewDetail = msgs.viewDetail
            }
    in
    displayStarDetails
        stellarObjectMsgs
        solarSystem.surveyIndex
        solarSystem.primaryStar
        0
        jumpShadowCheckers
        selectedStellarObject
        isReferee


{-| View the main sidebar column.

The `solarSystemStatus` field should contain a status message for the selected hex,
or Nothing if there's no status to display.

The `isHexMapMode` and `isFullJourneyMode` fields indicate which view mode is active.

-}
viewSidebarColumn :
    SidebarMsgs msg
    ->
        { a
            | hexScale : Float
            , isHexMapMode : Bool
            , isFullJourneyMode : Bool
            , selectedHex : Maybe HexAddress
            , solarSystemStatus : Maybe String
            , sectors : SectorDict
            , regions : Dict.Dict k { b | hexes : List HexAddress, name : String, colour : Color }
            , selectedSystem : Maybe SolarSystem
            , selectedStellarObject : Maybe StellarObject
            , isReferee : Bool
        }
    -> Element msg
viewSidebarColumn msgs { hexScale, isHexMapMode, isFullJourneyMode, selectedHex, solarSystemStatus, sectors, regions, selectedSystem, selectedStellarObject, isReferee } =
    column [ Element.spacing 10, Element.centerX, Element.height Element.fill ]
        [ column [ Element.width Element.fill ]
            [ let
                clickableIcon size =
                    let
                        selectorColor =
                            if hexScale == size / 2 && isHexMapMode then
                                deepnightColor

                            else
                                textColor

                        hexStyle =
                            if hexScale == size / 2 && isHexMapMode then
                                "fa-regular"

                            else
                                "fa-thin"
                    in
                    renderFAIcon (hexStyle ++ " fa-hexagon") (floor size)
                        |> Element.el
                            [ Element.pointer
                            , Element.mouseOver [ Font.color <| convertColor (Color.Manipulate.lighten 0.15 selectorColor) ]
                            , Events.onClick <| msgs.setHexSize <| size / 2
                            , Font.color <| convertColor selectorColor
                            ]
              in
              row [ Element.spacing 6, Element.centerX ]
                [ clickableIcon 80
                , clickableIcon 60
                , clickableIcon 50
                , clickableIcon 30
                , let
                    selectorColor =
                        if isFullJourneyMode then
                            deepnightColor

                        else
                            textColor

                    hexStyle =
                        if isFullJourneyMode then
                            "fa-regular"

                        else
                            "fa-thin"
                  in
                  el
                    [ Element.width <| Element.px 50
                    , Element.height <| Element.px 50
                    , Element.pointer
                    , Events.onClick msgs.toggleHexmap
                    , Element.mouseOver [ Font.color <| convertColor (Color.Manipulate.lighten 0.15 selectorColor) ]
                    , Font.color <| convertColor selectorColor
                    ]
                  <|
                    renderFAIcon (hexStyle ++ " " ++ "fa-map") 50
                ]
            , case selectedHex of
                Just viewingAddress ->
                    column [ centerY, Element.paddingXY 0 10, width fill ]
                        [ case solarSystemStatus of
                            Just status ->
                                text status

                            Nothing ->
                                Element.none
                        , row [ Element.spacing 5, width fill ]
                            [ text <| universalHexLabel sectors viewingAddress
                            , regions
                                |> Dict.values
                                |> -- abusing lists here since we only expect one label,
                                   -- but this iterates over all the regions
                                   -- and renders the name if it exists
                                   List.filterMap
                                    (\region ->
                                        if List.member viewingAddress region.hexes then
                                            text region.name
                                                |> el [ Font.size 12, Font.color <| convertColor region.colour ]
                                                |> Just

                                        else
                                            Nothing
                                    )
                                |> column [ Element.alignRight ]
                            ]
                        ]

                Nothing ->
                    column [ centerX, centerY, Font.size 10 ]
                        [ text "Select hex in console to view parsec details."
                        ]
            , case selectedSystem of
                Just solarSystem ->
                    Element.Lazy.lazy4 viewSystemDetailsSidebar
                        msgs
                        solarSystem
                        selectedStellarObject
                        isReferee

                Nothing ->
                    column [ centerX, centerY, Font.size 10, Element.moveDown 20 ]
                        [ text "Click a hex to view system details."
                        ]
            ]
        , Element.Lazy.lazy viewSidebarFooter selectedHex
        ]


{-| View the sidebar footer.
-}
viewSidebarFooter : Maybe HexAddress -> Element msg
viewSidebarFooter selectedHex =
    let
        _ =
            Debug.log "footer" 123
    in
    -- footer
    Element.el
        [ Element.padding 10
        , Element.alignBottom
        , centerX
        , Font.size 10
        , uiDeepnightColorFontColour
        ]
    <|
        case selectedHex of
            Just viewingAddress ->
                text <| Debug.toString viewingAddress

            Nothing ->
                text "Deepnight Corporation LLC"
