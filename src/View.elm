module View exposing (text)

import Data exposing (fontMult)
import Element exposing (Element)
import Emoji
import Html
import Html.Attributes as Attributes


text : Int -> String -> Element msg
text int string =
    let
        scale : Float
        scale =
            1.1

        diff : Float -> Float
        diff =
            (*) (scale - 1)
    in
    Element.html <|
        Html.span
            [ Attributes.class "elm-emoji"
            , Attributes.style "height" (String.fromInt int ++ "px")
            , Attributes.style "overflow" "hidden"
            ]
        <|
            Emoji.textWith
                (\list ->
                    Html.img
                        [ Attributes.src <|
                            "https://openmoji.org/data/color/svg/"
                                ++ (List.intersperse "-" list |> String.join "" |> String.toUpper)
                                ++ ".svg"
                        , Attributes.height <| round <| (*) scale <| toFloat int
                        ]
                        []
                )
            <|
                string
