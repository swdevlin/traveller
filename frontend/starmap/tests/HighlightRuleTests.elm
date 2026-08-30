module HighlightRuleTests exposing (..)

import Codec
import Color
import Expect
import Json.Encode as Encode
import Test exposing (Test, describe)
import Traveller.HighlightRule as HighlightRule exposing (Condition, Field(..), Operator(..))
import Traveller.StarSystemStars exposing (StarSystem, StarType, starTypeCodec)


baseSystem : StarSystem
baseSystem =
    { address = { x = 0, y = 0 }
    , sectorName = "Test Sector"
    , name = "Testworld"
    , scanPoints = 0
    , surveyIndex = 6
    , gasGiantCount = 0
    , terrestrialPlanetCount = 1
    , planetoidBeltCount = 0
    , allegiance = Nothing
    , nativeSophont = False
    , extinctSophont = False
    , techLevel = Just 12
    , stars = []
    , mainWorldUwp = Just "A788899-C"
    , travelZone = Nothing
    , known = True
    , mainWorldName = Just "Testworld"
    , mainWorldImage = Nothing
    , wtn = Nothing
    , gwp = Nothing
    , importance = Nothing
    , tradeCodes = []
    , strategic = Nothing
    , baseCodes = []
    , habitabilityRating = Nothing
    , governmentCode = Just 9
    , governmentName = Nothing
    , sectorId = 42
    , subsectorId = Just 7
    }


{-| Builds a `StarType` fixture by round-tripping it through `starTypeCodec`,
since `StarType` is an opaque wrapper with no exposed constructor - this is
how the app itself ever gets one, decoding the API's `stars` payload.
`au = 0` marks the primary star, per `Api::StarMapController#build_star_hash`'s
`au || 0` convention.
-}
starWith : { au : Float, stellarType : String, stellarClass : String, companion : Maybe StarType } -> StarType
starWith { au, stellarType, stellarClass, companion } =
    let
        encoded =
            Encode.object
                [ ( "au", Encode.float au )
                , ( "stellar_subtype", Encode.null )
                , ( "companion", companion |> Maybe.map (Codec.encoder starTypeCodec) |> Maybe.withDefault Encode.null )
                , ( "stellar_type", Encode.string stellarType )
                , ( "stellar_class", Encode.string stellarClass )
                , ( "colour", Encode.null )
                , ( "diameter", Encode.null )
                ]
    in
    case Codec.decodeValue starTypeCodec encoded of
        Ok star ->
            star

        Err error ->
            Debug.todo ("invalid starWith test fixture: " ++ Debug.toString error)


condition : Field -> Operator -> List String -> Condition
condition field operator values =
    { field = field, operator = operator, negate = False, values = values }


ruleFrom : List (List Condition) -> HighlightRule.Rule
ruleFrom groups =
    { id = "test", name = "Test Rule", colour = Color.red, enabled = True, groups = groups }


evaluatesTo : Bool -> HighlightRule.Rule -> Expect.Expectation
evaluatesTo expected rule =
    Expect.equal expected (HighlightRule.evaluate rule baseSystem)


parseUwpTests : Test
parseUwpTests =
    describe "parseUwp"
        [ Test.test "slices a valid UWP string into its components" <|
            \_ ->
                Expect.equal
                    (Just
                        { starport = "A"
                        , size = "7"
                        , atmosphere = "8"
                        , hydrographics = "8"
                        , population = "8"
                        , government = "9"
                        , lawLevel = "9"
                        , techLevel = "C"
                        }
                    )
                    (HighlightRule.parseUwp "A788899-C")
        , Test.test "returns Nothing for a too-short string" <|
            \_ ->
                Expect.equal Nothing (HighlightRule.parseUwp "A78")
        ]


