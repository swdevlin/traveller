module Traveller.StarOrbitMap exposing
    ( ChildNode
    , Config
    , ResizeConfig
    , StatItem
    , buildChildren
    , viewModal
    )

{-| Resizable orbit map of a star's immediate children, radially ranked
(not placed by absolute AU/orbit magnitude) so unevenly-clustered real
astronomical spacing stays legible.
-}

import Html exposing (Html)
import Html.Attributes as HtmlAttrs
import Html.Events
import Html.Events.Extra.Mouse as Mouse
import Json.Decode as JsDecode
import List.Extra
import Round
import Svg exposing (Svg)
import Svg.Attributes as SA
import Svg.Events as SE
import Traveller.StarSystemMap as StarSystemMap
import Traveller.StellarObject
    exposing
        ( StarData
        , StellarObject(..)
        , getInnerStarData
        , getStellarOrbit
        )
import Traveller.TravelCalculations as TravelCalculations



-- ── TYPES ────────────────────────────────────────────────────────────────────


type alias ChildNode =
    { stellarObject : StellarObject
    , xKm : Float
    , yKm : Float
    , au : Float
    , orbit : Float
    , eccentricity : Float
    , syntheticIndex : Maybe Int
    }


type alias StatItem =
    { label : String
    , value : String
    }


type alias Config msg =
    { close : msg
    , noOp : msg
    , onSelectObject : StellarObject -> msg
    , zIndex : Int
    }


type alias ResizeConfig msg =
    { width : Float
    , height : Float
    , onResizeStart : { startX : Float, startY : Float } -> msg
    }



-- ── CHILD LIST ───────────────────────────────────────────────────────────────


{-| The star's companion (if any) plus its immediate non-star-recursed
children, filtered by survey visibility, with a synthesized fan-out angle
assigned to any child whose orbit\_x/orbit\_y are both absent (0,0).
-}
buildChildren : Int -> Maybe StarData -> List StellarObject -> List ChildNode
buildChildren surveyIndex maybeCompanion stellarObjects =
    let
        companionList =
            case maybeCompanion of
                Just companionStarData ->
                    [ Star companionStarData ]

                Nothing ->
                    []

        visibleChildren =
            (companionList ++ stellarObjects)
                |> List.filter (StarSystemMap.isKnown surveyIndex)
                |> List.filter StarSystemMap.isDisplayable

        toRawChild obj =
            let
                orbit =
                    getStellarOrbit obj
            in
            { stellarObject = obj
            , xKm = orbit.orbitPosition.x
            , yKm = orbit.orbitPosition.y
            , au = orbit.au
            , orbit = orbit.orbit
            , eccentricity = orbit.eccentricity
            , syntheticIndex = Nothing
            }

        assignSynthetic child ( nextIndex, acc ) =
            if child.xKm == 0 && child.yKm == 0 then
                ( nextIndex + 1, { child | syntheticIndex = Just nextIndex } :: acc )

            else
                ( nextIndex, child :: acc )
    in
    visibleChildren
        |> List.map toRawChild
        |> List.foldl assignSynthetic ( 0, [] )
        |> Tuple.second
        |> List.reverse



-- ── RANKED RADIAL PROJECTION ─────────────────────────────────────────────────


goldenAngleRadians : Float
goldenAngleRadians =
    2.399963


{-| How many multiples of this star's typical adjacent-orbit-number spacing
a gap between consecutive children needs to be to count as a hard break —
e.g. a companion star orbiting far outside the planetary system, rather
than just the outermost "normal" planet. Tunable; not derived from any
game rule.
-}
outlierGapMultiplier : Float
outlierGapMultiplier =
    4


