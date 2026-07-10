module Traveller.Region exposing (Region, RegionDict, codec, codecColour)

import Codec exposing (Codec)
import Color exposing (Color)
import Color.Convert exposing (colorToHex, hexToColor)
import Dict
import Traveller.HexAddress as HexAddress exposing (HexAddress)


type alias Region =
    { id : Int
    , colour : Color
    , borderColour : Maybe Color
    , name : String
    , playerVisible : Bool
    , labelPosition : Maybe HexAddress
    , hexes : List HexAddress
    , borderHexes : List HexAddress
    }


type alias RegionDict =
    Dict.Dict Int Region


codecColour : Codec Color
codecColour =
    Codec.string
        |> Codec.andThen
            (\s ->
                case hexToColor s of
                    Ok color ->
                        Codec.succeed color

                    Err errString ->
                        Codec.fail errString
            )
            (\c -> colorToHex c)


codecMaybeColour : Codec (Maybe Color)
codecMaybeColour =
    Codec.maybe codecColour


codec : Codec Region
codec =
    Codec.object
        (\mx my id colour borderColour name playerVisible hexes borderHexes ->
            Region id colour borderColour name playerVisible (Maybe.map2 (\x y -> { x = x, y = y }) mx my) hexes borderHexes
        )
        |> Codec.field "label_x" (.labelPosition >> Maybe.map .x) (Codec.maybe Codec.int)
        |> Codec.field "label_y" (.labelPosition >> Maybe.map .y) (Codec.maybe Codec.int)
        |> Codec.field "id" .id Codec.int
        |> Codec.field "colour" .colour codecColour
        |> Codec.field "border_colour" .borderColour codecMaybeColour
        |> Codec.field "name" .name Codec.string
        |> Codec.field "player_visible" .playerVisible Codec.bool
        |> Codec.field "hexes" .hexes (Codec.list HexAddress.codec)
        |> Codec.field "border_hexes" .borderHexes (Codec.list HexAddress.codec)
        |> Codec.buildObject
