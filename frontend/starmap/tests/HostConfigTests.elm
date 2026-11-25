module HostConfigTests exposing (suite)

import Expect
import HostConfig
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "HostConfig.starmapData"
        [ test "swaps the api segment for the starmap's own endpoints" <|
            \_ ->
                HostConfig.fromApiBaseUrl "/c/drizzle/api"
                    |> HostConfig.starmapData
                    |> Expect.equal ( "", [ "c", "drizzle", "starmap", "data" ] )
        , test "keeps the host" <|
            \_ ->
                HostConfig.fromApiBaseUrl "https://example.com/c/drizzle/api"
                    |> HostConfig.starmapData
                    |> Expect.equal ( "https://example.com", [ "c", "drizzle", "starmap", "data" ] )
        , test "works from the default" <|
            \_ ->
                HostConfig.starmapData HostConfig.default
                    |> Expect.equal ( "", [ "starmap", "data" ] )
        ]
