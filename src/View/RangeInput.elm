module View.RangeInput exposing (view)

import Element exposing (Attribute, Element)
import Element.Input as Input
import Framework.Button as Button
import Framework.Color as Color
import Framework.Grid as Grid


view : { minValue : Int, maxValue : Int, onChange : Int -> msg, value : Int, label : String } -> Element msg
view { minValue, maxValue, onChange, value, label } =
    let
        button : List (Attribute msg) -> Int -> Element msg
        button attribute num =
            Input.button
                (attribute
                    ++ [ Element.width <| Element.fill ]
                    ++ (if num == value then
                            Color.primary

                        else
                            []
                       )
                )
                { onPress = Just <| onChange num
                , label = Element.text <| String.fromInt <| num
                }
    in
    Element.row Grid.spaceEvenly <|
        [ Element.paragraph [ Element.width <| Element.fill ] <|
            List.singleton <|
                Element.text <|
                    label
        , Element.row (Grid.compact ++ [ Element.width <| Element.fill ]) <|
            List.concat <|
                [ List.singleton <| button Button.groupLeft minValue
                , List.range (minValue + 1) (maxValue - 1)
                    |> List.map (button Button.groupCenter)
                , List.singleton <| button Button.groupRight maxValue
                ]
        ]
