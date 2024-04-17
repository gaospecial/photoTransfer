run_photo_label_tool = function() {
  app = system.file("shiny", "photo-label-tool.R", package = "photoTransfer", mustWork = TRUE)
  if(interactive()) shiny::runApp(app)
}
