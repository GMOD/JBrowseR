test_that("creating a wiggle track returns the correct string", {
  expect_type(theme("#311b92"), "character")
  expect_equal(theme("#311b92"), "{ \"palette\": { \"primary\": { \"main\": \"#311b92\" }}}")
  expect_equal(theme("#311b92", "#0097a7"), "{ \"palette\": { \"primary\": { \"main\": \"#311b92\" }, \"secondary\": { \"main\": \"#0097a7\" }}}")
  expect_equal(theme("#311b92", "#0097a7", "#f57c00"), "{ \"palette\": { \"primary\": { \"main\": \"#311b92\" }, \"secondary\": { \"main\": \"#0097a7\" }, \"tertiary\": { \"main\": \"#f57c00\" }}}")
  expect_equal(theme("#311b92", "#0097a7", "#f57c00", "#d50000"), "{ \"palette\": { \"primary\": { \"main\": \"#311b92\" }, \"secondary\": { \"main\": \"#0097a7\" }, \"tertiary\": { \"main\": \"#f57c00\" }, \"quaternary\": { \"main\": \"#d50000\" }}}")
})
