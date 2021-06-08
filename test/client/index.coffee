import assert from "@dashkite/assert"
import { test } from "@dashkite/amen"
import * as n from "@dashkite/neon"

do ->

  window.__test = await do ->

    test "In-Browser Tests", [

      test "render", ->
        n.render "head",
          -> "<title>Hello, World!</title>",
          {}
        assert (document.querySelector "head > title")?


    ]
