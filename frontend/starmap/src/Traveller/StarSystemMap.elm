module Traveller.StarSystemMap exposing (MapNode, systemNodes, viewStarSystemMap)

{-| Vertical subway-style SVG map of a star system.

Primary star's bodies are laid out top-to-bottom on a central spine.
Secondary stars branch off at their orbital position with their own
indented sub-spine, mirroring the approach chosen for the visual design.

-}

import Element exposing (Element)
import Round
import Svg exposing (Svg)
import Svg.Attributes as SA
import Svg.Events as SE
import Traveller.SolarSystem exposing (SolarSystem)
import Traveller.StarColour exposing (starFillColour)
import Traveller.StellarObject
    exposing
        ( GasGiantData
        , InnerStarData
        , SharedPData
        , StarData(..)
        , StellarObject(..)
        , getInnerStarData
        , getSafeJumpTime
        , getStellarOrbit
        , isBrownDwarf
        )
import Traveller.StellarObjectView exposing (StellarObjectMsgs)
import Traveller.TravelCalculations exposing (auToKMs)



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
    8.05


beltRadius : Float
beltRadius =
    9


defaultRadius : Float
defaultRadius =
    5



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
    , image : Maybe String
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



-- ── IMAGE SELECTION ─────────────────────────────────────────────────────────


startsWithPrefix : String -> String -> Bool
startsWithPrefix prefix str =
    String.left (String.length prefix) str == prefix


standardStarTypes : List String
standardStarTypes =
    [ "O", "B", "A", "F", "G", "K", "M", "BD", "NS", "D", "PS", "L", "T", "Y" ]


starImageName : InnerStarData -> Maybe String
starImageName star =
    let
        upperType =
            String.toUpper star.stellarType
    in
    if List.member upperType standardStarTypes then
        Just (String.toLower upperType ++ "_star")

    else
        Nothing


gasGiantImageName : GasGiantData -> Maybe String
gasGiantImageName data =
    case data.code of
        "GS" ->
            Just "gg_small"

        "GM" ->
            Just "gg_medium"

        "GL" ->
            Just "gg_large"

        _ ->
            Nothing


terrestrialImageName : SharedPData -> Maybe String
terrestrialImageName pdata =
    let
        atmo =
            pdata.atmosphere.code

        hydro =
            pdata.hydrographics |> Maybe.map .code |> Maybe.withDefault 0

        temp =
            pdata.meanTemperature

        density =
            pdata.atmosphere.density |> Maybe.withDefault ""

        isSparse =
            startsWithPrefix "Trace" density
                || startsWithPrefix "Thin" density
                || startsWithPrefix "Very Thin" density
    in
    if atmo == 10 then
        Just "unusual"

    else if atmo == 11 then
        Just "corrosive"

    else if atmo == 12 then
        Just "insidious"

    else if atmo == 13 then
        Just "dense"

    else if atmo == 14 then
        Just "low"

    else if atmo == 15 then
        Just "unusual"

    else if atmo == 16 then
        Just "helium"

    else if atmo == 17 then
        Just "hydrogen"

    else if String.toUpper pdata.atmosphere.taint.code == "B" then
        Just "biological"

    else if hydro == 0 then
        if temp |> Maybe.map (\t -> t > 473.15) |> Maybe.withDefault False then
            Just "hot_rockball"

        else if isSparse then
            Just "trace"

        else
            Just "desert"

    else if temp |> Maybe.map (\t -> t >= 673.15) |> Maybe.withDefault False then
        Just "molten"

    else if temp |> Maybe.map (\t -> t < 263.15) |> Maybe.withDefault False then
        Just "ice"

    else if atmo >= 2 && atmo <= 9 then
        if hydro == 10 then
            Just "waterworld"

        else if hydro >= 1 && hydro <= 9 then
            Just ("tp_" ++ String.fromInt (hydro * 10))

        else
            Nothing

    else
        Nothing



-- ── ENTRY POINT ──────────────────────────────────────────────────────────────


viewStarSystemMap : StellarObjectMsgs msg -> SolarSystem -> Bool -> Maybe Int -> Element msg
viewStarSystemMap msgs solarSystem isReferee mDrive =
    let
        showNames =
            isReferee || solarSystem.surveyIndex >= 10

        layout =
            computeLayout showNames solarSystem

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
            , renderJumpShadows layout.jumpShadows
            , renderEdges layout.edges
            , renderNodes msgs mDrive layout.nodes
            ]



-- ── LAYOUT ───────────────────────────────────────────────────────────────────


computeLayout : Bool -> SolarSystem -> MapLayout
computeLayout showNames solarSystem =
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
            layoutSpine showNames filteredBodies si 0 (topY + starToBodyGap) topY

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
layoutSpine : Bool -> List StellarObject -> Int -> Int -> Float -> Float -> SpineAcc
layoutSpine showNames bodies si nestLevel startY prevY =
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
                    makeBodyNode showNames body x acc.currentY

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
                                    layoutSpine showNames secBodies si (nestLevel + 1) (acc.currentY + starToBodyGap) acc.currentY

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
    , image = starImageName starData
    }


nameLabel : Maybe String -> String -> ( String, Maybe String )
nameLabel maybeName defaultLabel =
    case maybeName of
        Just n ->
            ( n, Just defaultLabel )

        Nothing ->
            ( defaultLabel, Nothing )


