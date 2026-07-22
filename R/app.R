#' Embed the full JBrowse 2 app (multiple views of any type)
#'
#' Where [JBrowseR()] shows a single linear genome view, `JBrowseRApp()` drives
#' the whole app engine, so `views` can mix a linear view, a synteny view, a
#' dotplot, and more. Each `views` entry is a `list(type = ..., init = ...)`
#' spec — the same vocabulary JBrowse Web serializes into its `?session=spec-…`
#' URLs — built most easily with [linear_view()], [synteny_view()], and
#' [dotplot_view()].
#'
#' @param assemblies A list of assembly configs (each from [assembly()], or a
#'   plain config list). A synteny/dotplot view needs two or more.
#' @param tracks A list of full track config lists. Because a synteny track
#'   spans two assemblies there is no single-assembly shorthand; [synteny_track()]
#'   builds the common PAF case.
#' @param views A list of view specs, e.g. from [synteny_view()] / [linear_view()].
#' @param plugins A list of JBrowse plugin specs (name + url) to load at runtime.
#' @param theme A theme config from [theme()].
#' @param config Escape hatch: a whole JBrowse config forming the payload base
#'   that explicit arguments override — a list, or the path, URL, or JSON text of
#'   a `config.json`.
#' @param width,height,elementId Standard htmlwidget sizing arguments.
#'
#' @return an htmlwidget of the JBrowse 2 app
#'
#' @import htmlwidgets
#' @export
#'
#' @examples
#' \dontrun{
#' JBrowseRApp(
#'   assemblies = list(assembly(hg38_fa), assembly(mm39_fa)),
#'   tracks = list(synteny_track(paf_url, "hg38", "mm39")),
#'   views = list(synteny_view(c("hg38", "mm39"), tracks = "hg38-mm39"))
#' )
#' }
JBrowseRApp <- function(assemblies = NULL, tracks = NULL, views = NULL,
                        plugins = NULL, theme = NULL, config = NULL,
                        width = NULL, height = NULL, elementId = NULL) {
  if (is.null(assemblies) && is.null(config)) {
    stop("provide `assemblies` (or a whole `config`)", call. = FALSE)
  }
  create_widget("JBrowseRApp", config, list(
    assemblies = assemblies,
    tracks = tracks,
    views = views,
    plugins = plugins,
    configuration = configuration_from_theme(theme)
  ), width, height, elementId)
}

#' Describe a view for `JBrowseRApp(views = ...)`
#'
#' The general form behind [linear_view()], [synteny_view()], and
#' [dotplot_view()]: builds the `list(type = ..., init = ...)` spec any view type
#' understands, where `init` is the declarative
#' [session-spec init](https://jbrowse.org/jb2/docs/urlparams/#session-spec) for
#' that type. Use it for view types those helpers don't cover, including any a
#' runtime `plugins` entry registers — its init fields are the plugin's own, so
#' nothing here has to keep up with them:
#'
#' \preformatted{view("ProteinView",
#'      url = "https://alphafold.ebi.ac.uk/files/AF-P04637-F1-model_v6.cif",
#'      height = 600)}
#'
#' @param type The view type (e.g. `"LinearGenomeView"`, `"LinearSyntenyView"`,
#'   `"ProteinView"`).
#' @param ... Fields of the view's init blob; `NULL` fields are dropped.
#'
#' @return a view spec list
#' @export
view <- function(type, ...) {
  list(type = type, init = drop_null(list(...)))
}

# comparative-view panels: {assembly, loc?} per side; accept bare assembly names
# or full panel lists
comparative_panels <- function(assemblies) {
  lapply(assemblies, \(a) if (is.list(a)) a else list(assembly = a))
}

#' Describe a linear genome view for `JBrowseRApp(views = ...)`
#'
#' @param assembly Assembly name.
#' @param loc A region string (`"chr1:1-1000"`) or a gene name.
#' @param tracks Track ids to show (referencing `JBrowseRApp`'s `tracks`).
#' @param ... Extra fields merged onto the view's init blob (e.g. `colorByCDS = TRUE`).
#'
#' @return a view spec list
#' @export
linear_view <- function(assembly, loc = NULL, tracks = NULL, ...) {
  view("LinearGenomeView",
    assembly = assembly, loc = loc, tracks = as_json_array(tracks), ...
  )
}

#' Describe a linear synteny view comparing two (or more) assemblies
#'
#' @param assemblies Assembly names (or `list(assembly=, loc=)` panels to focus
#'   each side on a region).
#' @param tracks Synteny track ids tying the assemblies together.
#' @param cigar_mode `"full"`, `"matches"`, or `"off"`.
#' @param ... Extra fields merged onto the view's init blob.
#'
#' @return a view spec list
#' @export
synteny_view <- function(assemblies, tracks = NULL, cigar_mode = NULL, ...) {
  view("LinearSyntenyView",
    views = comparative_panels(assemblies), tracks = as_json_array(tracks),
    cigarMode = cigar_mode, ...
  )
}

#' Describe a dotplot view comparing two assemblies
#'
#' @param assemblies Assembly names (or panel lists).
#' @param tracks Synteny track ids.
#' @param ... Extra fields merged onto the view's init blob.
#'
#' @return a view spec list
#' @export
dotplot_view <- function(assemblies, tracks = NULL, ...) {
  view("DotplotView",
    views = comparative_panels(assemblies), tracks = as_json_array(tracks), ...
  )
}

#' Build a synteny (PAF) track config spanning two assemblies
#'
#' @param uri URL to a `.paf` file.
#' @param target_assembly,query_assembly The two assembly names (PAF target is
#'   the first assembly of a [synteny_view()]).
#' @param name Track display name. Defaults to the file's base name.
#' @param track_id Track id. Defaults to a slug of `name`.
#' @param ... Extra config merged onto the track.
#'
#' @return a track config list
#' @export
synteny_track <- function(uri, target_assembly, query_assembly, name = NULL,
                          track_id = NULL, ...) {
  name <- name %||% base_name(uri)
  out <- list(
    type = "SyntenyTrack",
    trackId = track_id %||% gsub("[^A-Za-z0-9]+", "-", tolower(name)),
    name = name,
    assemblyNames = list(target_assembly, query_assembly),
    adapter = list(
      type = "PAFAdapter",
      targetAssembly = target_assembly,
      queryAssembly = query_assembly,
      uri = uri
    )
  )
  utils::modifyList(out, list(...))
}
