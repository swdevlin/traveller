module Traveller.StellarObjectView exposing
    ( JumpShadowChecker
    , JumpShadowCheckers
    , StellarObjectMsgs
    , calcNestedOffset
    , convertColor
    , displayStarDetails
    , iconSizing
    , renderGasGiant
    , renderIcon
    , renderIconRaw
    , renderImage
    , renderJumpTime
    , renderOrbit
    , renderOrbitSequence
    , renderPlanetoid
    , renderPlanetoidBelt
    , renderRawOrbit
    , renderSODescription
    , renderStellarObject
    , renderTerrestrialPlanet
    , renderTravelTime
    )

{-| View functions for rendering stellar objects in the sidebar.
-}

import Color
import Color.Manipulate
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
import FontAwesome as Icon exposing (Icon)
import FontAwesome.Solid as Icon
import Html
import Html.Attributes as HtmlAttrs
import Round
import Traveller.Point exposing (StellarPoint)
import Traveller.StellarObject
    exposing
        ( GasGiantData
        , PlanetoidBeltData
        , SharedPData
        , StarData(..)
        , StellarObject(..)
        , getInnerStarData
        , getStellarOrbit
        , isBrownDwarf
        )
import Traveller.TravelCalculations exposing (auToKMs, calcDistance2F, secondsToDaysWatches, travelTime)
import Traveller.UI
    exposing
        ( descriptionStyle
        , jumpShadowTextColor
        , monospaceText
        , orbitStyle
        , safeJumpStyle
        , sequenceStyle
        , travelStyle
        , travellerRed
        , zeroEach
        )


{-| Message constructors needed by stellar object rendering functions.
Pass this record to enable click handlers on stellar objects.
-}
type alias StellarObjectMsgs msg =
    { onFocusInSidebar : StellarObject -> msg
    , onViewDetail : StellarObject -> msg
    }


{-| A function that checks if a stellar object is within a jump shadow
and returns the travel time to exit if so.
-}
type alias JumpShadowChecker =
    StellarObject -> Maybe Float


type alias JumpShadowCheckers =
    List JumpShadowChecker


calcNestedOffset : Int -> Float
calcNestedOffset newNestingLevel =
    toFloat <| newNestingLevel * 5


renderRawOrbit : Float -> Element msg
renderRawOrbit au =
    let
        roundedAU =
            if au < 1 then
                Round.round 2 au

            else
                Round.round 1 au
    in
    Element.el
        orbitStyle
        (monospaceText <| roundedAU)


renderOrbit : Float -> Element msg
renderOrbit au =
    let
        zoneImage =
            ""

        roundedAU =
            if au < 1 then
                Round.round 2 au

            else
                Round.round 1 au
    in
    Element.el
        orbitStyle
        (monospaceText <| roundedAU ++ zoneImage)


renderOrbitSequence : String -> Element msg
renderOrbitSequence sequence =
    Element.el
        sequenceStyle
        (monospaceText <| sequence)


renderSODescription : msg -> String -> String -> Element msg
renderSODescription onClick description orbitSequence =
    Element.el
        descriptionStyle
        (row []
            [ monospaceText <| description
            , el
                [ Font.size 10
                , height fill
                , Element.paddingEach { zeroEach | left = 4, top = 2 }
                , Element.pointer
                , Element.mouseOver [ Font.color <| Element.rgb 1 1 1 ]
                , Events.onClick <| onClick
                ]
              <|
                renderIconRaw "fa-solid fa-scanner-touchscreen"
            ]
        )


iconSizing : List (Element.Attribute msg)
iconSizing =
    [ Element.height <| Element.px 16, Element.width <| Element.px 16 ]


renderIcon : Icon a -> Element msg
renderIcon icon =
    let
        iconSpacing =
            { zeroEach | right = 4 }
    in
    icon
        |> Icon.view
        |> Element.html
        |> Element.el (Element.paddingEach iconSpacing :: iconSizing)


renderIconRaw : String -> Element msg
renderIconRaw icon =
    let
        iconSpacing =
            { zeroEach | right = 4 }
    in
    Html.i [ HtmlAttrs.class icon ] []
        |> Element.html
        |> Element.el [ Element.paddingEach iconSpacing, height <| Element.px 10, width <| Element.px 10 ]


