module Traveller.StellarObject exposing (CodeAndDesc, GasGiantData, GovernmentDetailData, InnerStarData, IntCodeAndDesc, LawLevelDetailData, MoonsPage, PlanetoidBeltData, PlanetoidData, SharedPData, StarData(..), StellarObject(..), TechCapability, TechLevelDetailData, codecStarData, codecStellarObject, getInnerStarData, getProfileString, getSafeJumpTime, getStarData, getStellarOrbit, isBrownDwarf, moonsPageDecoder)

import Codec exposing (Codec)
import Json.Decode as JsDecode
import Json.Encode as JsEncode
import Traveller.Atmosphere as Atmosphere exposing (StellarAtmosphere)
import Traveller.Moon as Moon exposing (Moon)
import Traveller.Point as Point exposing (StellarPoint)
import Traveller.Population as Population exposing (CultureTrait, StellarPopulation)
import Traveller.StarColour exposing (StarColour, codecStarColour)
import Traveller.TravelCalculations as TravelCalculations


type alias CodeAndDesc =
    { code : String
    , description : String
    }


type alias IntCodeAndDesc =
    { code : Int
    , description : String
    }


type alias GovernmentStructure =
    { judicial : Maybe CodeAndDesc
    , executive : Maybe CodeAndDesc
    , legislative : Maybe CodeAndDesc
    }


type alias GovernmentCharacteristics =
    { authority : Maybe CodeAndDesc
    , centralisation : Maybe CodeAndDesc
    }


type alias GovernmentDetailData =
    { type_ : Maybe String
    , description : Maybe String
    , structure : Maybe GovernmentStructure
    , characteristics : Maybe GovernmentCharacteristics
    }


type alias LawSubClassifications =
    { weaponsAndArmour : Maybe IntCodeAndDesc
    , criminalLaw : Maybe IntCodeAndDesc
    , economicLaw : Maybe IntCodeAndDesc
    , privateLaw : Maybe IntCodeAndDesc
    , personalRights : Maybe IntCodeAndDesc
    }


type alias LawCharacteristics =
    { uniformity : Maybe CodeAndDesc
    , judicialSystem : Maybe CodeAndDesc
    , deathPenalty : Maybe Bool
    , presumedInnocence : Maybe Bool
    , econometricInfractionsAdministrative : Maybe Bool
    }


type alias LawLevelDetailData =
    { subClassifications : Maybe LawSubClassifications
    , characteristics : Maybe LawCharacteristics
    }


type alias TechCapability =
    { code : Int
    , description : String
    }


type alias TechLevelDetailData =
    { descriptor : Maybe String
    , energy : Maybe TechCapability
    , electronics : Maybe TechCapability
    , manufacturing : Maybe TechCapability
    , medical : Maybe TechCapability
    , environmental : Maybe TechCapability
    , land : Maybe TechCapability
    , sea : Maybe TechCapability
    , air : Maybe TechCapability
    , space : Maybe TechCapability
    , personalMilitary : Maybe TechCapability
    , heavyMilitary : Maybe TechCapability
    }


type alias SharedPData =
    { atmosphere : StellarAtmosphere
    , orbitPosition : StellarPoint
    , inclination : Float
    , eccentricity : Float
    , effectiveHZCODeviation : Float
    , size : String
    , orbit : Float
    , period : Maybe Float
    , composition : Maybe String
    , retrograde : Bool
    , trojanOffset : Maybe Float
    , axialTilt : Float
    , moons : List Moon
    , biomassRating : Int
    , biocomplexityCode : Int
    , biodiversityRating : Int
    , compatibilityRating : Int
    , resourceRating : Int
    , nativeSophont : Bool
    , extinctSophont : Bool
    , hasRing : Bool
    , hydrographics : Maybe Hydrographics
    , albedo : Float
    , density : Maybe Float
    , greenhouse : Maybe Float
    , meanTemperature : Maybe Float
    , habitabilityRating : Maybe Int
    , orbitSequence : String
    , uwp : String
    , diameter : Float
    , gravity : Maybe Float
    , mass : Maybe Float
    , escapeVelocity : Maybe Float
    , jumpShadow : Maybe Float
    , orbitType : Int
    , au : Float
    , population : Maybe StellarPopulation
    , rotation : Maybe Float
    , governmentDetail : Maybe GovernmentDetailData
    , lawLevelDetail : Maybe LawLevelDetailData
    , techLevelDetail : Maybe TechLevelDetailData
    , name : Maybe String
    , id : Int
    , isMoon : Bool
    , cityCount : Int
    }


