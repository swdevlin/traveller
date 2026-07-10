module HostConfig exposing (HostConfig, default, fromApiBaseUrl)

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
