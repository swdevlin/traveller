module Traveller.Moon exposing (Moon, codec)

import Codec exposing (Codec)
import Traveller.Orbit as Orbit exposing (StellarOrbit)
import Traveller.Point as Point exposing (StellarPoint)


{-| the data structure for a stellar object.
It needs to be separate from StellarObject so that it can nest within itself
-}
type alias Moon =
    { orbitPosition : StellarPoint
    , inclination : Float
    , eccentricity : Float
    , effectiveHZCODeviation : Float
    , orbit : Maybe StellarOrbit
    , size : String
    , period : Maybe Float
    , biomassRating : Int
    , axialTilt : Float
    , safeJumpDistance : Maybe String
    }


codecMoonSize : Codec String
codecMoonSize =
    Codec.oneOf Codec.string [ Codec.int |> Codec.map String.fromInt (String.toInt >> Maybe.withDefault 0) ]


codec : Codec Moon
codec =
    Codec.object Moon
        |> Codec.field "orbit_position" .orbitPosition Point.codec
        |> Codec.field "inclination" .inclination Codec.float
        |> Codec.field "eccentricity" .eccentricity Codec.float
        |> Codec.field "effective_hzco_deviation" .effectiveHZCODeviation Codec.float
        |> Codec.field "orbit" .orbit (Codec.nullable Orbit.codec)
        |> Codec.field "size" .size codecMoonSize
        |> Codec.optionalNullableField "period" .period Codec.float
        |> Codec.field "biomass_rating" .biomassRating Codec.int
        |> Codec.field "axial_tilt" .axialTilt Codec.float
        |> Codec.optionalField "safe_jump_distance" .safeJumpDistance Codec.string
        |> Codec.buildObject