type alias PlanetoidData =
    { orbitPosition : StellarPoint
    , inclination : Float
    , eccentricity : Float
    , effectiveHZCODeviation : Float
    , size : String
    , orbit : Float
    , period : Maybe Float
    , composition : String
    , retrograde : Bool
    , trojanOffset : Maybe Float
    , axialTilt : Float
    , moons : List Moon
    , biomassRating : Int
    , biocomplexityCode : Int
    , biodiversityRating : Int
    , compatibilityRating : Int
    , resourceRating : Int
    , nativeSophont : Bool
    , extinctSophont : Bool
    , hasRing : Bool
    , albedo : Float
    , density : Maybe Float
    , greenhouse : Maybe Float
    , meanTemperature : Maybe Float
    , orbitSequence : String
    , uwp : String
    , diameter : Float
    , gravity : Maybe Float
    , mass : Maybe Float
    , escapeVelocity : Maybe Float
    , jumpShadow : Maybe Float
    , orbitType : Int
    , au : Float

    -- , -- maybe not required for Planetoid?
    --   code : Maybe String
    }


type alias GasGiantData =
    { orbitPosition : StellarPoint
    , inclination : Float
    , eccentricity : Float
    , effectiveHZCODeviation : Float
    , code : String
    , diameter : Float
    , mass : Maybe Float
    , orbit : Float
    , moons : List Moon
    , hasRing : Bool
    , trojanOffset : Maybe Float
    , axialTilt : Float
    , period : Float
    , orbitSequence : String
    , jumpShadow : Maybe Float
    , orbitType : Int
    , au : Float
    , name : Maybe String
    , id : Int
    }


type alias PlanetoidBeltData =
    { orbitPosition : StellarPoint
    , inclination : Float
    , eccentricity : Float
    , effectiveHZCODeviation : Float
    , orbit : Float
    , mType : Float
    , sType : Float
    , cType : Float
    , oType : Float
    , span : Float
    , bulk : Float
    , resourceRating : Float
    , period : Float
    , orbitSequence : String
    , uwp : String
    , jumpShadow : Maybe Float
    , orbitType : Int
    , au : Float
    , retrograde : Bool
    , name : Maybe String
    , atmosphere : Maybe StellarAtmosphere
    , hydrographics : Maybe Hydrographics
    , population : Maybe StellarPopulation
    , biomassRating : Int
    , biocomplexityCode : Int
    , biodiversityRating : Int
    , compatibilityRating : Int
    , habitabilityRating : Maybe Int
    , nativeSophont : Bool
    , extinctSophont : Bool
    , governmentDetail : Maybe GovernmentDetailData
    , lawLevelDetail : Maybe LawLevelDetailData
    , techLevelDetail : Maybe TechLevelDetailData
    , meanTemperature : Maybe Float
    , id : Int
    , cityCount : Int
    }


type alias InnerStarData =
    { orbitPosition : StellarPoint
    , inclination : Float
    , eccentricity : Float
    , effectiveHZCODeviation : Float
    , stellarClass : String
    , stellarType : String
    , subtype : Maybe Int
    , orbitType : Int
    , mass : Maybe Float
    , diameter : Maybe Float
    , temperature : Maybe Int
    , age : Float
    , colour : Maybe StarColour
    , companion : Maybe StarData
    , orbit : Float
    , period : Float
    , baseline : Float
    , stellarObjects : List StellarObject
    , orbitSequence : String
    , au : Float
    , jumpShadow : Maybe Float
    , luminosity : Maybe Float
    , hzco : Maybe Float
    , minimumAllowableOrbit : Maybe Float
    , spread : Float
    }


isBrownDwarf : InnerStarData -> Bool
isBrownDwarf theStar =
    List.any (\a -> a == theStar.stellarType) [ "D", "Y", "T", "L" ]


{-| Since StarData is recursive, we need to use a Type for it, instead of an
alias
-}
type StarData
    = -- StarDataWrap is the type variant that contains the InnerStarData
      StarDataWrap
        -- InnerStarData is the actual data
        InnerStarData


type alias StellarOrbit =
    { orbitPosition : StellarPoint
    , orbitType : Int
    , orbit : Float
    , au : Float
    , orbitSequence : String
    }


