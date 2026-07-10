module Traveller.RoutePlan exposing
    ( Hop
    , RoutePlanEndpoint
    , RoutePlanResult
    , RoutePlanSystem
    , RoutePlanSystemResult
    , StoredRoutePlan
    , TravelZoneOption
    , planQuery
    , routePlanResultDecoder
    , routePlanSystemResultDecoder
    , saveBody
    , storedRoutePlanCodec
    , travelZoneOptionDecoder
    )

{-| Types and JSON (de)serialisers for jump-route planning, mirroring the
Rails `Api::RoutePlansController`/`Api::TravelZonesController` JSON shapes.
This module holds data only - the form/modal itself lives in
`Traveller.RoutePlanForm`.
-}

import Codec exposing (Codec)
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline exposing (required)
import Json.Encode as Encode
import Url.Builder


type alias RoutePlanSystem =
    { id : Int
    , name : String
    , hexLabel : String
    , x : Int
    , y : Int
    }


routePlanSystemDecoder : Decoder RoutePlanSystem
routePlanSystemDecoder =
    Decode.succeed RoutePlanSystem
        |> required "id" Decode.int
        |> required "name" Decode.string
        |> required "hex_label" Decode.string
        |> required "x" Decode.int
        |> required "y" Decode.int


type alias Hop =
    { system : RoutePlanSystem
    , distance : Int
    }


hopDecoder : Decoder Hop
hopDecoder =
    Decode.succeed Hop
        |> required "system" routePlanSystemDecoder
        |> required "distance" Decode.int


{-| The from/to endpoint as returned by the `plan` endpoint - just enough to
label the result, not a full `RoutePlanSystem` (no hex coordinates needed
since the endpoints are already known to the caller).
-}
type alias RoutePlanEndpoint =
    { id : Int
    , name : String
    }


routePlanEndpointDecoder : Decoder RoutePlanEndpoint
routePlanEndpointDecoder =
    Decode.succeed RoutePlanEndpoint
        |> required "id" Decode.int
        |> required "name" Decode.string


type alias RoutePlanResult =
    { from : RoutePlanEndpoint
    , to : RoutePlanEndpoint
    , jumpRange : Int
    , refueling : String
    , excludedTravelZoneIds : List Int
    , found : Bool
    , hops : List Hop
    , totalDistance : Maybe Int
    , parsecDistance : Maybe Int
    }


routePlanResultDecoder : Decoder RoutePlanResult
routePlanResultDecoder =
    Decode.succeed RoutePlanResult
        |> required "from" routePlanEndpointDecoder
        |> required "to" routePlanEndpointDecoder
        |> required "jump_range" Decode.int
        |> required "refueling" Decode.string
        |> required "excluded_travel_zone_ids" (Decode.list Decode.int)
        |> required "found" Decode.bool
        |> required "hops" (Decode.list hopDecoder)
        |> required "total_distance" (Decode.nullable Decode.int)
        |> required "parsec_distance" (Decode.nullable Decode.int)


type alias TravelZoneOption =
    { id : Int
    , code : String
    , name : String
    , colour : String
    }


travelZoneOptionDecoder : Decoder TravelZoneOption
travelZoneOptionDecoder =
    Decode.succeed TravelZoneOption
        |> required "id" Decode.int
        |> required "code" Decode.string
        |> required "name" Decode.string
        |> required "colour" Decode.string


{-| One row returned by the from/to system picker (`api/route_plan/systems`).
-}
type alias RoutePlanSystemResult =
    { id : Int
    , name : String
    , meta : String
    }


routePlanSystemResultDecoder : Decoder RoutePlanSystemResult
routePlanSystemResultDecoder =
    Decode.succeed RoutePlanSystemResult
        |> required "id" Decode.int
        |> required "name" Decode.string
        |> required "meta" Decode.string


{-| The single active route a player keeps in localStorage. Only the
successfully-planned result and its display colour are stored - referee-only
fields (name/save state) never enter this type, since players never save.
-}
type alias StoredRoutePlan =
    { result : RoutePlanResult
    , colour : String
    }


hopCodec : Codec Hop
hopCodec =
    Codec.object Hop
        |> Codec.field "system" .system routePlanSystemCodec
        |> Codec.field "distance" .distance Codec.int
        |> Codec.buildObject


routePlanSystemCodec : Codec RoutePlanSystem
routePlanSystemCodec =
    Codec.object RoutePlanSystem
        |> Codec.field "id" .id Codec.int
        |> Codec.field "name" .name Codec.string
        |> Codec.field "hex_label" .hexLabel Codec.string
        |> Codec.field "x" .x Codec.int
        |> Codec.field "y" .y Codec.int
        |> Codec.buildObject


routePlanEndpointCodec : Codec RoutePlanEndpoint
routePlanEndpointCodec =
    Codec.object RoutePlanEndpoint
        |> Codec.field "id" .id Codec.int
        |> Codec.field "name" .name Codec.string
        |> Codec.buildObject


routePlanResultCodec : Codec RoutePlanResult
routePlanResultCodec =
    Codec.object RoutePlanResult
        |> Codec.field "from" .from routePlanEndpointCodec
        |> Codec.field "to" .to routePlanEndpointCodec
        |> Codec.field "jump_range" .jumpRange Codec.int
        |> Codec.field "refueling" .refueling Codec.string
        |> Codec.field "excluded_travel_zone_ids" .excludedTravelZoneIds (Codec.list Codec.int)
        |> Codec.field "found" .found Codec.bool
        |> Codec.field "hops" .hops (Codec.list hopCodec)
        |> Codec.field "total_distance" .totalDistance (Codec.nullable Codec.int)
        |> Codec.field "parsec_distance" .parsecDistance (Codec.nullable Codec.int)
        |> Codec.buildObject


storedRoutePlanCodec : Codec StoredRoutePlan
storedRoutePlanCodec =
    Codec.object StoredRoutePlan
        |> Codec.field "result" .result routePlanResultCodec
        |> Codec.field "colour" .colour Codec.string
        |> Codec.buildObject


{-| Query params for `GET api/route_plan`.
-}
planQuery : { fromId : Int, toId : Int, jumpRange : Int, refueling : String, excludedTravelZoneIds : List Int } -> List Url.Builder.QueryParameter
planQuery { fromId, toId, jumpRange, refueling, excludedTravelZoneIds } =
    Url.Builder.int "from_id" fromId
        :: Url.Builder.int "to_id" toId
        :: Url.Builder.int "jump_range" jumpRange
        :: Url.Builder.string "refueling" refueling
        :: List.map (\id -> Url.Builder.int "excluded_travel_zone_ids[]" id) excludedTravelZoneIds


{-| JSON body for `POST api/route_plan/save`.
-}
saveBody :
    { name : String
    , colour : String
    , jumpRange : Int
    , refueling : String
    , fromId : Int
    , toId : Int
    , excludedTravelZoneIds : List Int
    , systemIds : List Int
    }
    -> Encode.Value
saveBody { name, colour, jumpRange, refueling, fromId, toId, excludedTravelZoneIds, systemIds } =
    Encode.object
        [ ( "name", Encode.string name )
        , ( "colour", Encode.string colour )
        , ( "jump_range", Encode.int jumpRange )
        , ( "refueling", Encode.string refueling )
        , ( "from_id", Encode.int fromId )
        , ( "to_id", Encode.int toId )
        , ( "excluded_travel_zone_ids", Encode.list Encode.int excludedTravelZoneIds )
        , ( "system_ids", Encode.list Encode.int systemIds )
        ]
