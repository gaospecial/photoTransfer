$(document).ready(function() {
  Shiny.addCustomMessageHandler('jumpTo', function(msg) {
      var table = $('#' + msg.container + ' table').DataTable();
      var index = table.rows().indexes().indexOf(msg.index);

      // 计算页码
      var page_length = table.page.info().length;
      var page = Math.floor(index / page_length);

      // log
      console.log('msg:', msg);
      console.log('indexes:', table.rows().indexes());
      console.log('index:', index);
      console.log('page_length:', page_length);
      console.log('page:', page);

      // 跳转到指定页码
      table.page(page).draw(false);
    });
});
