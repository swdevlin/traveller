module Traveller.HighlightRule exposing
    ( Condition
    , Field(..)
    , Group
    , Operator(..)
    , Option
    , PickerData
    , Rule
    , UwpFields
    , allFields
    , apiRuleEncodeBody
    , apiRulesDecoder
    , evaluate
    , fieldLabel
    , fieldOptions
    , matchColour
    , newCondition
    , newRule
    , operatorLabel
    , operatorsFor
    , parseUwp
    , rulesCodec
    )

import Codec exposing (Codec)
import Color exposing (Color)
import Json.Decode as JsDecode
import Json.Encode as Encode
import Traveller.Region exposing (codecColour)
import Traveller.SolarSystemStars exposing (StarSystem, StarTypeData, getStarTypeData)


{-| Every field a highlight rule can be built from: the eight UWP components,
the referee-only survey index and known state, the system's gas giant and
planetoid belt counts, its native/extinct sophont flags, its primary star's
spectral type/luminosity class and total star count, and its
allegiance/sector/subsector membership.
-}
type Field
    = Starport
    | Size
    | Atmosphere
    | Hydrographics
    | Population
    | Government
    | LawLevel
    | TechLevel
    | SurveyIndex
    | Known
    | GasGiantCount
    | PlanetoidBeltCount
    | NativeSophont
    | ExtinctSophont
    | Importance
    | Bases
    | BaseCount
    | StarCount
    | PrimaryStar
    | PrimaryStarClass
    | Allegiance
    | Sector
    | Subsector


allFields : List Field
allFields =
    [ Allegiance, Atmosphere, BaseCount, Bases, ExtinctSophont, GasGiantCount, Government, Hydrographics, Importance, Known, LawLevel, NativeSophont, PlanetoidBeltCount, Population, PrimaryStar, PrimaryStarClass, Sector, Size, StarCount, Starport, Subsector, SurveyIndex, TechLevel ]


{-| The (code, name) shape of a live, server-loaded option list - bases
(Facility), allegiances, sectors and subsectors are all referee-editable
rows in their own tables rather than a fixed enum, so their picker options
are sourced live rather than hardcoded.
-}
type alias Option =
    { code : String, name : String }


{-| The live option lists needed to drive the value picker for every
"sourced from a DB table" field. Threaded through the rule editor alongside
the rule itself.
-}
type alias PickerData =
    { facilities : List Option
    , allegiances : List Option
    , sectors : List Option
    , subsectors : List Option
    }


fieldLabel : Field -> String
fieldLabel field =
    case field of
        Starport ->
            "Starport"

        Size ->
            "Size"

        Atmosphere ->
            "Atmosphere"

        Hydrographics ->
            "Hydrographics"

        Population ->
            "Population"

        Government ->
            "Government"

        LawLevel ->
            "Law Level"

        TechLevel ->
            "Tech Level"

        SurveyIndex ->
            "Survey Index"

        Known ->
            "Known"

        GasGiantCount ->
            "Gas Giants"

        PlanetoidBeltCount ->
            "Planetoid Belts"

        NativeSophont ->
            "Native Sophont"

        ExtinctSophont ->
            "Extinct Sophont"

        Importance ->
            "Importance"

        Bases ->
            "Bases"

        BaseCount ->
            "Base Count"

        StarCount ->
            "Star Count"

        PrimaryStar ->
            "Primary Star"

        PrimaryStarClass ->
            "Primary Star Class"

        Allegiance ->
            "Allegiance"

        Sector ->
            "Sector"

        Subsector ->
            "Subsector"


type Operator
    = Eq
    | Lt
    | Lte
    | Gt
    | Gte
    | Between
    | OneOf
    | Has
    | HasOneOf


operatorLabel : Operator -> String
operatorLabel operator =
    case operator of
        Eq ->
            "is"

        Lt ->
            "less than"

        Lte ->
            "less than or equal to"

        Gt ->
            "greater than"

        Gte ->
            "greater than or equal to"

        Between ->
            "between"

        OneOf ->
            "one of"

        Has ->
            "has"

        HasOneOf ->
            "has one of"


