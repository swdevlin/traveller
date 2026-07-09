port module Dialog exposing (toggleDialog, view)

import Html exposing (Html, text)
import Html.Attributes
import Html.Events


port toggleDialog : String -> Cmd msg


dialogNode : String -> List (Html.Attribute msg) -> List (Html msg) -> Html msg
dialogNode elementId attr content =
    Html.node "dialog" (Html.Attributes.id elementId :: attr) content


view : String -> msg -> Html msg -> Html msg
view elementId closeMsg content =
    dialogNode
        elementId
        [-- avoid display/visibility Tailwind classes here — they conflict with the native dialog element
        ]
        [ content
        , Html.button
            [ Html.Attributes.class "px-4 py-2 bg-button-primary text-fg-bright rounded hover:bg-button-primary-outline m-2"
            , Html.Events.onClick closeMsg
            ]
            [ text "Close" ]
        ]
