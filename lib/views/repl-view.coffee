Cycle = require '@cycle/core'
CycleDOM = require '@cycle/dom'
highlighter = require '../utils/highlighter'

REPLCycle =
  # highlight : forall a.
  #   { code : String, highlightInformation : HighlightInformation } ->
  #   CycleDOM
  highlight: ({ code, highlightInformation }) ->
    highlights = highlighter.highlight code, highlightInformation
    highlighter.highlightToCycle highlights

  # view : Observable State -> Observable CycleDOM
  view: (state$) ->
    state$.map (lines) ->
      lines = lines.map (line) ->
        highlightedCode = REPLCycle.highlight line
        CycleDOM.h 'div', { className: 'idris-repl-line' },
          [
            CycleDOM.h 'div', { className: 'idris-repl-input' }, line.input
            CycleDOM.h 'div', { className: 'idris-repl-output' }, highlightedCode
          ]

      CycleDOM.h 'div',
        {
          className: 'idris-panel-view'
        },
        [
          CycleDOM.h 'input', { type: 'text', className: 'native-key-bindings idris-repl-input-field' }, 'toggle'
          CycleDOM.h 'div', lines
        ]

  main: (responses) ->
    input = responses.DOM.select('input').events('keydown')
      .filter (ev) -> ev.keyCode == 13
      .map (ev) -> ev.target.value
      .startWith ''

    DOM: REPLCycle.view responses.CONTENT
    CONTENT: input

  # driver : forall a.
  #   IdrisModel -> Observable String ->
  #   Observable (List { a | code : String, highlightInformation : highlightInformation })
  driver:
    (options) ->
      DOM: CycleDOM.makeDOMDriver options.hostElement
      CONTENT: (inp) ->
        inp
          .filter (line) -> line != ''
          .flatMap (line) ->
            escapedLine = line.replace(/"/g, '\\"')
            options.model.interpret escapedLine
              .map (e) ->
                input: line
                code: e.msg[0]
                highlightInformation: e.msg[1]
          .scan ((acc, x) -> [x].concat acc), []
          .startWith []

class REPLView
  constructor: (params) ->
    hostElement = document.createElement 'div'
    hostElement.className = "blu"
    @[0] = hostElement

    model = params.controller.model

    drivers =
      REPLCycle.driver
        hostElement: hostElement
        model: model

    Cycle.run REPLCycle.main, drivers

module.exports = REPLView
