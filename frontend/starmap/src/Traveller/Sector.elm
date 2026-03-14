module Traveller.Sector exposing (Sector, SectorDict, codec, sectorKey)

import Codec exposing (Codec)
import Dict


type alias Sector =
    { x : Int
    , y : Int
    , name : String
    , abbreviation : String
    }


sectorKey : Sector -> String
sectorKey sector =
    String.fromInt sector.x
        ++ "."
        ++ String.fromInt sector.y


codec : Codec Sector
codec =
    Codec.object Sector
        |> Codec.field "x" .x Codec.int
        |> Codec.field "y" .y Codec.int
        |> Codec.field "name" .name Codec.string
        |> Codec.field "name" .abbreviation Codec.string
        |> Codec.buildObject


type alias SectorDict =
    Dict.Dict String Sector
