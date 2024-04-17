library(shiny)
library(DT)
library(readr)
library(shinyjs)

ui <- fluidPage(
  useShinyjs(),

  tags$head(
    tags$script(src = "jquery.zoom.min.js"),
    tags$script(src = "script.js"),
    tags$link(rel = "stylesheet", type = "text/css", href = "shiny.css")
  ),

  titlePanel("图片标注工具"),

  sidebarLayout(
    sidebarPanel(width = 6,
      # TODO: 从文件夹读取待注释数据

      # 上传处理列表
      fileInput("fileInput", "选择标注 CSV 文件"),
      DTOutput("dataTable"),
      hr(),
      # 添加下载链接
      downloadButton("save", "下载当前标注"),
    ),

    mainPanel(width = 6,
      fluidRow(imageOutput("imageDisplay", width = "500px", height = "auto")),
      fluidRow(textOutput("current_image"), width = "500px"),
      fluidRow(textInput("imageLabel", "修改标注", "", width = "500px")),
      fluidRow(
        column(width = 3, actionButton("prev_photo", "上一张", icon = icon("arrow-left"))),
        column(width = 3, actionButton("next_photo", "下一张", icon = icon("arrow-right")))
      )
    )
  )
)

server <- function(input, output, session) {
  # 初始化反应式变量
  annotations = reactiveVal()
  current_index <- reactiveVal()

  # example annotation
  example_annotation = data.frame(
    image_path = list.files("www/images", ".jpg", full.names = TRUE),
    old_label = "",
    current_label = "")

  # 初始化示例数据
  annotations(example_annotation)
  current_index(1L)

  output$dataTable <- renderDT(annotations(), selection = "single", server = TRUE)

  # 处理文件上传并更新标注数据
  observeEvent(input$fileInput, {
    file <- input$fileInput
    if (is.null(file)) return()
    user_data = read_csv(file$datapath, col_types = "c", col_names = c("image_path","old_label"))
    user_data$current_label = ""

    # 在UI中显示标注数据
    output$dataTable <- renderDT(user_data, selection = "single", server = TRUE)
    annotations(user_data)
    current_index(1L)
  })

  # 创建一个 datatable proxy
  dataTableProxy <- dataTableProxy('dataTable')

  # 使用选中的行更新 current_index
  observeEvent(input$dataTable_rows_selected, {
    selected_absolute_index = input$dataTable_rows_selected
    current_index(selected_absolute_index)
  })

  # 输出图片路径
  output$current_image = renderText({
    data = annotations()
    idx = current_index()
    paste0("Filename: ", data$image_path[idx])
  })

  # 切换到上一张图片
  observeEvent(input$prev_photo, {
    idx = current_index()
    indexes = input$dataTable_rows_all
    pos = which(indexes == idx)
    if (length(pos) == 1) {
      if (pos > 1) {
        current_index(indexes[[pos - 1]])
      } else {
      # 如果是第一个元素，那么禁用 prev_photo 按钮
      disable("prev_photo")
      }
    } else {
      disable("prev_photo")
    }
  })

  # 切换到下一张图片
  observeEvent(input$next_photo, {
    idx = current_index()
    indexes = input$dataTable_rows_all
    pos = which(indexes == idx)

    if (length(pos) == 1) {
      if (pos < length(indexes)) {
        current_index(indexes[[pos + 1]])
      } else {
        # 如果是最后一个元素，那么禁用 next_photo 按钮
        disable("next_photo")
      }
    } else {
      disable("next_photo")
    }
  })

  # 响应 search 后的列表
  observeEvent(input$dataTable_search, {
    search = input$dataTable_search
    idx = current_index()
    indexes = input$dataTable_rows_all

    # search result may have no data
    if (length(indexes) < 1) {
      return()
    }

    # 更新页面
    if (idx %in% indexes) {
      targetRow = which(input$dataTable_rows_all == idx)
      targetPage = ceiling(targetRow / input$dataTable_state$length) # 向上取整得到页码
      selectPage(dataTableProxy, targetPage)
    } else {
      current_index(indexes[[1]])
    }

    # 更新按钮状态

  })

  # 响应 index 变化，更新当前图片、dataTable 的显示和按钮状态
  observeEvent(current_index(), {
    data <- annotations()
    idx <- current_index()
    # 更新图片显示
    output$imageDisplay <- renderImage({
      imagePath <- data$image_path[[idx]]
      # 直接从磁盘路径加载图片
      list(src = imagePath, id = "mainImage", width = "100%")
    }, deleteFile = FALSE)

    # 更新 dataTable 状态，高亮显示 idx 的行
    selectRows(dataTableProxy, c(row = idx))

    # 显示对应的页面
    targetRow = which(input$dataTable_rows_all == idx)
    targetPage = ceiling(targetRow / input$dataTable_state$length) # 向上取整得到页码
    selectPage(dataTableProxy, targetPage)

    # 更新 imageLabel
    updateTextInput(session, inputId = "imageLabel", value = data$current_label[[idx]])

    # 更新按钮状态
    indexes = input$dataTable_rows_all
    if (is.null(indexes)) indexes = 1:nrow(data)
    if (!(idx %in% indexes)) {  # search result may have no data
      disable("prev_photo")
      disable("next_photo")
    } else if (idx == indexes[[1]]) {
      disable("prev_photo")
      enable("next_photo")
    } else if (idx == indexes[[length(indexes)]]) {
      enable("prev_photo")
      disable("next_photo")
    } else {
      enable("prev_photo")
      enable("next_photo")
    }
  })

  # 监听imageLabel输入并更新标注
  observeEvent(input$imageLabel, {
    idx = current_index()
    data <- annotations()
    data[idx, "current_label"] = input$imageLabel
    annotations(data) # 更新标注数据

    # 同步更新 dataTable
    replaceData(dataTableProxy, data, resetPaging = FALSE, clearSelection = "none")
  })

  # 处理标注保存逻辑
  output$save <- downloadHandler(
    filename = function() {
      paste0("annotations_updated_", Sys.Date(), ".csv")
    },
    content = function(file) {
      write.csv(annotations(), file, row.names = FALSE)
    }
  )

  # Ensure that the zoom is set up after the app has flushed its output
  session$onFlushed(function() {
    session$sendCustomMessage(type = 'triggerZoom', message = list())
    session$sendCustomMessage(type = 'focusImageLabel', message = list())
  }, once = FALSE)

}

shinyApp(ui, server)
