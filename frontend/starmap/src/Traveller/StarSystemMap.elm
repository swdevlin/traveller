module Traveller.StarSystemMap exposing (viewStarSystemMap)

{-| Vertical subway-style SVG map of a star system.

Primary star's bodies are laid out top-to-bottom on a central spine.
Secondary stars branch off at their orbital position with their own
indented sub-spine, mirroring the approach chosen for the visual design.
-}

import Element exposing (Element)
import Html.Events
import Json.Decode
import Round
import Svg exposing (Svg)
import Svg.Attributes as SA
import Svg.Events as SE
import Traveller.SolarSystem exposing (SolarSystem)
import Traveller.StarColour exposing (starFillColour)
import Traveller.StellarObject
    exposing
        ( InnerStarData
        , SharedPData
        , StarData(..)
        , StellarObject(..)
        , getInnerStarData
        , getSafeJumpTime
        , getStellarOrbit
        , isBrownDwarf
        )
import Traveller.StellarObjectView exposing (StellarObjectMsgs)
import Traveller.TravelCalculations
    exposing
        ( auToKMs
        , calcDistance2F
        , secondsToDaysWatches
        , travelTimeInSeconds
        )


-- ── CONSTANTS ────────────────────────────────────────────────────────────────


baseSpineX : Float
baseSpineX =
    50


topY : Float
topY =
    50


vertStep : Float
vertStep =
    38


starToBodyGap : Float
starToBodyGap =
    52


nestIndent : Float
nestIndent =
    92


companionGap : Float
companionGap =
    80


starRadius : Float
starRadius =
    14


gasGiantRadius : Float
gasGiantRadius =
    10


terrRadius : Float
terrRadius =
    7


beltRadius : Float
beltRadius =
    9


defaultRadius : Float
defaultRadius =
    5


shipMDrive : Int
shipMDrive =
    4



-- ── TYPES ────────────────────────────────────────────────────────────────────


type NodeKind
    = StarNodeKind
    | GasGiantNodeKind
    | TerrestrialNodeKind
    | BeltNodeKind
    | OtherNodeKind


type alias MapNode =
    { x : Float
    , y : Float
    , radius : Float
    , kind : NodeKind
    , fillColour : String
    , label : String
    , sublabel : Maybe String
    , stellarObject : StellarObject
    }


type alias MapEdge =
    { x1 : Float
    , y1 : Float
    , x2 : Float
    , y2 : Float
    , isDashed : Bool
    , auLabel : Maybe String
    }


type alias MapJumpShadow =
    { x1 : Float
    , y1 : Float
    , x2 : Float
    , y2 : Float
    , colour : String
    , hasMarker : Bool
    }


type alias MapLayout =
    { nodes : List MapNode
    , edges : List MapEdge
    , jumpShadows : List MapJumpShadow
    , svgWidth : Float
    , svgHeight : Float
    }


type alias SpineAcc =
    { nodes : List MapNode
    , edges : List MapEdge
    , jumpShadows : List MapJumpShadow
    , currentY : Float
    , prevY : Float
    , bodyAnchors : List ( Float, Float )
    }



-- ── ENTRY POINT ──────────────────────────────────────────────────────────────


viewStarSystemMap : StellarObjectMsgs msg -> SolarSystem -> Maybe StellarObject -> Bool -> Element msg
viewStarSystemMap msgs solarSystem selectedStellarObject _ =
    let
        layout =
            computeLayout solarSystem

        w =
            String.fromFloat layout.svgWidth

        h =
            String.fromFloat layout.svgHeight

        vb =
            "0 0 " ++ w ++ " " ++ h
    in
    Element.html <|
        Svg.svg
            [ SA.width "100%"
            , SA.viewBox vb
            , SA.preserveAspectRatio "xMinYMin meet"
            , SA.style "display:block;"
            ]
            [ svgDefs
            , svgStyle
            , renderEdges layout.edges
            , renderJumpShadows layout.jumpShadows
            , renderNodes msgs selectedStellarObject layout.nodes
            ]



-- ── LAYOUT ───────────────────────────────────────────────────────────────────


