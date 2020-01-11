;; from https://github.com/jcollard/elm-mode/issues/138#issuecomment-416761616
((elm-mode
  (elm-interactive-command . ("elm" "repl"))
  (elm-reactor-command . ("elm" "reactor"))
  (elm-reactor-arguments . ("--port" "8000"))
  (elm-compile-command . ("elm" "make"))
  (elm-compile-arguments . ("--debug"))
  (elm-package-command . ("elm" "package"))
  (elm-package-json . "elm.json")))
