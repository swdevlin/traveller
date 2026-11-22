module Traveller.StarportCapacity exposing (StarportCapacity, codec, rows)

{-| Docking and shipyard capacity of a world's starport, rolled once by the
generator and stored. Worlds generated before this existed have none, and any
figure that does not apply (no highport, no shipyard) is null, so every field
is optional.
-}

import Codec exposing (Codec)
import FormatNumber exposing (format)
import FormatNumber.Locales exposing (Decimals(..), usLocale)


type alias StarportCapacity =
    { hasHighport : Maybe Bool
    , highport : Maybe Int
    , downport : Maybe Int
    , internalBayCapacity : Maybe Int
    , shipyardCapability : Maybe String
    , shipyardBuildCapacity : Maybe Int
    , annualShipyardOutput : Maybe Int
    }


codec : Codec StarportCapacity
codec =
    Codec.object StarportCapacity
        |> Codec.optionalNullableField "has_highport" .hasHighport Codec.bool
        |> Codec.optionalNullableField "highport" .highport Codec.int
        |> Codec.optionalNullableField "downport" .downport Codec.int
        |> Codec.optionalNullableField "internal_bay_capacity" .internalBayCapacity Codec.int
        |> Codec.optionalNullableField "shipyard_capability" .shipyardCapability Codec.string
        |> Codec.optionalNullableField "shipyard_build_capacity" .shipyardBuildCapacity Codec.int
        |> Codec.optionalNullableField "annual_shipyard_output" .annualShipyardOutput Codec.int
        |> Codec.buildObject


{-| Label and value pairs for display, in order, leaving out anything that does not apply.
-}
rows : StarportCapacity -> List ( String, String )
rows capacity =
    List.filterMap identity
        [ capacity.hasHighport
            |> Maybe.map
                (\present ->
                    ( "Highport"
                    , if present then
                        "Present"

                      else
                        "None"
                    )
                )
        , capacity.highport |> Maybe.map (\n -> ( "Highport Capacity", tons n ))
        , capacity.downport |> Maybe.map (\n -> ( "Downport Capacity", tons n ))
        , capacity.internalBayCapacity |> Maybe.map (\n -> ( "Internal Bays", tons n ))
        , capacity.shipyardCapability |> Maybe.map (\c -> ( "Shipyard", shipyardLabel c ))
        , capacity.shipyardBuildCapacity |> Maybe.map (\n -> ( "Shipyard Build", tons n ))
        , capacity.annualShipyardOutput |> Maybe.map (\n -> ( "Annual Output", tons n ++ " / year" ))
        ]


tons : Int -> String
tons n =
    format { usLocale | decimals = Exact 0 } (toFloat n) ++ " tons"


shipyardLabel : String -> String
shipyardLabel capability =
    case capability of
        "starships" ->
            "Starships"

        "spacecraft" ->
            "Spacecraft"

        "smallCraft" ->
            "Small craft"

        "none" ->
            "None"

        other ->
            other
