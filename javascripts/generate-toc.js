function generateTOC(insertBefore, heading) {
  var container = jQuery("<div id='tocBlock'></div>");
  var div = jQuery("<ul id='toc'></ul>");
  
  var content = $(insertBefore).first();

  if (heading != undefined && heading != null) {
    container.append('<span class="tocHeading">' + heading + '</span>');
  }

// div.tableOfContents(content);
  div.toc({content: content, headings: "h2,h3,h4"});
  container.append(div);
  container.insertBefore(insertBefore);
}