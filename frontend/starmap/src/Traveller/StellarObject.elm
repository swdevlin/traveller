module Traveller.StellarObject exposing (GasGiantData, InnerStarData, PlanetoidBeltData, PlanetoidData, SharedPData, StarData(..), StellarObject(..), codecStarData, codecStellarObject, getInnerStarData, getProfileString, getStarData, getStellarOrbit, isBrownDwarf)

import Codec exposing (Codec)
import Json.Decode as JsDecode
import Traveller.Atmosphere as Atmosphere exposing (StellarAtmosphere)
import Traveller.Moon as Moon exposing (Moon)
import Traveller.Point as Point exposing (StellarPoint)
import Traveller.StarColour exposing (StarColour, codecStarColour)


type alias SharedPData =
    { atmosphere : StellarAtmosphere
    , orbitPosition : StellarPoint
    , inclination : Float
    , eccentricity : Float
    , effectiveHZCODeviation : Float
    , size : String
    , orbit : Float
    , period : Float
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
    , safeJumpTime : String
    , orbitType : Int
    , au : Float
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
    , safeJumpTime : String
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
    , safeJumpTime : String
    , orbitType : Int
    , au : Float
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
    , safeJumpTime : String
    , orbitType : Int
    , au : Float
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
    , baseline : Int
    , stellarObjects : List StellarObject
    , orbitSequence : String
    , safeJumpTime : String
    , au : Float
    , jumpShadow : Maybe Float
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


getSafeJumpTime : StellarObject -> String
getSafeJumpTime stellarObject =
    case stellarObject of
        GasGiant gasGiantData ->
            gasGiantData.safeJumpTime

        TerrestrialPlanet terrestrialData ->
            terrestrialData.safeJumpTime

        PlanetoidBelt planetoidBeltData ->
            planetoidBeltData.safeJumpTime

        Planetoid planetoidData ->
            planetoidData.safeJumpTime

        Star (StarDataWrap starDataConfig) ->
            starDataConfig.safeJumpTime


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
    Codec.object PlanetoidBeltData
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
        |> Codec.field "safe_jump_time" .safeJumpTime Codec.string
        |> Codec.field "orbit_type" .orbitType Codec.int
        |> Codec.field "au" .au Codec.float
        |> Codec.buildObject


codecGasGiantData : Codec GasGiantData
codecGasGiantData =
    Codec.object
        (\pos inc ecc hzco code_ diam mass_ orb mns hasRingM tj axTilt per orbitSeq sjt ot au ->
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
            , safeJumpTime = sjt
            , orbitType = ot
            , au = au
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
        |> Codec.field "safe_jump_time" .safeJumpTime Codec.string
        |> Codec.field "orbit_type" .orbitType Codec.int
        |> Codec.field "au" .au Codec.float
        |> Codec.buildObject


codecSharedPData : Codec SharedPData
codecSharedPData =
    Codec.object
        (\atm pos inc ecc hzco sz orb per comp ret tj axTilt mns bio bioC bioDiv compat res natS extS hasRingM hydro alb den grn temp hab orbitSeq uwp_ diam grav mass_ escV sjt ot au ->
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
            , safeJumpTime = sjt
            , orbitType = ot
            , au = au
            }
        )
        |> Codec.field "atmosphere" .atmosphere Atmosphere.codec
        |> Codec.field "orbit_position" .orbitPosition Point.codec
        |> Codec.field "inclination" .inclination Codec.float
        |> Codec.field "eccentricity" .eccentricity Codec.float
        |> Codec.field "effective_hzco_deviation" .effectiveHZCODeviation Codec.float
        |> Codec.field "size"
            .size
            (Codec.oneOf Codec.string
                [ -- force int to string
                  Codec.int |> Codec.andThen (String.fromInt >> Codec.succeed) (String.toInt >> Maybe.withDefault 999999)
                ]
            )
        |> Codec.field "orbit" .orbit Codec.float
        |> Codec.field "period" .period Codec.float
        |> Codec.optionalField "composition" .composition Codec.string
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
        |> Codec.optionalField "density" .density Codec.float
        |> Codec.optionalField "greenhouse" .greenhouse Codec.float
        |> Codec.optionalNullableField "temperature" .meanTemperature Codec.float
        |> Codec.optionalField "habitability_rating" .habitabilityRating Codec.int
        |> Codec.field "orbit_sequence" .orbitSequence Codec.string
        |> Codec.field "uwp" .uwp Codec.string
        |> Codec.field "diameter" .diameter Codec.float
        |> Codec.optionalNullableField "gravity" .gravity Codec.float
        |> Codec.optionalNullableField "mass" .mass Codec.float
        |> Codec.optionalNullableField "escape_velocity" .escapeVelocity Codec.float
        |> Codec.field "safe_jump_time" .safeJumpTime Codec.string
        |> Codec.field "orbit_type" .orbitType Codec.int
        |> Codec.field "au" .au Codec.float
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
        |> Codec.field "baseline" .baseline Codec.int
        |> Codec.field "stellar_objects" .stellarObjects (Codec.list (Codec.lazy (\_ -> codecStellarObject)))
        |> Codec.field "orbit_sequence" .orbitSequence Codec.string
        |> Codec.field "safe_jump_time" .safeJumpTime Codec.string
        |> Codec.field "au" .au Codec.float
        |> Codec.field "jump_shadow" .jumpShadow (Codec.nullable Codec.float)
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
    }


codecHydrographics : Codec Hydrographics
codecHydrographics =
    Codec.object Hydrographics
        |> Codec.field "code" .code Codec.int
        |> Codec.field "distribution" .distribution (Codec.nullable Codec.int)
        |> Codec.buildObject


codecStellarObject : Codec StellarObject
codecStellarObject =
    Codec.build
        encodeStellarObject
        decodeStellarObject
