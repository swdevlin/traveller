module HostConfig exposing (HostConfig, default, fromApiBaseUrl, starmapData)

import Url


type alias HostConfig =
    ( String, List String )


default : HostConfig
default =
    ( "", [ "api" ] )


fromApiBaseUrl : String -> HostConfig
fromApiBaseUrl apiBaseUrl =
    case Url.fromString apiBaseUrl of
        Just { protocol, host, path, port_ } ->
            ( rebuildRoot protocol host port_
            , pathSegments path
            )

        Nothing ->
            ( ""
            , pathSegments apiBaseUrl
            )


{-| The same host, for the endpoints that serve the starmap alone (`starmap/data`, beside `api`).
These carry what the map draws and are free to change with it; `api` is the documented API.
-}
starmapData : HostConfig -> HostConfig
starmapData ( root, apiPath ) =
    ( root, List.take (List.length apiPath - 1) apiPath ++ [ "starmap", "data" ] )


protocolToString : Url.Protocol -> String
protocolToString protocol =
    case protocol of
        Url.Http ->
            "http://"

        Url.Https ->
            "https://"


rebuildRoot : Url.Protocol -> String -> Maybe Int -> String
rebuildRoot protocol host port_ =
    protocolToString protocol
        ++ host
        ++ (case port_ of
                Just portNumber ->
                    ":" ++ String.fromInt portNumber

                Nothing ->
                    ""
           )


pathSegments : String -> List String
pathSegments path =
    path
        |> String.split "/"
        |> List.filter (\segment -> segment /= "")