computeLayout : SolarSystem -> MapLayout
computeLayout solarSystem =
    let
        si =
            solarSystem.surveyIndex

        primary =
            getInnerStarData solarSystem.primaryStar

        primaryX =
            nestX 0

        primaryNode =
            makeStarNode solarSystem.primaryStar primaryX topY

        ( compNodes, compEdges ) =
            layoutCompanion primary.companion primaryX topY

        filteredBodies =
            primary.stellarObjects
                |> List.filter (isKnown si)
                |> List.filter isDisplayable

        spineAcc =
            layoutSpine filteredBodies si 0 (topY + starToBodyGap) topY

        primaryShadow =
            computeVerticalShadow primary primaryX topY spineAcc.bodyAnchors

        allNodes =
            primaryNode :: compNodes ++ spineAcc.nodes

        allEdges =
            compEdges ++ spineAcc.edges

        allShadows =
            maybeToList primaryShadow ++ spineAcc.jumpShadows

        maxX =
            allNodes
                |> List.map (\n -> n.x + n.radius + 100)
                |> List.maximum
                |> Maybe.withDefault 280

        maxY =
            max spineAcc.currentY (topY + 80)
    in
    { nodes = allNodes
    , edges = allEdges
    , jumpShadows = allShadows
    , svgWidth = max 220 maxX
    , svgHeight = maxY + 50
    }


{-| Walk a list of bodies downward on the spine at the given nesting level.
Secondary stars (Star variants) get their own recursive sub-spine one
nesting level deeper.
-}
layoutSpine : List StellarObject -> Int -> Int -> Float -> Float -> SpineAcc
layoutSpine bodies si nestLevel startY prevY =
    let
        x =
            nestX nestLevel

        init =
            { nodes = []
            , edges = []
            , jumpShadows = []
            , currentY = startY
            , prevY = prevY
            , bodyAnchors = []
            }

        step body acc =
            let
                au =
                    (getStellarOrbit body).au

                edge =
                    MapEdge x acc.prevY x acc.currentY False (Just (formatAU au))

                bodyNode =
                    makeBodyNode body x acc.currentY

                extra =
                    case body of
                        Star secStarData ->
                            let
                                secInner =
                                    getInnerStarData secStarData

                                ( compN, compE ) =
                                    layoutCompanion secInner.companion x acc.currentY

                                secBodies =
                                    secInner.stellarObjects
                                        |> List.filter (isKnown si)
                                        |> List.filter isDisplayable

                                subSpine =
                                    layoutSpine secBodies si (nestLevel + 1) (acc.currentY + starToBodyGap) acc.currentY

                                secShadow =
                                    computeVerticalShadow secInner (nestX (nestLevel + 1)) acc.currentY subSpine.bodyAnchors

                                connector =
                                    if not (List.isEmpty secBodies) then
                                        [ MapEdge x acc.currentY (nestX (nestLevel + 1)) acc.currentY True Nothing ]

                                    else
                                        []
                            in
                            { nodes = compN ++ subSpine.nodes
                            , edges = compE ++ connector ++ subSpine.edges
                            , shadows = maybeToList secShadow ++ subSpine.jumpShadows
                            , nextY = max subSpine.currentY (acc.currentY + vertStep)
                            }

                        _ ->
                            { nodes = [], edges = [], shadows = [], nextY = acc.currentY + vertStep }
            in
            { nodes = acc.nodes ++ bodyNode :: extra.nodes
            , edges = acc.edges ++ edge :: extra.edges
            , jumpShadows = acc.jumpShadows ++ extra.shadows
            , currentY = extra.nextY
            , prevY = acc.currentY
            , bodyAnchors = acc.bodyAnchors ++ [ ( au, acc.currentY ) ]
            }
    in
    List.foldl step init bodies


layoutCompanion : Maybe StarData -> Float -> Float -> ( List MapNode, List MapEdge )
layoutCompanion maybeComp x y =
    case maybeComp of
        Nothing ->
            ( [], [] )

        Just comp ->
            let
                cx =
                    x + starRadius * 2 + companionGap
            in
            ( [ makeStarNode comp cx y ]
            , [ MapEdge x y cx y True Nothing ]
            )


