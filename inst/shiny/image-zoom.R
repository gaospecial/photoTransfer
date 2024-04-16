library(shiny)

ui <- fluidPage(
  tags$head(
    # tags$script(src = "jquery.zoom.js"),
    tags$script(src = "jquery.zoom.min.js"),
    tags$script(src = "script.js"),
    tags$link(rel = "stylesheet", type = "text/css", href = "shiny.css")
  ),

  # The image container with zoom
  imageOutput("imageDisplay", width = '400px', height = "400px")
)

server <- function(input, output, session) {

  # Server-oriented image URL
  imageURL <- "www/images/1.jpg"

  output$imageDisplay <- renderImage({
    # Return null if the URL is missing
    if (is.null(imageURL)) {
      return(NULL)
    }
    # Return an image list
    list(id = "mainImage", src = imageURL)
  }, deleteFile = FALSE)

  # Ensure that the zoom is set up after the app has flushed its output
  session$onFlushed(function() {
    session$sendCustomMessage(type = 'triggerZoom', message = list())
  }, once = TRUE)

}

shinyApp(ui, server)