{-| The star's typical adjacent-orbit-number spacing: `spread`, with
`baseline` (clamped to at least 1, per the generator's own rule) as a
floor, and an absolute floor so a 0-1-child system's degenerate/zero
spread can't collapse the outlier threshold to zero.
-}
typicalOrbitGap : StarData -> Float
typicalOrbitGap primaryStarData =
    let
        inner =
            getInnerStarData primaryStarData
    in
    max 0.5 (max inner.baseline 1 * inner.spread)


{-| Splits children into a "core" cluster and far outliers, based on the
single largest gap between consecutive orbit numbers (sorted ascending).
If no gap exceeds `orbitGapThreshold`, everything is core.
-}
partitionCoreAndOutliers : Float -> List ChildNode -> ( List ChildNode, List ChildNode )
partitionCoreAndOutliers orbitGapThreshold children =
    let
        sorted =
            children |> List.sortBy .orbit

        orbits =
            sorted |> List.map .orbit

        gaps =
            List.map2 (\a b -> b - a) orbits (List.drop 1 orbits)
                |> List.indexedMap Tuple.pair

        splitIndex =
            gaps
                |> List.Extra.maximumBy Tuple.second
                |> Maybe.andThen
                    (\( index, gap ) ->
                        if gap > orbitGapThreshold then
                            Just index

                        else
                            Nothing
                    )
    in
    case splitIndex of
        Just index ->
            ( List.take (index + 1) sorted, List.drop (index + 1) sorted )

        Nothing ->
            ( sorted, [] )


type alias ProjectedChild =
    { node : StarSystemMap.MapNode
    , auDist : Float
    , pixelR : Float
    , au : Float
    , eccentricity : Float
    }


{-| The real orbital distance (in AU): shown in the label, and used (as
relative gaps, not absolute magnitude) to perturb the ranked core layout —
see `rankedCorePositions`.
-}
childAuDist : ChildNode -> Float
childAuDist child =
    let
        rKm =
            sqrt (child.xKm ^ 2 + child.yKm ^ 2)
    in
    if rKm == 0 then
        max child.au 0.01

    else
        TravelCalculations.kmToAu rKm


{-| How strongly a real AU gap that's bigger or smaller than the previous
real AU gap nudges this object's evenly-ranked position outward/inward, as
a fraction of the baseline per-step size (clamped so the relative-gap
comparison never moves an object more than half a step — this keeps
positions strictly increasing, so ranked order can never invert).
-}
gapAdjustmentFactor : Float
gapAdjustmentFactor =
    0.5


{-| Caps how far an orbit ring's ellipse can stretch beyond its object's own
schematic ring radius (`pixelR`) when eccentricity is high and the object's
real generated position happens to sit near its true periapsis (where the
recovered ellipse is largest). Without this, a handful of real systems with
`eccentricity` approaching 1 would draw ellipses that swallow several
neighbouring rings. Tunable; not derived from any game rule. In the rare
clamped case the object sits fractionally off its drawn ring rather than
exactly on it.
-}
maxOrbitStretch : Float
maxOrbitStretch =
    3


{-| Radial pixel position for each of the core children (sorted ascending
by real AU distance), evenly ranked from `coreInnerPx` to `coreOuterPx`
(1st-closest, 2nd-closest, ...) rather than placed by absolute AU/orbit
magnitude — real astronomical spacing is too unevenly clustered for any
absolute-value scale to stay legible (a system with bodies at, say, 0.15,
0.30, 0.49, 0.64 AU has real gaps of 0.15/0.19/0.15 AU; those differences
are what perturb the otherwise-even spacing below, not the raw magnitudes).

Each step is the baseline spacing, nudged by how much bigger/smaller this
object's real gap is than the previous object's real gap, relative to the
cluster's own average gap — so e.g. the object after an unusually large
gap sits a bit further out than a strictly even layout would put it, and
the object after that (once the gap shrinks back) sits correspondingly
closer in, without the full magnitude of either gap ever dominating.
-}
rankedCorePositions : Float -> Float -> List ChildNode -> List Float
rankedCorePositions coreInnerPx coreOuterPx sortedCore =
    let
        n =
            List.length sortedCore

        step =
            (coreOuterPx - coreInnerPx) / toFloat (n + 1)

        distances =
            sortedCore |> List.map childAuDist

        gaps =
            List.map2 (\a b -> b - a) distances (List.drop 1 distances)

        averageGap =
            case gaps of
                [] ->
                    1.0

                _ ->
                    let
                        total =
                            List.sum gaps
                    in
                    if total == 0 then
                        1.0

                    else
                        total / toFloat (List.length gaps)

        adjustment thisGap prevGap =
            clamp -1 1 ((thisGap - prevGap) / averageGap) * gapAdjustmentFactor * step

        firstPosition =
            coreInnerPx + step
    in
    case gaps of
        [] ->
            List.repeat n firstPosition

        firstGap :: restGaps ->
            let
                secondPosition =
                    firstPosition + step

                ( _, _, restPositionsReversed ) =
                    restGaps
                        |> List.foldl
                            (\gap ( prevGap, prevPosition, acc ) ->
                                let
                                    nextPosition =
                                        prevPosition + step + adjustment gap prevGap
                                in
                                ( gap, nextPosition, nextPosition :: acc )
                            )
                            ( firstGap, secondPosition, [] )
            in
            firstPosition :: secondPosition :: List.reverse restPositionsReversed


{-| The primary star's jump-shadow boundary radius, found the same way the
schematic subway map (`StarSystemMap.computeVerticalShadow`) already does:
bracket the shadow's real AU value between the two nearest known children
(by AU) and take the midpoint of their already-ranked pixel radii, rather
than trying to place it by absolute AU scale (which has no consistent
meaning against a rank-based layout). `Nothing` when there are no core
children to bracket against, mirroring that same precedent.
-}
starJumpShadowRadius : Float -> List ( Float, Float ) -> Float -> Maybe Float
starJumpShadowRadius coreOuterPx auRadiusPairs jumpShadowKm =
    if List.isEmpty auRadiusPairs then
        Nothing

    else
        let
            jumpAu =
                TravelCalculations.kmToAu jumpShadowKm

            anchors =
                ( 0, 0 ) :: auRadiusPairs

            insideR =
                anchors |> List.filter (\( au, _ ) -> au <= jumpAu) |> List.map Tuple.second |> List.maximum

            outsideR =
                anchors |> List.filter (\( au, _ ) -> au > jumpAu) |> List.map Tuple.second |> List.minimum
        in
        case ( insideR, outsideR ) of
            ( Just insideRadius, Just outsideRadius ) ->
                Just ((insideRadius + outsideRadius) / 2)

            ( Just insideRadius, Nothing ) ->
                Just (min coreOuterPx (insideRadius + 20))

            _ ->
                Nothing


renderJumpShadowRing : Float -> Float -> String -> Float -> Svg msg
renderJumpShadowRing centerX centerY colour radius =
    Svg.circle
        [ SA.cx (String.fromFloat centerX)
        , SA.cy (String.fromFloat centerY)
        , SA.r (String.fromFloat radius)
        , SA.fill "none"
        , SA.stroke colour
        , SA.strokeWidth "2"
        , SA.filter "url(#jump-glow)"
        , SA.opacity "0.4"
        ]
        []


{-| Projects a child's real (relative) position onto the map at the given
radius, preserving its true angle (or the synthesized golden-angle fallback
when orbit\_x/orbit\_y are both absent).
-}
projectChild : Float -> Float -> Float -> Bool -> ChildNode -> ProjectedChild
projectChild centerX centerY pixelR showNames child =
    let
        theta =
            case child.syntheticIndex of
                Just index ->
                    toFloat index * goldenAngleRadians

                Nothing ->
                    atan2 child.yKm child.xKm

        auDist =
            childAuDist child

        pixelX =
            centerX + pixelR * cos theta

        pixelY =
            centerY + pixelR * sin theta

        node =
            case child.stellarObject of
                Star starData ->
                    StarSystemMap.makeStarNode starData pixelX pixelY

                _ ->
                    let
                        base =
                            StarSystemMap.makeBodyNode showNames child.stellarObject pixelX pixelY
                    in
                    { base | label = childLabel showNames child.stellarObject, sublabel = Nothing }
    in
    { node = node
    , auDist = auDist
    , pixelR = pixelR
    , au = child.au
    , eccentricity = child.eccentricity
    }


{-| The orbit sequence letter (A, B, C…) or the object's name if it has one
(and names are currently visible to the viewer).
-}
childLabel : Bool -> StellarObject -> String
childLabel showNames obj =
    let
        orbitSequence =
            (getStellarOrbit obj).orbitSequence

        maybeName =
            case obj of
                GasGiant data ->
                    data.name

                TerrestrialPlanet data ->
                    data.name

                PlanetoidBelt data ->
                    data.name

                Planetoid data ->
                    data.name

                Star _ ->
                    Nothing
    in
    if showNames then
        maybeName |> Maybe.withDefault orbitSequence

    else
        orbitSequence


formatAu : Float -> String
formatAu au =
    if au >= 10 then
        Round.round 0 au

    else if au >= 1 then
        Round.round 1 au

    else
        Round.round 2 au



{-| Label sizing distinct from the shared subway-map classes (`.sm-body-label`
etc. in `StarSystemMap.svgStyle`) — this map's tighter layout reads better a
size up from the subway map's body labels.
-}
orbitMapStyle : Svg msg
orbitMapStyle =
    Svg.node "style"
        []
        [ Svg.text """
            .orbit-body-label { font-family: ui-monospace, monospace; font-size: 11px; fill: var(--color-highlight); }
            .orbit-au { font-family: ui-monospace, monospace; font-size: 10px; fill: var(--color-fg-muted); }
        """
        ]



-- ── MAP RENDERING ────────────────────────────────────────────────────────────


viewMap : (StellarObject -> msg) -> Float -> Float -> Bool -> StarData -> List ChildNode -> Html msg
viewMap onSelectObject mapWidth mapHeight showNames primaryStarData children =
    let
        centerX =
            mapWidth / 2

        centerY =
            mapHeight / 2

        innerPx =
            StarSystemMap.starRadius + 16

        outerPx =
            max innerPx ((min mapWidth mapHeight / 2) - StarSystemMap.gasGiantRadius - 8)

        starNode =
            StarSystemMap.makeStarNode primaryStarData centerX centerY

        orbitGapThreshold =
            outlierGapMultiplier * typicalOrbitGap primaryStarData

        ( coreChildren, outlierChildren ) =
            partitionCoreAndOutliers orbitGapThreshold children

        -- Reserve an outer band exclusively for outliers when there are any,
        -- so a pinned companion star never lands on the same ring as the
        -- core system's own outermost object.
        coreOuterPx =
            if List.isEmpty outlierChildren then
                outerPx

            else
                innerPx + 0.8 * (outerPx - innerPx)

        sortedCore =
            coreChildren |> List.sortBy childAuDist

        corePositions =
            rankedCorePositions innerPx coreOuterPx sortedCore

        projected =
            List.map2 (\child pixelR -> projectChild centerX centerY pixelR showNames child) sortedCore corePositions
                ++ (outlierChildren |> List.map (projectChild centerX centerY outerPx showNames))

        orbitRingElements =
            projected |> List.map (renderOrbitRing centerX centerY)

        childElements =
            projected |> List.map (renderMapNode onSelectObject)

        auRadiusPairs =
            List.map2 (\child pixelR -> ( childAuDist child, pixelR )) sortedCore corePositions

        -- Every star drawn on this map gets its own jump-shadow ring — the
        -- primary at the centre, and any companion/secondary star among the
        -- children at its own position — all bracketed against the same
        -- system-wide AU/pixel scale (`auRadiusPairs`/`coreOuterPx`), since
        -- there's no separate local scale for a companion's own orbit in
        -- this view.
        jumpShadowRingFor centerPointX centerPointY colour maybeJumpShadowKm =
            case maybeJumpShadowKm of
                Nothing ->
                    []

                Just jumpShadowKm ->
                    case starJumpShadowRadius coreOuterPx auRadiusPairs jumpShadowKm of
                        Just radius ->
                            [ renderJumpShadowRing centerPointX centerPointY colour radius ]

                        Nothing ->
                            []

        childStarJumpShadowElements =
            projected
                |> List.concatMap
                    (\p ->
                        case p.node.stellarObject of
                            Star childStarData ->
                                jumpShadowRingFor p.node.x p.node.y p.node.fillColour (getInnerStarData childStarData).jumpShadow

                            _ ->
                                []
                    )

        jumpShadowElements =
            jumpShadowRingFor centerX centerY starNode.fillColour (getInnerStarData primaryStarData).jumpShadow
                ++ childStarJumpShadowElements
    in
    Svg.svg
        [ SA.width "100%"
        , SA.height "100%"
        , SA.viewBox ("0 0 " ++ String.fromFloat mapWidth ++ " " ++ String.fromFloat mapHeight)
        , SA.preserveAspectRatio "xMidYMid meet"
        , SA.style "display:block;"
        ]
        (StarSystemMap.svgDefs
            :: StarSystemMap.svgStyle
            :: orbitMapStyle
            :: (jumpShadowElements
                    ++ orbitRingElements
                    ++ [ renderMapNode onSelectObject { node = starNode, auDist = 0, pixelR = 0, au = 0, eccentricity = 0 } ]
                    ++ childElements
               )
        )


{-| The orbit ring's ellipse geometry, recovered from the object's real
generated data rather than assumed. The generator (`assignPosition`) places
each object at a random true point on its real ellipse — star at one focus,
oriented by a random `longitudeOfPeriapsis` — but only the resulting
Cartesian position (`theta`/`r`, via `xKm`/`yKm`) survives; the periapsis
angle itself is never persisted.

Since `r` as a function of true anomaly and `r` as a function of the
generator's eccentric anomaly describe the same real ellipse, the periapsis
direction can be recovered exactly from `theta`, `r`, `a` (`au`) and `e`
(`eccentricity`) via the orbit's polar equation, rather than guessed. The
result is then uniformly rescaled (same factor in every direction) so the
object's own already-plotted ring position (`pixelR`, `theta`) sits exactly
on the drawn ellipse — this preserves the real ellipse's shape/orientation,
only changing its overall size to fit this map's rank-based (not
real-AU-scaled) ring radius.

`maxOrbitStretch` bounds the pixel size for the rare high-eccentricity case
where the object's real position happens to sit near periapsis (where the
recovered ellipse is largest).
-}
orbitEllipse : Float -> Float -> Float -> Float -> Float -> { rx : Float, ry : Float, rotationDeg : Float, offsetX : Float, offsetY : Float }
orbitEllipse theta r a e pixelR =
    let
        eccentricity =
            clamp 0 0.95 e

        cosNu =
            if eccentricity > 1.0e-6 then
                clamp -1 1 (((a * (1 - eccentricity ^ 2)) / r - 1) / eccentricity)

            else
                1

        nu =
            acos cosNu

        periapsisDir =
            theta - nu

        aPxRaw =
            pixelR * (1 + eccentricity * cosNu) / (1 - eccentricity ^ 2)

        aPx =
            min aPxRaw (maxOrbitStretch * pixelR)

        bPx =
            aPx * sqrt (1 - eccentricity ^ 2)

        cPx =
            aPx * eccentricity
    in
    { rx = aPx
    , ry = bPx
    , rotationDeg = periapsisDir * 180 / pi
    , offsetX = -cPx * cos periapsisDir
    , offsetY = -cPx * sin periapsisDir
    }