{-| Boolean fields only ever make sense as an equality check; every other
field supports the full comparison set. Bases is list-valued (a system can
have several), so it only supports containment checks, never ordering.
-}
operatorsFor : Field -> List Operator
operatorsFor field =
    case field of
        Known ->
            [ Eq ]

        NativeSophont ->
            [ Eq ]

        ExtinctSophont ->
            [ Eq ]

        Bases ->
            [ Has, HasOneOf ]

        Allegiance ->
            [ Eq, OneOf ]

        Sector ->
            [ Eq, OneOf ]

        Subsector ->
            [ Eq, OneOf ]

        PrimaryStar ->
            [ Eq, OneOf ]

        _ ->
            [ Eq, Lt, Lte, Gt, Gte, Between, OneOf ]


{-| A single condition. `values` holds one entry for Eq/Lt/Lte/Gt/Gte, two for
Between, and any number for OneOf.
-}
type alias Condition =
    { field : Field
    , operator : Operator
    , negate : Bool
    , values : List String
    }


{-| A group of conditions, all of which must match (AND).
-}
type alias Group =
    List Condition


{-| A named, coloured, toggleable rule: any one of its groups matching (OR)
means the rule matches.
-}
type alias Rule =
    { id : String
    , name : String
    , colour : Color
    , enabled : Bool
    , groups : List Group
    }


newCondition : Field -> Condition
newCondition field =
    let
        defaultValue =
            fieldOptions field |> List.head |> Maybe.map .code |> Maybe.withDefault ""
    in
    { field = field, operator = Eq, negate = False, values = [ defaultValue ] }


newRule : String -> Color -> Rule
newRule id colour =
    { id = id
    , name = "New Overlay"
    , colour = colour
    , enabled = True
    , groups = [ [ newCondition Starport ] ]
    }



-- VALUE DOMAINS


{-| The expanded-hex alphabet shared with `app/domain/hex_digit.rb` and
`Traveller.EHex` (digits 0-9 then A-Z, skipping I and O).
-}
alphabet : String
alphabet =
    "0123456789ABCDEFGHJKLMNPQRSTUVWXYZ"


codesUpTo : Int -> List String
codesUpTo maxCode =
    alphabet
        |> String.left (maxCode + 1)
        |> String.toList
        |> List.map String.fromChar