nestX : Int -> Float
nestX level =
    baseSpineX + toFloat level * nestIndent


{-| Compute the y position where the jump shadow ends on a vertical spine.
Returns Nothing if the star has no jump shadow or no body anchors.
-}
computeVerticalShadow : InnerStarData -> Float -> Float -> List ( Float, Float ) -> Maybe MapJumpShadow
computeVerticalShadow star x parentY bodyAnchors =
    case star.jumpShadow of
        Nothing ->
            Nothing

        Just jumpShadowKMs ->
            if List.isEmpty bodyAnchors then
                Nothing

            else
                let
                    jumpAU =
                        jumpShadowKMs / auToKMs 1

                    anchors =
                        ( 0, parentY ) :: bodyAnchors

                    insideY =
                        anchors
                            |> List.filter (\( au, _ ) -> au <= jumpAU)
                            |> List.map Tuple.second
                            |> List.maximum

                    outsideY =
                        anchors
                            |> List.filter (\( au, _ ) -> au > jumpAU)
                            |> List.map Tuple.second
                            |> List.minimum

                    shadowEndY =
                        case ( insideY, outsideY ) of
                            ( Just iy, Just oy ) ->
                                (iy + oy) / 2

                            ( Just iy, Nothing ) ->
                                iy + vertStep / 2

                            ( Nothing, Just oy ) ->
                                (parentY + oy) / 2

                            ( Nothing, Nothing ) ->
                                parentY + vertStep / 2
                in
                Just
                    { x1 = x
                    , y1 = parentY
                    , x2 = x
                    , y2 = shadowEndY
                    , colour = starFillColour star.colour
                    , hasMarker = True
                    }



-- ── NODE CREATION ────────────────────────────────────────────────────────────


makeStarNode : StarData -> Float -> Float -> MapNode
makeStarNode (StarDataWrap starData) x y =
    { x = x
    , y = y
    , radius = starRadius
    , kind = StarNodeKind
    , fillColour = starFillColour starData.colour
    , label = starLabel starData
    , sublabel = Nothing
    , stellarObject = Star (StarDataWrap starData)
    }


makeBodyNode : StellarObject -> Float -> Float -> MapNode
makeBodyNode body x y =
    case body of
        GasGiant data ->
            { x = x
            , y = y
            , radius = gasGiantRadius
            , kind = GasGiantNodeKind
            , fillColour = "#8b5cf6"
            , label = data.code
            , sublabel = Nothing
            , stellarObject = body
            }

        TerrestrialPlanet data ->
            { x = x
            , y = y
            , radius = terrRadius
            , kind = TerrestrialNodeKind
            , fillColour = terrestrialColour data
            , label = data.uwp
            , sublabel = Nothing
            , stellarObject = body
            }

        PlanetoidBelt data ->
            { x = x
            , y = y
            , radius = beltRadius
            , kind = BeltNodeKind
            , fillColour = "#64748b"
            , label = data.uwp
            , sublabel = Nothing
            , stellarObject = body
            }

        Planetoid data ->
            { x = x
            , y = y
            , radius = terrRadius
            , kind = TerrestrialNodeKind
            , fillColour = terrestrialColour data
            , label = data.uwp
            , sublabel = Nothing
            , stellarObject = body
            }

        Star starData ->
            makeStarNode starData x y


starLabel : InnerStarData -> String
starLabel star =
    star.stellarType
        ++ (star.subtype |> Maybe.map String.fromInt |> Maybe.withDefault "")
        ++ " "
        ++ star.stellarClass


terrestrialColour : SharedPData -> String
terrestrialColour pdata =
    let
        atmo =
            pdata.atmosphere.code

        hydro =
            pdata.hydrographics |> Maybe.map .code |> Maybe.withDefault 0
    in
    if atmo == 10 then
        "#16a34a"

    else if atmo == 11 then
        "#f59e0b"

    else if atmo == 12 then
        "#ef4444"

    else if atmo == 0 then
        "#78716c"

    else if hydro == 0 then
        "#d97706"

    else if hydro <= 2 then
        "#b45309"

    else if hydro <= 4 then
        "#0e7490"

    else if hydro <= 6 then
        "#0369a1"

    else if hydro <= 8 then
        "#1d4ed8"

    else
        "#1e40af"



