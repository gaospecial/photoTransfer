library(shiny)
library(markdown)

markdown_text <- "

`renderImage` 默认会将图像以 `base64` 编码形式嵌入超文本标记语言（HTML）输出中，为了避免这一点，您需要使用 Shiny 应用程序的目录结构。

Shiny 应用程序有一个名为 `www` 的特殊子目录，可以将其用作静态资源的存放目录。当您将图片放入 `www` 目录时，Shiny 会自动将该目录的内容提供为可通过 web 访问的资源。这意味着您可以通过一个 URL 直接引用 `www` 目录中的内容。

这里是如何在 Shiny 应用中使用 `www` 目录提供图片而不使用 `base64` 编码：

- 把你的图片文件放入 Shiny 应用的 `www` 目录中。
- 在服务器逻辑中使用图片相对于 `www` 目录的路径。
- 在 Shiny UI 中使用 `img` 标签的 `src` 属性来指向该图片。

"

ui <- fluidPage(
  # 展示图片的UI元素
  imageOutput("renderedImage", inline = TRUE),
  uiOutput('linkedImage', inline = TRUE),

  HTML(markdownToHTML(markdown_text))
)

server <- function(input, output, session) {
  # 假设我们有一张图片位于www/目录下
  # 这个目录是应用程序的静态资源目录
  img_path <- "www/images/1.jpg"

  output$renderedImage <- renderImage({
    # 返回列表包含src路径和其他属性，这会生成图片的URL而不是嵌入图片
    list(src = img_path,
         contentType = 'image/jpg',
         alt = "This is an rendered image", # 可选的，设置图片不可用时的替代文本
         width = "40%"
    )
  }, deleteFile = FALSE) # 不删除文件，因为我们使用的是静态资源

  output$linkedImage <- renderUI({
    # 使用HTML标签来创建img元素
    tags$img(src = "images/1.jpg", alt = "This is an linked image", width = "40%")
  })
}

# 运行Shiny应用
shinyApp(ui = ui, server = server)
