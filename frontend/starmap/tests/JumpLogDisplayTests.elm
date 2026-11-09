module JumpLogDisplayTests exposing (..)

import Codec
import Expect
import Json.Decode as Decode
import Test exposing (Test, describe, test)
import Traveller.JumpLogDisplay as JumpLogDisplay exposing (Mode(..))


campaign : JumpLogDisplay.Settings
campaign =
    { mode = Both
    , fillColour = "#111111"
    , lineColour = "#222222"
    , lineStyle = "dashed"
    , lineWidth = 6
    }


suite : Test
suite =
    describe "JumpLogDisplay"
        [ describe "resolve"
            [ test "an empty override yields the campaign settings" <|
                \_ ->
                    JumpLogDisplay.resolve campaign JumpLogDisplay.emptyOverride
                        |> Expect.equal campaign
            , test "personal values win field by field" <|
                \_ ->
                    JumpLogDisplay.resolve campaign
                        { mode = Just Off
                        , fillColour = Nothing
                        , lineColour = Just "#abcdef"
                        , lineStyle = Nothing
                        , lineWidth = Just 2
                        }
                        |> Expect.equal
                            { mode = Off
                            , fillColour = "#111111"
                            , lineColour = "#abcdef"
                            , lineStyle = "dashed"
                            , lineWidth = 2
                            }
            ]
        , describe "modes"
            [ test "fill and both draw fills" <|
                \_ ->
                    List.map (\m -> JumpLogDisplay.showsFill { campaign | mode = m }) [ Fill, Line, Both, Off ]
                        |> Expect.equal [ True, False, True, False ]
            , test "line and both draw lines" <|
                \_ ->
                    List.map (\m -> JumpLogDisplay.showsLine { campaign | mode = m }) [ Fill, Line, Both, Off ]
                        |> Expect.equal [ False, True, True, False ]
            , test "mode strings round trip, matching the Rails values" <|
                \_ ->
                    [ Fill, Line, Both, Off ]
                        |> List.map (JumpLogDisplay.modeToString >> JumpLogDisplay.modeFromString)
                        |> Expect.equal [ Just Fill, Just Line, Just Both, Just Off ]
            , test "unknown mode strings are rejected" <|
                \_ -> JumpLogDisplay.modeFromString "bogus" |> Expect.equal Nothing
            ]
        , describe "codecs"
            [ test "override round trips" <|
                \_ ->
                    let
                        override =
                            { mode = Just Line
                            , fillColour = Nothing
                            , lineColour = Just "#123456"
                            , lineStyle = Just "dotted"
                            , lineWidth = Just 3
                            }
                    in
                    Codec.encodeToValue JumpLogDisplay.overrideCodec override
                        |> Codec.decodeValue JumpLogDisplay.overrideCodec
                        |> Expect.equal (Ok override)
            , test "campaign settings decode from the Rails flag" <|
                \_ ->
                    Decode.decodeString
                        (Codec.decoder JumpLogDisplay.campaignCodec)
                        """{"display":"both","fillColour":"#111111","lineColour":"#222222","lineStyle":"dashed","lineWidth":6,"lineDasharray":"16,10"}"""
                        |> Expect.equal (Ok campaign)
            ]
        , describe "dasharrayFor"
            [ test "solid has none" <|
                \_ -> JumpLogDisplay.dasharrayFor "solid" |> Expect.equal Nothing
            , test "matches the Rails table" <|
                \_ ->
                    List.map JumpLogDisplay.dasharrayFor [ "dashed", "dotted", "dash_dot", "dash_dot_dot", "long_dash", "short_dash" ]
                        |> Expect.equal
                            [ Just "16,10", Just "3,7", Just "16,7,3,7", Just "16,7,3,7,3,7", Just "28,10", Just "8,7" ]
            ]
        ]
