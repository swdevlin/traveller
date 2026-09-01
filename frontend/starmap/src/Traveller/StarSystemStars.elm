module Traveller.StarSystemStars exposing (FallibleStarSystem, StarSystem, StarType, StarTypeData, StrategicData, TravelZone, fallibleStarSystemDecoder, getStarTypeData, isBrownDwarfType, starSystemCodec, starTypeCodec)

import Codec exposing (Codec)
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline exposing (custom, optional, required)
import Traveller.HexAddress as HexAddress exposing (HexAddress)
import Traveller.StarColour exposing (StarColour, codecStarColour)


type alias StrategicData =
    { importanceTier : Int
    , resourceUnitsTier : Int
    , resourceTier : Int
    , tradeEaseTier : Int
    , routeRole : Maybe String
    }


strategicDataDecoder : Decoder StrategicData
strategicDataDecoder =
    Decode.succeed StrategicData
        |> required "importance_tier" Decode.int
        |> required "resource_units_tier" Decode.int
        |> required "resource_tier" Decode.int
        |> required "trade_ease_tier" Decode.int
        |> optional "route_role" (Decode.nullable Decode.string) Nothing


type alias TravelZone =
    { code : String
    , colour : String
    }


travelZoneCodec : Codec TravelZone
travelZoneCodec =
    Codec.object TravelZone
        |> Codec.field "code" .code Codec.string
        |> Codec.field "colour" .colour Codec.string
        |> Codec.buildObject


type alias StarTypeData =
    { au : Float
    , subtype : Maybe Int
    , companion : Maybe StarType
    , stellarType : String
    , stellarClass : String
    , colour : Maybe StarColour
    , diameter : Maybe Float
    }


isBrownDwarfType : StarTypeData -> Bool
isBrownDwarfType theStar =
    List.any (\a -> a == theStar.stellarType) [ "D", "Y", "T", "L" ]


type StarType
    = StarTypeWrap StarTypeData


getStarTypeData : StarType -> StarTypeData
getStarTypeData (StarTypeWrap starTypeData) =
    starTypeData


starTypeCodec : Codec StarType
starTypeCodec =
    Codec.object StarTypeData
        |> Codec.field "au" .au Codec.float
        |> Codec.field "stellar_subtype" .subtype (Codec.nullable Codec.int)
        |> Codec.field "companion" .companion (Codec.nullable <| Codec.lazy (\_ -> starTypeCodec))
        |> Codec.field "stellar_type" .stellarType Codec.string
        |> Codec.field "stellar_class" .stellarClass Codec.string
        |> Codec.field "colour" .colour (Codec.nullable codecStarColour)
        |> Codec.field "diameter" .diameter (Codec.nullable Codec.float)
        |> Codec.buildObject
        |> Codec.map StarTypeWrap (\(StarTypeWrap data) -> data)


type alias StarSystem =
    { address : HexAddress
    , sectorName : String
    , name : String
    , scanPoints : Int
    , surveyIndex : Int
    , gasGiantCount : Int
    , terrestrialPlanetCount : Int
    , planetoidBeltCount : Int
    , allegiance : Maybe String
    , nativeSophont : Bool
    , extinctSophont : Bool
    , techLevel : Maybe Int
    , stars : List StarType
    , mainWorldUwp : Maybe String
    , travelZone : Maybe TravelZone
    , known : Bool
    , mainWorldName : Maybe String
    , mainWorldImage : Maybe String
    , wtn : Maybe Float
    , gwp : Maybe Int
    , importance : Maybe Int
    , tradeCodes : List String
    , strategic : Maybe StrategicData
    , baseCodes : List String
    , habitabilityRating : Maybe Int
    , governmentCode : Maybe Int
    , governmentName : Maybe String
    , sectorId : Int
    , subsectorId : Maybe Int
    }


type alias FallibleStarSystem =
    { address : HexAddress
    , sectorName : String
    , name : String
    , scanPoints : Int
    , surveyIndex : Int
    , gasGiantCount : Int
    , terrestrialPlanetCount : Int
    , planetoidBeltCount : Int
    , allegiance : Maybe String
    , nativeSophont : Bool
    , extinctSophont : Bool
    , techLevel : Maybe Int
    , stars : List (Result Decode.Error StarType)
    , mainWorldUwp : Maybe String
    , travelZone : Maybe TravelZone
    , known : Bool
    , mainWorldName : Maybe String
    , mainWorldImage : Maybe String
    , wtn : Maybe Float
    , gwp : Maybe Int
    , importance : Maybe Int
    , tradeCodes : List String
    , strategic : Maybe StrategicData
    , baseCodes : List String
    , habitabilityRating : Maybe Int
    , governmentCode : Maybe Int
    , governmentName : Maybe String
    , sectorId : Int
    , subsectorId : Maybe Int
    }


