# Neon

*[Combinators](https://raganwald.com/2012/12/01/combinators-in-js.html) for dynamically rendering/updating Web pages.*

With Neon, you can describe the updates you want to make to a Web page. You may update individual elements (identified via selectors) or swap out views for a given page.

Views are useful in single-page applications, where you don't want to reload the page just to view a different item in a collection (like a blog post or a product listing).

You may use Neon in combination with a router to determine how to update page based on the URL. Neon can also be easily extended by adding your own combinators.

(Code examples are CoffeeScript because we prefer it, but Oxygen is transpiled into modern JavaScript.)

```coffeescript
import {flow} from "panda-garden"
import Router from "@dashkite/oxygen"
import {resource, render, view, show} from "@dashkite/neon"
import Post from "../post"

router = Router.create()

Router.add "/blog/posts/{key}",
	name: "view post"
  flow [
    resource ({bindings}) -> Post.get bindings.key
    render "head", ({resource}) -> "<title>#{resource.title}</title>"
    view "main", ({resource}) ->
    	"""
			<h1>#{resource.title}</h1>
			<img src='#{resource.image.url}'/>
			#{resource.html}
			"""
    show
  ]
```

## Installation

```
npm i @dashkite/neon
```

Neon is intended to be used in the browser via a bundler like Web Pack. It may also be used in a server context, such as server-side rendering, with a sufficiently rich DOM emulation.

## Features

- Supports asynchronous composition: all combinators return promises when necessary.
- Rendering is done via (possibly async) functions returning strings, so you may use whatever templating strategy you prefer.
- Intelligently patches the DOM using [diffHTML](https://diffhtml.org/).
- You can select specific pages or views using logical selectors, like `[name='view post']`
- Extensible simply by adding new combinators that take a rendering context.

## API

All combinators accept a rendering context, which includes the following properties:

- `name`: a logical name for the context, such as `view post` or `checkout`
- `data`: other _static_ data associated with context—data that doesn't change
- `bindings`: dynamic data associated with the context—this may change with each render
- `resource`: dynamic data combining the context with external application data

The distinctions between `data`, `bindings`, and `resource` are subtle. The easiest way to think about it is that `data` corresponds to a page (like `view post`), `bindings` correspond to the view (a specific post), and `resource` corresponds to external data (like the post itself). They're kept separate to avoid side-effects between render events, like the title of one blog post being rendered for another.

Combinators are often curryable, meaning you can provide all but the contex argument (the last argument) when composing them, which effectively tailors their behaviors. For example, the `render` combinator takes three arguments: a selector, a rendering function, and the context, but you need only provide the first two when composing it with other combinators.

### `resource getter, context`

Adds a resource to the rendering context. The getter may be an async function and should accept a context. Typically, the getter will use the `data` and `bindings` properties of the context to determine which resource to retrieve.

### `properties dictionary, context`

Adds getters directly to the bindings. This is useful for adding properties to the bindings for use in rendering without burdening your template functions with logic.

### `render selector, template, context`

Renders the template function into the element corresponding to the given selector. Patches the DOM using [diffHTML](https://diffhtml.org/). The template function should take a context and return an HTML string.

### `view selector, template, context`

Like `render` except that it renders a view of a page using the given template. Pages are rendered into the element corresponding to the given selector. If a page or view already exists, it will simply be updated.

#### Pages

A page is simply a `div` with class `page` and a `name` attribute corresponding to the `data.name` property of the rendering context.

#### Views

A view is also a `div`, but with class `view` and a `data-path` attribute containing the page URL. (This is how we know whether we're returning to an existing page or not.)

Views are rendered within pages. So a blog post view might be rendered like this:

```html
<div class='page' name='view post'>
  <div class='view' data-path='/blog/posts/my-first-post'>
    <!-- post would go here -->
  </div>
</div>
```

> **Limitation ▸ ** You currently cannot tailor the class names.

### `activate selectors, context`

Dispatches an activate event to the elements corresponding to the given selectors. This is typically done to notify any Web Components that have been rendered or updated that they're “on stage.”

### `show context`

Shows the view for the given render context. Until `show` is called, the view remains hidden.