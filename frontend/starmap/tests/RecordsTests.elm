module RecordsTests exposing (suite)

import Codec
import Expect
import Json.Decode as Decode
import Test exposing (Test, describe, test)
import Traveller.StellarObject exposing (StellarObject(..), codecStellarObject)


gasGiantJson : String -> String
gasGiantJson extra =
    """
    { "orbit_type": 10, "orbit_position": { "x": 0.0, "y": 0.0 }, "inclination": 0.0, "eccentricity": 0.0,
      "periapsis": 1.0, "apoapsis": 1.0, "effective_hzco_deviation": 0.0, "code": "GM", "diameter": 100000.0,
      "orbit": 5.0, "moons": [], "axial_tilt": 0.0, "period": 100.0, "orbit_sequence": "A1",
      "jump_shadow": null, "au": 5.0, "id": 7
      """ ++ extra ++ " }"


decodeRecords : String -> Maybe { surveyHtml : Maybe String, classifiedHtml : Maybe String }
decodeRecords json =
    case Decode.decodeString (Codec.decoder codecStellarObject) json of
        Ok (GasGiant data) ->
            Just data.records

        _ ->
            Nothing


suite : Test
suite =
    describe "survey and classified records"
        [ test "the referee payload carries both" <|
            \_ ->
                gasGiantJson """, "survey_records_html": "<p>Seen</p>", "classified_records_html": "<p>Secret</p>" """
                    |> decodeRecords
                    |> Expect.equal (Just { surveyHtml = Just "<p>Seen</p>", classifiedHtml = Just "<p>Secret</p>" })
        , test "the player payload omits the classified records" <|
            \_ ->
                gasGiantJson """, "survey_records_html": "<p>Seen</p>" """
                    |> decodeRecords
                    |> Expect.equal (Just { surveyHtml = Just "<p>Seen</p>", classifiedHtml = Nothing })
        , test "a body without records decodes with none" <|
            \_ ->
                gasGiantJson ""
                    |> decodeRecords
                    |> Expect.equal (Just { surveyHtml = Nothing, classifiedHtml = Nothing })
        ]