starSystemCodec : Codec StarSystem
starSystemCodec =
    Codec.object
        (\ox oy sname name sp si ggc tpc ppc al stars ->
            StarSystem { x = ox, y = oy } sname name sp si ggc tpc ppc al stars
        )
        |> Codec.field "origin_x" (.address >> .x) Codec.int
        |> Codec.field "origin_y" (.address >> .y) Codec.int
        |> Codec.field "sector_name" .sectorName Codec.string
        |> Codec.field "name" .name Codec.string
        |> Codec.field "scan_points" .scanPoints Codec.int
        |> Codec.field "survey_index" .surveyIndex Codec.int
        |> Codec.field "gas_giant_count" .gasGiantCount Codec.int
        |> Codec.field "terrestrial_count" .terrestrialPlanetCount Codec.int
        |> Codec.field "belt_count" .planetoidBeltCount Codec.int
        |> Codec.field "allegiance" .allegiance (Codec.nullable Codec.string)
        |> Codec.field "native_sophont" .nativeSophont Codec.bool
        |> Codec.field "extinct_sophont" .extinctSophont Codec.bool
        |> Codec.field "tech_level" .techLevel (Codec.nullable Codec.int)
        |> Codec.field "stars" .stars (Codec.list starTypeCodec)
        |> Codec.field "main_world_uwp" .mainWorldUwp (Codec.nullable Codec.string)
        |> Codec.field "travel_zone" .travelZone (Codec.nullable travelZoneCodec)
        |> Codec.field "known" .known Codec.bool
        |> Codec.field "main_world_name" .mainWorldName (Codec.nullable Codec.string)
        |> Codec.field "main_world_image" .mainWorldImage (Codec.nullable Codec.string)
        |> Codec.field "wtn" .wtn (Codec.nullable Codec.float)
        |> Codec.field "gwp" .gwp (Codec.nullable Codec.int)
        |> Codec.field "importance" .importance (Codec.nullable Codec.int)
        |> Codec.field "trade_codes" .tradeCodes (Codec.list Codec.string)
        |> Codec.field "strategic" .strategic (Codec.nullable strategicDataCodec)
        |> Codec.field "bases" .baseCodes (Codec.list Codec.string)
        |> Codec.field "habitability_rating" .habitabilityRating (Codec.nullable Codec.int)
        |> Codec.field "government_code" .governmentCode (Codec.nullable Codec.int)
        |> Codec.field "government_name" .governmentName (Codec.nullable Codec.string)
        |> Codec.field "sector_id" .sectorId Codec.int
        |> Codec.field "subsector_id" .subsectorId (Codec.nullable Codec.int)
        |> Codec.buildObject


strategicDataCodec : Codec StrategicData
strategicDataCodec =
    Codec.object StrategicData
        |> Codec.field "importance_tier" .importanceTier Codec.int
        |> Codec.field "resource_units_tier" .resourceUnitsTier Codec.int
        |> Codec.field "resource_tier" .resourceTier Codec.int
        |> Codec.field "trade_ease_tier" .tradeEaseTier Codec.int
        |> Codec.field "route_role" .routeRole (Codec.nullable Codec.string)
        |> Codec.buildObject


{-| all the fields from StarSystem, but with stars as a list of Result Decode.Error StarType

this is so the decoder can handle errors in the starTypeCodec

-}
fallibleStarSystemDecoder : Decoder FallibleStarSystem
fallibleStarSystemDecoder =
    let
        decodeOrCatchError : Decode.Value -> Result Decode.Error StarType
        decodeOrCatchError =
            Decode.decodeValue (Codec.decoder starTypeCodec)
    in
    Decode.succeed
        (\ox oy sname name sp si ggc tpc ppc al stars ->
            FallibleStarSystem { x = ox, y = oy } sname name sp si ggc tpc ppc al stars
        )
        |> required "origin_x" Decode.int
        |> required "origin_y" Decode.int
        |> required "sector_name" Decode.string
        |> required "name" Decode.string
        |> required "scan_points" Decode.int
        |> required "survey_index" Decode.int
        |> required "gas_giant_count" Decode.int
        |> required "terrestrial_count" Decode.int
        |> required "belt_count" Decode.int
        |> required "allegiance" (Decode.nullable Decode.string)
        |> required "native_sophont" Decode.bool
        |> required "extinct_sophont" Decode.bool
        |> required "tech_level" (Decode.nullable Decode.int)
        |> required "stars"
            (Decode.list
                (Decode.map decodeOrCatchError Decode.value)
            )
        |> optional "main_world_uwp" (Decode.nullable Decode.string) Nothing
        |> optional "travel_zone" (Decode.nullable (Codec.decoder travelZoneCodec)) Nothing
        |> optional "known" Decode.bool False
        |> optional "main_world_name" (Decode.nullable Decode.string) Nothing
        |> optional "main_world_image" (Decode.nullable Decode.string) Nothing
        |> optional "wtn" (Decode.nullable Decode.float) Nothing
        |> optional "gwp" (Decode.nullable Decode.int) Nothing
        |> optional "importance" (Decode.nullable Decode.int) Nothing
        |> optional "trade_codes" (Decode.list Decode.string) []
        |> optional "strategic" (Decode.nullable strategicDataDecoder) Nothing
        |> optional "bases" (Decode.list Decode.string) []
        |> optional "habitability_rating" (Decode.nullable Decode.int) Nothing
        |> optional "government_code" (Decode.nullable Decode.int) Nothing
        |> optional "government_name" (Decode.nullable Decode.string) Nothing
        |> optional "sector_id" Decode.int 0
        |> optional "subsector_id" (Decode.nullable Decode.int) Nothing
