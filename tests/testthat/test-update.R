# tools/verify_widget.mjs pins the JS end of this message

fake_domain <- function(ns = NULL) {
  sent <- list()
  list(
    ns = ns,
    sendCustomMessage = function(type, message) {
      sent[[length(sent) + 1]] <<- list(type = type, message = message)
    },
    sent = function() sent
  )
}

test_that("update_jbrowse sends the named options to the output", {
  domain <- fake_domain()
  update_jbrowse("browser", location = "chr1:1-1000", domain = domain)

  sent <- domain$sent()
  expect_length(sent, 1)
  expect_equal(sent[[1]]$type, "jbrowser-update")
  expect_equal(sent[[1]]$message$id, "browser")
  expect_equal(sent[[1]]$message$options, list(location = "chr1:1-1000"))
})

test_that("session is an option, not the Shiny session", {
  domain <- fake_domain()
  update_jbrowse("app", session = list(name = "saved"), domain = domain)
  expect_equal(domain$sent()[[1]]$message$options$session$name, "saved")
})

test_that("a bare id is namespaced inside a module, and one already namespaced is not", {
  domain <- fake_domain(function(x) paste0("mod-", x))
  update_jbrowse("browser", location = "1", domain = domain)
  update_jbrowse("mod-browser", location = "1", domain = domain)
  ids <- vapply(domain$sent(), function(x) x$message$id, character(1))
  expect_equal(ids, c("mod-browser", "mod-browser"))
})

test_that("outside a Shiny session, or with an unnamed option, it is an error", {
  expect_error(update_jbrowse("browser", location = "1", domain = NULL), "Shiny server function")
  domain <- fake_domain()
  expect_error(update_jbrowse("browser", "1", domain = domain), "every option is named")
  expect_length(domain$sent(), 0)
})