evaluateTests : Test
evaluateTests =
    describe "evaluate"
        [ Test.test "Eq matches an exact starport code" <|
            \_ ->
                ruleFrom [ [ condition Starport Eq [ "A" ] ] ]
                    |> evaluatesTo True
        , Test.test "Eq rejects a non-matching starport code" <|
            \_ ->
                ruleFrom [ [ condition Starport Eq [ "B" ] ] ]
                    |> evaluatesTo False
        , Test.test "negate inverts an Eq match" <|
            \_ ->
                ruleFrom [ [ { field = Starport, operator = Eq, negate = True, values = [ "A" ] } ] ]
                    |> evaluatesTo False
        , Test.test "Lt compares ordinal rank, not string order" <|
            \_ ->
                -- population code is 8 ("8"), Lt "9" should match
                ruleFrom [ [ condition Population Lt [ "9" ] ] ]
                    |> evaluatesTo True
        , Test.test "Starport rank is reversed: A outranks C (better quality)" <|
            \_ ->
                -- baseSystem's main world starport is "A" ("A788899-C")
                ruleFrom [ [ condition Starport Gt [ "C" ] ] ]
                    |> evaluatesTo True
        , Test.test "Starport rank is reversed: E is worse than A" <|
            \_ ->
                let
                    system =
                        { baseSystem | mainWorldUwp = Just "E788899-C" }

                    rule =
                        ruleFrom [ [ condition Starport Lt [ "A" ] ] ]
                in
                Expect.equal True (HighlightRule.evaluate rule system)
        , Test.test "Lte is inclusive of the boundary" <|
            \_ ->
                ruleFrom [ [ condition Population Lte [ "8" ] ] ]
                    |> evaluatesTo True
        , Test.test "Gt rejects an equal value" <|
            \_ ->
                ruleFrom [ [ condition Population Gt [ "8" ] ] ]
                    |> evaluatesTo False
        , Test.test "Gte accepts an equal value" <|
            \_ ->
                ruleFrom [ [ condition Population Gte [ "8" ] ] ]
                    |> evaluatesTo True
        , Test.test "Between matches inside the range" <|
            \_ ->
                ruleFrom [ [ condition Population Between [ "3", "9" ] ] ]
                    |> evaluatesTo True
        , Test.test "Between rejects outside the range" <|
            \_ ->
                ruleFrom [ [ condition Population Between [ "0", "3" ] ] ]
                    |> evaluatesTo False
        , Test.test "Between normalises reversed bounds" <|
            \_ ->
                ruleFrom [ [ condition Population Between [ "9", "3" ] ] ]
                    |> evaluatesTo True
        , Test.test "OneOf matches any listed code" <|
            \_ ->
                ruleFrom [ [ condition Starport OneOf [ "A", "B", "C" ] ] ]
                    |> evaluatesTo True
        , Test.test "OneOf rejects a code not in the list" <|
            \_ ->
                ruleFrom [ [ condition Starport OneOf [ "D", "E", "X" ] ] ]
                    |> evaluatesTo False
        , Test.test "Known field matches the boolean known state" <|
            \_ ->
                ruleFrom [ [ condition Known Eq [ "true" ] ] ]
                    |> evaluatesTo True
        , Test.test "NativeSophont matches the boolean native sophont flag" <|
            \_ ->
                let
                    system =
                        { baseSystem | nativeSophont = True }

                    rule =
                        ruleFrom [ [ condition NativeSophont Eq [ "true" ] ] ]
                in
                Expect.equal True (HighlightRule.evaluate rule system)
        , Test.test "ExtinctSophont matches the boolean extinct sophont flag" <|
            \_ ->
                ruleFrom [ [ condition ExtinctSophont Eq [ "false" ] ] ]
                    |> evaluatesTo True
        , Test.test "SurveyIndex field matches the plain integer value" <|
            \_ ->
                ruleFrom [ [ condition SurveyIndex Eq [ "6" ] ] ]
                    |> evaluatesTo True
        , Test.test "GasGiantCount supports numeric comparisons" <|
            \_ ->
                let
                    system =
                        { baseSystem | gasGiantCount = 2 }

                    rule =
                        ruleFrom [ [ condition GasGiantCount Gt [ "0" ] ] ]
                in
                Expect.equal True (HighlightRule.evaluate rule system)
        , Test.test "GasGiantCount of zero fails a greater-than-zero condition" <|
            \_ ->
                ruleFrom [ [ condition GasGiantCount Gt [ "0" ] ] ]
                    |> evaluatesTo False
        , Test.test "PlanetoidBeltCount supports numeric comparisons" <|
            \_ ->
                let
                    system =
                        { baseSystem | planetoidBeltCount = 3 }

                    rule =
                        ruleFrom [ [ condition PlanetoidBeltCount Gte [ "3" ] ] ]
                in
                Expect.equal True (HighlightRule.evaluate rule system)
        , Test.test "Has matches a system with the given base code" <|
            \_ ->
                let
                    system =
                        { baseSystem | baseCodes = [ "N", "S" ] }

                    rule =
                        ruleFrom [ [ condition Bases Has [ "N" ] ] ]
                in
                Expect.equal True (HighlightRule.evaluate rule system)
        , Test.test "Has rejects a system without the given base code" <|
            \_ ->
                let
                    system =
                        { baseSystem | baseCodes = [ "S" ] }

                    rule =
                        ruleFrom [ [ condition Bases Has [ "N" ] ] ]
                in
                Expect.equal False (HighlightRule.evaluate rule system)
        , Test.test "negate inverts a Has match" <|
            \_ ->
                let
                    system =
                        { baseSystem | baseCodes = [ "N" ] }

                    rule =
                        ruleFrom [ [ { field = Bases, operator = Has, negate = True, values = [ "N" ] } ] ]
                in
                Expect.equal False (HighlightRule.evaluate rule system)
        , Test.test "HasOneOf matches when any target base code is present" <|
            \_ ->
                let
                    system =
                        { baseSystem | baseCodes = [ "W" ] }

                    rule =
                        ruleFrom [ [ condition Bases HasOneOf [ "N", "S", "W" ] ] ]
                in
                Expect.equal True (HighlightRule.evaluate rule system)
        , Test.test "HasOneOf rejects when none of the target base codes are present" <|
            \_ ->
                let
                    system =
                        { baseSystem | baseCodes = [ "M" ] }

                    rule =
                        ruleFrom [ [ condition Bases HasOneOf [ "N", "S", "W" ] ] ]
                in
                Expect.equal False (HighlightRule.evaluate rule system)
        , Test.test "BaseCount supports numeric comparisons against the base list length" <|
            \_ ->
                let
                    system =
                        { baseSystem | baseCodes = [ "N", "S" ] }

                    rule =
                        ruleFrom [ [ condition BaseCount Gte [ "2" ] ] ]
                in
                Expect.equal True (HighlightRule.evaluate rule system)
        , Test.test "BaseCount of zero fails a greater-than-zero condition" <|
            \_ ->
                ruleFrom [ [ condition BaseCount Gt [ "0" ] ] ]
                    |> evaluatesTo False
        , Test.test "all conditions in a group must match (AND)" <|
            \_ ->
                ruleFrom [ [ condition Starport Eq [ "A" ], condition Population Gt [ "8" ] ] ]
                    |> evaluatesTo False
        , Test.test "any group matching is enough (OR)" <|
            \_ ->
                -- (Starport in [A,B,C] AND Population > 8) OR (SurveyIndex = 10)
                ruleFrom
                    [ [ condition Starport OneOf [ "A", "B", "C" ], condition Population Gt [ "8" ] ]
                    , [ condition SurveyIndex Eq [ "10" ] ]
                    ]
                    |> evaluatesTo False
        , Test.test "worked example: second OR-group matches" <|
            \_ ->
                let
                    system =
                        { baseSystem | surveyIndex = 10 }

                    rule =
                        ruleFrom
                            [ [ condition Starport OneOf [ "A", "B", "C" ], condition Population Gt [ "8" ] ]
                            , [ condition SurveyIndex Eq [ "10" ] ]
                            ]
                in
                Expect.equal True (HighlightRule.evaluate rule system)
        , Test.test "worked example: first OR-group matches" <|
            \_ ->
                let
                    system =
                        { baseSystem | mainWorldUwp = Just "A789999-C" }

                    rule =
                        ruleFrom
                            [ [ condition Starport OneOf [ "A", "B", "C" ], condition Population Gt [ "8" ] ]
                            , [ condition SurveyIndex Eq [ "10" ] ]
                            ]
                in
                Expect.equal True (HighlightRule.evaluate rule system)
        , Test.test "a system with no main world UWP fails UWP-based conditions" <|
            \_ ->
                let
                    system =
                        { baseSystem | mainWorldUwp = Nothing }

                    rule =
                        ruleFrom [ [ condition Starport Eq [ "A" ] ] ]
                in
                Expect.equal False (HighlightRule.evaluate rule system)
        , Test.test "Allegiance matches the system's allegiance code" <|
            \_ ->
                let
                    system =
                        { baseSystem | allegiance = Just "Im" }

                    rule =
                        ruleFrom [ [ condition Allegiance Eq [ "Im" ] ] ]
                in
                Expect.equal True (HighlightRule.evaluate rule system)
        , Test.test "Allegiance fails when the system has no allegiance" <|
            \_ ->
                ruleFrom [ [ condition Allegiance Eq [ "Im" ] ] ]
                    |> evaluatesTo False
        , Test.test "Allegiance OneOf matches any listed code" <|
            \_ ->
                let
                    system =
                        { baseSystem | allegiance = Just "Zh" }

                    rule =
                        ruleFrom [ [ condition Allegiance OneOf [ "Im", "Zh" ] ] ]
                in
                Expect.equal True (HighlightRule.evaluate rule system)
        , Test.test "Sector matches the system's sector id" <|
            \_ ->
                ruleFrom [ [ condition Sector Eq [ "42" ] ] ]
                    |> evaluatesTo True
        , Test.test "Sector rejects a non-matching sector id" <|
            \_ ->
                ruleFrom [ [ condition Sector Eq [ "1" ] ] ]
                    |> evaluatesTo False
        , Test.test "Subsector matches the system's subsector id" <|
            \_ ->
                ruleFrom [ [ condition Subsector Eq [ "7" ] ] ]
                    |> evaluatesTo True
        , Test.test "Subsector fails when the system has no subsector" <|
            \_ ->
                let
                    system =
                        { baseSystem | subsectorId = Nothing }

                    rule =
                        ruleFrom [ [ condition Subsector Eq [ "7" ] ] ]
                in
                Expect.equal False (HighlightRule.evaluate rule system)
        ]


