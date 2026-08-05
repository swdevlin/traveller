module RulebookSearchTests exposing (..)

import Codec
import Expect
import Json.Decode as Decode
import Test exposing (Test, describe)
import Traveller.RulebookSearch as RulebookSearch


groupJson : String
groupJson =
    """
    [
      {
        "rulebook_id": 8,
        "title": "Core Rulebook",
        "short_title": "core",
        "edition": "2nd",
        "category": "rulebook",
        "total_matches": 1,
        "hits": [
          {
            "printed_page_label": "42",
            "rank": 0.9371,
            "heading_segments": [
              { "text": "Starships", "highlighted": false }
            ],
            "excerpt_segments": [
              { "text": "Every starship requires a ", "highlighted": false },
              { "text": "jump", "highlighted": true },
              { "text": " drive.", "highlighted": false }
            ]
          }
        ]
      }
    ]
    """


groupJsonWithNulls : String
groupJsonWithNulls =
    """
    [
      {
        "rulebook_id": 9,
        "title": "Unnamed Sourcebook",
        "short_title": null,
        "edition": null,
        "category": "supplement",
        "total_matches": 2,
        "hits": []
      }
    ]
    """


groupCodecTests : Test
groupCodecTests =
    describe "RulebookSearch.groupCodec"
        [ Test.test "decodes a group with hits and highlighted excerpt segments" <|
            \_ ->
                case Codec.decodeString (Codec.list RulebookSearch.groupCodec) groupJson of
                    Ok groups ->
                        case groups of
                            [ group ] ->
                                Expect.all
                                    [ \g -> Expect.equal 8 g.rulebookId
                                    , \g -> Expect.equal "Core Rulebook" g.title
                                    , \g -> Expect.equal (Just "core") g.shortTitle
                                    , \g -> Expect.equal (Just "2nd") g.edition
                                    , \g -> Expect.equal "rulebook" g.category
                                    , \g -> Expect.equal 1 g.totalMatches
                                    , \g -> Expect.equal 1 (List.length g.hits)
                                    , \g ->
                                        case g.hits of
                                            [ hit ] ->
                                                Expect.equal "42" hit.printedPageLabel

                                            _ ->
                                                Expect.fail "expected exactly one hit"
                                    , \g ->
                                        case g.hits of
                                            [ hit ] ->
                                                Expect.equal
                                                    [ False, True, False ]
                                                    (List.map .highlighted hit.excerptSegments)

                                            _ ->
                                                Expect.fail "expected exactly one hit"
                                    , \g ->
                                        case g.hits of
                                            [ hit ] ->
                                                Expect.equal [ "Starships" ] (List.map .text hit.headingSegments)

                                            _ ->
                                                Expect.fail "expected exactly one hit"
                                    ]
                                    group

                            _ ->
                                Expect.fail "expected exactly one group"

                    Err err ->
                        Expect.fail (Decode.errorToString err)
        , Test.test "decodes null short_title/edition and an empty hits list" <|
            \_ ->
                case Codec.decodeString (Codec.list RulebookSearch.groupCodec) groupJsonWithNulls of
                    Ok groups ->
                        case groups of
                            [ group ] ->
                                Expect.all
                                    [ \g -> Expect.equal Nothing g.shortTitle
                                    , \g -> Expect.equal Nothing g.edition
                                    , \g -> Expect.equal [] g.hits
                                    ]
                                    group

                            _ ->
                                Expect.fail "expected exactly one group"

                    Err err ->
                        Expect.fail (Decode.errorToString err)
        ]