renderJumpTime : Maybe Float -> String -> Element msg
renderJumpTime maxJumpTime time =
    Element.row safeJumpStyle
        [ renderIcon Icon.arrowUpFromBracket
        , text <|
            case maxJumpTime of
                Just maxTime ->
                    secondsToDaysWatches maxTime

                Nothing ->
                    time
        ]


renderImage : String -> Maybe Float -> Element msg
renderImage uwp maybeTemp =
    let
        gasGiantUwps =
            [ "GS", "GM", "GL" ]

        hydrographics =
            if String.length uwp == 9 then
                String.slice 3 4 uwp

            else
                ""

        atmosphere =
            if String.length uwp == 9 then
                String.slice 2 3 uwp

            else
                ""

        imageUrl =
            if List.member uwp gasGiantUwps then
                "/images/gasgiant-small.png"

            else if atmosphere == "B" || atmosphere == "C" then
                "/images/corrosivehellworld-small.png"

            else if hydrographics == "A" then
                "/images/waterworld-small.png"

            else if hydrographics == "0" then
                "/images/desertworld-small.png"

            else if atmosphere == "1" || atmosphere == "2" || atmosphere == "3" then
                "/images/traceworld-small.png"

            else
                "/images/moon-small.png"
    in
    Element.image [ width <| Element.px 18, height <| Element.px 18 ]
        { src = imageUrl
        , description = ""
        }


renderTravelTime : StellarObject -> Maybe StellarObject -> Element msg
renderTravelTime destination origin =
    let
        shipMDrive =
            4

        travelTimeStr =
            case origin of
                Just obj ->
                    if obj /= destination then
                        let
                            destPosition =
                                (getStellarOrbit destination).orbitPosition

                            objPosition =
                                (getStellarOrbit obj).orbitPosition

                            dist =
                                calcDistance2F destPosition objPosition
                        in
                        travelTime dist shipMDrive False

                    else
                        ""

                Nothing ->
                    ""
    in
    case origin of
        Just obj ->
            if obj /= destination then
                Element.el
                    travelStyle
                    (monospaceText <| travelTimeStr)

            else
                Element.row travelStyle
                    [ renderIcon Icon.upDown
                    ]

        Nothing ->
            monospaceText <| ""


renderGasGiant : StellarObjectMsgs msg -> Int -> GasGiantData -> JumpShadowCheckers -> Maybe StellarObject -> Bool -> Element msg
renderGasGiant msgs newNestingLevel gasGiantData jumpShadowCheckers selectedStellarObject isReferee =
    let
        stellarObject =
            GasGiant gasGiantData

        maxShadow =
            List.maximum <|
                List.filterMap (\checker -> checker stellarObject) jumpShadowCheckers

        orbit =
            renderOrbit gasGiantData.au
    in
    row
        [ Element.spacing 8
        , Element.moveRight <| calcNestedOffset newNestingLevel
        , Font.size 14
        , Events.onClick <| msgs.onFocusInSidebar stellarObject
        ]
        [ orbit
        , renderOrbitSequence gasGiantData.orbitSequence
        , renderSODescription (msgs.onViewDetail stellarObject) gasGiantData.code gasGiantData.orbitSequence
        , renderImage gasGiantData.code Nothing
        , renderJumpTime maxShadow gasGiantData.safeJumpTime
        , renderTravelTime stellarObject selectedStellarObject
        ]


renderTerrestrialPlanet : StellarObjectMsgs msg -> Int -> SharedPData -> JumpShadowCheckers -> Maybe StellarObject -> Bool -> Element msg
renderTerrestrialPlanet msgs newNestingLevel terrestrialData jumpShadowCheckers selectedStellarObject isReferee =
    let
        planet =
            TerrestrialPlanet terrestrialData

        maxShadow =
            List.maximum <| List.filterMap (\checker -> checker planet) jumpShadowCheckers

        orbit =
            renderOrbit terrestrialData.au
    in
    row
        [ Element.spacing 8
        , Element.moveRight <| calcNestedOffset newNestingLevel
        , Font.size 14
        , Events.onClick <| msgs.onFocusInSidebar planet
        ]
        [ orbit
        , renderOrbitSequence terrestrialData.orbitSequence
        , renderSODescription (msgs.onViewDetail planet) terrestrialData.uwp terrestrialData.orbitSequence
        , renderImage terrestrialData.uwp terrestrialData.meanTemperature
        , renderJumpTime maxShadow terrestrialData.safeJumpTime
        , renderTravelTime planet selectedStellarObject
        ]


