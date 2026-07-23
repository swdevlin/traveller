module Traveller.TravelCalculations exposing
    ( auToKMs
    , calcDistance2F
    , formatDurationHours
    , formatDurationRange
    , kmToAu
    , safeJumpTimeFromShadow
    , secondsToDaysWatches
    , travelTime
    , travelTimeHoursDays
    , travelTimeInSeconds
    )

import Round
import Traveller.Point exposing (StellarPoint)


{-| Convert AU (Astronomical Units) to kilometers
-}
auToKMs : Float -> Float
auToKMs au =
    au * 149597871.0


{-| Convert kilometers to AU (Astronomical Units)
-}
kmToAu : Float -> Float
kmToAu km =
    km / 149597871.0


{-| Calculate travel time in seconds based on distance in km and M-drive rating
-}
travelTimeInSeconds : Float -> Int -> Float
travelTimeInSeconds kms mdrive =
    2 * sqrt (kms * 1000 / (toFloat mdrive * 9.8))


{-| Convert seconds to a "days and watches" string format
-}
secondsToDaysWatches : Float -> String
secondsToDaysWatches secs =
    let
        watches =
            toFloat <| ceiling <| secs / (60 * 60 * 8)

        days =
            toFloat <| floor <| watches / 3

        watches_ =
            watches - days * 3
    in
    Round.floor 0 days ++ "d " ++ Round.ceiling 0 watches_ ++ "w"


{-| Calculate safe jump time from a jump shadow distance, using the ship's M-drive rating.
Returns "—" if no drive is available or not set.
-}
safeJumpTimeFromShadow : Maybe Int -> Maybe Float -> String
safeJumpTimeFromShadow maybeMDrive maybeKms =
    case ( maybeMDrive, maybeKms ) of
        ( Just mDrive, Just kms ) ->
            if mDrive <= 0 || kms <= 0 then
                "0d 0w"

            else
                secondsToDaysWatches (travelTimeInSeconds kms mDrive)

        _ ->
            "—"


{-| Calculate travel time as a formatted string

Arguments:

  - kms: distance in kilometers
  - mdrive: M-drive rating (1-6 typically)
  - useHours: if True, format as hours/minutes; if False, format as days/watches

-}
travelTime : Float -> Int -> Bool -> String
travelTime kms mdrive useHours =
    let
        rawSeconds =
            travelTimeInSeconds kms mdrive
    in
    if useHours then
        let
            rawMinutes =
                toFloat <| ceiling <| rawSeconds / 60

            hours =
                toFloat <| floor <| rawMinutes / 60

            minutes =
                rawMinutes - hours * 60
        in
        if hours > 0 then
            Round.floor 0 hours ++ "h " ++ Round.ceiling 0 minutes ++ "m"

        else
            Round.ceiling 0 minutes ++ "m"

    else
        secondsToDaysWatches rawSeconds


{-| Format travel time in seconds as hours (if under a day) or days+hours.
-}
travelTimeHoursDays : Float -> String
travelTimeHoursDays secs =
    if secs < 3600 then
        let
            minutes =
                ceiling (secs / 60)
        in
        String.fromInt minutes ++ "m"

    else if secs < 86400 then
        let
            rawHours =
                secs / 3600

            rounded =
                toFloat (round (rawHours * 10)) / 10
        in
        String.fromFloat rounded ++ "h"

    else
        let
            totalHours =
                floor (secs / 3600)

            days =
                totalHours // 24

            hours =
                totalHours - days * 24
        in
        String.fromInt days ++ "d " ++ String.fromInt hours ++ "h"


{-| Format an hours duration as minutes/hours+minutes/weeks+days+hours,
matching the Rails `RouteTimingHelper#format_duration_hours` formatter used
for route-planning jump/transit times.
-}
formatDurationHours : Float -> String
formatDurationHours hours =
    let
        totalMinutes =
            round (hours * 60)
    in
    if totalMinutes < 60 then
        String.fromInt totalMinutes ++ "m"

    else
        let
            totalHours =
                totalMinutes // 60

            remainingMinutes =
                totalMinutes - (totalHours * 60)
        in
        if totalHours < 24 then
            String.fromInt totalHours ++ "h " ++ String.fromInt remainingMinutes ++ "m"

        else
            let
                weeks =
                    totalHours // 168

                days =
                    modBy 168 totalHours // 24

                hoursRemainder =
                    modBy 24 totalHours

                weekPart =
                    if weeks > 0 then
                        [ String.fromInt weeks ++ "w" ]

                    else
                        []

                dayPart =
                    if days > 0 then
                        [ String.fromInt days ++ "d" ]

                    else
                        []
            in
            String.join " " (weekPart ++ dayPart ++ [ String.fromInt hoursRemainder ++ "h" ])


{-| Format an average duration with a symmetric plus-or-minus range, matching
the Rails `RouteTimingHelper#format_duration_range` formatter.
-}
formatDurationRange : { min : Float, avg : Float, max : Float } -> String
formatDurationRange { min, avg, max } =
    formatDurationHours avg ++ " (±" ++ formatDurationHours ((max - min) / 2) ++ ")"


{-| Calculate 2D distance between two stellar points
-}
calcDistance2F : StellarPoint -> StellarPoint -> Float
calcDistance2F p1 p2 =
    let
        deltaX =
            p1.x - p2.x

        deltaY =
            p1.y - p2.y

        distanceSquared =
            deltaX * deltaX + deltaY * deltaY

        distance =
            sqrt distanceSquared
    in
    distance