getProfileString : StellarObject -> String
getProfileString stellarObject =
    case stellarObject of
        GasGiant gasGiantData ->
            gasGiantData.code

        TerrestrialPlanet terrestrialData ->
            terrestrialData.uwp

        PlanetoidBelt planetoidBeltData ->
            planetoidBeltData.uwp

        Planetoid planetoidData ->
            planetoidData.uwp

        Star (StarDataWrap starDataConfig) ->
            starDataConfig.stellarType
                ++ (starDataConfig.subtype |> Maybe.map String.fromInt |> Maybe.withDefault "")
                ++ " "
                ++ starDataConfig.stellarClass


extractStellarOrbit orbit =
    { orbitPosition = orbit.orbitPosition
    , orbitType = orbit.orbitType
    , orbit = orbit.orbit
    , au = orbit.au
    , orbitSequence = orbit.orbitSequence
    }


getSafeJumpTime : Maybe Int -> StellarObject -> String
getSafeJumpTime mDrive stellarObject =
    case stellarObject of
        GasGiant data ->
            TravelCalculations.safeJumpTimeFromShadow mDrive data.jumpShadow

        TerrestrialPlanet data ->
            TravelCalculations.safeJumpTimeFromShadow mDrive data.jumpShadow

        PlanetoidBelt data ->
            TravelCalculations.safeJumpTimeFromShadow mDrive data.jumpShadow

        Planetoid data ->
            TravelCalculations.safeJumpTimeFromShadow mDrive data.jumpShadow

        Star (StarDataWrap data) ->
            TravelCalculations.safeJumpTimeFromShadow mDrive data.jumpShadow


getStellarOrbit : StellarObject -> StellarOrbit
getStellarOrbit stellarObject =
    case stellarObject of
        GasGiant giantData ->
            extractStellarOrbit giantData

        TerrestrialPlanet terrestrialData ->
            extractStellarOrbit terrestrialData

        PlanetoidBelt planetoidBelt ->
            extractStellarOrbit planetoidBelt

        Planetoid planetoid ->
            extractStellarOrbit planetoid

        Star (StarDataWrap innerStarData) ->
            extractStellarOrbit innerStarData


getInnerStarData : StarData -> InnerStarData
getInnerStarData (StarDataWrap starDataConfig) =
    starDataConfig


type StellarObject
    = GasGiant GasGiantData
    | TerrestrialPlanet SharedPData
    | PlanetoidBelt PlanetoidBeltData
    | Planetoid SharedPData
    | Star StarData


{-| Returns the StarData if the StellarObject is a Star, otherwise Nothing
-}
getStarData : StellarObject -> Maybe StarData
getStarData stellarObject =
    case stellarObject of
        Star starData ->
            Just starData

        _ ->
            Nothing


{-| Returns the GasGiantData if the StellarObject is a GasGiant, otherwise Nothing
-}
getGasGiantData : StellarObject -> Maybe GasGiantData
getGasGiantData stellarObject =
    case stellarObject of
        GasGiant gasGiantData ->
            Just gasGiantData

        _ ->
            Nothing


{-| Returns the TerrestrialData if the StellarObject is a TerrestrialPlanet, otherwise Nothing
-}
getTerrestrialData : StellarObject -> Maybe SharedPData
getTerrestrialData stellarObject =
    case stellarObject of
        TerrestrialPlanet terrestrialData ->
            Just terrestrialData

        _ ->
            Nothing


{-| Returns the PlanetoidBeltData if the StellarObject is a PlanetoidBelt, otherwise Nothing
-}
getPlanetoidBeltData : StellarObject -> Maybe PlanetoidBeltData
getPlanetoidBeltData stellarObject =
    case stellarObject of
        PlanetoidBelt planetoidBeltData ->
            Just planetoidBeltData

        _ ->
            Nothing


{-| Returns the PlanetoidData if the StellarObject is a Planetoid, otherwise Nothing
-}
getPlanetoidData : StellarObject -> Maybe SharedPData
getPlanetoidData stellarObject =
    case stellarObject of
        Planetoid planetoidData ->
            Just planetoidData

        _ ->
            Nothing