{-| The valid, canonically ordered codes for a field - drives both the
click-only value picker and the ordinal rank used for comparisons.
-}
fieldOptions : Field -> List { code : String, label : String }
fieldOptions field =
    case field of
        Starport ->
            [ "A", "B", "C", "D", "E", "X" ] |> List.map (\c -> { code = c, label = c })

        SurveyIndex ->
            List.range 0 12 |> List.map (\n -> { code = String.fromInt n, label = String.fromInt n })

        Importance ->
            List.range -3 5 |> List.map (\n -> { code = String.fromInt n, label = String.fromInt n })

        Known ->
            [ { code = "true", label = "Yes" }, { code = "false", label = "No" } ]

        Size ->
            codesUpTo 15 |> List.map (\c -> { code = c, label = c })

        Atmosphere ->
            codesUpTo 17 |> List.map (\c -> { code = c, label = c })

        Hydrographics ->
            codesUpTo 10 |> List.map (\c -> { code = c, label = c })

        Population ->
            codesUpTo 12 |> List.map (\c -> { code = c, label = c })

        Government ->
            codesUpTo 15 |> List.map (\c -> { code = c, label = c })

        LawLevel ->
            codesUpTo 18 |> List.map (\c -> { code = c, label = c })

        TechLevel ->
            codesUpTo 16 |> List.map (\c -> { code = c, label = c })

        GasGiantCount ->
            List.range 0 10 |> List.map (\n -> { code = String.fromInt n, label = String.fromInt n })

        PlanetoidBeltCount ->
            List.range 0 10 |> List.map (\n -> { code = String.fromInt n, label = String.fromInt n })

        NativeSophont ->
            [ { code = "true", label = "Yes" }, { code = "false", label = "No" } ]

        ExtinctSophont ->
            [ { code = "true", label = "Yes" }, { code = "false", label = "No" } ]

        BaseCount ->
            List.range 0 10 |> List.map (\n -> { code = String.fromInt n, label = String.fromInt n })

        StarCount ->
            List.range 1 8 |> List.map (\n -> { code = String.fromInt n, label = String.fromInt n })

        PrimaryStar ->
            ([ "O", "B", "A", "F", "G", "K", "M" ] |> List.map (\c -> { code = c, label = c }))
                ++ [ { code = "L", label = "L Dwarf" }, { code = "T", label = "T Dwarf" }, { code = "Y", label = "Y Dwarf" } ]
                ++ [ { code = "BD", label = "Brown Dwarf" }
                   , { code = "D", label = "White Dwarf" }
                   , { code = "BH", label = "Black Hole" }
                   , { code = "PSR", label = "Pulsar" }
                   , { code = "NS", label = "Neutron Star" }
                   , { code = "NB", label = "Nebula" }
                   , { code = "PS", label = "Protostar" }
                   , { code = "AN", label = "Anomaly" }
                   ]

        PrimaryStarClass ->
            [ { code = "0", label = "0 (Hypergiant)" }
            , { code = "Ia", label = "Ia (Luminous supergiant)" }
            , { code = "Iab", label = "Iab (Intermediate supergiant)" }
            , { code = "Ib", label = "Ib (Less luminous supergiant)" }
            , { code = "II", label = "II (Bright giant)" }
            , { code = "III", label = "III (Giant)" }
            , { code = "IV", label = "IV (Subgiant)" }
            , { code = "V", label = "V (Main sequence)" }
            , { code = "VI", label = "VI (Subdwarf)" }
            , { code = "VII", label = "VII (White dwarf)" }
            ]

        Bases ->
            []

        Allegiance ->
            []

        Sector ->
            []

        Subsector ->
            []


{-| The ordinal rank used by the comparison operators, e.g. `<`/`between`.
For most fields this is just the option's position in `fieldOptions` (which
is already in ascending order). Starport quality runs the other way - A is
the best starport, X the worst - so its rank is the reversed position, making
"Starport greater than C" match A and B rather than D, E, X.
-}
fieldRank : Field -> String -> Maybe Int
fieldRank field code =
    let
        indexed =
            fieldOptions field
                |> List.indexedMap (\i opt -> ( i, opt.code ))

        count =
            List.length indexed

        indexOf =
            indexed
                |> List.filter (\( _, c ) -> c == code)
                |> List.head
                |> Maybe.map Tuple.first
    in
    case field of
        Starport ->
            indexOf |> Maybe.map (\i -> count - 1 - i)

        _ ->
            indexOf



-- PARSING THE RAW UWP STRING


{-| The main-world UWP string (e.g. "A788899-C") sliced into its named
components. Positions match `HasUwp#sync_uwp`:
starport, size, atmosphere, hydrographics, population, government, law level, '-', tech level.
-}
type alias UwpFields =
    { starport : String
    , size : String
    , atmosphere : String
    , hydrographics : String
    , population : String
    , government : String
    , lawLevel : String
    , techLevel : String
    }


parseUwp : String -> Maybe UwpFields
parseUwp raw =
    if String.length raw < 9 then
        Nothing

    else
        Just
            { starport = String.slice 0 1 raw
            , size = String.slice 1 2 raw
            , atmosphere = String.slice 2 3 raw
            , hydrographics = String.slice 3 4 raw
            , population = String.slice 4 5 raw
            , government = String.slice 5 6 raw
            , lawLevel = String.slice 6 7 raw
            , techLevel = String.slice 8 9 raw
            }