renderOrbitRing : Float -> Float -> ProjectedChild -> Svg msg
renderOrbitRing centerX centerY projectedChild =
    let
        theta =
            atan2 (projectedChild.node.y - centerY) (projectedChild.node.x - centerX)

        r =
            projectedChild.auDist

        a =
            max projectedChild.au 0.01

        geometry =
            orbitEllipse theta r a projectedChild.eccentricity projectedChild.pixelR

        cx =
            centerX + geometry.offsetX

        cy =
            centerY + geometry.offsetY
    in
    Svg.ellipse
        [ SA.cx (String.fromFloat cx)
        , SA.cy (String.fromFloat cy)
        , SA.rx (String.fromFloat geometry.rx)
        , SA.ry (String.fromFloat geometry.ry)
        , SA.transform ("rotate(" ++ String.fromFloat geometry.rotationDeg ++ " " ++ String.fromFloat cx ++ " " ++ String.fromFloat cy ++ ")")
        , SA.fill "none"
        , SA.stroke "var(--color-outline)"
        , SA.strokeWidth "1"
        , SA.strokeDasharray "2 3"
        , SA.opacity "0.85"
        ]
        []


renderMapNode : (StellarObject -> msg) -> ProjectedChild -> Svg msg
renderMapNode onSelectObject { node, auDist } =
    let
        iconEl =
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
                    Svg.circle
                        [ SA.cx (String.fromFloat node.x)
                        , SA.cy (String.fromFloat node.y)
                        , SA.r (String.fromFloat node.radius)
                        , SA.fill node.fillColour
                        , SA.stroke "var(--color-outline)"
                        , SA.strokeWidth "1.5"
                        ]
                        []

        isStar =
            case node.stellarObject of
                Star _ ->
                    True

                _ ->
                    False

        labelClass =
            if isStar then
                "sm-star-label"

            else
                "orbit-body-label"

        labelY =
            node.y - node.radius - 4

        auY =
            node.y + node.radius + 12

        labelEls =
            Svg.text_
                [ SA.x (String.fromFloat node.x)
                , SA.y (String.fromFloat labelY)
                , SA.textAnchor "middle"
                , SA.class labelClass
                ]
                [ Svg.text node.label ]
                :: (if isStar then
                        []

                    else
                        [ Svg.text_
                            [ SA.x (String.fromFloat node.x)
                            , SA.y (String.fromFloat auY)
                            , SA.textAnchor "middle"
                            , SA.class "orbit-au"
                            ]
                            [ Svg.text (formatAu auDist) ]
                        ]
                   )
        clickAttrs =
            if isStar then
                []

            else
                [ SE.onClick (onSelectObject node.stellarObject), SA.class "sm-node" ]
    in
    Svg.g clickAttrs (iconEl :: labelEls)