codecPlanetoidBeltData : Codec PlanetoidBeltData
codecPlanetoidBeltData =
    Codec.object
        (\pos inc ecc hzco orb mt st ct ot sp blk rr per orbitSeq uwp_ js ot_ au ret nm atm hydro pop bio bioC bioDiv compat hab natS extS govD llD tlD temp id_ cityCount_ ->
            { orbitPosition = pos
            , inclination = inc
            , eccentricity = ecc
            , effectiveHZCODeviation = hzco
            , orbit = orb
            , mType = mt
            , sType = st
            , cType = ct
            , oType = ot
            , span = sp
            , bulk = blk
            , resourceRating = rr
            , period = per
            , orbitSequence = orbitSeq
            , uwp = uwp_
            , jumpShadow = js
            , orbitType = ot_
            , au = au
            , retrograde = ret
            , name = nm
            , atmosphere = atm
            , hydrographics = hydro
            , population = pop
            , biomassRating = Maybe.withDefault 0 bio
            , biocomplexityCode = Maybe.withDefault 0 bioC
            , biodiversityRating = Maybe.withDefault 0 bioDiv
            , compatibilityRating = Maybe.withDefault 0 compat
            , habitabilityRating = hab
            , nativeSophont = Maybe.withDefault False natS
            , extinctSophont = Maybe.withDefault False extS
            , governmentDetail = govD
            , lawLevelDetail = llD
            , techLevelDetail = tlD
            , meanTemperature = temp
            , id = id_
            , cityCount = cityCount_
            }
        )
        |> Codec.field "orbit_position" .orbitPosition Point.codec
        |> Codec.field "inclination" .inclination Codec.float
        |> Codec.field "eccentricity" .eccentricity Codec.float
        |> Codec.field "effective_hzco_deviation" .effectiveHZCODeviation Codec.float
        |> Codec.field "orbit" .orbit Codec.float
        |> Codec.field "m_type" .mType Codec.float
        |> Codec.field "s_type" .sType Codec.float
        |> Codec.field "c_type" .cType Codec.float
        |> Codec.field "o_type" .oType Codec.float
        |> Codec.field "span" .span Codec.float
        |> Codec.field "bulk" .bulk Codec.float
        |> Codec.field "resource_rating" .resourceRating Codec.float
        |> Codec.field "period" .period Codec.float
        |> Codec.field "orbit_sequence" .orbitSequence Codec.string
        |> Codec.field "uwp" .uwp Codec.string
        |> Codec.field "jump_shadow" .jumpShadow (Codec.build (Codec.encoder (Codec.nullable Codec.float)) (JsDecode.nullable (JsDecode.field "distance_km" JsDecode.float)))
        |> Codec.field "orbit_type" .orbitType Codec.int
        |> Codec.field "au" .au Codec.float
        |> Codec.field "retrograde" .retrograde Codec.bool
        |> Codec.optionalNullableField "name" .name Codec.string
        |> Codec.optionalField "atmosphere" .atmosphere Atmosphere.codec
        |> Codec.optionalField "hydrographics" .hydrographics codecHydrographics
        |> Codec.optionalNullableField "population"
            .population
            (Codec.oneOf Population.codec
                [ Codec.succeed
                    { code = 0
                    , concentrationRating = Nothing
                    , urbanizationPercentage = Nothing
                    , majorCities = Nothing
                    , censusPopulation = Nothing
                    , cultureTrait = []
                    }
                ]
            )
        |> Codec.optionalField "biomass_rating" (\d -> Just d.biomassRating) Codec.int
        |> Codec.optionalField "biocomplexity_rating" (\d -> Just d.biocomplexityCode) Codec.int
        |> Codec.optionalField "biodiversity_rating" (\d -> Just d.biodiversityRating) Codec.int
        |> Codec.optionalField "compatibility_rating" (\d -> Just d.compatibilityRating) Codec.int
        |> Codec.optionalField "habitability_rating" .habitabilityRating Codec.int
        |> Codec.optionalField "native_sophont" (\d -> Just d.nativeSophont) Codec.bool
        |> Codec.optionalField "extinct_sophont" (\d -> Just d.extinctSophont) Codec.bool
        |> Codec.optionalField "government" .governmentDetail codecGovernmentDetail
        |> Codec.optionalField "law_level" .lawLevelDetail codecLawLevelDetail
        |> Codec.optionalField "tech_level" .techLevelDetail codecTechLevelDetail
        |> Codec.optionalNullableField "temperature" .meanTemperature Codec.float
        |> Codec.field "id" .id Codec.int
        |> Codec.field "city_count" .cityCount Codec.int
        |> Codec.buildObject


