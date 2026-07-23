module TravelCalculationsTests exposing (..)

import Expect
import Test exposing (Test, describe)
import Traveller.TravelCalculations as TravelCalc


formatDurationHoursTests : Test
formatDurationHoursTests =
    describe "formatDurationHours"
        [ Test.test "formats sub-hour durations as minutes" <|
            \_ -> Expect.equal "30m" (TravelCalc.formatDurationHours 0.5)
        , Test.test "formats sub-day durations as hours and minutes" <|
            \_ -> Expect.equal "5h 30m" (TravelCalc.formatDurationHours 5.5)
        , Test.test "formats sub-week durations as days and hours" <|
            \_ -> Expect.equal "2d 3h" (TravelCalc.formatDurationHours ((2 * 24) + 3 |> toFloat))
        , Test.test "formats 102 hours as 4d 6h, not 102h" <|
            \_ -> Expect.equal "4d 6h" (TravelCalc.formatDurationHours 102)
        , Test.test "formats week-plus durations as weeks and hours" <|
            \_ -> Expect.equal "1w 5h" (TravelCalc.formatDurationHours (168 + 5))
        , Test.test "breaks a large remainder into days too, not raw hours" <|
            \_ -> Expect.equal "1w 4d 6h" (TravelCalc.formatDurationHours (168 + 102))
        , Test.test "handles a multi-week duration with a days-and-hours remainder" <|
            \_ -> Expect.equal "8w 6d 14h" (TravelCalc.formatDurationHours ((8 * 168) + 158))
        ]


formatDurationRangeTests : Test
formatDurationRangeTests =
    describe "formatDurationRange"
        [ Test.test "shows the average with a symmetric plus-or-minus range" <|
            \_ -> Expect.equal "10h 0m (±2h 0m)" (TravelCalc.formatDurationRange { min = 8, avg = 10, max = 12 })
        ]
