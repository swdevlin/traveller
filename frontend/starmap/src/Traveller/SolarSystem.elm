module Traveller.SolarSystem exposing (MainWorldProfile, SolarSystem, codec)

import Codec
import Dict
import Traveller.HexAddress as HexAddress exposing (HexAddress)
import Traveller.StellarObject exposing (StarData, codecStarData, codecStellarObject)


type alias MainWorldProfile =
    { uwp : String
    , gravity : Maybe Float
    , temperature : Maybe Float
    , nativeSophont : Bool
    , extinctSophont : Bool
    , survivalRequirement : String
    , jumpShadow : Maybe Float
    }


type alias SolarSystem =
    { id : Int
    , address : HexAddress
    , primaryStar : StarData
    , gasGiants : Int
    , planetoidBelts : Int
    , terrestrialPlanets : Int
    , surveyIndex : Int
    , nativeSophont : Bool
    , extinctSophont : Bool
    , allegiance : Maybe String
    , name : Maybe String
    , sectorName : String
    , mainWorldProfile : Maybe MainWorldProfile
    }


type alias RawSolarSystem =
    { id : Int
    , x : Int
    , y : Int
    , primaryStar : StarData
    , gasGiants : Int
    , planetoidBelts : Int
    , terrestrialPlanets : Int
    , surveyIndex : Int
    , nativeSophont : Bool
    , extinctSophont : Bool
    , sectorX : Int
    , sectorY : Int
    , allegiance : Maybe String
    , name : Maybe String
    , sectorName : String
    , mainWorldProfile : Maybe MainWorldProfile
    }


codec : Codec.Codec SolarSystem
codec =
    rawCodec
        |> Codec.andThen rawToFinal finalToRaw


rawToFinal : RawSolarSystem -> Codec.Codec SolarSystem
rawToFinal rawSolarSystem =
    Codec.succeed
        { id = rawSolarSystem.id
        , address = HexAddress.createFromStarSystem rawSolarSystem
        , primaryStar = rawSolarSystem.primaryStar
        , gasGiants = rawSolarSystem.gasGiants
        , planetoidBelts = rawSolarSystem.planetoidBelts
        , terrestrialPlanets = rawSolarSystem.terrestrialPlanets
        , surveyIndex = rawSolarSystem.surveyIndex
        , nativeSophont = rawSolarSystem.nativeSophont
        , extinctSophont = rawSolarSystem.extinctSophont
        , allegiance = rawSolarSystem.allegiance
        , name = rawSolarSystem.name
        , sectorName = rawSolarSystem.sectorName
        , mainWorldProfile = rawSolarSystem.mainWorldProfile
        }


finalToRaw : SolarSystem -> RawSolarSystem
finalToRaw solarSystem =
    { id = solarSystem.id
    , x = 9999999999
    , y = 9999999999
    , primaryStar = solarSystem.primaryStar
    , gasGiants = solarSystem.gasGiants
    , planetoidBelts = solarSystem.planetoidBelts
    , terrestrialPlanets = solarSystem.terrestrialPlanets
    , surveyIndex = solarSystem.surveyIndex
    , nativeSophont = solarSystem.nativeSophont
    , extinctSophont = solarSystem.extinctSophont
    , sectorX = 9999999999
    , sectorY = 9999999999
    , allegiance = solarSystem.allegiance
    , name = solarSystem.name
    , sectorName = solarSystem.sectorName
    , mainWorldProfile = solarSystem.mainWorldProfile
    }


mainWorldProfileCodec : Codec.Codec MainWorldProfile
mainWorldProfileCodec =
    Codec.object MainWorldProfile
        |> Codec.field "uwp" .uwp Codec.string
        |> Codec.field "gravity" .gravity (Codec.nullable Codec.float)
        |> Codec.field "temperature" .temperature (Codec.nullable Codec.float)
        |> Codec.field "native_sophont" .nativeSophont Codec.bool
        |> Codec.field "extinct_sophont" .extinctSophont Codec.bool
        |> Codec.field "survival_requirement" .survivalRequirement Codec.string
        |> Codec.field "jump_shadow" .jumpShadow (Codec.nullable Codec.float)
        |> Codec.buildObject


rawCodec : Codec.Codec RawSolarSystem
rawCodec =
    Codec.object RawSolarSystem
        |> Codec.field "id" .id Codec.int
        |> Codec.field "x" .x Codec.int
        |> Codec.field "y" .y Codec.int
        |> Codec.field "primary_star" .primaryStar codecStarData
        |> Codec.field "gas_giant_count" .gasGiants Codec.int
        |> Codec.field "belt_count" .planetoidBelts Codec.int
        |> Codec.field "terrestrial_count" .terrestrialPlanets Codec.int
        |> Codec.field "survey_index" .surveyIndex Codec.int
        |> Codec.field "native_sophont" .nativeSophont Codec.bool
        |> Codec.field "extinct_sophont" .extinctSophont Codec.bool
        |> Codec.field "sector_x" .sectorX Codec.int
        |> Codec.field "sector_y" .sectorY Codec.int
        |> Codec.field "allegiance" .allegiance (Codec.nullable Codec.string)
        |> Codec.field "name" .name (Codec.nullable Codec.string)
        |> Codec.field "sector_name" .sectorName Codec.string
        |> Codec.optionalNullableField "main_world" .mainWorldProfile mainWorldProfileCodec
        |> Codec.buildObject