-- ── FILTERS ──────────────────────────────────────────────────────────────────


isKnown : Int -> StellarObject -> Bool
isKnown si obj =
    case obj of
        GasGiant _ ->
            si >= 5

        TerrestrialPlanet _ ->
            si >= 6

        PlanetoidBelt _ ->
            si >= 6

        Planetoid _ ->
            si >= 6

        Star starData ->
            if isBrownDwarf (getInnerStarData starData) then
                si >= 4

            else
                si >= 3


isDisplayable : StellarObject -> Bool
isDisplayable obj =
    case obj of
        Planetoid pdata ->
            pdata.size /= "S" && pdata.size /= "0"

        _ ->
            True



-- ── SVG RENDERING ────────────────────────────────────────────────────────────


svgDefs : Svg msg
svgDefs =
    Svg.defs []
        [ Svg.linearGradient
            [ SA.id "gg-bands", SA.x1 "0", SA.y1 "0", SA.x2 "0", SA.y2 "1" ]
            [ Svg.stop [ SA.offset "0%", SA.stopColor "#c4b5fd" ] []
            , Svg.stop [ SA.offset "25%", SA.stopColor "#8b5cf6" ] []
            , Svg.stop [ SA.offset "50%", SA.stopColor "#c4b5fd" ] []
            , Svg.stop [ SA.offset "75%", SA.stopColor "#7c3aed" ] []
            , Svg.stop [ SA.offset "100%", SA.stopColor "#a78bfa" ] []
            ]
        , Svg.node "symbol"
            [ SA.id "jump-shadow-marker", SA.viewBox "0 0 640 640" ]
            [ Svg.path [ SA.d "M416 104L184 320L416 536L416 104z" ] [] ]
        , Svg.node "symbol"
            [ SA.id "belt-icon", SA.viewBox "-16 -16 32 32" ]
            [ Svg.polygon [ SA.points "-12,-6 -7,-10 -3,-5 -6,-1 -10,-2", SA.fill "#94a3b8" ] []
            , Svg.polygon [ SA.points "4,-11 10,-9 8,-4 3,-6", SA.fill "#cbd5e1" ] []
            , Svg.polygon [ SA.points "-10,4 -5,2 -2,7 -7,10", SA.fill "#64748b" ] []
            , Svg.polygon [ SA.points "2,1 8,-1 11,5 7,8 3,6", SA.fill "#94a3b8" ] []
            , Svg.polygon [ SA.points "-1,9 4,11 1,14 -3,12", SA.fill "#cbd5e1" ] []
            ]
        , Svg.filter [ SA.id "jump-glow" ]
            [ Svg.feGaussianBlur
                [ SA.in_ "SourceGraphic", SA.stdDeviation "2.5", SA.result "blur" ]
                []
            , Svg.feMerge []
                [ Svg.feMergeNode [ SA.in_ "blur" ] []
                , Svg.feMergeNode [ SA.in_ "SourceGraphic" ] []
                ]
            ]
        ]


svgStyle : Svg msg
svgStyle =
    Svg.node "style"
        []
        [ Svg.text """
            .sm-au { font-family: ui-monospace, monospace; font-size: 10px; fill: #2A6A8A; }
            .sm-star-label { font-family: "Orbitron", system-ui, sans-serif; font-size: 12px; fill: #1A3A5A; font-weight: 600; letter-spacing: 0.04em; }
            .sm-body-label { font-family: ui-monospace, monospace; font-size: 10px; fill: #2A6A8A; }
            .sm-travel { font-family: ui-monospace, monospace; font-size: 10px; fill: #007A6A; }
            .sm-travel-btn { font-size: 12px; fill: #4A7A9A; cursor: pointer; font-family: ui-monospace, monospace; }
            .sm-travel-btn:hover { fill: #007A6A; }
            .sm-travel-btn-active { font-size: 12px; fill: #007A6A; cursor: pointer; font-family: ui-monospace, monospace; }
            .sm-jump-time { font-family: ui-monospace, monospace; font-size: 10px; fill: #4A7A9A; }
            .sm-node:hover circle { opacity: 0.75; }
            .sm-node { cursor: pointer; }
        """
        ]


