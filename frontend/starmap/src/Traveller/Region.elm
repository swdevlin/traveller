module Traveller.Region exposing (Region, RegionDict, codec)

import Codec exposing (Codec)
import Color exposing (Color)
import Color.Convert exposing (colorToHex, hexToColor)
import Dict
import Traveller.HexAddress as HexAddress exposing (HexAddress)


type alias Region =
    { id : Int
    , colour : Color
    , name : String
    , labelPosition : Maybe HexAddress
    , hexes : List HexAddress
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


codec : Codec Region
codec =
    Codec.object
        (\mx my id colour name hexes ->
            Region id colour name (Maybe.map2 (\x y -> { x = x, y = y }) mx my) hexes
        )
        |> Codec.field "label_x" (.labelPosition >> Maybe.map .x) (Codec.maybe Codec.int)
        |> Codec.field "label_y" (.labelPosition >> Maybe.map .y) (Codec.maybe Codec.int)
        |> Codec.field "id" .id Codec.int
        |> Codec.field "colour" .colour codecColour
        |> Codec.field "name" .name Codec.string
        |> Codec.field "hexes" .hexes (Codec.list HexAddress.codec)
        |> Codec.buildObject
