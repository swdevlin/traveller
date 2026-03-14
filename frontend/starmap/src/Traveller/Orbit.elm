module Traveller.Orbit exposing (StellarOrbit(..), codec)

import Codec exposing (Codec)
import Json.Decode as JsDecode
import Json.Encode as JsEncode
import Parser exposing ((|.), (|=), Parser)
import Parser.Extras as Parser


type alias ComplexOrbitData =
    { zone : String
    , orbit : Maybe Float
    }


type StellarOrbit
    = SimpleOrbit Float
    | ComplexOrbit ComplexOrbitData


codec : Codec StellarOrbit
codec =
    Codec.build
        (\stellarOrbit ->
            case stellarOrbit of
                SimpleOrbit orbit ->
                    JsEncode.float orbit

                ComplexOrbit complexOrbitData ->
                    JsEncode.object
                        [ ( "zone", JsEncode.string complexOrbitData.zone )
                        , ( "orbit"
                          , case complexOrbitData.orbit of
                                Just orbitNum ->
                                    JsEncode.float orbitNum

                                Nothing ->
                                    JsEncode.null
                          )
                        ]
        )
        (JsDecode.oneOf
            [ JsDecode.map SimpleOrbit JsDecode.float
            , JsDecode.map2
                (\zone_ orbit -> ComplexOrbit { zone = zone_, orbit = orbit })
                (JsDecode.field "zone" JsDecode.string)
                (JsDecode.field "orbit" (JsDecode.nullable JsDecode.float))
            ]
        )