primaryStarFieldOptionsTests : Test
primaryStarFieldOptionsTests =
    describe "fieldOptions"
        [ Test.test "PrimaryStar includes normal spectral types and special types" <|
            \_ ->
                let
                    codes =
                        HighlightRule.fieldOptions PrimaryStar |> List.map .code
                in
                Expect.equal True (List.member "G" codes && List.member "BD" codes && List.member "AN" codes)
        , Test.test "PrimaryStarClass includes the giant luminosity class" <|
            \_ ->
                let
                    codes =
                        HighlightRule.fieldOptions PrimaryStarClass |> List.map .code
                in
                Expect.equal True (List.member "III" codes)
        , Test.test "StarCount options run from 1 to 8" <|
            \_ ->
                Expect.equal (List.map String.fromInt (List.range 1 8)) (HighlightRule.fieldOptions StarCount |> List.map .code)
        ]


primaryStarAndCountEvaluateTests : Test
primaryStarAndCountEvaluateTests =
    describe "evaluate - PrimaryStar / PrimaryStarClass / StarCount"
        [ Test.test "PrimaryStar matches the stellar type of the au=0 star" <|
            \_ ->
                let
                    system =
                        { baseSystem | stars = [ starWith { au = 0, stellarType = "M", stellarClass = "V", companion = Nothing } ] }
                in
                Expect.equal True (HighlightRule.evaluate (ruleFrom [ [ condition PrimaryStar Eq [ "M" ] ] ]) system)
        , Test.test "PrimaryStar ignores stars that aren't the primary (au /= 0)" <|
            \_ ->
                let
                    system =
                        { baseSystem
                            | stars =
                                [ starWith { au = 0, stellarType = "M", stellarClass = "V", companion = Nothing }
                                , starWith { au = 12, stellarType = "G", stellarClass = "V", companion = Nothing }
                                ]
                        }
                in
                Expect.equal False (HighlightRule.evaluate (ruleFrom [ [ condition PrimaryStar Eq [ "G" ] ] ]) system)
        , Test.test "PrimaryStar OneOf matches any listed spectral type" <|
            \_ ->
                let
                    system =
                        { baseSystem | stars = [ starWith { au = 0, stellarType = "M", stellarClass = "V", companion = Nothing } ] }
                in
                Expect.equal True (HighlightRule.evaluate (ruleFrom [ [ condition PrimaryStar OneOf [ "G", "M" ] ] ]) system)
        , Test.test "PrimaryStarClass matches the primary's luminosity class" <|
            \_ ->
                let
                    system =
                        { baseSystem | stars = [ starWith { au = 0, stellarType = "M", stellarClass = "III", companion = Nothing } ] }
                in
                Expect.equal True (HighlightRule.evaluate (ruleFrom [ [ condition PrimaryStarClass Eq [ "III" ] ] ]) system)
        , Test.test "PrimaryStarClass Gt matches a less luminous class than the target" <|
            \_ ->
                let
                    system =
                        { baseSystem | stars = [ starWith { au = 0, stellarType = "G", stellarClass = "V", companion = Nothing } ] }
                in
                Expect.equal True (HighlightRule.evaluate (ruleFrom [ [ condition PrimaryStarClass Gt [ "III" ] ] ]) system)
        , Test.test "PrimaryStarClass Gt rejects a more luminous class than the target" <|
            \_ ->
                let
                    system =
                        { baseSystem | stars = [ starWith { au = 0, stellarType = "B", stellarClass = "Ia", companion = Nothing } ] }
                in
                Expect.equal False (HighlightRule.evaluate (ruleFrom [ [ condition PrimaryStarClass Gt [ "III" ] ] ]) system)
        , Test.test "StarCount counts each top-level star" <|
            \_ ->
                let
                    system =
                        { baseSystem
                            | stars =
                                [ starWith { au = 0, stellarType = "G", stellarClass = "V", companion = Nothing }
                                , starWith { au = 40, stellarType = "M", stellarClass = "V", companion = Nothing }
                                ]
                        }
                in
                Expect.equal True (HighlightRule.evaluate (ruleFrom [ [ condition StarCount Eq [ "2" ] ] ]) system)
        , Test.test "StarCount adds one for each nested tight-binary companion" <|
            \_ ->
                let
                    companion =
                        starWith { au = 2, stellarType = "M", stellarClass = "V", companion = Nothing }

                    system =
                        { baseSystem | stars = [ starWith { au = 0, stellarType = "G", stellarClass = "V", companion = Just companion } ] }
                in
                Expect.equal True (HighlightRule.evaluate (ruleFrom [ [ condition StarCount Eq [ "2" ] ] ]) system)
        ]


