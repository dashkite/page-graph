import {tee, rtee, curry} from "panda-garden"
import _hash from "hash-sum"
import {$} from "panda-play"

hash = tee (context) -> context.bindings.hash ?= _hash context.bindings

meta = tee (context) -> context.bindings.meta = context.data

root = curry rtee (selector, context) ->
  context.root = document.querySelector selector

page = tee (context) ->
  context.page = document.querySelector ".page[name='#{context.data.name}']"
  if !context.page?
    context.root.insertAdjacentHTML "beforeend",
      "<div class='page' name='#{context.data.name}'>"
    context.page = document.querySelector ".page[name='#{context.data.name}']"

view = curry rtee (template, context) ->
  context.view = context.dom.querySelector "[data-hash='#{context.bindings.hash}']"
  if !context.view?
    context.html = template context.bindings
    context.dom.insertAdjacentHTML  "beforeend", context.html
    context.view =  context.dom.querySelector "[data-hash='#{context.bindings.hash}']"
    context.view.addEventListener "dispose", ->
      context.dom.removeChild context.view

activate = curry rtee (selectors, context) ->
  event = new CustomEvent "activate"
  for selector in selectors
    context.view.querySelector selector
    ?.dispatchEvent event

show = tee (context) ->
  document.querySelector ".view.active"
  ?.classList.remove "active"
  context.view.classList.add "active"

export {hash, meta, root, page, view, activate, show}
