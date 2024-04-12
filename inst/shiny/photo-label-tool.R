library(shiny)
library(DT)
library(readr)

ui <- fluidPage(
  titlePanel("图片标注工具"),

  sidebarLayout(
    sidebarPanel(width = 6,
      fileInput("fileInput", "选择标注 CSV 文件"),
      DTOutput("dataTable"),
      hr(),
      actionButton("save", "保存当前标注")
    ),

    mainPanel(width = 6,
      imageOutput("imageDisplay"),
      textOutput("current_image"),
      textInput("imageLabel", "图片标注", "")
    )
  )
)

server <- function(input, output, session) {

  # 存储图片数据和标注的反应性值
  annotations <- reactiveVal()

  # 处理文件上传并更新标注数据
  observeEvent(input$fileInput, {
    file <- input$fileInput
    if (is.null(file)) return()
    user_data = read_csv(file$datapath)
    colnames(user_data) = c("image_path","old_label")
    user_data$new_label = ""
    annotations(user_data)
  })

  # 在UI中展示图片和标注
  output$dataTable <- renderDT({
    datatable(annotations(), selection = 'none', escape = FALSE, callback = JS("
            table.on('click', 'tr', function () {
                var data = table.row(this).data();
                if (data) {
                    Shiny.setInputValue('image_click', data[1]);
                }
            });
        "))
  })

  # 根据点击事件显示图片
  output$imageDisplay <- renderImage({
    clickData <- input$image_click
    if (is.null(clickData))
      return(NULL)
    showNotification(clickData, duration = NULL)
    imagePath <- clickData
    # 直接从磁盘路径加载图片
    list(src = imagePath, width = "400px")
  }, deleteFile = FALSE)

  # 更新文本输入的值为当前图片的标注
  observe({
    clickData <- input$image_click
    #showNotification(clickData, duration = NULL)
    if (!is.null(clickData)) {
      data <- annotations()
      row <- data[data$image_path == clickData, ]
      if (nrow(row) > 0) {
        updateTextInput(session, "imageLabel", value = row$new_label[1])
      }
    }
  })

  # 处理标注保存逻辑
  observeEvent(input$save, {
    write_csv(annotations(), file = sprintf("annotations_updated_%s.csv", Sys.Date()))
  })

  # 处理自动保存逻辑
  observe({
    # 自动保存逻辑代码将放置于此处
  })
}

shinyApp(ui, server)
