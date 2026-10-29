module RecordsTests exposing (suite)

import Codec
import Expect
import Html.Attributes as HtmlAttrs
import Json.Decode as Decode
import Test exposing (Test, describe, test)
import Test.Html.Query as Query
import Test.Html.Selector as Selector
import Traveller.Records as Records
import Traveller.StellarObject exposing (StellarObject(..), codecStellarObject, moonsPageDecoder)


gasGiantJson : String -> String
gasGiantJson extra =
    """
    { "orbit_type": 10, "orbit_position": { "x": 0.0, "y": 0.0 }, "inclination": 0.0, "eccentricity": 0.0,
      "periapsis": 1.0, "apoapsis": 1.0, "effective_hzco_deviation": 0.0, "code": "GM", "diameter": 100000.0,
      "orbit": 5.0, "moons": [], "axial_tilt": 0.0, "period": 100.0, "orbit_sequence": "A1",
      "jump_shadow": null, "au": 5.0, "id": 7
      """ ++ extra ++ " }"


decodeRecords : String -> Maybe Records.Records
decodeRecords json =
    case Decode.decodeString (Codec.decoder codecStellarObject) json of
        Ok (GasGiant data) ->
            Just data.records

        _ ->
            Nothing


suite : Test
suite =
    describe "survey and classified records"
        [ test "body tags decode and render as text" <|
            \_ ->
                gasGiantJson """, "tags": ["Research", "<script>"] """
                    |> decodeRecords
                    |> Maybe.withDefault Records.empty
                    |> Records.viewTags
                    |> Query.fromHtml
                    |> Query.has [ Selector.text "<script>" ]
        , test "tag links encode the name for the campaign tag page" <|
            \_ ->
                Records.empty
                    |> Records.withTags (Just [ "Research / A&B" ])
                    |> Records.viewTags
                    |> Query.fromHtml
                    |> Query.find [ Selector.tag "a" ]
                    |> Query.has [ Selector.attribute (HtmlAttrs.href "tags/show?name=Research%20%2F%20A%26B"), Selector.attribute (HtmlAttrs.target "_self") ]
        , test "players never render tag badges in records" <|
            \_ ->
                Records.empty
                    |> Records.withTags (Just [ "Private tag" ])
                    |> Records.viewForReferee False
                    |> Query.fromHtml
                    |> Query.hasNot [ Selector.text "Private tag" ]
        , test "starmap tag editors use a live frame for the matching record" <|
            \_ ->
                Records.viewEditor "StellarObject" 42 "analysis"
                    |> Query.fromHtml
                    |> Query.has
                        [ Selector.attribute (HtmlAttrs.id "starmap_tags_StellarObject_42_analysis")
                        , Selector.attribute (HtmlAttrs.attribute "src" "object_tags?record_type=StellarObject&record_id=42&tag_context=analysis")
                        ]
        , test "the referee payload carries both" <|
            \_ ->
                gasGiantJson """, "survey_records_html": "<p>Seen</p>", "classified_records_html": "<p>Secret</p>" """
                    |> decodeRecords
                    |> Expect.equal (Just { tags = [], surveyHtml = Just "<p>Seen</p>", classifiedHtml = Just "<p>Secret</p>" })
        , test "the player payload omits the classified records" <|
            \_ ->
                gasGiantJson """, "survey_records_html": "<p>Seen</p>" """
                    |> decodeRecords
                    |> Expect.equal (Just { tags = [], surveyHtml = Just "<p>Seen</p>", classifiedHtml = Nothing })
        , test "a body without records decodes with none" <|
            \_ ->
                gasGiantJson ""
                    |> decodeRecords
                    |> Expect.equal (Just { tags = [], surveyHtml = Nothing, classifiedHtml = Nothing })
        , test "referee sees the empty classified section" <|
            \_ ->
                Records.viewForReferee True Records.empty
                    |> Query.fromHtml
                    |> Query.has [ Selector.text "Classified Records" ]
        , test "player does not see the empty classified section" <|
            \_ ->
                Records.viewForReferee False Records.empty
                    |> Query.fromHtml
                    |> Query.hasNot [ Selector.text "Classified Records" ]
        , test "classified HTML reaches the rendered notes" <|
            \_ ->
                Records.fromHtml Nothing (Just "<p>Secret</p>")
                    |> Records.viewForReferee True
                    |> Query.fromHtml
                    |> Query.find [ Selector.tag "html-content" ]
                    |> Query.has [ Selector.attribute (HtmlAttrs.attribute "html" "<p>Secret</p>") ]
        , test "moons page decodes the parent diameter for kilometre distances" <|
            \_ ->
                Decode.decodeString moonsPageDecoder """{"moons":[],"rings":[],"count":0,"page":1,"pages":1,"parent_diameter_km":120000}"""
                    |> Result.map .parentDiameterKm
                    |> Expect.equal (Ok (Just 120000))
        , test "older moons payloads do not invent a diameter" <|
            \_ ->
                Decode.decodeString moonsPageDecoder """{"moons":[],"count":0,"page":1,"pages":1}"""
                    |> Result.map .parentDiameterKm
                    |> Expect.equal (Ok Nothing)
        ]
