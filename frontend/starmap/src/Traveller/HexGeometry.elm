module Traveller.HexGeometry exposing
    ( VisualHexOrigin
    , calcVisualOrigin
    , convertRawHexagonPoints
    , defaultHexSize
    , hexColOffset
    , hexHeight
    , hexSizeFactor
    , hexWidth
    , hexagonPoints
    , hexapointsBuilder
    , rawHexagonPoint
    , rawHexagonPoints
    , rotatePoint
    , scaleAttr
    )

{-| Hexagon geometry calculations for hex map rendering.
-}


{-| The factor used in hexagon point calculations (2π/6)
-}
hexSizeFactor : Float
hexSizeFactor =
    2 * pi / 6


{-| Default hex size in pixels
-}
defaultHexSize : Float
defaultHexSize =
    40


{-| Calculate the width of a hexagon given its scale
-}
hexWidth : Float -> Float
hexWidth hexScale =
    hexScale * (1.0 + cos hexSizeFactor)


{-| Calculate the height of a hexagon given its scale
-}
hexHeight : Float -> Float
hexHeight hexScale =
    hexScale * (1.0 + sin hexSizeFactor)


{-| Calculate a single point on a hexagon at position n (0-5)
-}
rawHexagonPoint : Float -> Float -> ( Float, Float )
rawHexagonPoint size n =
    let
        x =
            size * cos (hexSizeFactor * n)

        y =
            size * sin (hexSizeFactor * n)
    in
    ( x, y )


{-| Get all hexagon points as a list of coordinate strings, offset by origin
-}
hexagonPoints : ( Float, Float ) -> Float -> List String
hexagonPoints ( xOrigin, yOrigin ) size =
    rawHexagonPoints size
        |> List.map
            (\( x, y ) ->
                String.fromFloat (xOrigin + x) ++ "," ++ String.fromFloat (yOrigin + y)
            )


{-| Hexagon points independent of origin
-}
rawHexagonPoints : Float -> List ( Float, Float )
rawHexagonPoints size =
    List.range 0 5
        |> List.map (toFloat >> rawHexagonPoint size)


{-| Build a coordinate string from origin and point
-}
hexapointsBuilder : Float -> Float -> ( Float, Float ) -> String
hexapointsBuilder xOrigin yOrigin ( x, y ) =
    String.fromFloat (xOrigin + x) ++ "," ++ String.fromFloat (yOrigin + y)


{-| Localize the hexagon points to the visualOrigin
-}
convertRawHexagonPoints : ( Float, Float ) -> List ( Float, Float ) -> String
convertRawHexagonPoints ( xOrigin, yOrigin ) points =
    points
        |> List.map (hexapointsBuilder xOrigin yOrigin)
        |> String.join " "


{-| Scale an attribute value based on hex size
-}
scaleAttr : Float -> Int -> Float
scaleAttr hexSize default =
    toFloat default * min 1 (hexSize / defaultHexSize)


{-| Rotate a point around a center by a given angle and distance
Used for positioning companion stars
-}
rotatePoint : Float -> Int -> ( Float, Float ) -> Float -> Int -> ( Float, Float )
rotatePoint hexSize idx ( x_, y_ ) degrees_ distance =
    let
        rads =
            (toFloat idx * degrees_)
                - 30
                |> degrees

        cosTheta =
            cos rads

        sinTheta =
            sin rads
    in
    ( x_ + (scaleAttr hexSize distance * cosTheta) - (0 * sinTheta)
    , y_ + (scaleAttr hexSize distance * sinTheta) + (0 * cosTheta)
    )


{-| Calculate the column offset for odd/even rows in hex grid
-}
hexColOffset : Int -> Float
hexColOffset row =
    if remainderBy 2 row == 0 then
        1.0

    else
        0.0


{-| Where the Hex is on the screen, in pixel coordinates
-}
type alias VisualHexOrigin =
    ( Int, Int )


{-| Calculate the visual origin (pixel coordinates) for a hex at a given row/col
-}
calcVisualOrigin : Float -> { row : Int, col : Int } -> VisualHexOrigin
calcVisualOrigin hexSize { row, col } =
    let
        x =
            hexSize + toFloat col * (hexSize + hexSize * cos hexSizeFactor)

        y =
            -1 * (hexSize + toFloat row * 2 * hexSize * sin hexSizeFactor + hexSize * hexColOffset col * sin hexSizeFactor)
    in
    ( floor x, floor y )
