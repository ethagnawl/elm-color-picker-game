module ColorPicker where

import Debug
import Effects exposing (Effects, Never)
import Html.Attributes exposing (style)
import Html.Events exposing (..)
import Html exposing (Html, text, div)
import Maybe exposing (Maybe(Just, Nothing))
import Signal exposing (Address, Signal, Mailbox, mailbox, send)
import StartApp
import Task

optionView address color =
  let
    guess = GuessMade color
  in
    div
      [onClick address guess]
      [text color]

answerView color =
  div
    [style
      [
        ("background-color", color),
        ("height", "100px"),
        ("width", "100px")]]
    []

view address model =
  let
    answer' = answerView model.answer
    options' = div [] (List.map (optionView address) model.options)
    prompt = if model.guess /= "" then "" else "Pick a color!"
    promptView = div [] [text prompt]
    rightOrWrong = if  model.guess /= "" then
                     if model.guess == model.answer then "Right!" else "Wrong!"
                   else
                     ""
    rightOrWrongView = div [] [text rightOrWrong]
    scoreView = div [] [text ("score: " ++ (toString model.score))]
  in
    div
      []
      [
        answer',
        options',
        promptView,
        rightOrWrongView,
        scoreView
        , div [] [text ("debug: " ++ model.answer)]
      ]

type alias GameObject = {
  answer : String,
  options : List String,
  guess : String,
  score : Int
}

init = GameObject "rgb(0, 0, 0)" ["rgb(0, 0, 0)"] "" 0

type Action =
    GameObjectReceived GameObject
  | GuessMade String
  | Noop

update action model =
  case action of

    GuessMade newGuess ->
      let
        score = if newGuess == model.answer then
                   if newGuess == model.guess then model.score else (model.score + 5)
                else
                  if model.score - 5 < 0 then 0 else model.score - 5
        model = { model | guess = newGuess,
                          score = score }
      in
        (model, sendNewGameObjectRequest model)

    GameObjectReceived newGameObject ->
      (
        { model | answer = newGameObject.answer,
                  guess = "",
                  options = newGameObject.options,
                  score = model.score }
        , Effects.none
      )

    Noop ->
      ( model, Effects.none )

portRequestNewGameObject : Mailbox GameObject
portRequestNewGameObject =
  mailbox init

port requestNewGameObject : Signal GameObject
port requestNewGameObject =
  portRequestNewGameObject.signal

sendNewGameObjectRequest model =
  send portRequestNewGameObject.address model
    |> Effects.task
    |> Effects.map (\_ -> Noop)

port options : Signal GameObject

incomingGameObject : Signal Action
incomingGameObject =
  Signal.map GameObjectReceived options

app =
  StartApp.start {
    init = (init, Effects.none),
    view = view,
    update = update,
    inputs = [incomingGameObject]
  }

port tasks : Signal (Task.Task Never ())
port tasks =
  app.tasks

main = app.html