renderPlanetoidBelt : StellarObjectMsgs msg -> Int -> PlanetoidBeltData -> JumpShadowCheckers -> Maybe StellarObject -> Bool -> Element msg
renderPlanetoidBelt msgs newNestingLevel planetoidBeltData jumpShadowCheckers selectedStellarObject isReferee =
    let
        belt =
            PlanetoidBelt planetoidBeltData

        maxShadow =
            List.maximum <| List.filterMap (\checker -> checker belt) jumpShadowCheckers

        orbit =
            renderOrbit planetoidBeltData.au
    in
    row
        [ Element.spacing 8
        , Element.moveRight <| calcNestedOffset newNestingLevel
        , Font.size 14
        , Events.onClick <| msgs.onFocusInSidebar belt
        ]
        [ orbit
        , renderOrbitSequence planetoidBeltData.orbitSequence
        , renderSODescription (msgs.onViewDetail belt) planetoidBeltData.uwp planetoidBeltData.orbitSequence
        , renderImage planetoidBeltData.uwp Nothing
        , renderJumpTime maxShadow planetoidBeltData.safeJumpTime
        , renderTravelTime belt selectedStellarObject
        ]


renderPlanetoid : StellarObjectMsgs msg -> Int -> SharedPData -> JumpShadowCheckers -> Maybe StellarObject -> Bool -> Element msg
renderPlanetoid msgs newNestingLevel planetoidData jumpShadowCheckers selectedStellarObject isReferee =
    let
        planet =
            Planetoid planetoidData

        maxShadow =
            List.maximum <| List.filterMap (\checker -> checker planet) jumpShadowCheckers

        orbit =
            renderOrbit planetoidData.au
    in
    row
        [ Element.spacing 8
        , Element.moveRight <| calcNestedOffset newNestingLevel
        , Font.size 14
        , Events.onClick <| msgs.onFocusInSidebar planet
        ]
        [ orbit
        , renderOrbitSequence planetoidData.orbitSequence
        , renderSODescription (msgs.onViewDetail planet) planetoidData.uwp planetoidData.orbitSequence
        , renderImage planetoidData.uwp planetoidData.meanTemperature
        , renderJumpTime maxShadow planetoidData.safeJumpTime
        , renderTravelTime planet selectedStellarObject
        ]


renderStellarObject : StellarObjectMsgs msg -> Int -> Int -> StellarObject -> JumpShadowCheckers -> Maybe StellarObject -> Bool -> Element msg
renderStellarObject msgs surveyIndex newNestingLevel stellarObject jumpShadowCheckers selectedStellarObject isReferee =
    row
        [ Element.spacing 8
        , Font.size 14
        , Element.width Element.fill
        ]
        [ case stellarObject of
            GasGiant gasGiantData ->
                renderGasGiant msgs newNestingLevel gasGiantData jumpShadowCheckers selectedStellarObject isReferee

            TerrestrialPlanet terrestrialData ->
                renderTerrestrialPlanet msgs newNestingLevel terrestrialData jumpShadowCheckers selectedStellarObject isReferee

            PlanetoidBelt planetoidBeltData ->
                renderPlanetoidBelt msgs newNestingLevel planetoidBeltData jumpShadowCheckers selectedStellarObject isReferee

            Planetoid planetoidData ->
                renderPlanetoid msgs newNestingLevel planetoidData jumpShadowCheckers selectedStellarObject isReferee

            Star starDataConfig ->
                el [ Element.width Element.fill, Element.paddingEach { top = 0, left = 0, right = 0, bottom = 5 } ] <|
                    displayStarDetails msgs surveyIndex starDataConfig newNestingLevel jumpShadowCheckers selectedStellarObject isReferee
        ]


