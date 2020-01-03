module View.ToggleInput exposing (view)

import Element exposing (Attribute, Element)
import Element.Input as Input
import Framework.Button as Button
import Framework.Color as Color
import Framework.Grid as Grid


view : { onChange : Bool -> msg, value : Bool, label : String } -> Element msg
view { onChange, value, label } =
    let
        button : List (Attribute msg) -> Bool -> Element msg
        button attribute bool =
            Input.button
                (attribute
                    ++ [ Element.width <| Element.fill ]
                    ++ (case ( value, bool ) of
                            ( True, True ) ->
                                Color.success

                            ( False, False ) ->
                                Color.primary

                            ( _, _ ) ->
                                []
                       )
                )
                { onPress = Just <| onChange bool
                , label = Element.text <| ""
                }
    in
    Element.row Grid.spaceEvenly <|
        [ Element.paragraph [ Element.width <| Element.fill ] <|
            List.singleton <|
                Element.text <|
                    label
        , Element.row (Grid.compact ++ [ Element.width <| Element.fill ]) <|
            List.concat <|
                [ List.singleton <| button Button.groupLeft False
                , List.singleton <| button Button.groupRight True
                ]
        ]