-- ── MODAL CHROME ─────────────────────────────────────────────────────────────


headerHeight : Float
headerHeight =
    44


statBarHeight : Float
statBarHeight =
    76


viewModal : Config msg -> ResizeConfig msg -> String -> List StatItem -> Bool -> StarData -> List ChildNode -> Html msg
viewModal config resizeConfig title stats showNames primaryStarData children =
    let
        mapWidth =
            max 100 resizeConfig.width

        mapHeight =
            max 100 (resizeConfig.height - headerHeight - statBarHeight)
    in
    Html.div
        [ HtmlAttrs.style "position" "fixed"
        , HtmlAttrs.style "inset" "0"
        , HtmlAttrs.style "display" "flex"
        , HtmlAttrs.style "align-items" "center"
        , HtmlAttrs.style "justify-content" "center"
        , HtmlAttrs.style "z-index" (String.fromInt config.zIndex)

        -- Close on mousedown (not click): a resize drag's mousedown always
        -- starts on the handle inside the panel (which stops propagation
        -- below), so it can never reach this handler regardless of where
        -- the drag's mouseup eventually lands — unlike "click", which the
        -- browser can synthesize on this backdrop when mousedown/mouseup
        -- targets differ (e.g. shrinking the panel out from under the
        -- cursor mid-drag), incorrectly closing the modal.
        , Html.Events.on "mousedown" (JsDecode.succeed config.close)
        ]
        [ Html.div
            [ HtmlAttrs.style "position" "relative"
            , HtmlAttrs.style "display" "flex"
            , HtmlAttrs.style "flex-direction" "column"
            , HtmlAttrs.style "width" (String.fromFloat resizeConfig.width ++ "px")
            , HtmlAttrs.style "height" (String.fromFloat resizeConfig.height ++ "px")
            , HtmlAttrs.style "max-width" "calc(100vw - 32px)"
            , HtmlAttrs.style "max-height" "calc(100vh - 32px)"
            , HtmlAttrs.style "background-color" "var(--color-panel)"
            , HtmlAttrs.style "border" "1px solid var(--color-outline)"
            , HtmlAttrs.style "border-radius" "6px"
            , HtmlAttrs.style "box-shadow" "0 8px 32px rgba(0, 0, 0, 0.25)"
            , HtmlAttrs.style "overflow" "hidden"
            , Html.Events.stopPropagationOn "mousedown" (JsDecode.succeed ( config.noOp, True ))
            ]
            [ viewHeader config.close title
            , viewStatBar stats
            , Html.div
                [ HtmlAttrs.style "position" "relative"
                , HtmlAttrs.style "flex" "1 1 auto"
                , HtmlAttrs.style "min-height" "0"
                , HtmlAttrs.style "overflow" "hidden"
                ]
                [ viewMap config.onSelectObject mapWidth mapHeight showNames primaryStarData children ]
            , viewResizeHandle resizeConfig.onResizeStart
            ]
        ]