codecGasGiantData : Codec GasGiantData
codecGasGiantData =
    Codec.object
        (\pos inc ecc hzco code_ diam mass_ orb mns hasRingM tj axTilt per orbitSeq js ot au nm id_ ->
            { orbitPosition = pos
            , inclination = inc
            , eccentricity = ecc
            , effectiveHZCODeviation = hzco
            , code = code_
            , diameter = diam
            , mass = mass_
            , orbit = orb
            , moons = mns
            , hasRing = Maybe.withDefault False hasRingM
            , trojanOffset = tj
            , axialTilt = axTilt
            , period = per
            , orbitSequence = orbitSeq
            , jumpShadow = js
            , orbitType = ot
            , au = au
            , name = nm
            , id = id_
            }
        )
        |> Codec.field "orbit_position" .orbitPosition Point.codec
        |> Codec.field "inclination" .inclination Codec.float
        |> Codec.field "eccentricity" .eccentricity Codec.float
        |> Codec.field "effective_hzco_deviation" .effectiveHZCODeviation Codec.float
        |> Codec.field "code" .code Codec.string
        |> Codec.field "diameter" .diameter Codec.float
        |> Codec.optionalNullableField "mass" .mass Codec.float
        |> Codec.field "orbit" .orbit Codec.float
        |> Codec.field "moons"
            .moons
            (Codec.build
                (Codec.encoder (Codec.list Moon.codec))
                (JsDecode.oneOf
                    [ Codec.decoder (Codec.list Moon.codec)
                    , JsDecode.succeed []
                    ]
                )
            )
        |> Codec.optionalField "has_ring" (\d -> Just d.hasRing) Codec.bool
        |> Codec.optionalNullableField "trojan_offset" .trojanOffset Codec.float
        |> Codec.field "axial_tilt" .axialTilt Codec.float
        |> Codec.field "period" .period Codec.float
        |> Codec.field "orbit_sequence" .orbitSequence Codec.string
        |> Codec.field "jump_shadow" .jumpShadow (Codec.build (Codec.encoder (Codec.nullable Codec.float)) (JsDecode.nullable (JsDecode.field "distance_km" JsDecode.float)))
        |> Codec.field "orbit_type" .orbitType Codec.int
        |> Codec.field "au" .au Codec.float
        |> Codec.optionalNullableField "name" .name Codec.string
        |> Codec.field "id" .id Codec.int
        |> Codec.buildObject


nullableString : Codec String
nullableString =
    Codec.build JsEncode.string
        (JsDecode.oneOf [ JsDecode.string, JsDecode.null "" ])


codecCodeAndDesc : Codec CodeAndDesc
codecCodeAndDesc =
    Codec.object CodeAndDesc
        |> Codec.field "code" .code Codec.string
        |> Codec.field "description" .description nullableString
        |> Codec.buildObject


codecIntCodeAndDesc : Codec IntCodeAndDesc
codecIntCodeAndDesc =
    Codec.object IntCodeAndDesc
        |> Codec.field "code" .code Codec.int
        |> Codec.field "description" .description nullableString
        |> Codec.buildObject


codecGovernmentStructure : Codec GovernmentStructure
codecGovernmentStructure =
    Codec.object GovernmentStructure
        |> Codec.optionalField "judicial" .judicial codecCodeAndDesc
        |> Codec.optionalField "executive" .executive codecCodeAndDesc
        |> Codec.optionalField "legislative" .legislative codecCodeAndDesc
        |> Codec.buildObject


codecGovernmentCharacteristics : Codec GovernmentCharacteristics
codecGovernmentCharacteristics =
    Codec.object GovernmentCharacteristics
        |> Codec.optionalField "authority" .authority codecCodeAndDesc
        |> Codec.optionalField "centralisation" .centralisation codecCodeAndDesc
        |> Codec.buildObject


codecGovernmentDetail : Codec GovernmentDetailData
codecGovernmentDetail =
    Codec.object GovernmentDetailData
        |> Codec.optionalNullableField "type" .type_ Codec.string
        |> Codec.optionalNullableField "description" .description Codec.string
        |> Codec.optionalField "structure" .structure codecGovernmentStructure
        |> Codec.optionalField "characteristics" .characteristics codecGovernmentCharacteristics
        |> Codec.buildObject


codecLawSubClassifications : Codec LawSubClassifications
codecLawSubClassifications =
    Codec.object LawSubClassifications
        |> Codec.optionalField "weapons_and_armour" .weaponsAndArmour codecIntCodeAndDesc
        |> Codec.optionalField "criminal_law" .criminalLaw codecIntCodeAndDesc
        |> Codec.optionalField "economic_law" .economicLaw codecIntCodeAndDesc
        |> Codec.optionalField "private_law" .privateLaw codecIntCodeAndDesc
        |> Codec.optionalField "personal_rights" .personalRights codecIntCodeAndDesc
        |> Codec.buildObject