displayStarDetails : StellarObjectMsgs msg -> Int -> StarData -> Int -> JumpShadowCheckers -> Maybe StellarObject -> Bool -> Element msg
displayStarDetails msgs surveyIndex (StarDataWrap starData) nestingLevel jumpShadowCheckers selectedStellarObject isReferee =
    let
        inJumpShadow obj =
            case starData.jumpShadow of
                Just jumpShadow ->
                    jumpShadow >= (getStellarOrbit obj).au

                Nothing ->
                    False

        isKnown obj =
            case obj of
                GasGiant _ ->
                    surveyIndex >= 5

                TerrestrialPlanet _ ->
                    surveyIndex >= 6

                PlanetoidBelt _ ->
                    surveyIndex >= 6

                Planetoid _ ->
                    surveyIndex >= 6

                Star childStar ->
                    if isBrownDwarf <| getInnerStarData childStar then
                        surveyIndex >= 4

                    else
                        surveyIndex >= 3

        isDisplayable obj =
            case obj of
                Planetoid pdata ->
                    pdata.size /= "S" && pdata.size /= "0"

                _ ->
                    True

        nextNestingLevel =
            nestingLevel + 1
    in
    column
        [ Color.rgba (33 / 255.0) (37 / 255.0) (41 / 255.0) 0.15
            |> Color.Manipulate.darken 0.4
            |> convertColor
            |> Background.color
        , Element.width Element.fill
        , Element.moveRight <| toFloat <| nestingLevel * 5
        , Border.rounded 10
        , Element.width <| Element.minimum 200 Element.fill
        , Element.spacing 10
        , Element.paddingXY 0 5
        ]
        [ row [ Element.paddingXY 4 0, Font.alignLeft, Element.alignLeft ]
            [ if starData.orbitPosition.x == 0 && starData.orbitPosition.y == 0 then
                Element.none

              else
                renderRawOrbit starData.au
            , el [ Font.alignLeft, Element.alignLeft, Font.size 16, Font.bold ] <|
                text <|
                    starData.stellarType
                        ++ (case starData.subtype of
                                Just num ->
                                    String.fromInt num

                                Nothing ->
                                    ""
                           )
                        ++ " "
                        ++ starData.stellarClass
            ]
        , starData.companion
            |> Maybe.map
                (\compStarData ->
                    displayStarDetails msgs surveyIndex compStarData nextNestingLevel jumpShadowCheckers selectedStellarObject isReferee
                )
            |> Maybe.withDefault Element.none
        , column [ Element.paddingXY 4 0, Element.width Element.fill ] <|
            let
                red =
                    Element.el
                        [ width <| Element.fill
                        , height <| Element.px 4
                        , Element.centerY
                        , Border.rounded 2
                        , Background.gradient
                            { angle = pi / 2.0
                            , steps =
                                [ travellerRed
                                , Element.rgba 0 0 0 0.25
                                , travellerRed
                                ]
                            }
                        ]
                    <|
                        text <|
                            " "
            in
            [ starData.stellarObjects
                |> List.filter isDisplayable
                |> List.filter inJumpShadow
                |> List.filter isKnown
                |> List.map (\so -> renderStellarObject msgs surveyIndex nextNestingLevel so jumpShadowCheckers selectedStellarObject isReferee)
                |> column []
            , column [ Font.size 14, Font.shadow { blur = 1, color = jumpShadowTextColor, offset = ( 0.5, 0.5 ) }, Element.width Element.fill, Element.behindContent red ]
                [ case starData.jumpShadow of
                    Just jumpShadow ->
                        Element.el [ Element.centerX ] <| text <| Round.round 2 (jumpShadow / auToKMs 1) ++ " AU"

                    Nothing ->
                        text ""
                ]
            , starData.stellarObjects
                |> List.filter isDisplayable
                |> List.filter (not << inJumpShadow)
                |> List.filter isKnown
                |> List.map (\so -> renderStellarObject msgs surveyIndex nextNestingLevel so jumpShadowCheckers selectedStellarObject isReferee)
                |> column []
            ]
        ]


convertColor : Color.Color -> Element.Color
convertColor color =
    Element.fromRgb <| Color.toRgba <| color
