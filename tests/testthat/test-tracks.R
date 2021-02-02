test_that("tracks returns a JSON array as a string", {
  expect_type(tracks("foo"), "character")
  expect_true(stringr::str_starts(tracks("foo"), "\\["))
  expect_true(stringr::str_ends(tracks("foo"), "\\]"))
})
