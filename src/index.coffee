import {innerHTML as diff} from "diffhtml"
import {tee, rtee, curry} from "@pandastrike/garden"

$ = (root, selector) -> root.querySelector selector
$$ = (root, selector) -> (root.querySelectorAll selector) ? []
join = (selectors) -> selectors.join ", "

append = curry (root, html) ->
  root.insertAdjacentHTML "beforeend", html
  root.lastElementChild

_root = curry rtee (selector, context) ->
  context.root = $ document, selector

_page = tee (context) ->
  context.page = ($ context.root, ".page[name='#{context.data.name}']") ?
    (append context.root, "<div class='page' name='#{context.data.name}'>")

_view = curry rtee (template, context) ->
  {bindings, path} = context
  context.initializing = false
  context.view = ($ context.page, "[data-path='#{path}']") ?
    do ->
      # create and initialize view
      view = append context.page, "<div class='view' data-path='#{path}'>"
      context.initializing = true
      view.addEventListener "dispose", -> context.page.removeChild context.view
      view
  diff context.view, template bindings


resource = curry rtee (getter, context) ->
  context.resource = await getter context

properties = curry rtee (dictionary, context) ->
  Promise.all do ->
    for key, getter of dictionary
      do (key, getter) ->
        context.bindings[key] = await getter context

view = curry rtee (selector, template, context) ->
  _view template, _page _root selector, context

render = curry rtee (selector, template, context) ->
  diff ($ document, selector), template context.bindings

show = tee (context) ->
  for el in $$ context.root, ".active"
    el.classList.remove "active"
  context.page.classList.add "active"
  context.view.classList.add "active"

activate = curry rtee (handler, context) ->
  handler context.bindings, context

deactivate = curry rtee (handler, context) ->
  if context.initializing
    _handler = ([..., {intersectionRatio}]) ->
      if intersectionRatio != 1 then handler()
    observer = new IntersectionObserver _handler, threshold: 1
    observer.observe context.view


export {resource, properties, view, activate, deactivate, render, show}