valueBool : Codec Bool
valueBool =
    Codec.build JsEncode.bool (JsDecode.field "value" JsDecode.bool)


codecLawCharacteristics : Codec LawCharacteristics
codecLawCharacteristics =
    Codec.object LawCharacteristics
        |> Codec.optionalField "uniformity" .uniformity codecCodeAndDesc
        |> Codec.optionalField "judicial_system" .judicialSystem codecCodeAndDesc
        |> Codec.optionalField "death_penalty" .deathPenalty valueBool
        |> Codec.optionalField "presumed_innocence" .presumedInnocence valueBool
        |> Codec.optionalField "econometric_infractions_administrative" .econometricInfractionsAdministrative valueBool
        |> Codec.buildObject


codecLawLevelDetail : Codec LawLevelDetailData
codecLawLevelDetail =
    Codec.object LawLevelDetailData
        |> Codec.optionalField "sub_classifications" .subClassifications codecLawSubClassifications
        |> Codec.optionalField "characteristics" .characteristics codecLawCharacteristics
        |> Codec.buildObject


codecTechCapability : Codec TechCapability
codecTechCapability =
    Codec.object TechCapability
        |> Codec.field "code" .code Codec.int
        |> Codec.field "description" .description nullableString
        |> Codec.buildObject


codecTechLevelDetail : Codec TechLevelDetailData
codecTechLevelDetail =
    Codec.object TechLevelDetailData
        |> Codec.optionalNullableField "descriptor" .descriptor Codec.string
        |> Codec.optionalField "energy" .energy codecTechCapability
        |> Codec.optionalField "electronics" .electronics codecTechCapability
        |> Codec.optionalField "manufacturing" .manufacturing codecTechCapability
        |> Codec.optionalField "medical" .medical codecTechCapability
        |> Codec.optionalField "environmental" .environmental codecTechCapability
        |> Codec.optionalField "land" .land codecTechCapability
        |> Codec.optionalField "sea" .sea codecTechCapability
        |> Codec.optionalField "air" .air codecTechCapability
        |> Codec.optionalField "space" .space codecTechCapability
        |> Codec.optionalField "personal_military" .personalMilitary codecTechCapability
        |> Codec.optionalField "heavy_military" .heavyMilitary codecTechCapability
        |> Codec.buildObject


