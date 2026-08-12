module UwpBreakdownTests exposing (suite)

import Dict
import Expect
import Parser
import Test exposing (Test, describe, test)
import Traveller exposing (uwpBreakdown)
import Traveller.Parser exposing (uwp)


breakdown : String -> Dict.Dict String String
breakdown uwpString =
    case Parser.run uwp uwpString of
        Ok parsed ->
            Dict.fromList (uwpBreakdown parsed)

        Err _ ->
            Dict.empty


field : String -> String -> String
field key uwpString =
    breakdown uwpString
        |> Dict.get key
        |> Maybe.withDefault "MISSING"


suite : Test
suite =
    describe "uwpBreakdown"
        [ test "population 0 and government 0 abbreviates Government" <|
            \_ -> Expect.equal "—" (field "Government" "A000000-0")
        , test "population 0 but government > 0 shows the real value" <|
            \_ -> Expect.equal "Company/Corporation" (field "Government" "A000010-0")
        , test "population 0 and law level 0 abbreviates Law level" <|
            \_ -> Expect.equal "—" (field "Law level" "A000000-0")
        , test "population 0 but law level > 0 shows the real value" <|
            \_ -> Expect.equal "Portable Energy Weapons" (field "Law level" "A000001-0")
        , test "population 0 and tech level 0 abbreviates Tech level" <|
            \_ -> Expect.equal "—" (field "Tech level" "A000000-0")
        , test "population 0 but tech level > 0 shows the real value" <|
            \_ -> Expect.equal "Metal Age" (field "Tech level" "A000000-1")
        , test "population > 0 always shows the real government value, even when its code is 0" <|
            \_ -> Expect.equal "No Government Structure" (field "Government" "A000500-0")
        ]