viewHeader : msg -> String -> Html msg
viewHeader closeMsg title =
    Html.div
        [ HtmlAttrs.class "flex items-center justify-between px-4 py-2 border-b"
        , HtmlAttrs.style "border-color" "var(--color-outline)"
        , HtmlAttrs.style "flex" "0 0 auto"
        ]
        [ Html.span
            [ HtmlAttrs.class "font-bold text-lg"
            , HtmlAttrs.style "color" "var(--color-fg-bright)"
            ]
            [ Html.text title ]
        , Html.span
            [ HtmlAttrs.class "starmap-modal-close cursor-pointer"
            , HtmlAttrs.style "color" "var(--color-fg-muted)"
            , Html.Events.onClick closeMsg
            ]
            [ Html.text "✕" ]
        ]


viewStatBar : List StatItem -> Html msg
viewStatBar stats =
    Html.div
        [ HtmlAttrs.class "flex flex-wrap gap-x-6 gap-y-1 px-4 py-2 border-b"
        , HtmlAttrs.style "border-color" "var(--color-outline)"
        , HtmlAttrs.style "flex" "0 0 auto"
        ]
        (List.map viewStatItem stats)


viewStatItem : StatItem -> Html msg
viewStatItem stat =
    Html.div
        [ HtmlAttrs.style "display" "flex"
        , HtmlAttrs.style "flex-direction" "column"
        ]
        [ Html.span [ HtmlAttrs.class "edit-label" ] [ Html.text stat.label ]
        , Html.span
            [ HtmlAttrs.class "font-mono text-sm"
            , HtmlAttrs.style "color" "var(--color-fg)"
            ]
            [ Html.text stat.value ]
        ]


viewResizeHandle : ({ startX : Float, startY : Float } -> msg) -> Html msg
viewResizeHandle onResizeStart =
    Html.div
        [ HtmlAttrs.style "position" "absolute"
        , HtmlAttrs.style "right" "2px"
        , HtmlAttrs.style "bottom" "2px"
        , HtmlAttrs.style "width" "16px"
        , HtmlAttrs.style "height" "16px"
        , HtmlAttrs.style "line-height" "16px"
        , HtmlAttrs.style "text-align" "center"
        , HtmlAttrs.style "cursor" "nwse-resize"
        , HtmlAttrs.style "color" "var(--color-fg-muted)"
        , HtmlAttrs.style "user-select" "none"
        , Html.Events.on "mousedown" (resizeStartDecoder onResizeStart)
        ]
        [ Html.text "⋰" ]


resizeStartDecoder : ({ startX : Float, startY : Float } -> msg) -> JsDecode.Decoder msg
resizeStartDecoder toMsg =
    Mouse.eventDecoder
        |> JsDecode.map
            (\evt ->
                let
                    ( x, y ) =
                        evt.clientPos
                in
                toMsg { startX = x, startY = y }
            )
