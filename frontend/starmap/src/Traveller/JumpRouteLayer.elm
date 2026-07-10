module Traveller.JumpRouteLayer exposing
    ( DraftFields
    , Route
    , draftBody
    , hiddenIdsCodec
    , routeDecoder
    , routesDecoder
    )

{-| Types and JSON (de)serialisers for the "Jump Route Layers" panel,
mirroring the Rails `Api::JumpRoutesController` JSON shape. This module holds
data only - the add/edit modal lives in `Traveller.JumpRouteLayerEditor`.
-}

import Codec exposing (Codec)
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline exposing (required)
import Json.Encode as Encode
import Set exposing (Set)


type alias Route =
    { id : Int
    , name : String
    , colour : String
    , lineStyle : String
    , lineWidth : Int
    , known : Bool
    , routeType : String
    , notes : Maybe String
    , maxJump : Maybe Int
    , linkCount : Int
    }


routeDecoder : Decoder Route
routeDecoder =
    Decode.succeed Route
        |> required "id" Decode.int
        |> required "name" Decode.string
        |> required "colour" Decode.string
        |> required "line_style" Decode.string
        |> required "line_width" Decode.int
        |> required "known" Decode.bool
        |> required "route_type" Decode.string
        |> required "notes" (Decode.nullable Decode.string)
        |> required "max_jump" (Decode.nullable Decode.int)
        |> required "link_count" Decode.int


routesDecoder : Decoder (List Route)
routesDecoder =
    Decode.list routeDecoder


{-| The quick-edit field subset accepted by `Api::JumpRoutesController`'s
`create`/`update` actions - deliberately excludes `route_type` and every
plotted-route-only field.
-}
type alias DraftFields =
    { name : String
    , colour : String
    , lineStyle : String
    , lineWidth : Int
    , known : Bool
    , notes : String
    }


draftBody : DraftFields -> Encode.Value
draftBody draft =
    Encode.object
        [ ( "name", Encode.string draft.name )
        , ( "colour", Encode.string draft.colour )
        , ( "line_style", Encode.string draft.lineStyle )
        , ( "line_width", Encode.int draft.lineWidth )
        , ( "known", Encode.bool draft.known )
        , ( "notes", Encode.string draft.notes )
        ]


{-| The set of jump-route ids a user has hidden from their own map - purely
local, persisted to localStorage, and never sent to the server.
-}
hiddenIdsCodec : Codec (Set Int)
hiddenIdsCodec =
    Codec.list Codec.int |> Codec.map Set.fromList Set.toList