matchColourTests : Test
matchColourTests =
    describe "matchColour"
        [ Test.test "returns Nothing when no rule matches" <|
            \_ ->
                Expect.equal Nothing (HighlightRule.matchColour [ ruleFrom [ [ condition Starport Eq [ "X" ] ] ] ] (Just baseSystem))
        , Test.test "returns the colour of the first matching enabled rule" <|
            \_ ->
                let
                    rules =
                        [ { id = "1", name = "First", colour = Color.blue, enabled = True, groups = [ [ condition Starport Eq [ "A" ] ] ] }
                        , { id = "2", name = "Second", colour = Color.green, enabled = True, groups = [ [ condition Starport Eq [ "A" ] ] ] }
                        ]
                in
                Expect.equal (Just Color.blue) (HighlightRule.matchColour rules (Just baseSystem))
        , Test.test "skips disabled rules even if they match" <|
            \_ ->
                let
                    rules =
                        [ { id = "1", name = "Disabled", colour = Color.blue, enabled = False, groups = [ [ condition Starport Eq [ "A" ] ] ] }
                        , { id = "2", name = "Enabled", colour = Color.green, enabled = True, groups = [ [ condition Starport Eq [ "A" ] ] ] }
                        ]
                in
                Expect.equal (Just Color.green) (HighlightRule.matchColour rules (Just baseSystem))
        , Test.test "returns Nothing when there is no system" <|
            \_ ->
                Expect.equal Nothing (HighlightRule.matchColour [ ruleFrom [ [ condition Starport Eq [ "A" ] ] ] ] Nothing)
        ]
