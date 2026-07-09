module Traveller.HexAddress exposing (AfterChange, Delta, HexAddress, SectorHexAddress, addVal, between, betweenWithMax, codec, create, createFromStarSystem, hexAddressToString, hexLabel, sectorColumns, sectorHexAddressToString, sectorRows, shiftAddressBy, toKey, toSectorAddress, toSectorKey, toUniversalAddress, universalHexX, universalHexY, universalToSectorX, universalToSectorY)

import Codec exposing (Codec)


sectorColumns =
    32


sectorRows =
    40


type alias HexAddress =
    { x : Int
    , y : Int
    }


type alias SectorHexAddress =
    { sectorX : Int
    , sectorY : Int
    , x : Int
    , y : Int
    }


type alias Delta =
    { hexVal : Int, delta : Int, max : Int }


type alias AfterChange =
    { hexVal : Int, sectorDelta : Int }


addVal : Delta -> AfterChange
addVal { hexVal, delta, max } =
    let
        rangeMin : Int
        rangeMin =
            1

        rangeMax =
            max

        rangeSize =
            rangeMax - rangeMin + 1

        total =
            hexVal + delta

        counter =
            ceiling <| (toFloat rangeMin - toFloat total) / toFloat rangeSize

        newHexVal =
            modBy rangeSize (modBy rangeSize (total - rangeMin) + rangeSize) + rangeMin
    in
    { sectorDelta = -1 * counter, hexVal = newHexVal }


shiftAddressBy :
    { deltaX : Int, deltaY : Int }
    -> HexAddress
    -> HexAddress
shiftAddressBy { deltaX, deltaY } hexAddress =
    { x = hexAddress.x + deltaX
    , y = hexAddress.y - deltaY
    }


createFromStarSystem : { a | sectorX : Int, sectorY : Int, x : Int, y : Int } -> HexAddress
createFromStarSystem { sectorX, sectorY, x, y } =
    toUniversalAddress <| create { sectorX = sectorX, sectorY = sectorY, x = x, y = y }


create : { sectorX : Int, sectorY : Int, x : Int, y : Int } -> SectorHexAddress
create { sectorX, sectorY, x, y } =
    { sectorX = sectorX
    , sectorY = sectorY
    , x = x
    , y = y
    }


toKey : HexAddress -> String
toKey { x, y } =
    String.fromInt x
        ++ "."
        ++ String.fromInt y


sectorHexAddressToString : SectorHexAddress -> String
sectorHexAddressToString { sectorX, sectorY, x, y } =
    "Sector: "
        ++ String.fromInt sectorX
        ++ ", "
        ++ String.fromInt sectorY
        ++ " Hex: "
        ++ String.fromInt x
        ++ ", "
        ++ String.fromInt y


hexAddressToString : HexAddress -> String
hexAddressToString { x, y } =
    " Universal Hex: "
        ++ String.fromInt x
        ++ ", "
        ++ String.fromInt y


{-| Returns the universal x coordinate of a hex address, so it can be compared to all others across sectors.
-}
universalHexX hexAddr =
    hexAddr.x + hexAddr.sectorX * 32


{-| Returns the universal y coordinate of a hex address, so it can be compared to all others across sectors.
-}
universalHexY hexAddr =
    hexAddr.sectorY * 40 - hexAddr.y


toUniversalAddress : SectorHexAddress -> HexAddress
toUniversalAddress sectorHex =
    { x = universalHexX sectorHex, y = universalHexY sectorHex }


toSectorKey : SectorHexAddress -> String
toSectorKey { sectorX, sectorY } =
    String.fromInt sectorX
        ++ "."
        ++ String.fromInt sectorY


{-| Returns a list of hex addresses between two hex addresses, inclusive.
-}
between : HexAddress -> HexAddress -> List HexAddress
between upperLeftHex lowerRightHex =
    List.range upperLeftHex.x lowerRightHex.x
        |> List.concatMap
            (\x ->
                List.range lowerRightHex.y upperLeftHex.y
                    |> List.map
                        (\y ->
                            { x = x, y = y }
                        )
            )


{-| Returns a list of hex addresses between two hex addresses, inclusive.
limits the max number of hexes across and tall.
-}
betweenWithMax : HexAddress -> HexAddress -> { maxAcross : Int, maxTall : Int } -> List HexAddress
betweenWithMax upperLeftHex lowerRightHex { maxAcross, maxTall } =
    let
        across =
            min (lowerRightHex.x - upperLeftHex.x) maxAcross

        tall =
            min (upperLeftHex.y - lowerRightHex.y) maxTall
    in
    List.range upperLeftHex.x (upperLeftHex.x + across)
        |> List.concatMap
            (\x ->
                List.range (upperLeftHex.y - tall) upperLeftHex.y
                    |> List.map
                        (\y ->
                            { x = x, y = y }
                        )
            )


hexLabel : HexAddress -> String
hexLabel hex =
    let
        sectorHex =
            toSectorAddress hex
    in
    (String.fromInt (sectorHex.x + 1) |> String.pad 2 '0')
        ++ (String.fromInt (sectorHex.y + 1) |> String.pad 2 '0')


universalToSectorX : HexAddress -> Int
universalToSectorX { x } =
    if x < 0 then
        -1 + (x + 1) // 32

    else
        x // 32


universalToSectorY : HexAddress -> Int
universalToSectorY { y } =
    if y <= 0 then
        y // 40

    else
        1 + (y - 1) // 40


toSectorAddress : HexAddress -> SectorHexAddress
toSectorAddress universal =
    let
        sectorX =
            universalToSectorX universal

        sectorY =
            universalToSectorY universal
    in
    { sectorX = sectorX, sectorY = sectorY, x = universal.x - sectorX * 32, y = sectorY * 40 - universal.y }


codec : Codec HexAddress
codec =
    Codec.object HexAddress
        |> Codec.field "x" .x Codec.int
        |> Codec.field "y" .y Codec.int
        |> Codec.buildObject