codecSharedPData : Codec SharedPData
codecSharedPData =
    Codec.object
        (\atm pos inc ecc hzco sz orb per comp ret tj axTilt mns bio bioC bioDiv compat res natS extS hasRingM hydro alb den grn temp hab orbitSeq uwp_ diam grav mass_ escV js ot au pop rot govD llD tlD nm id_ isMoon_ cityCount_ ->
            { atmosphere = atm
            , orbitPosition = pos
            , inclination = inc
            , eccentricity = ecc
            , effectiveHZCODeviation = hzco
            , size = sz
            , orbit = orb
            , period = per
            , composition = comp
            , retrograde = ret
            , trojanOffset = tj
            , axialTilt = axTilt
            , moons = mns
            , biomassRating = bio
            , biocomplexityCode = bioC
            , biodiversityRating = bioDiv
            , compatibilityRating = compat
            , resourceRating = res
            , nativeSophont = natS
            , extinctSophont = extS
            , hasRing = Maybe.withDefault False hasRingM
            , hydrographics = hydro
            , albedo = alb
            , density = den
            , greenhouse = grn
            , meanTemperature = temp
            , habitabilityRating = hab
            , orbitSequence = orbitSeq
            , uwp = uwp_
            , diameter = diam
            , gravity = grav
            , mass = mass_
            , escapeVelocity = escV
            , jumpShadow = js
            , orbitType = ot
            , au = au
            , population = pop
            , rotation = rot
            , governmentDetail = govD
            , lawLevelDetail = llD
            , techLevelDetail = tlD
            , name = nm
            , id = id_
            , isMoon = isMoon_
            , cityCount = cityCount_
            }
        )
        |> Codec.field "atmosphere" .atmosphere Atmosphere.codec
        |> Codec.field "orbit_position" .orbitPosition Point.codec
        |> Codec.field "inclination" .inclination Codec.float
        |> Codec.field "eccentricity" .eccentricity Codec.float
        |> Codec.field "effective_hzco_deviation" .effectiveHZCODeviation Codec.float
        |> Codec.field "size_code"
            .size
            (Codec.oneOf Codec.string
                [ -- force int to string
                  Codec.int |> Codec.andThen (String.fromInt >> Codec.succeed) (String.toInt >> Maybe.withDefault 999999)
                ]
            )
        |> Codec.field "orbit" .orbit Codec.float
        |> Codec.optionalNullableField "period" .period Codec.float
        |> Codec.optionalNullableField "composition" .composition Codec.string
        |> Codec.field "retrograde" .retrograde Codec.bool
        |> Codec.optionalNullableField "trojan_offset" .trojanOffset Codec.float
        |> Codec.field "axial_tilt" .axialTilt Codec.float
        |> Codec.field "moons"
            .moons
            (Codec.build
                (Codec.encoder (Codec.list (Codec.lazy (\_ -> Moon.codec))))
                (JsDecode.oneOf
                    [ Codec.decoder (Codec.list (Codec.lazy (\_ -> Moon.codec)))
                    , JsDecode.succeed []
                    ]
                )
            )
        |> Codec.field "biomass_rating" .biomassRating Codec.int
        |> Codec.field "biocomplexity_rating" .biocomplexityCode Codec.int
        |> Codec.field "biodiversity_rating" .biodiversityRating Codec.int
        |> Codec.field "compatibility_rating" .compatibilityRating Codec.int
        |> Codec.field "resource_rating" .resourceRating Codec.int
        |> Codec.field "native_sophont" .nativeSophont Codec.bool
        |> Codec.field "extinct_sophont" .extinctSophont Codec.bool
        |> Codec.optionalField "has_ring" (\d -> Just d.hasRing) Codec.bool
        |> Codec.optionalField "hydrographics" .hydrographics codecHydrographics
        |> Codec.field "albedo" .albedo Codec.float
        |> Codec.optionalNullableField "density" .density Codec.float
        |> Codec.optionalNullableField "greenhouse" .greenhouse Codec.float
        |> Codec.optionalNullableField "temperature" .meanTemperature Codec.float
        |> Codec.optionalNullableField "habitability_rating" .habitabilityRating Codec.int
        |> Codec.field "orbit_sequence" .orbitSequence Codec.string
        |> Codec.field "uwp" .uwp Codec.string
        |> Codec.field "diameter" .diameter Codec.float
        |> Codec.optionalNullableField "gravity" .gravity Codec.float
        |> Codec.optionalNullableField "mass" .mass Codec.float
        |> Codec.optionalNullableField "escape_velocity" .escapeVelocity Codec.float
        |> Codec.field "jump_shadow" .jumpShadow (Codec.build (Codec.encoder (Codec.nullable Codec.float)) (JsDecode.nullable (JsDecode.field "distance_km" JsDecode.float)))
        |> Codec.field "orbit_type" .orbitType Codec.int
        |> Codec.field "au" .au Codec.float
        |> Codec.optionalNullableField "population"
            .population
            (Codec.oneOf Population.codec
                [ Codec.succeed
                    { code = 0
                    , concentrationRating = Nothing
                    , urbanizationPercentage = Nothing
                    , majorCities = Nothing
                    , censusPopulation = Nothing
                    , cultureTrait = []
                    }
                ]
            )
        |> Codec.optionalNullableField "rotation" .rotation Codec.float
        |> Codec.optionalField "government" .governmentDetail codecGovernmentDetail
        |> Codec.optionalField "law_level" .lawLevelDetail codecLawLevelDetail
        |> Codec.optionalField "tech_level" .techLevelDetail codecTechLevelDetail
        |> Codec.optionalNullableField "name" .name Codec.string
        |> Codec.field "id" .id Codec.int
        |> Codec.field "is_moon" .isMoon Codec.bool
        |> Codec.field "city_count" .cityCount Codec.int
        |> Codec.buildObject


decodeStellarObject : JsDecode.Decoder StellarObject
decodeStellarObject =
    JsDecode.field "orbit_type" JsDecode.int
        |> JsDecode.andThen
            (\orbitType ->
                case orbitType of
                    10 ->
                        JsDecode.map GasGiant (Codec.decoder codecGasGiantData)

                    11 ->
                        JsDecode.map TerrestrialPlanet (Codec.decoder codecSharedPData)

                    12 ->
                        JsDecode.map PlanetoidBelt (Codec.decoder codecPlanetoidBeltData)

                    13 ->
                        JsDecode.map Planetoid (Codec.decoder codecSharedPData)

                    _ ->
                        JsDecode.map Star (Codec.decoder codecStarData)
            )


