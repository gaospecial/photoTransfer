library(shiny)
library(DT)
library(readr)
library(shinyjs)

ui <- fluidPage(
  useShinyjs(),
  includeCSS("www/shiny.css"),
  titlePanel("图片标注工具"),

  sidebarLayout(
    sidebarPanel(width = 6,
      fileInput("fileInput", "选择标注 CSV 文件"),
      DTOutput("dataTable"),
      hr(),
      # 添加下载链接
      downloadLink("save", "下载标注"),
      # 隐藏的输入，用于接收current_index的更新
      tags$div(style = "display: none;", numericInput("current_index", "current_index", value = 1, min = 1))
    ),

    mainPanel(width = 6,
      imageOutput("imageDisplay", click = "image_click"),
      textOutput("current_image"),
      fluidRow(
        column(2, align = "left", actionButton("prev_photo", "上一张", icon = icon("arrow-left"))),
        column(2, align = "center", textInput("imageLabel", NULL, "")),
        column(2, align = "right", actionButton("next_photo", "下一张", icon = icon("arrow-right")))
      )
    )
  )
)

server <- function(input, output, session) {
  # 存储图片数据和标注的反应性值
  annotations <- reactiveVal(data.frame(image_path = "", old_label = "", current_label = ""))
  current_index <- reactiveVal()

  # 处理文件上传并更新标注数据
  observeEvent(input$fileInput, {
    file <- input$fileInput
    if (is.null(file)) return()
    user_data = read_csv(file$datapath)
    colnames(user_data) = c("image_path","old_label")
    user_data$current_label = user_data$old_label
    annotations(user_data)
    current_index(1)
  })

  # 在UI中显示标注数据
  output$dataTable <- renderDT({
    datatable(annotations(), selection = "none", escape = FALSE, callback = JS("
            table.on('click', 'tr', function () {
                $(this).toggleClass('selected').siblings().removeClass('selected');
                var data = table.row(this).data();
                if (data) {
                    Shiny.setInputValue('table_click', data[1]);
                    // 获取当前行的索引（注意：索引是从0开始的）
                    var index = table.row(this).index();
                    // 通过Shiny.setInputValue更新current_index
                    Shiny.setInputValue('current_index', index + 1); // 索引+1以匹配R中的1-based索引
                }
            });
        "),
        #
        options = list(rowCallback = JS("
                function(row, data, displayNum, displayIndex, dataIndex) {
                  if (dataIndex === ", current_index(), " - 1) {
                    $(row).addClass('selected');
                  } else {
                    $(row).removeClass('selected');
                  }
                }
            "))
    )
  })

  output$current_image = renderText({
    data = annotations()
    idx = current_index()
    paste0("Filename: ", data$image_path[[idx]])
  })

  # 切换到上一张图片
  observeEvent(input$prev_photo, {
    idx <- current_index()
    if(idx > 1) {
      current_index(idx - 1)
      # 同步更新dataTable中加粗显示的行
    } else {
      # 如果是第一个元素，那么禁用 prev_photo 按钮
      disable("prev_photo")
    }
    # 将 imageLabel 更新为 current_label
  })

  # 切换到下一张图片
  observeEvent(input$next_photo, {
    data <- annotations()
    idx <- current_index()
    if(idx < nrow(data)) {
      current_index(idx + 1)
      # 同步更新dataTable中加粗显示的行
    } else {
      # 如果是最后一个元素，那么禁用 next_photo 按钮
      disable("next_photo")
    }
  })

  # 响应 index 变化，更新当前图片、dataTable 的显示和按钮状态
  observeEvent(current_index(), {
    data <- annotations()
    idx <- current_index()
    # 更新图片显示
    output$imageDisplay <- renderImage({
      imagePath <- data$image_path[[idx]]
      # showNotification(imagePath)
      # 直接从磁盘路径加载图片
      list(src = imagePath, width = "400px")
    }, deleteFile = FALSE)

    # 更新 dataTable 状态，高亮显示 idx 的行
    dataTableProxy <- dataTableProxy('dataTable')
    selectRows(dataTableProxy, idx, select = TRUE)

    # 更新 imageLabel
    updateTextInput(session, inputId = "imageLabel", value = data$current_label[[idx]])

    # 更新按钮状态
    if (idx == 1) {
      disable("prev_photo")
    } else {
      enable("prev_photo")
    }
    if (idx == nrow(data)) {
      disable("next_photo")
    } else {
      enable("next_photo")
    }
  })


  # 观察current_index的变化并更新
  observeEvent(input$current_index, {
    # 更新current_index的值
    current_index(input$current_index)
    # 可能还需要在这里添加其他代码，比如更新图片显示或按钮状态
  })

  # 监听imageLabel输入并更新标注
  observeEvent(input$imageLabel, {
    data <- annotations()
    idx <- current_index()
    data[idx, "current_label"] <- input$imageLabel
    annotations(data) # 更新标注数据
    current_index(idx)
  })

  # 当 annotation 更新时，同步更新 dataTable
  observeEvent(annotations(), {
    data = annotations()
    idx = current_index()

    # 用新数据替换旧数据
    replaceData(dataTableProxy('dataTable'), data)

    # 将 idx 对应的行加上 .selected 类
    dataTableProxy <- dataTableProxy('dataTable')
    selectRows(dataTableProxy, idx, select = TRUE)

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



}

shinyApp(ui, server)
