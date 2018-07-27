module Main exposing (..)

import Html exposing (Attribute, Html, a, button, div, form, img, input, label, li, p, program, text, ul)
import Html.Attributes exposing (attribute, autocomplete, class, for, href, id, src, target, type_)
import Html.Events exposing (onClick, onInput, onSubmit)
import Http
import Json.Decode as D exposing (..)
import Json.Decode.Pipeline exposing (decode, optional, required)
import Navigation
import Port exposing (..)
import Routes exposing (Route)
import Util exposing (onClickLink, unwrap)


type alias GitHubAcct =
    { avatar_url : String
    , html_url : String
    , location : Maybe String
    }


gitHubAcctDecoder : Decoder GitHubAcct
gitHubAcctDecoder =
    decode GitHubAcct
        |> required "avatar_url" D.string
        |> required "html_url" D.string
        |> optional "location" (D.map Just D.string) Nothing


gitHubRequest : String -> Http.Request GitHubAcct
gitHubRequest username =
    let
        url =
            "https://api.github.com/users/" ++ username
    in
    Http.get url gitHubAcctDecoder


getGitHubAcct : String -> Cmd Msg
getGitHubAcct username =
    Http.send
        (\res ->
            case res of
                Ok account ->
                    GotGitHubAcct account

                Err httpErr ->
                    ShowHttpError httpErr
        )
        (gitHubRequest username)


type alias LinkData msg =
    { url : Route
    , attrs : List (Attribute msg)
    , label : String
    }


link : Route -> LinkData Msg -> Html Msg
link route { url, attrs, label } =
    let
        a11yCurrent : List (Attribute msg)
        a11yCurrent =
            if route == url then
                [ attribute "aria-current" "page" ]
            else
                []
    in
    {- HELPER FUNCTION FOR SPA NAVIGATION -}
    a (attrs |> List.append [ Routes.href url, onClickLink (NavigateTo url) ] |> List.append a11yCurrent) [ text label ]



{- MODEL -}


type alias Model =
    { count : Int
    , httpErrMsg : String
    , gitHubUsernameInput : String
    , gitHubAccount : Maybe GitHubAcct
    , page : Route
    , screenData : Maybe ScreenData
    }


initialModel : Model
initialModel =
    { count = 0
    , gitHubAccount = Nothing
    , gitHubUsernameInput = ""
    , httpErrMsg = ""
    , page = Routes.Home
    , screenData = Nothing
    }



{- VIEW -}


view : Model -> Html Msg
view model =
    let
        appShell : List (Html Msg) -> Html Msg
        appShell children =
            div []
                ([ navBar model.page ] |> List.append children)
    in
    case model.page of
        Routes.Home ->
            appShell
                [ p [] [ text "Home" ]
                , counter model.count
                , githubInput model.gitHubUsernameInput
                , accountCard model.gitHubAccount
                ]

        Routes.About ->
            appShell
                [ p [] [ text "About" ]
                , counter model.count
                ]

        _ ->
            appShell
                [ p [] [ text "Fallback" ]
                , counter model.count
                ]


counter : Int -> Html Msg
counter count =
    div []
        [ p [] [ "The count is " ++ toString count |> text ]
        , button [ class "button", onClick Increment ] [ text "+1" ]
        , button [ class "button", onClick Decrement ] [ text "-1" ]
        ]


accountCard : Maybe GitHubAcct -> Html Msg
accountCard acct =
    case acct of
        Just acct ->
            div []
                [ a [ href acct.html_url, target "blank" ] [ text "View Profile" ]
                , p [] [ text (Maybe.withDefault "" acct.location) ]
                , img [ src acct.avatar_url ] []
                ]

        Nothing ->
            div [] []


navBar : Route -> Html Msg
navBar route =
    ul []
        [ li []
            [ link route { url = Routes.Home, attrs = [], label = "Home" } ]
        , li []
            [ link route { url = Routes.About, attrs = [], label = "About" } ]
        , li []
            [ link route { url = Routes.Projects, attrs = [], label = "Projects" } ]
        , li []
            [ link route { url = Routes.Contact, attrs = [], label = "Contact" } ]
        ]


githubInput : String -> Html Msg
githubInput inputValue =
    Html.form [ onSubmit (FetchGithubAcct inputValue) ]
        [ div []
            [ label [ for "github-input" ] [ text "GitHub username" ]
            , input [ id "github-input", onInput SetGitHubUsername, autocomplete False, Html.Attributes.required True ] []
            ]
        , button [ type_ "submit" ] [ text "Search" ]
        ]



{- UPDATE -}


type Msg
    = NoOp
    | SetRoute (Maybe Route)
    | Increment
    | Decrement
    | SetGitHubUsername String
    | FetchGithubAcct String
    | GotGitHubAcct GitHubAcct
    | ShowHttpError Http.Error
    | NavigateTo Route
    | Outside InfoForElm
    | LogErr String


httpErrorString : Http.Error -> String
httpErrorString error =
    case error of
        Http.BadUrl text ->
            "Bad Url: " ++ text

        Http.Timeout ->
            "Http Timeout"

        Http.NetworkError ->
            "Network Error"

        Http.BadStatus response ->
            response.body

        Http.BadPayload message response ->
            "Bad Http Payload: "
                ++ toString message
                ++ " ("
                ++ toString response.status.code
                ++ ")"


setRoute : Maybe Route -> Model -> ( Model, Cmd Msg )
setRoute maybeRoute model =
    case maybeRoute of
        Nothing ->
            { model | page = Routes.NotFound } ! []

        Just Routes.Home ->
            { model | page = Routes.Home } ! []

        Just Routes.About ->
            { model | page = Routes.About } ! []

        Just Routes.Projects ->
            { model | page = Routes.Projects } ! []

        Just Routes.Contact ->
            { model | page = Routes.Contact } ! []

        _ ->
            { model | page = Routes.NotFound } ! []


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            model ! []

        SetRoute maybeRoute ->
            setRoute maybeRoute model

        Outside infoForElm ->
            case infoForElm of
                ScrollOrResize data ->
                    { model | screenData = Just data } ! []

        LogErr err ->
            model ! [ sendInfoToJS (LogErrorToConsole err) ]

        Increment ->
            { model | count = model.count + 1 } ! []

        Decrement ->
            { model | count = model.count - 1 } ! []

        SetGitHubUsername input ->
            { model | gitHubUsernameInput = input } ! []

        FetchGithubAcct username ->
            model ! [ getGitHubAcct username ]

        GotGitHubAcct acct ->
            { model | gitHubAccount = Just acct } ! []

        ShowHttpError httpError ->
            { model
                | httpErrMsg = httpErrorString httpError
            }
                ! []

        NavigateTo page ->
            {- THE SECOND ARGUMENT TO routeToString IS A JWT FOR VALIDATION, IF NEEDED -}
            model ! [ Navigation.newUrl (Routes.routeToString page "") ]



{- SUBSCRIPTIONS -}


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



{- MAIN -}


init : Navigation.Location -> ( Model, Cmd Msg )
init location =
    let
        maybeRoute =
            location |> Routes.fromLocation
    in
    setRoute maybeRoute initialModel


main : Program Never Model Msg
main =
    Navigation.program (Routes.fromLocation >> SetRoute)
        { init = init
        , view = view
        , update = update
        , subscriptions =
            \model ->
                Sub.batch
                    [ receiveInfoFromJS Outside LogErr ]
        }
