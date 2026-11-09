module JumpLogTests exposing (suite)

import Expect
import Json.Decode as Decode
import Test exposing (Test, describe, test)
import Traveller.JumpLog as JumpLog


jumpJson : String
jumpJson =
    """
    { "id": 7, "sequence": 3, "ship_id": 1, "ship_name": "Deep Night",
      "depart_year": 1105, "depart_day": 100, "arrive_year": 1105, "arrive_day": 107,
      "from_parsec_id": 10, "from_sector_name": "Spinward Marches", "from_hex_code": "0101",
      "to_parsec_id": 11, "to_sector_name": "Spinward Marches", "to_hex_code": "0202",
      "misjump": true }
    """


{-| Ship 1 has three consecutive jumps (ids 1 to 3); ship 2 has one.
-}
chain : List JumpLog.JumpLog
chain =
    [ chainJump 1 1 1 1 8
    , chainJump 2 1 8 8 15
    , chainJump 3 1 15 15 22
    , chainJump 4 2 1 1 3
    ]


chainJump : Int -> Int -> Int -> Int -> Int -> JumpLog.JumpLog
chainJump id shipId departDay _ arriveDay =
    { id = id
    , sequence = id
    , shipId = shipId
    , shipName = "Ship"
    , departYear = 1105
    , departDay = departDay
    , arriveYear = 1105
    , arriveDay = arriveDay
    , fromParsecId = 1
    , fromSectorName = "S"
    , fromHex = "0101"
    , toParsecId = 2
    , toSectorName = "S"
    , toHex = "0202"
    , misjump = False
    , notes = ""
    }


suite : Test
suite =
    describe "JumpLog"
        [ describe "formatDate"
            [ test "pads the day to three digits" <|
                \_ -> JumpLog.formatDate 1105 7 |> Expect.equal "1105.007"
            , test "leaves a three digit day alone" <|
                \_ -> JumpLog.formatDate 1105 365 |> Expect.equal "1105.365"
            ]
        , describe "addDays"
            [ test "adds within the year" <|
                \_ -> JumpLog.addDays 7 ( 1105, 100 ) |> Expect.equal ( 1105, 107 )
            , test "reaches day 365 without rolling over" <|
                \_ -> JumpLog.addDays 7 ( 1105, 358 ) |> Expect.equal ( 1105, 365 )
            , test "rolls over into the next year" <|
                \_ -> JumpLog.addDays 7 ( 1105, 360 ) |> Expect.equal ( 1106, 2 )
            ]
        , describe "hexDistance"
            [ test "is zero for the same hex" <|
                \_ -> JumpLog.hexDistance ( 5, 5 ) ( 5, 5 ) |> Expect.equal 0
            , test "adjacent hexes are one apart" <|
                \_ -> JumpLog.hexDistance ( 2, 2 ) ( 3, 2 ) |> Expect.equal 1
            , test "four hexes along a column" <|
                \_ -> JumpLog.hexDistance ( 2, 2 ) ( 2, 6 ) |> Expect.equal 4
            , test "floors for negative columns like the Rails implementation" <|
                \_ -> JumpLog.hexDistance ( -1, 0 ) ( 0, 0 ) |> Expect.equal 1
            ]
        , describe "sectorInRange"
            [ test "the sector holding the origin is always in range" <|
                \_ ->
                    JumpLog.sectorInRange 2 ( -100, -60 ) { id = 1, name = "Spinward Marches", x = -4, y = -1 }
                        |> Expect.equal True
            , test "a neighbouring sector within range of the shared edge is in range" <|
                \_ ->
                    JumpLog.sectorInRange 4 ( -97, -60 ) { id = 2, name = "Deneb", x = -3, y = -1 }
                        |> Expect.equal True
            , test "a neighbouring sector beyond the range is out of range" <|
                \_ ->
                    JumpLog.sectorInRange 4 ( -110, -60 ) { id = 2, name = "Deneb", x = -3, y = -1 }
                        |> Expect.equal False
            , test "uses the vertical extent, with y running down" <|
                \_ ->
                    -- sector y = -1 spans universal y -79..-40
                    ( JumpLog.sectorInRange 2 ( -100, -38 ) { id = 3, name = "Above", x = -4, y = -1 }
                    , JumpLog.sectorInRange 2 ( -100, -30 ) { id = 3, name = "Above", x = -4, y = -1 }
                    )
                        |> Expect.equal ( True, False )
            ]
        , describe "daysBetween"
            [ test "counts days within a year" <|
                \_ -> JumpLog.daysBetween ( 1105, 100 ) ( 1105, 106 ) |> Expect.equal 6
            , test "counts across a year end" <|
                \_ -> JumpLog.daysBetween ( 1105, 360 ) ( 1106, 1 ) |> Expect.equal 6
            , test "is negative when the second date is earlier" <|
                \_ -> JumpLog.daysBetween ( 1105, 10 ) ( 1105, 8 ) |> Expect.equal -2
            ]
        , describe "previousArrival"
            [ test "is the latest arrival of the ship for a new jump" <|
                \_ ->
                    JumpLog.previousArrival chain 1 Nothing
                        |> Expect.equal (Just ( 1105, 22 ))
            , test "ignores other ships" <|
                \_ ->
                    JumpLog.previousArrival chain 2 Nothing
                        |> Expect.equal (Just ( 1105, 3 ))
            , test "is the arrival of the jump before the one being edited" <|
                \_ ->
                    JumpLog.previousArrival chain 1 (Just 2)
                        |> Expect.equal (Just ( 1105, 8 ))
            , test "is nothing for the first jump of a ship when editing it" <|
                \_ ->
                    JumpLog.previousArrival chain 1 (Just 1)
                        |> Expect.equal Nothing
            , test "is nothing for a ship with no jumps" <|
                \_ ->
                    JumpLog.previousArrival chain 3 Nothing
                        |> Expect.equal Nothing
            ]
        , describe "compareNewestFirst"
            [ test "orders by arrival date descending" <|
                \_ ->
                    case Decode.decodeString JumpLog.jumpDecoder jumpJson of
                        Ok jump ->
                            [ jump, { jump | id = 8, arriveDay = 200 } ]
                                |> List.sortWith JumpLog.compareNewestFirst
                                |> List.map .id
                                |> Expect.equal [ 8, 7 ]

                        Err e ->
                            Expect.fail (Decode.errorToString e)
            ]
        , describe "jumpDecoder"
            [ test "decodes a referee payload with notes" <|
                \_ ->
                    Decode.decodeString JumpLog.jumpDecoder (String.replace "\"misjump\": true" "\"misjump\": true, \"notes\": \"Hot\"" jumpJson)
                        |> Result.map (\j -> { ship = j.shipName, hex = j.fromHex, misjump = j.misjump, notes = j.notes })
                        |> Expect.equal (Ok { ship = "Deep Night", hex = "0101", misjump = True, notes = "Hot" })
            , test "defaults notes to empty when the public payload omits them" <|
                \_ ->
                    Decode.decodeString JumpLog.jumpDecoder jumpJson
                        |> Result.map .notes
                        |> Expect.equal (Ok "")
            ]
        , describe "lastJumpDecoder"
            [ test "null means the ship has no jumps" <|
                \_ -> Decode.decodeString JumpLog.lastJumpDecoder "null" |> Expect.equal (Ok Nothing)
            ]
        ]