uwpFieldAccessor : Field -> UwpFields -> Maybe String
uwpFieldAccessor field fields =
    case field of
        Starport ->
            Just fields.starport

        Size ->
            Just fields.size

        Atmosphere ->
            Just fields.atmosphere

        Hydrographics ->
            Just fields.hydrographics

        Population ->
            Just fields.population

        Government ->
            Just fields.government

        LawLevel ->
            Just fields.lawLevel

        TechLevel ->
            Just fields.techLevel

        SurveyIndex ->
            Nothing

        Known ->
            Nothing

        GasGiantCount ->
            Nothing

        PlanetoidBeltCount ->
            Nothing

        NativeSophont ->
            Nothing

        ExtinctSophont ->
            Nothing

        Importance ->
            Nothing

        Bases ->
            Nothing

        BaseCount ->
            Nothing

        StarCount ->
            Nothing

        PrimaryStar ->
            Nothing

        PrimaryStarClass ->
            Nothing

        Allegiance ->
            Nothing

        Sector ->
            Nothing

        Subsector ->
            Nothing


getFieldValue : Field -> StarSystem -> Maybe String
getFieldValue field system =
    case field of
        Known ->
            Just
                (if system.known then
                    "true"

                 else
                    "false"
                )

        SurveyIndex ->
            Just (String.fromInt system.surveyIndex)

        Importance ->
            Maybe.map String.fromInt system.importance

        BaseCount ->
            Just (String.fromInt (List.length system.baseCodes))

        StarCount ->
            let
                starData =
                    List.map getStarTypeData system.stars

                companionCount =
                    starData |> List.filter (\s -> s.companion /= Nothing) |> List.length
            in
            Just (String.fromInt (List.length starData + companionCount))

        PrimaryStar ->
            primaryStarData system |> Maybe.map .stellarType

        PrimaryStarClass ->
            primaryStarData system |> Maybe.map .stellarClass

        Bases ->
            Nothing

        GasGiantCount ->
            Just (String.fromInt system.gasGiantCount)

        PlanetoidBeltCount ->
            Just (String.fromInt system.planetoidBeltCount)

        NativeSophont ->
            Just
                (if system.nativeSophont then
                    "true"

                 else
                    "false"
                )

        ExtinctSophont ->
            Just
                (if system.extinctSophont then
                    "true"

                 else
                    "false"
                )

        Allegiance ->
            system.allegiance

        Sector ->
            Just (String.fromInt system.sectorId)

        Subsector ->
            Maybe.map String.fromInt system.subsectorId

        _ ->
            system.mainWorldUwp
                |> Maybe.andThen parseUwp
                |> Maybe.andThen (uwpFieldAccessor field)


{-| The primary star is the one entry in `system.stars` (the top-level
list — tight-binary partners are nested inside `.companion` instead) that
doesn't orbit anything. `Api::StarMapController#build_star_hash` encodes
that as `au = 0` (its real `au` is `nil`, since it has no orbit).
-}
primaryStarData : StarSystem -> Maybe StarTypeData
primaryStarData system =
    system.stars
        |> List.map getStarTypeData
        |> List.filter (\s -> s.au == 0)
        |> List.head



-- EVALUATION


conditionMatches : StarSystem -> Condition -> Bool
conditionMatches system condition =
    let
        result =
            case condition.field of
                Bases ->
                    case ( condition.operator, condition.values ) of
                        ( Has, target :: _ ) ->
                            List.member target system.baseCodes

                        ( HasOneOf, targets ) ->
                            List.any (\t -> List.member t system.baseCodes) targets

                        _ ->
                            False

                _ ->
                    case getFieldValue condition.field system of
                        Nothing ->
                            False

                        Just code ->
                            case ( condition.operator, condition.values ) of
                                ( Eq, target :: _ ) ->
                                    code == target

                                ( OneOf, targets ) ->
                                    List.member code targets

                                ( Lt, target :: _ ) ->
                                    compareRank condition.field code target (<)

                                ( Lte, target :: _ ) ->
                                    compareRank condition.field code target (<=)

                                ( Gt, target :: _ ) ->
                                    compareRank condition.field code target (>)

                                ( Gte, target :: _ ) ->
                                    compareRank condition.field code target (>=)

                                ( Between, [ lo, hi ] ) ->
                                    compareBetween condition.field code lo hi

                                _ ->
                                    False
    in
    if condition.negate then
        not result

    else
        result


