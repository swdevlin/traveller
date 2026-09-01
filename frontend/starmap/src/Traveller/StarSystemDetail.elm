module Traveller.StarSystemDetail exposing (BaseFacility, MainWorldProfile, StarSystemDetail, codec)

import Codec
import Dict
import Traveller.HexAddress as HexAddress exposing (HexAddress)
import Traveller.StellarObject exposing (StarData, codecStarData, codecStellarObject)


type alias BaseFacility =
    { code : String
    , name : String
    , iconClass : Maybe String
    }


type alias MainWorldProfile =
    { uwp : String
    , gravity : Maybe Float
    , temperature : Maybe Float
    , nativeSophont : Bool
    , extinctSophont : Bool
    , censusPopulation : Maybe Int
    , survivalRequirement : String
    , jumpShadow : Maybe Float
    , berthingCost : Maybe Int
    , refinedFuelCost : Maybe Int
    , unrefinedFuelCost : Maybe Int
    }


type alias StarSystemDetail =
    { id : Int
    , address : HexAddress
    , primaryStar : StarData
    , gasGiants : Int
    , planetoidBelts : Int
    , terrestrialPlanets : Int
    , surveyIndex : Int
    , actualSurveyIndex : Int
    , nativeSophont : Bool
    , extinctSophont : Bool
    , allegiance : Maybe String
    , allegianceName : Maybe String
    , name : Maybe String
    , sectorName : String
    , mainWorldProfile : Maybe MainWorldProfile
    , known : Bool
    , bases : List BaseFacility
    , tradeCodes : List String
    , referenceUrl : Maybe String
    }


type alias RawStarSystemDetail =
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
    , allegianceName : Maybe String
    , name : Maybe String
    , sectorName : String
    , mainWorldProfile : Maybe MainWorldProfile
    , known : Bool
    , bases : List BaseFacility
    , tradeCodes : List String
    , referenceUrl : Maybe String
    }


codec : Codec.Codec StarSystemDetail
codec =
    rawCodec
        |> Codec.andThen rawToFinal finalToRaw


rawToFinal : RawStarSystemDetail -> Codec.Codec StarSystemDetail
rawToFinal rawStarSystemDetail =
    Codec.succeed
        { id = rawStarSystemDetail.id
        , address = HexAddress.createFromStarSystem rawStarSystemDetail
        , primaryStar = rawStarSystemDetail.primaryStar
        , gasGiants = rawStarSystemDetail.gasGiants
        , planetoidBelts = rawStarSystemDetail.planetoidBelts
        , terrestrialPlanets = rawStarSystemDetail.terrestrialPlanets
        , surveyIndex = rawStarSystemDetail.surveyIndex
        , actualSurveyIndex = rawStarSystemDetail.surveyIndex
        , nativeSophont = rawStarSystemDetail.nativeSophont
        , extinctSophont = rawStarSystemDetail.extinctSophont
        , allegiance = rawStarSystemDetail.allegiance
        , allegianceName = rawStarSystemDetail.allegianceName
        , name = rawStarSystemDetail.name
        , sectorName = rawStarSystemDetail.sectorName
        , mainWorldProfile = rawStarSystemDetail.mainWorldProfile
        , known = rawStarSystemDetail.known
        , bases = rawStarSystemDetail.bases
        , tradeCodes = rawStarSystemDetail.tradeCodes
        , referenceUrl = rawStarSystemDetail.referenceUrl
        }


finalToRaw : StarSystemDetail -> RawStarSystemDetail
finalToRaw starSystemDetail =
    { id = starSystemDetail.id
    , x = 9999999999
    , y = 9999999999
    , primaryStar = starSystemDetail.primaryStar
    , gasGiants = starSystemDetail.gasGiants
    , planetoidBelts = starSystemDetail.planetoidBelts
    , terrestrialPlanets = starSystemDetail.terrestrialPlanets
    , surveyIndex = starSystemDetail.surveyIndex
    , nativeSophont = starSystemDetail.nativeSophont
    , extinctSophont = starSystemDetail.extinctSophont
    , sectorX = 9999999999
    , sectorY = 9999999999
    , allegiance = starSystemDetail.allegiance
    , allegianceName = starSystemDetail.allegianceName
    , name = starSystemDetail.name
    , sectorName = starSystemDetail.sectorName
    , mainWorldProfile = starSystemDetail.mainWorldProfile
    , known = starSystemDetail.known
    , bases = starSystemDetail.bases
    , tradeCodes = starSystemDetail.tradeCodes
    , referenceUrl = starSystemDetail.referenceUrl
    }


mainWorldProfileCodec : Codec.Codec MainWorldProfile
mainWorldProfileCodec =
    Codec.object MainWorldProfile
        |> Codec.field "uwp" .uwp Codec.string
        |> Codec.field "gravity" .gravity (Codec.nullable Codec.float)
        |> Codec.field "temperature" .temperature (Codec.nullable Codec.float)
        |> Codec.field "native_sophont" .nativeSophont Codec.bool
        |> Codec.field "extinct_sophont" .extinctSophont Codec.bool
        |> Codec.field "census_population" .censusPopulation (Codec.nullable Codec.int)
        |> Codec.field "survival_requirement" .survivalRequirement Codec.string
        |> Codec.field "jump_shadow" .jumpShadow (Codec.nullable Codec.float)
        |> Codec.field "berthing_cost" .berthingCost (Codec.nullable Codec.int)
        |> Codec.field "refined_fuel_cost" .refinedFuelCost (Codec.nullable Codec.int)
        |> Codec.field "unrefined_fuel_cost" .unrefinedFuelCost (Codec.nullable Codec.int)
        |> Codec.buildObject


baseFacilityCodec : Codec.Codec BaseFacility
baseFacilityCodec =
    Codec.object BaseFacility
        |> Codec.field "code" .code Codec.string
        |> Codec.field "name" .name Codec.string
        |> Codec.optionalNullableField "icon_class" .iconClass Codec.string
        |> Codec.buildObject


rawCodec : Codec.Codec RawStarSystemDetail
rawCodec =
    Codec.object RawStarSystemDetail
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
        |> Codec.optionalNullableField "allegiance_name" .allegianceName Codec.string
        |> Codec.field "name" .name (Codec.nullable Codec.string)
        |> Codec.field "sector_name" .sectorName Codec.string
        |> Codec.optionalNullableField "main_world" .mainWorldProfile mainWorldProfileCodec
        |> Codec.field "known" .known Codec.bool
        |> Codec.field "bases" .bases (Codec.list baseFacilityCodec)
        |> Codec.field "trade_codes" .tradeCodes (Codec.list Codec.string)
        |> Codec.optionalNullableField "reference_url" .referenceUrl Codec.string
        |> Codec.buildObject