renderEdges : List MapEdge -> Svg msg
renderEdges edges =
    Svg.g [] (List.map renderEdge edges)


renderEdge : MapEdge -> Svg msg
renderEdge edge =
    let
        isVertical =
            edge.x1 == edge.x2

        dashAttr =
            if edge.isDashed then
                [ SA.strokeDasharray "6 3" ]

            else
                []

        lineEl =
            Svg.line
                ([ SA.x1 (String.fromFloat edge.x1)
                 , SA.y1 (String.fromFloat edge.y1)
                 , SA.x2 (String.fromFloat edge.x2)
                 , SA.y2 (String.fromFloat edge.y2)
                 , SA.stroke "#8AAFC4"
                 , SA.strokeWidth "3"
                 , SA.strokeLinecap "round"
                 ]
                    ++ dashAttr
                )
                []

        labelEls =
            case edge.auLabel of
                Nothing ->
                    []

                Just label ->
                    [ Svg.text_
                        [ SA.x (String.fromFloat ((edge.x1 + edge.x2) / 2))
                        , SA.y (String.fromFloat ((edge.y1 + edge.y2) / 2 + 4))
                        , SA.textAnchor "middle"
                        , SA.class "sm-au"
                        ]
                        [ Svg.text label ]
                    ]
    in
    Svg.g [] (lineEl :: labelEls)


renderJumpShadows : List MapJumpShadow -> Svg msg
renderJumpShadows shadows =
    Svg.g [] (List.map renderJumpShadow shadows)


renderJumpShadow : MapJumpShadow -> Svg msg
renderJumpShadow shadow =
    let
        lineEl =
            Svg.line
                [ SA.x1 (String.fromFloat shadow.x1)
                , SA.y1 (String.fromFloat shadow.y1)
                , SA.x2 (String.fromFloat shadow.x2)
                , SA.y2 (String.fromFloat shadow.y2)
                , SA.stroke shadow.colour
                , SA.strokeWidth "5"
                , SA.strokeLinecap "round"
                , SA.filter "url(#jump-glow)"
                , SA.opacity "0.7"
                ]
                []

        -- Marker at the boundary end of the shadow (x2, y2), rotated to point downward
        markerEl =
            Svg.node "use"
                [ SA.xlinkHref "#jump-shadow-marker"
                , SA.x (String.fromFloat (shadow.x2 - 10))
                , SA.y (String.fromFloat (shadow.y2 - 10))
                , SA.width "20"
                , SA.height "20"
                , SA.fill shadow.colour
                , SA.transform
                    ("rotate(90,"
                        ++ String.fromFloat shadow.x2
                        ++ ","
                        ++ String.fromFloat shadow.y2
                        ++ ")"
                    )
                , SA.filter "url(#jump-glow)"
                , SA.opacity "0.9"
                ]
                []
    in
    Svg.g [] <|
        if shadow.hasMarker then
            [ lineEl, markerEl ]

        else
            [ lineEl ]


renderNodes : StellarObjectMsgs msg -> Maybe StellarObject -> List MapNode -> Svg msg
renderNodes msgs selectedStellarObject nodes =
    Svg.g [] (List.map (renderNode msgs selectedStellarObject) nodes)