compareRank : Field -> String -> String -> (Int -> Int -> Bool) -> Bool
compareRank field code target op =
    Maybe.map2 op (fieldRank field code) (fieldRank field target)
        |> Maybe.withDefault False


compareBetween : Field -> String -> String -> String -> Bool
compareBetween field code lo hi =
    Maybe.map3
        (\c a b ->
            let
                ( low, high ) =
                    ( min a b, max a b )
            in
            c >= low && c <= high
        )
        (fieldRank field code)
        (fieldRank field lo)
        (fieldRank field hi)
        |> Maybe.withDefault False


{-| A rule matches a system if any one of its groups has every condition matching.
-}
evaluate : Rule -> StarSystem -> Bool
evaluate rule system =
    rule.groups
        |> List.any (List.all (conditionMatches system))


{-| The colour of the first enabled, matching rule (in list order), if any.
-}
matchColour : List Rule -> Maybe StarSystem -> Maybe Color
matchColour rules maybeSystem =
    case maybeSystem of
        Nothing ->
            Nothing

        Just system ->
            rules
                |> List.filter .enabled
                |> List.filter (\rule -> evaluate rule system)
                |> List.head
                |> Maybe.map .colour



-- CODECS


fieldToString : Field -> String
fieldToString field =
    case field of
        Starport ->
            "starport"

        Size ->
            "size"

        Atmosphere ->
            "atmosphere"

        Hydrographics ->
            "hydrographics"

        Population ->
            "population"

        Government ->
            "government"

        LawLevel ->
            "law_level"

        TechLevel ->
            "tech_level"

        SurveyIndex ->
            "survey_index"

        Known ->
            "known"

        GasGiantCount ->
            "gas_giant_count"

        PlanetoidBeltCount ->
            "planetoid_belt_count"

        NativeSophont ->
            "native_sophont"

        ExtinctSophont ->
            "extinct_sophont"

        Importance ->
            "importance"

        Bases ->
            "bases"

        BaseCount ->
            "base_count"

        StarCount ->
            "star_count"

        PrimaryStar ->
            "primary_star"

        PrimaryStarClass ->
            "primary_star_class"

        Allegiance ->
            "allegiance"

        Sector ->
            "sector"

        Subsector ->
            "subsector"


fieldFromString : String -> Maybe Field
fieldFromString s =
    case s of
        "starport" ->
            Just Starport

        "size" ->
            Just Size

        "atmosphere" ->
            Just Atmosphere

        "hydrographics" ->
            Just Hydrographics

        "population" ->
            Just Population

        "government" ->
            Just Government

        "law_level" ->
            Just LawLevel

        "tech_level" ->
            Just TechLevel

        "survey_index" ->
            Just SurveyIndex

        "known" ->
            Just Known

        "gas_giant_count" ->
            Just GasGiantCount

        "planetoid_belt_count" ->
            Just PlanetoidBeltCount

        "native_sophont" ->
            Just NativeSophont

        "extinct_sophont" ->
            Just ExtinctSophont

        "importance" ->
            Just Importance

        "bases" ->
            Just Bases

        "base_count" ->
            Just BaseCount

        "star_count" ->
            Just StarCount

        "primary_star" ->
            Just PrimaryStar

        "primary_star_class" ->
            Just PrimaryStarClass

        "allegiance" ->
            Just Allegiance

        "sector" ->
            Just Sector

        "subsector" ->
            Just Subsector

        _ ->
            Nothing


fieldCodec : Codec Field
fieldCodec =
    Codec.string
        |> Codec.andThen
            (\s ->
                case fieldFromString s of
                    Just field ->
                        Codec.succeed field

                    Nothing ->
                        Codec.fail ("Unknown highlight rule field: " ++ s)
            )
            fieldToString


