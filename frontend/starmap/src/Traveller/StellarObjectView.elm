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
import Traveller.TravelCalculations exposing (auToKMs, safeJumpTimeFromShadow, secondsToDaysWatches)
import Traveller.UI
    exposing
        ( descriptionStyle
        , jumpShadowTextColor
        , monospaceText
        , orbitStyle
        , safeJumpStyle
        , sequenceStyle
        , travellerRed
        , zeroEach
        )


{-| Message constructors needed by stellar object rendering functions.
Pass this record to enable click handlers on stellar objects.
-}
type alias StellarObjectMsgs msg =
    { onViewDetail : StellarObject -> msg
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
                , Element.htmlAttribute (HtmlAttrs.class "starmap-icon-hover")
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


renderJumpTime : Maybe Int -> Maybe Float -> Maybe Float -> Element msg
renderJumpTime mDrive maxJumpTime jumpShadowKms =
    Element.row safeJumpStyle
        [ renderIcon Icon.arrowUpFromBracket
        , text <|
            case maxJumpTime of
                Just maxTime ->
                    secondsToDaysWatches maxTime

                Nothing ->
                    safeJumpTimeFromShadow mDrive jumpShadowKms
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


renderGasGiant : StellarObjectMsgs msg -> Int -> GasGiantData -> JumpShadowCheckers -> Bool -> Maybe Int -> Element msg
renderGasGiant msgs newNestingLevel gasGiantData jumpShadowCheckers isReferee mDrive =
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
        ]
        [ orbit
        , renderOrbitSequence gasGiantData.orbitSequence
        , renderSODescription (msgs.onViewDetail stellarObject) gasGiantData.code gasGiantData.orbitSequence
        , renderImage gasGiantData.code Nothing
        , renderJumpTime mDrive maxShadow gasGiantData.jumpShadow
        ]


renderTerrestrialPlanet : StellarObjectMsgs msg -> Int -> SharedPData -> JumpShadowCheckers -> Bool -> Maybe Int -> Element msg
renderTerrestrialPlanet msgs newNestingLevel terrestrialData jumpShadowCheckers isReferee mDrive =
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
        ]
        [ orbit
        , renderOrbitSequence terrestrialData.orbitSequence
        , renderSODescription (msgs.onViewDetail planet) terrestrialData.uwp terrestrialData.orbitSequence
        , renderImage terrestrialData.uwp terrestrialData.meanTemperature
        , renderJumpTime mDrive maxShadow terrestrialData.jumpShadow
        ]


renderPlanetoidBelt : StellarObjectMsgs msg -> Int -> PlanetoidBeltData -> JumpShadowCheckers -> Bool -> Maybe Int -> Element msg
renderPlanetoidBelt msgs newNestingLevel planetoidBeltData jumpShadowCheckers isReferee mDrive =
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
        ]
        [ orbit
        , renderOrbitSequence planetoidBeltData.orbitSequence
        , renderSODescription (msgs.onViewDetail belt) planetoidBeltData.uwp planetoidBeltData.orbitSequence
        , renderImage planetoidBeltData.uwp Nothing
        , renderJumpTime mDrive maxShadow planetoidBeltData.jumpShadow
        ]


renderPlanetoid : StellarObjectMsgs msg -> Int -> SharedPData -> JumpShadowCheckers -> Bool -> Maybe Int -> Element msg
renderPlanetoid msgs newNestingLevel planetoidData jumpShadowCheckers isReferee mDrive =
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
        ]
        [ orbit
        , renderOrbitSequence planetoidData.orbitSequence
        , renderSODescription (msgs.onViewDetail planet) planetoidData.uwp planetoidData.orbitSequence
        , renderImage planetoidData.uwp planetoidData.meanTemperature
        , renderJumpTime mDrive maxShadow planetoidData.jumpShadow
        ]


renderStellarObject : StellarObjectMsgs msg -> Int -> Int -> StellarObject -> JumpShadowCheckers -> Bool -> Maybe Int -> Element msg
renderStellarObject msgs surveyIndex newNestingLevel stellarObject jumpShadowCheckers isReferee mDrive =
    row
        [ Element.spacing 8
        , Font.size 14
        , Element.width Element.fill
        ]
        [ case stellarObject of
            GasGiant gasGiantData ->
                renderGasGiant msgs newNestingLevel gasGiantData jumpShadowCheckers isReferee mDrive

            TerrestrialPlanet terrestrialData ->
                renderTerrestrialPlanet msgs newNestingLevel terrestrialData jumpShadowCheckers isReferee mDrive

            PlanetoidBelt planetoidBeltData ->
                renderPlanetoidBelt msgs newNestingLevel planetoidBeltData jumpShadowCheckers isReferee mDrive

            Planetoid planetoidData ->
                renderPlanetoid msgs newNestingLevel planetoidData jumpShadowCheckers isReferee mDrive

            Star starDataConfig ->
                el [ Element.width Element.fill, Element.paddingEach { top = 0, left = 0, right = 0, bottom = 5 } ] <|
                    displayStarDetails msgs surveyIndex starDataConfig newNestingLevel jumpShadowCheckers isReferee mDrive
        ]


displayStarDetails : StellarObjectMsgs msg -> Int -> StarData -> Int -> JumpShadowCheckers -> Bool -> Maybe Int -> Element msg
displayStarDetails msgs surveyIndex (StarDataWrap starData) nestingLevel jumpShadowCheckers isReferee mDrive =
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
        [ Element.htmlAttribute (HtmlAttrs.style "background-color" "color-mix(in srgb, var(--color-outline) 15%, transparent)")
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
                    displayStarDetails msgs surveyIndex compStarData nextNestingLevel jumpShadowCheckers isReferee mDrive
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
                                , Element.rgba 0.88 0.93 0.97 0.6
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
                |> List.map (\so -> renderStellarObject msgs surveyIndex nextNestingLevel so jumpShadowCheckers isReferee mDrive)
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
                |> List.map (\so -> renderStellarObject msgs surveyIndex nextNestingLevel so jumpShadowCheckers isReferee mDrive)
                |> column []
            ]
        ]


convertColor : Color.Color -> Element.Color
convertColor color =
    Element.fromRgb <| Color.toRgba <| color
