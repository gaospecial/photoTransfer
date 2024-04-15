library(shiny)
library(DT)

# 假定的数据集
my_data <- data.frame(
  ID = 1:100,
  Value = sample(LETTERS, 100, replace = TRUE)
)

# Shiny应用UI部分
ui <- fluidPage(
  # 客户端的JavaScript代码将在收到上面的custom message后执行
  includeScript("www/datatable.js"),
  titlePanel("DataTable with SliderInput Example"),
  fluidRow(
    column(
      4,
      sliderInput(
        "row_id",
        "Select a row ID:",
        min = 1,
        max = nrow(my_data),
        value = 1
      )
    )
  ),
  DTOutput("my_datatable")
)

server <- function(input, output, session) {

  # 渲染DT
  output$my_datatable <- renderDT({
    datatable(my_data, selection = 'single', options = list(pageLength = 10, lengthChange = FALSE))
  }, server = FALSE)

  # 监听滑块变化事件
  observeEvent(input$row_id, {
    # 数据表格代理
    proxy <- dataTableProxy('my_datatable')

    # 选择行
    selectRows(proxy, input$row_id)

    # 向客户端传递信息
    session$sendCustomMessage(type = 'jumpTo', list(container = "my_datatable", index = input$row_id - 1))
    # showNotification(input$row_id)
  })



}

# 启动Shiny应用
shinyApp(ui, server)
