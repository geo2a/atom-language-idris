Cycle = require '@cycle/core'
CycleDOM = require '@cycle/dom'
highlighter = require '../utils/highlighter'

fontOptions = () ->
  fontSize = atom.config.get 'language-idris.panelFontSize'
  fontSizeAttr = "#{fontSize}px"
  enableLigatures = atom.config.get 'language-idris.panelFontLigatures'
  webkitFontFeatureSettings =
    if enableLigatures
      '"liga"'
    else
      '"inherit"'

  fontFamily = atom.config.get 'language-idris.panelFontFamily'
  if fontFamily != ''
    fontFamily
  else
    '"inherit"'

  'font-size': fontSizeAttr
  '-webkit-font-feature-settings': webkitFontFeatureSettings
  'font-family': fontFamily

AproposCycle =
  # highlight : forall a.
  #   { code : String, highlightInformation : HighlightInformation } ->
  #   CycleDOM
  highlight: ({ code, highlightInformation }) ->
    highlights = highlighter.highlight code, highlightInformation
    highlighter.highlightToCycle highlights

  # view : Observable State -> Observable CycleDOM
  view: (state$) ->
    styles = fontOptions()

    state$.map (apropos) ->
      aproposAnswer =
        if apropos.code
          highlightedCode = AproposCycle.highlight apropos
          CycleDOM.h 'pre', { className: 'idris-apropos-output', style: styles }, highlightedCode
        else
          CycleDOM.h 'span', ''

      CycleDOM.h 'div',
        {
          className: 'idris-panel-view'
        },
        [
          CycleDOM.h 'input', { type: 'text', className: 'native-key-bindings idris-repl-input-field' }, 'toggle'
          CycleDOM.h 'div', aproposAnswer
        ]

  main: (responses) ->
    input = responses.DOM.select('input').events('keydown')
      .filter (ev) -> ev.keyCode == 13
      .map (ev) -> ev.target.value
      .startWith ''

    DOM: AproposCycle.view responses.CONTENT
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
            options.model.apropos escapedLine
          .map (e) ->
            code: e.msg[0]
            highlightInformation: e.msg[1]
          .startWith {}

class AproposView
  constructor: (params) ->
    hostElement = document.createElement 'div'
    @[0] = hostElement

    model = params.controller.model

    drivers =
      AproposCycle.driver
        hostElement: hostElement
        model: model

    Cycle.run AproposCycle.main, drivers

module.exports = AproposView
