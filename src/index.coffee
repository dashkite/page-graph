import { use, innerHTML as diff } from "diffhtml"
import * as Fn from "@dashkite/joy/function"

use
  syncTreeHook: (oldTree, newTree) ->
    # Ignore style elements.
    if oldTree.nodeName == "head"
      styles = []
      for child in oldTree.childNodes
        styles.push child if child.nodeName == "style"

      newTree.childNodes.push styles...
      return newTree

$ = ( root, selector ) -> root.querySelector selector

$$ = ( root, selector ) -> (root.querySelectorAll selector) ? []

Selectors =

  join: ( selectors ) -> selectors.join ", "

DOM =

  append: ( root, html ) ->
    root.insertAdjacentHTML "beforeend", html
    root.lastElementChild

Page =

  get: ( context ) ->
    $ context.root, ".page[name='#{context.data.name}']"

  make: ( context ) ->
    DOM.append context.root,
      "<div class='page' name='#{context.data.name}'>"
  


View =

  get: ( context ) ->
    $ context.page, "[data-path='#{context.path}']"

  make: ( context ) ->
    DOM.append context.page,
      "<div class='view'
        data-path='#{context.path}' 
        data-name='#{context.data.name}'>"

Context =

  root: ( selector ) ->
    Fn.tee ( context ) -> 
      context.root = $ document, selector

  page: Fn.tee ( context ) ->
    context.page = ( Page.get context ) ? ( Page.make context )

  view: ( template ) ->
    Fn.tee ( context ) ->
      if ( context.view = View.get context )?
        context.initializing = false
      else
        context.initializing = true
        context.view = View.make context
        context.view.addEventListener "dispose", -> 
          context.page.removeChild context.view
      diff context.view, template context

view = ( selector, template ) ->
  Fn.tee Fn.pipe [
    Context.root selector
    Context.page
    Context.view template
  ]

render = ( selector, template ) ->
  Fn.tee ( context ) ->
    diff ( $ document, selector ), template context

append = ( selector, template ) ->
  Fn.tee ( context ) ->
    DOM.append ( $ document, selector ), template context

show = Fn.tee ( context ) ->
  for element in $$ context.root, ".active"
    element.classList.remove "active"
  context.page.classList.add "active"
  context.view.classList.add "active"

activate = ( handler ) ->
  Fn.tee ( context ) ->
    _handler = ([..., {intersectionRatio}]) ->
      if intersectionRatio > 0
        handler context
        observer.unobserve context.view
    observer = new IntersectionObserver _handler, threshold: 0
    observer.observe context.view

deactivate = ( handler ) ->
  Fn.tee ( context ) ->
    _handler = ([..., {intersectionRatio}]) ->
      if intersectionRatio <= 0
        handler context
        observer.unobserve context.view
    observer = new IntersectionObserver _handler, threshold: 0
    observer.observe context.view

dispose = deactivate ( context ) -> context.view.remove()

event = ( name, handler ) ->
  Fn.tee ( context ) ->
    _handler = ( event ) -> handler event, context
    context.view.addEventListener name, handler, once: true

export {
  view
  activate
  deactivate
  dispose
  show
  event
  render
  append
}

export default {
  view
  activate
  deactivate
  dispose
  show
  event
  render
  append
}
