module TradeSynergyTests exposing (..)

import Expect
import Json.Decode as Decode
import Test exposing (Test, describe, test)
import Traveller.TradeSynergy as TradeSynergy


sampleJson : String
sampleJson =
    """
    {
      "jump": 2,
      "origin": {
        "id": 1, "name": "Alpha", "hex": "0101", "sector": "Spinward", "origin_x": 0, "origin_y": 0,
        "uwp": "A788899-C", "wtn": 4.5, "starport": "A", "gas_giant": true, "travel_zone": null, "trade_codes": ["In"]
      },
      "partners": [
        {
          "id": 2, "name": null, "hex": "0102", "sector": "Spinward", "origin_x": 1, "origin_y": 0,
          "uwp": null, "wtn": null, "starport": "C", "gas_giant": false, "travel_zone": "A", "trade_codes": ["Ni"],
          "distance": 1, "outbound_count": 1, "outbound_bonus": 8, "inbound_count": 0, "inbound_bonus": 0,
          "outbound_goods": [ { "d66": 12, "name": "Common Industrial Goods", "category": "common", "buy_dm": 5, "sell_dm": 3, "bonus": 8 } ],
          "inbound_goods": []
        }
      ]
    }
    """


suite : Test
suite =
    describe "TradeSynergy"
        [ test "decodes the API response" <|
            \_ ->
                case Decode.decodeString TradeSynergy.tradeSynergiesDecoder sampleJson of
                    Ok data ->
                        Expect.all
                            [ \d -> Expect.equal 2 d.jump
                            , \d -> Expect.equal True d.origin.gasGiant
                            , \d -> Expect.equal [ "Nothing" ] (List.map (\p -> Maybe.withDefault "Nothing" p.system.name) d.partners)
                            , \d -> Expect.equal [ Just "A" ] (List.map (.system >> .travelZone) d.partners)
                            , \d -> Expect.equal [ 8 ] (List.map .outboundBonus d.partners)
                            , \d -> Expect.equal [ [ 12 ] ] (List.map (.outboundGoods >> List.map .d66) d.partners)
                            ]
                            data

                    Err err ->
                        Expect.fail (Decode.errorToString err)
        , describe "hexDistance"
            [ test "is zero for the same hex" <|
                \_ -> Expect.equal 0 (TradeSynergy.hexDistance ( 5, 7 ) ( 5, 7 ))
            , test "adjacent hexes are one apart (even column)" <|
                \_ ->
                    -- Mirrors HexDistance#neighbours for an even column.
                    [ ( 1, 0 ), ( 0, -1 ), ( -1, 0 ), ( -1, 1 ), ( 0, 1 ), ( 1, 1 ) ]
                        |> List.map (\n -> TradeSynergy.hexDistance ( 0, 0 ) n)
                        |> Expect.equal [ 1, 1, 1, 1, 1, 1 ]
            , test "adjacent hexes are one apart (odd column, negative coordinates)" <|
                \_ ->
                    [ ( 0, -1 ), ( -1, -1 ), ( -2, -1 ), ( -2, 0 ), ( -1, 1 ), ( 0, 0 ) ]
                        |> List.map (\n -> TradeSynergy.hexDistance ( -1, 0 ) n)
                        |> Expect.equal [ 1, 1, 1, 1, 1, 1 ]
            ]
        , describe "cellsWithin"
            [ test "radius 1 is the origin and its six neighbours" <|
                \_ -> Expect.equal 7 (List.length (TradeSynergy.cellsWithin 1 ( 3, 3 )))
            , test "radius 2 has 19 cells" <|
                \_ -> Expect.equal 19 (List.length (TradeSynergy.cellsWithin 2 ( 3, 3 )))
            , test "radius 6 has 127 cells" <|
                \_ -> Expect.equal 127 (List.length (TradeSynergy.cellsWithin 6 ( -4, 9 )))
            ]
        ]
