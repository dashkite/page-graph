import {innerHTML as diff} from "diffhtml"
import {tee, rtee, curry} from "panda-garden"

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

view = curry rtee (selector, template, context) ->
  _view template, _page _root selector, context

render = curry rtee (selector, template, context) ->
  diff ($ document, selector), template context.bindings

isClassChange = (mutation) ->
   mutation.type == "attributes" && mutation.attributeName == "class"

wasActive = (mutation) ->
  if mutation.oldValue?
    ("active" in mutation.oldValue.split /\s+/)
  else
    false

isActive = (mutation) -> mutation.target.classList.contains "active"

isActivation = (mutation) ->
  (isClassChange mutation) && !(wasActive mutation) && (isActive mutation)

isDeactivation = (mutation) ->
  (isClassChange mutation) && (wasActive mutation) && !(isActive mutation)

observe = (predicate, action, element) ->
  observer = new MutationObserver (mutations) ->
    for mutation in mutations when predicate mutation
      action mutation.target
  observer.observe element,
    attributes: true
    attributeOldValue: true

activate = curry rtee (handler, context) ->
  if context.initializing
    observe isActivation, handler, context.view

deactivate = curry rtee (handler, context) ->
  if context.initializing
    observe isDeactivation, handler, context.view

show = tee (context) ->
  for el in $$ context.root, ".active"
    el.classList.remove "active"
  context.page.classList.add "active"
  context.view.classList.add "active"

resource = curry rtee (getter, context) ->
  context.resource = await getter context

properties = curry rtee (dictionary, context) ->
  Promise.all do ->
    for key, getter of dictionary
      do (key, getter) ->
        context.bindings[key] = await getter context

export {resource, properties, view, activate, deactivate, render, show}
