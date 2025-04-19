# Phoenix Multilingual

Phoenix Multilingual simplifies handling localized routes
in Elixir Phoenix applications, with and without LiveView.

# Rationale

In Phoenix Multilingual, "view" means a page in an application, **which can be
rendered in one or more languages**.

When a site is localized, it is important to know which paths
are the various localizations of a specific view.

For example, a site may have a page about the company, the "about page".
This page may be available in multiple languages, such as English and Italian.
The English path would be `/about` and `/it/chi-siamo` the Italian version.

Localized site commonly need these things:

* access to the current locale,
* localized links — for example, a link to the "about" page in the current locale,
* a language selector — where you can jump to the same view in another language,
* rel links in the header with alternative paths for the same view in other languages.

TO achieve all this, somewhere, for *each* localized view, there needs to be a mapping like this:

* "en" -> "/about"
* "it" -> "/it/chi-siamo"

This library is based on the idea that it is better to put such localization
information directly in the router.

# Route Metadata

Fortunately, the [Phoenix.Router](https://hexdocs.pm/phoenix/Phoenix.Router.html)
allows [metadata](https://hexdocs.pm/phoenix/Phoenix.Router.html#match/5-options)
to be added to route declarations.

With Phoenix Multilingual, you add metadata to indicate the locale of each localized view.

You can do this via a helper:

```ex
import PhoenixMultilingual.Routes, only: [metadata: 1]

...

get "/", PageController, :index, metadata("zh")
```

`metadata/1` sets the [`options`](https://hexdocs.pm/phoenix/Phoenix.Router.html#match/5-options)
for the route, specifically, setting the locale as the metadata for this library.

It's the same if you do this:

```ex
get "/", PageController, :index, metadata: [multilingual: %{locale: "zh"}]
```

# How Paths Are Grouped

Consider these routes:

```ex
get "/", PageController, :index, metadata("en")
get "/zh", PageController, :index, metadata("zh")
```

As they have the same `plug` (`PageController`) and `plug_opts` (`:index`),
Multilingual groups them to create the mapping that we need between
localized versions of the same view.

From the above, we can deduce that "/" and "/zh" are the same view,
but in different languages.

So, by default `plug_opts` is used to identify the view. This has the
limitation that only one action is used for each view.

If you want to have multiple actions for the same view, you can
use the `metadata/2` function in the metadata to specify both the
view and the locale:

```ex
import Multilingual.Routes, only: [metadata: 2]

...

get "/", PageController, :index_zh, metadata(:index, "zh")
get "/en", PageController, :index_en, metadata(:index, "en")
```

# Route Organization

Phoenix Multilingual places no restrictions on how you structure your router declarations.

You can group the localized versions under scopes, with path prefixes:

```ex
scope "/", MyAppWeb do
  get "/", PageController, :index, metadata("en")
end

scope "/zh", MyAppWeb do
  get "/", PageController, :index, metadata("zh")
end
```

Otherwise, you can group the localized versions of a view together:

```ex
scope "/", MyAppWeb do
  get "/", PageController, :index, metadata("en")
  get "/zh", PageController, :index, metadata("zh")
end
```

If the path itself is localized, it's easy to follow what's going on:

```ex
scope "/", MyAppWeb do
  get "/about", PageController, :index, metadata("en")
  get "/it/chi-siamo", PageController, :index, metadata("it")
end
```

# `mix multilingual.routes`

If you want to check how your localized routes are configured,
there is a Mix task:

```sh
$ mix multilingual.routes
method  module                   view    en      it
get     MyAppWeb.PageController  :index  /about  /it/chi-siamo
```

# Using Multilingual Routes

With you routes set up, you can then make use of the information they give
via the following modules and functions.

This works by first storing the current path and locale
([the 'LocalizedView'](lib/phoenix_multilingual/localized_view.ex))
in the `conn` or, the `socket` for LiveViews, and then using that
information to take further actions.

## Plugs for the Router

* The [StoreView Plug](lib/phoenix_multilingual/plugs/store_view.ex) to store
  [localized view](lib/phoenix_multilingual/localized_view.ex) information;
* The [RedirectIncoming Plug](lib/phoenix_multilingual/plugs/redirect_incoming.ex)
  for incoming links, which checks the 'accept-langauge' header
  and redirects to the correct view for the user's needs;
* The [PutGettextLocale Plug](lib/phoenix_multilingual/plugs/put_gettext_locale.ex)
  which calls `Gettext.put_locale/1`.

## LiveView Hooks

* The [StoreView on_mount hook](lib/phoenix_multilingual/live_view/hooks/store_view.ex)
  to store [localized view](lib/phoenix_multilingual/view.ex) information in the LiveView socket;
* The [PutGettextLocale on_mount hook](lib/phoenix_multilingual/live_view/hooks/put_gettext_locale.ex)
  which calls `Gettext.put_locale/1`.

## HTML Generation

* [get_rel_links/1](lib/phoenix_multilingual/html.ex) builds a set of SEO-friendly
  rel links for the document head, indicating the canonical URL and links to
  localized views,
* [localized_path/3](lib/phoenix_multilingual/routes.ex) takes any path and
  a locale and returns the equivalent path for that locale,
* [build_page_mapping/2](lib/phoenix_multilingual/routes.ex) returns a mapping
  of locales to paths to aid the creation of language selectors.
