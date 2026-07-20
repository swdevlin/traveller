module Traveller.MapLabel exposing (MapLabel, codec)

import Codec exposing (Codec)
import Color exposing (Color)
import Traveller.Region exposing (codecColour)


type alias MapLabel =
    { parsecId : Int
    , x : Int
    , y : Int
    , text : Maybe String
    , colour : Maybe Color
    , iconViewBox : Maybe String
    , iconPathData : Maybe String
    , known : Bool
    }


codec : Codec MapLabel
codec =
    Codec.object MapLabel
        |> Codec.field "id" .parsecId Codec.int
        |> Codec.field "x" .x Codec.int
        |> Codec.field "y" .y Codec.int
        |> Codec.field "text" .text (Codec.maybe Codec.string)
        |> Codec.field "colour" .colour (Codec.maybe codecColour)
        |> Codec.field "icon_view_box" .iconViewBox (Codec.maybe Codec.string)
        |> Codec.field "icon_path_data" .iconPathData (Codec.maybe Codec.string)
        |> Codec.field "known" .known Codec.bool
        |> Codec.buildObject