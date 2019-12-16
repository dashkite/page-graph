import {innerHTML as diff} from "diffhtml"
import {tee, rtee, curry} from "panda-garden"

# TODO remove dependency on hash-sum?
# TODO use a jquery replacement library? (see append, replace, ... below)
# TODO use a diffHTML style update? (see replace, renderTo)

add = curry rtee (key, context) -> context.bindings[key] ?= context[key]

append = curry (root, html) ->
  root.insertAdjacentHTML "beforeend", html
  root.lastElementChild

replace = curry (el, html) ->
  el.outerHTML = html
  el

selectOrAppend = curry (root, selector, html) ->
  if (el = root.querySelector selector)? then el else append root, html

_root = curry rtee (selector, context) ->
  context.root = document.querySelector selector

_page = tee (context) ->
  context.page = selectOrAppend context.root,
    ".page[name='#{context.data.name}']",
    "<div class='page' name='#{context.data.name}'>"

_view = curry rtee (template, context) ->
  {bindings, path} = context
  context.view = selectOrAppend context.page,
    "[data-path='#{path}']",
    "<div class='view' data-path='#{path}'>"
  diff context.view, template bindings
  # TODO feels like there should be a more elegant way to do this
  unless context.view.dataset.initialized
    context.view.dataset.initalized = "true"
    context.view.addEventListener "dispose", ->
      context.page.removeChild context.view

view = curry rtee (selector, template, context) ->
  _view template, _page _root selector, context

render = curry rtee (selector, template, context) ->
  diff (document.querySelector selector), template context.bindings

activate = curry rtee (selectors, context) ->
  event = new CustomEvent "activate"
  for selector in selectors
    context.view.querySelector selector
    ?.dispatchEvent event

show = tee (context) ->
  active = document.querySelectorAll ".active"
  for el in active
    el.classList.remove "active"
  context.page.classList.add "active"
  context.view.classList.add "active"

export {add, view, activate, render, show}
