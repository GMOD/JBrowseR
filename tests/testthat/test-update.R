# update_location() is one custom message. These check what lands on the wire,
# with a fake session standing in for Shiny's — the JS side reads
# `id`/`method`/`args` and nothing else, and nothing type-checks that seam, so
# tools/verify_proxy.mjs pins the other end of it against the built bundle.

fake_session <- function(ns = NULL) {
  sent <- list()
  list(
    ns = ns,
    sendCustomMessage = function(type, message) {
      sent[[length(sent) + 1]] <<- list(type = type, message = message)
      invisible(NULL)
    },
    sent = function() sent
  )
}

test_that("update_location sends the location to the named output", {
  session <- fake_session()
  update_location("browser", "chr1:1-1000", session)

  sent <- session$sent()
  expect_length(sent, 1)
  expect_equal(sent[[1]]$type, "jbrowser-call")
  expect_equal(sent[[1]]$message$id, "browser")
  expect_equal(sent[[1]]$message$method, "update")
  expect_equal(sent[[1]]$message$args$location, "chr1:1-1000")
})

test_that("a bare id is namespaced inside a module, and one already namespaced is not", {
  session <- fake_session(function(x) paste0("mod-", x))

  update_location("browser", "chr1:1-1000", session)
  update_location("mod-browser", "chr1:1-1000", session)

  ids <- vapply(session$sent(), function(x) x$message$id, character(1))
  expect_equal(ids, c("mod-browser", "mod-browser"))
})

test_that("calling it outside a Shiny session is an error, not a silent no-op", {
  expect_error(
    update_location("browser", "chr1:1-1000", NULL),
    "Shiny server function"
  )
})

test_that("update_location rejects anything but one location string", {
  session <- fake_session()
  expect_error(update_location("browser", c("chr1:1-1000", "chr2:1-1000"), session))
  expect_error(update_location("browser", 1, session))
  expect_length(session$sent(), 0)
})
