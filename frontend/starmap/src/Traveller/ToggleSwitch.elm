module Traveller.ToggleSwitch exposing (Size(..), view)

import Html exposing (Html)
import Html.Attributes as HtmlAttrs


type Size
    = Small
    | Regular


{-| A boolean switch control, styled with the app's shared `bg-toggle-on/off`
and `bg-toggle-knob-on/off` classes. The caller supplies the click behaviour
as an `Html.Attribute` so it can be a plain `Html.Events.onClick` or a
`Html.Events.stopPropagationOn "click"` when the switch sits inside a larger
clickable row.
-}
view : Size -> Bool -> Html.Attribute msg -> Html msg
view size checked onClickAttr =
    let
        ( trackSize, knobSize, knobOnTranslate ) =
            case size of
                Small ->
                    ( "h-5 w-9", "h-4 w-4", "translate-x-4" )

                Regular ->
                    ( "h-6 w-11", "h-5 w-5", "translate-x-5" )
    in
    Html.button
        [ HtmlAttrs.type_ "button"
        , HtmlAttrs.attribute "role" "switch"
        , HtmlAttrs.attribute "aria-checked"
            (if checked then
                "true"

             else
                "false"
            )
        , HtmlAttrs.class
            ("relative inline-flex flex-shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors duration-200 ease-in-out focus:outline-none "
                ++ trackSize
                ++ " "
                ++ (if checked then
                        "bg-toggle-on"

                    else
                        "bg-toggle-off"
                   )
            )
        , onClickAttr
        ]
        [ Html.span
            [ HtmlAttrs.class
                ("pointer-events-none inline-block transform rounded-full shadow ring-0 transition duration-200 ease-in-out "
                    ++ knobSize
                    ++ " "
                    ++ (if checked then
                            knobOnTranslate ++ " bg-toggle-knob-on"

                        else
                            "translate-x-0 bg-toggle-knob-off"
                       )
                )
            ]
            []
        ]
