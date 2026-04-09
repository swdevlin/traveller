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
import Traveller.StellarObject exposing (StellarObject(..))
import Traveller.StarSystemMap exposing (viewStarSystemMap)
import Traveller.StellarObjectView
    exposing
        ( StellarObjectMsgs
        , convertColor
        )
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
    300


{-| Message constructors needed by sidebar view functions.
-}
type alias SidebarMsgs msg =
    { focusInSidebar : StellarObject -> msg
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
        stellarObjectMsgs : StellarObjectMsgs msg
        stellarObjectMsgs =
            { onFocusInSidebar = msgs.focusInSidebar
            , onViewDetail = msgs.viewDetail
            }
    in
    viewStarSystemMap stellarObjectMsgs solarSystem selectedStellarObject isReferee


{-| View the main sidebar column.

The `solarSystemStatus` field should contain a status message for the selected hex,
or Nothing if there's no status to display.

The `isHexMapMode` and `isFullJourneyMode` fields indicate which view mode is active.

-}
viewSidebarColumn :
    SidebarMsgs msg
    ->
        { a
            | selectedHex : Maybe HexAddress
            , solarSystemStatus : Maybe String
            , sectors : SectorDict
            , regions : Dict.Dict k { b | hexes : List HexAddress, name : String, colour : Color }
            , selectedSystem : Maybe SolarSystem
            , selectedStellarObject : Maybe StellarObject
            , isReferee : Bool
            , allSectorsMapUrl : Maybe String
        }
    -> Element msg
viewSidebarColumn msgs { selectedHex, solarSystemStatus, sectors, regions, selectedSystem, selectedStellarObject, isReferee, allSectorsMapUrl } =
    column [ Element.spacing 4, Element.centerX, Element.height Element.fill ]
        [ column [ Element.width Element.fill ]
            [ case selectedHex of
                Just viewingAddress ->
                    column [ centerY, Element.paddingXY 0 4, width fill, centerX ]
                        [ case solarSystemStatus of
                            Just status ->
                                el [ centerX ] (text status)

                            Nothing ->
                                Element.none
                        , column [ centerX, Element.spacing 2 ]
                            [ el [ centerX, uiDeepnightColorFontColour ] (text <| universalHexLabel sectors viewingAddress)
                            , case selectedSystem of
                                Just sys ->
                                    if sys.surveyIndex >= 10 then
                                        case sys.mainWorldUwp of
                                            Just uwp ->
                                                el [ centerX, Font.size 12, Font.color <| convertColor textColor ] (text uwp)

                                            Nothing ->
                                                Element.none

                                    else
                                        Element.none

                                Nothing ->
                                    Element.none
                            , regions
                                |> Dict.values
                                |> List.filterMap
                                    (\region ->
                                        if List.member viewingAddress region.hexes then
                                            text region.name
                                                |> el [ Font.size 12, Font.color <| convertColor region.colour, centerX ]
                                                |> Just

                                        else
                                            Nothing
                                    )
                                |> column [ centerX ]
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
viewSidebarFooter _ =
    Element.el
        [ Element.padding 10
        , Element.alignBottom
        , centerX
        , Font.size 10
        , uiDeepnightColorFontColour
        ]
    <|
        text "Deepnight Corporation LLC"