operatorToString : Operator -> String
operatorToString operator =
    case operator of
        Eq ->
            "eq"

        Lt ->
            "lt"

        Lte ->
            "lte"

        Gt ->
            "gt"

        Gte ->
            "gte"

        Between ->
            "between"

        OneOf ->
            "one_of"

        Has ->
            "has"

        HasOneOf ->
            "has_one_of"


operatorFromString : String -> Maybe Operator
operatorFromString s =
    case s of
        "eq" ->
            Just Eq

        "lt" ->
            Just Lt

        "lte" ->
            Just Lte

        "gt" ->
            Just Gt

        "gte" ->
            Just Gte

        "between" ->
            Just Between

        "one_of" ->
            Just OneOf

        "has" ->
            Just Has

        "has_one_of" ->
            Just HasOneOf

        _ ->
            Nothing


operatorCodec : Codec Operator
operatorCodec =
    Codec.string
        |> Codec.andThen
            (\s ->
                case operatorFromString s of
                    Just operator ->
                        Codec.succeed operator

                    Nothing ->
                        Codec.fail ("Unknown highlight rule operator: " ++ s)
            )
            operatorToString


conditionCodec : Codec Condition
conditionCodec =
    Codec.object Condition
        |> Codec.field "field" .field fieldCodec
        |> Codec.field "operator" .operator operatorCodec
        |> Codec.field "negate" .negate Codec.bool
        |> Codec.field "values" .values (Codec.list Codec.string)
        |> Codec.buildObject


groupCodec : Codec Group
groupCodec =
    Codec.list conditionCodec


ruleCodec : Codec Rule
ruleCodec =
    Codec.object Rule
        |> Codec.field "id" .id Codec.string
        |> Codec.field "name" .name Codec.string
        |> Codec.field "colour" .colour codecColour
        |> Codec.field "enabled" .enabled Codec.bool
        |> Codec.field "groups" .groups (Codec.list groupCodec)
        |> Codec.buildObject


rulesCodec : Codec (List Rule)
rulesCodec =
    Codec.list ruleCodec



-- API ENCODING/DECODING
--
-- `Api::SurveyOverlaysController` serializes/accepts `SurveyOverlay` rows as
-- `{ id, name, colour, enabled, rule_data, position }`, distinct from
-- `ruleCodec`'s shape (integer id rather than string, groups nested under
-- `rule_data` rather than top-level, no `position`). The server already
-- orders by `position`, so it isn't decoded here; `id`/`position` are never
-- sent back on write, since referee overlays are only ever created/updated
-- via their own dedicated request (id in the URL, not the body).


apiRulesDecoder : JsDecode.Decoder (List Rule)
apiRulesDecoder =
    JsDecode.list apiRuleDecoder


apiRuleDecoder : JsDecode.Decoder Rule
apiRuleDecoder =
    JsDecode.map5
        (\id name colour enabled groups ->
            { id = id, name = name, colour = colour, enabled = enabled, groups = groups }
        )
        (JsDecode.field "id" JsDecode.int |> JsDecode.map String.fromInt)
        (JsDecode.field "name" JsDecode.string)
        (JsDecode.field "colour" (Codec.decoder codecColour))
        (JsDecode.field "enabled" JsDecode.bool)
        (JsDecode.maybe (JsDecode.at [ "rule_data", "groups" ] (JsDecode.list (Codec.decoder groupCodec)))
            |> JsDecode.map (Maybe.withDefault [])
        )


{-| The JSON body for a create/update request against
`Api::SurveyOverlaysController` - see the comment above for why `id` and
`position` are omitted.
-}
apiRuleEncodeBody : Rule -> Encode.Value
apiRuleEncodeBody rule =
    Encode.object
        [ ( "name", Encode.string rule.name )
        , ( "colour", Codec.encoder codecColour rule.colour )
        , ( "enabled", Encode.bool rule.enabled )
        , ( "rule_data", Encode.object [ ( "groups", Encode.list groupEncodeValue rule.groups ) ] )
        ]


groupEncodeValue : Group -> Encode.Value
groupEncodeValue group =
    Encode.list (Codec.encoder conditionCodec) group