renderNode : StellarObjectMsgs msg -> Maybe StellarObject -> MapNode -> Svg msg
renderNode msgs selectedStellarObject node =
    let
        isSelected =
            selectedStellarObject == Just node.stellarObject

        strokeColour =
            "#1A4A6A"

        strokeWidth =
            "1.5"

        circleEl =
            case node.kind of
                GasGiantNodeKind ->
                    Svg.circle
                        [ SA.cx (String.fromFloat node.x)
                        , SA.cy (String.fromFloat node.y)
                        , SA.r (String.fromFloat node.radius)
                        , SA.fill "url(#gg-bands)"
                        , SA.stroke strokeColour
                        , SA.strokeWidth strokeWidth
                        ]
                        []

                BeltNodeKind ->
                    Svg.node "use"
                        [ SA.xlinkHref "#belt-icon"
                        , SA.x (String.fromFloat (node.x - node.radius))
                        , SA.y (String.fromFloat (node.y - node.radius))
                        , SA.width (String.fromFloat (node.radius * 2))
                        , SA.height (String.fromFloat (node.radius * 2))
                        ]
                        []

                _ ->
                    Svg.circle
                        [ SA.cx (String.fromFloat node.x)
                        , SA.cy (String.fromFloat node.y)
                        , SA.r (String.fromFloat node.radius)
                        , SA.fill node.fillColour
                        , SA.stroke strokeColour
                        , SA.strokeWidth strokeWidth
                        ]
                        []

        labelX =
            node.x + node.radius + 8

        travelLabel =
            case selectedStellarObject of
                Nothing ->
                    Nothing

                Just so ->
                    if so == node.stellarObject then
                        Nothing

                    else
                        let
                            dist =
                                calcDistance2F
                                    (getStellarOrbit so).orbitPosition
                                    (getStellarOrbit node.stellarObject).orbitPosition

                            secs =
                                travelTimeInSeconds dist shipMDrive
                        in
                        Just (secondsToDaysWatches secs)

        labelY =
            node.y + 4

        ( labelClass, charWidth ) =
            case node.kind of
                StarNodeKind ->
                    ( "sm-star-label", 8.5 )

                _ ->
                    ( "sm-body-label", 6.2 )

        -- Estimate where the label text ends so the travel-time icon can follow
        iconX =
            labelX + toFloat (String.length node.label) * charWidth + 5

        jumpTimeEl =
            Svg.text_
                [ SA.x (String.fromFloat (node.x - node.radius - 4))
                , SA.y (String.fromFloat labelY)
                , SA.textAnchor "end"
                , SA.class "sm-jump-time"
                ]
                [ Svg.text (getSafeJumpTime node.stellarObject) ]

        -- ⊙ when not selected (click to set as travel reference), ⊛ when active
        travelIconClass =
            if isSelected then
                "sm-travel-btn-active"

            else
                "sm-travel-btn"

        travelIconChar =
            if isSelected then
                "⊛"

            else
                "⊙"

        -- Wrap in a g with stopPropagation so clicking the icon does NOT
        -- also trigger the outer onViewDetail handler
        travelIconEl =
            Svg.g
                [ Html.Events.stopPropagationOn "click"
                    (Json.Decode.succeed ( msgs.onFocusInSidebar node.stellarObject, True ))
                ]
                [ Svg.text_
                    [ SA.x (String.fromFloat iconX)
                    , SA.y (String.fromFloat labelY)
                    , SA.class travelIconClass
                    ]
                    [ Svg.text travelIconChar ]
                ]

        labelEls =
            List.filterMap identity
                [ Just
                    (Svg.text_
                        [ SA.x (String.fromFloat labelX)
                        , SA.y (String.fromFloat labelY)
                        , SA.class labelClass
                        ]
                        [ Svg.text node.label ]
                    )
                , travelLabel
                    |> Maybe.map
                        (\tt ->
                            Svg.text_
                                [ SA.x (String.fromFloat labelX)
                                , SA.y (String.fromFloat (labelY + 14))
                                , SA.class "sm-travel"
                                ]
                                [ Svg.text tt ]
                        )
                ]
    in
    Svg.g
        [ SE.onClick (msgs.onViewDetail node.stellarObject)
        , SA.class "sm-node"
        ]
        (circleEl :: travelIconEl :: jumpTimeEl :: labelEls)



-- ── HELPERS ──────────────────────────────────────────────────────────────────


formatAU : Float -> String
formatAU au =
    if au >= 10 then
        Round.round 0 au

    else if au >= 1 then
        Round.round 1 au

    else
        Round.round 2 au


maybeToList : Maybe a -> List a
maybeToList m =
    case m of
        Just x ->
            [ x ]

        Nothing ->
            []