makeBodyNode : Bool -> StellarObject -> Float -> Float -> MapNode
makeBodyNode showNames body x y =
    case body of
        GasGiant data ->
            let
                ( lbl, sub ) =
                    if showNames then
                        nameLabel data.name data.code

                    else
                        ( data.code, Nothing )
            in
            { x = x
            , y = y
            , radius = gasGiantRadius
            , kind = GasGiantNodeKind
            , fillColour = "#8b5cf6"
            , label = lbl
            , sublabel = sub
            , stellarObject = body
            , image = gasGiantImageName data
            }

        TerrestrialPlanet data ->
            let
                ( lbl, sub ) =
                    if showNames then
                        nameLabel data.name data.uwp

                    else
                        ( data.uwp, Nothing )
            in
            { x = x
            , y = y
            , radius = terrRadius
            , kind = TerrestrialNodeKind
            , fillColour = terrestrialColour data
            , label = lbl
            , sublabel = sub
            , stellarObject = body
            , image = terrestrialImageName data
            }

        PlanetoidBelt data ->
            let
                ( lbl, sub ) =
                    if showNames then
                        nameLabel data.name data.uwp

                    else
                        ( data.uwp, Nothing )
            in
            { x = x
            , y = y
            , radius = beltRadius
            , kind = BeltNodeKind
            , fillColour = "#64748b"
            , label = lbl
            , sublabel = sub
            , stellarObject = body
            , image = Just "planetoid_belt"
            }

        Planetoid data ->
            let
                ( lbl, sub ) =
                    if showNames then
                        nameLabel data.name data.uwp

                    else
                        ( data.uwp, Nothing )
            in
            { x = x
            , y = y
            , radius = terrRadius
            , kind = TerrestrialNodeKind
            , fillColour = terrestrialColour data
            , label = lbl
            , sublabel = sub
            , stellarObject = body
            , image = terrestrialImageName data
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
        [ Svg.clipPath
            [ SA.id "circle-clip"
            , SA.clipPathUnits "objectBoundingBox"
            ]
            [ Svg.circle [ SA.cx "0.5", SA.cy "0.5", SA.r "0.5" ] [] ]
        , Svg.linearGradient
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
            .sm-au { font-family: ui-monospace, monospace; font-size: 10px; fill: var(--color-fg-muted); }
            .sm-star-label { font-family: "Tomorrow", system-ui, sans-serif; font-size: 12px; fill: var(--color-highlight); font-weight: 600; letter-spacing: 0.04em; }
            .sm-body-label { font-family: ui-monospace, monospace; font-size: 10px; fill: var(--color-highlight); }
            .sm-body-sublabel { font-family: ui-monospace, monospace; font-size: 9px; fill: var(--color-fg-muted); }
            .sm-orbit-sequence { font-family: ui-monospace, monospace; font-size: 10px; fill: var(--color-fg-muted); }
            .sm-jump-time { font-family: ui-monospace, monospace; font-size: 9px; fill: var(--color-fg-muted); }
            .sm-node:hover circle, .sm-node:hover image { opacity: 0.75; }
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
                 , SA.stroke "var(--color-outline)"
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


renderNodes : StellarObjectMsgs msg -> Maybe Int -> List MapNode -> Svg msg
renderNodes msgs mDrive nodes =
    Svg.g [] (List.map (renderNode msgs mDrive) nodes)


renderNode : StellarObjectMsgs msg -> Maybe Int -> MapNode -> Svg msg
renderNode msgs mDrive node =
    let
        strokeColour =
            "var(--color-outline)"

        strokeWidth =
            "1.5"

        circleEl =
            case node.image of
                Just imageName ->
                    Svg.image
                        [ SA.xlinkHref ("/stellar_objects/" ++ imageName ++ ".webp")
                        , SA.x (String.fromFloat (node.x - node.radius))
                        , SA.y (String.fromFloat (node.y - node.radius))
                        , SA.width (String.fromFloat (node.radius * 2))
                        , SA.height (String.fromFloat (node.radius * 2))
                        , SA.clipPath "url(#circle-clip)"
                        , SA.preserveAspectRatio "xMidYMid slice"
                        ]
                        []

                Nothing ->
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

        labelY =
            node.y + 4

        labelClass =
            case node.kind of
                StarNodeKind ->
                    "sm-star-label"

                _ ->
                    "sm-body-label"

        leftX =
            String.fromFloat (node.x - node.radius - 4)

        orbitSequenceEl =
            Svg.text_
                [ SA.x leftX
                , SA.y (String.fromFloat (node.y - 5))
                , SA.textAnchor "end"
                , SA.class "sm-orbit-sequence"
                ]
                [ Svg.text (getStellarOrbit node.stellarObject).orbitSequence ]

        jumpTimeEl =
            Svg.text_
                [ SA.x leftX
                , SA.y (String.fromFloat (node.y + 9))
                , SA.textAnchor "end"
                , SA.class "sm-jump-time"
                ]
                [ Svg.text (getSafeJumpTime mDrive node.stellarObject) ]

        labelEl =
            Svg.text_
                [ SA.x (String.fromFloat labelX)
                , SA.y (String.fromFloat labelY)
                , SA.class labelClass
                ]
                [ Svg.text node.label ]

        sublabelEls =
            case node.sublabel of
                Nothing ->
                    []

                Just sub ->
                    [ Svg.text_
                        [ SA.x (String.fromFloat labelX)
                        , SA.y (String.fromFloat (labelY + 12))
                        , SA.class "sm-body-sublabel"
                        ]
                        [ Svg.text sub ]
                    ]
    in
    Svg.g
        [ SE.onClick (msgs.onViewDetail node.stellarObject)
        , SA.class "sm-node"
        ]
        ([ circleEl, orbitSequenceEl, jumpTimeEl, labelEl ] ++ sublabelEls)



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


systemNodes : Bool -> SolarSystem -> List MapNode
systemNodes showNames solarSystem =
    (computeLayout showNames solarSystem).nodes
