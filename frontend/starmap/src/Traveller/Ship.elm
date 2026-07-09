module Traveller.Ship exposing (Ship)


type alias Ship =
    { name : String
    , jDrive : Maybe Int
    , mDrive : Maybe Int
    }
