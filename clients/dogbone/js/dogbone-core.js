/*
 * Dogbone core functionality for handling navigation
 */

window.Dogbone = {
  pageRoot: null,
  pages: Array("dummyItem"),
  currentHash: "",
  page: { id: "", title: "", param: false},
  init: function(root) {
    var rootObj = document.getElementById(root);
    if(rootObj) {
      Dogbone.pageRoot = rootObj;
      Dogbone.findPages();
      $(Dogbone.pages).each(function(id,el) { Dogbone.hidePage(el); });
      setInterval(Dogbone.checkLocation, 300);
    }
  },
  /* Go through children of root object and assign as pages */
  findPages: function() {
    $(Dogbone.pageRoot).children().each(function(i, el) {
      if(el.id) {
        Dogbone.pages.push(el.id);
      }
    });
  },
  showPage: function(pageID, param) {
    var pageObj = $("#"+pageID);
    if(pageObj && ($.inArray(pageID, Dogbone.pages))) {
      Dogbone.hidePage(Dogbone.page.id);
      Dogbone.page.id    = pageID;
      Dogbone.page.title = pageObj.attr('title');
      Dogbone.page.param = param;
      pageObj.show();
      
      $(document).trigger("Page."+pageID);
    }
  },
  hidePage: function(pageID) {
    if(pageID) {
      $('#'+pageID).hide();
    }
  },
  /* Continously monitor location */
  checkLocation: function() {
    if(location.hash != Dogbone.currentHash) {
      var hash = location.hash.substr(1);
      var ppos, pageId, param;

      ppos = hash.indexOf("/");
      if(ppos >= 0) {
        pageId = hash.substring(0, ppos);
        param  = hash.substring(ppos+1);
      } else {
        pageId = hash;
        param  = "";
      }
      Dogbone.currentHash = location.hash;
      Dogbone.showPage(pageId, param);
    }    
  }
};

window.onload = function() {
  Dogbone.init("content");
}