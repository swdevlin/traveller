module Traveller.Route exposing (Route, RouteList, codec)

import Codec exposing (Codec)
import Traveller.HexAddress exposing (HexAddress)


type alias Route =
    { address : HexAddress
    , shipId : Int
    , year : Int
    , day : Int
    }


type alias RouteList =
    List Route


codec : Codec.Codec Route
codec =
    Codec.object
        (\toX toY shipId arriveYear arriveDay ->
            { address = { x = toX, y = toY }
            , shipId = shipId
            , year = arriveYear
            , day = arriveDay
            }
        )
        |> Codec.field "to_x" (.address >> .x) Codec.int
        |> Codec.field "to_y" (.address >> .y) Codec.int
        |> Codec.field "ship_id" .shipId Codec.int
        |> Codec.field "arrive_year" .year Codec.int
        |> Codec.field "arrive_day" .day Codec.int
        |> Codec.buildObject
