module Traveller.Sector exposing (Sector, SectorDict, Subsector, codec, sectorKey, subsectorCodec)

import Codec exposing (Codec)
import Dict


type alias Sector =
    { x : Int
    , y : Int
    , name : String
    , abbreviation : Maybe String
    , subsectors : List Subsector
    }


type alias Subsector =
    { x : Int
    , y : Int
    , name : Maybe String
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
        |> Codec.field "abbreviation" .abbreviation (Codec.maybe Codec.string)
        |> Codec.field "subsectors" .subsectors (Codec.list subsectorCodec)
        |> Codec.buildObject


subsectorCodec : Codec Subsector
subsectorCodec =
    Codec.object Subsector
        |> Codec.field "x" .x Codec.int
        |> Codec.field "y" .y Codec.int
        |> Codec.field "name" .name (Codec.maybe Codec.string)
        |> Codec.buildObject


type alias SectorDict =
    Dict.Dict String Sector
