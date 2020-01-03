module Data.FormField exposing (FormField, create, toValue, unWrap, update)


type FormField a error
    = FormField
        { value : a
        , raw : String
        , errors : List error
        }


create : { default : a, value : String } -> FormField a error
create { default, value } =
    FormField
        { value = default, raw = value, errors = [] }


update : (String -> Result (List error) a) -> String -> FormField a error -> FormField a error
update fun string (FormField formField) =
    case fun string of
        Ok a ->
            FormField { value = a, raw = string, errors = [] }

        Err err ->
            FormField { formField | raw = string, errors = err }


unWrap : FormField a error -> { raw : String, errors : List error }
unWrap (FormField { raw, errors }) =
    { raw = raw, errors = errors }


toValue : FormField a error -> a
toValue (FormField { value }) =
    value