codecStarData : Codec StarData
codecStarData =
    Codec.object InnerStarData
        |> Codec.field "orbit_position" .orbitPosition Point.codec
        |> Codec.field "inclination" .inclination Codec.float
        |> Codec.field "eccentricity" .eccentricity Codec.float
        |> Codec.field "effective_hzco_deviation" .effectiveHZCODeviation Codec.float
        |> Codec.field "stellar_class" .stellarClass Codec.string
        |> Codec.field "stellar_type" .stellarType Codec.string
        |> Codec.field "stellar_subtype" .subtype (Codec.nullable Codec.int)
        |> Codec.field "orbit_type" .orbitType Codec.int
        |> Codec.field "mass" .mass (Codec.nullable Codec.float)
        |> Codec.field "diameter" .diameter (Codec.nullable Codec.float)
        |> Codec.field "temperature" .temperature (Codec.nullable Codec.int)
        |> Codec.field "age" .age Codec.float
        |> Codec.optionalField "colour" .colour codecStarColour
        |> Codec.field "companion" .companion (Codec.nullable <| Codec.lazy (\_ -> codecStarData))
        |> Codec.field "orbit" .orbit Codec.float
        |> Codec.field "period" .period Codec.float
        |> Codec.field "baseline" .baseline Codec.float
        |> Codec.field "stellar_objects" .stellarObjects (Codec.list (Codec.lazy (\_ -> codecStellarObject)))
        |> Codec.field "orbit_sequence" .orbitSequence Codec.string
        |> Codec.field "au" .au Codec.float
        |> Codec.field "jump_shadow" .jumpShadow (Codec.nullable Codec.float)
        |> Codec.optionalNullableField "luminosity" .luminosity Codec.float
        |> Codec.optionalNullableField "hzco" .hzco Codec.float
        |> Codec.optionalNullableField "minimum_allowable_orbit" .minimumAllowableOrbit Codec.float
        |> Codec.field "spread" .spread Codec.float
        |> Codec.buildObject
        |> Codec.map StarDataWrap (\(StarDataWrap data) -> data)


encodeStellarObject : StellarObject -> Codec.Value
encodeStellarObject stellarObject =
    case stellarObject of
        GasGiant data ->
            Codec.encodeToValue codecGasGiantData data

        TerrestrialPlanet data ->
            Codec.encodeToValue codecSharedPData data

        PlanetoidBelt data ->
            Codec.encodeToValue codecPlanetoidBeltData data

        Planetoid data ->
            Codec.encodeToValue codecSharedPData data

        Star data ->
            Codec.encodeToValue codecStarData data


type alias Hydrographics =
    { code : Int
    , distribution : Maybe Int
    , liquid : Maybe String
    }


codecHydrographics : Codec Hydrographics
codecHydrographics =
    Codec.object Hydrographics
        |> Codec.field "code" .code Codec.int
        |> Codec.field "distribution" .distribution codecDistribution
        |> Codec.optionalNullableField "liquid"
            .liquid
            (Codec.build JsEncode.string
                (JsDecode.oneOf
                    [ JsDecode.string
                    , JsDecode.field "value" JsDecode.string
                    ]
                )
            )
        |> Codec.buildObject


codecDistribution : Codec (Maybe Int)
codecDistribution =
    Codec.build
        (\maybeInt ->
            case maybeInt of
                Nothing ->
                    JsEncode.null

                Just n ->
                    JsEncode.int n
        )
        (JsDecode.nullable
            (JsDecode.oneOf
                [ JsDecode.int
                , JsDecode.field "code" JsDecode.int
                ]
            )
        )


codecStellarObject : Codec StellarObject
codecStellarObject =
    Codec.build
        encodeStellarObject
        decodeStellarObject


type alias MoonsPage =
    { moons : List StellarObject
    , count : Int
    , page : Int
    , pages : Int
    }


moonsPageDecoder : JsDecode.Decoder MoonsPage
moonsPageDecoder =
    JsDecode.map4 MoonsPage
        (JsDecode.field "moons" (JsDecode.list decodeStellarObject))
        (JsDecode.field "count" JsDecode.int)
        (JsDecode.field "page" JsDecode.int)
        (JsDecode.field "pages" JsDecode.int)
