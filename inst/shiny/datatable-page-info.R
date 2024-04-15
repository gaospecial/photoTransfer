library(shiny)
library(DT)

ui <- fluidPage(
  DTOutput("myTable", ), # 用于展示DataTable的UI组件
  verbatimTextOutput("info") # 用于显示与DataTable相关变量的UI组件
)

server <- function(input, output) {
  # 假设我们有一些数据
  set.seed(1)
  myData <- reactive({
    data.frame(
      Number = 1:100,
      Letter = sample(LETTERS, 100, replace = TRUE)
    )
  })

  # 渲染DataTable
  output$myTable <- renderDT({
    datatable(myData(), selection = 'single', callback = JS("
              table.on('draw.dt', function () {
                var currentPageInfo = table.page.info()
                Shiny.setInputValue('myTable_page_info', currentPageInfo);
              })
              table.on('click', 'tr', function(){
                var index = $(this).index()
                Shiny.setInputValue('myTable_index', index)
              })
              "))
  })

  # 显示DataTable相关的输入值
  output$info <- renderPrint({
    str(list(
      input = reactiveValuesToList(input),
      rows_selected = input$myTable_rows_selected,
      search = input$myTable_search,
      columns_search = input$myTable_columns_search,
      display_start = input$myTable_display_start,
      rows_current = input$myTable_rows_current, # the indices of rows on the current page
      tableId_rows_all = input$myTable_rows_all, # the indices of rows on all pages (after the table is filtered by the search strings)
      tableId_cell_clicked = input$myTable_cell_clicked, #  information about the cell being clicked of the form
      page_info = input$myTable_page_info,
      index = input$myTable_index,
      table_length = input$myTable_length
    ))
  })
}

shinyApp(ui, server)
