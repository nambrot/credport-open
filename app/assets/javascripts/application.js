// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
// WARNING: THE FIRST BLANK LINE MARKS THE END OF WHAT'S TO BE PROCESSED, ANY BLANK LINE SHOULD
// GO AFTER THE REQUIRES BELOW.
//
// = require jquery
// = require jquery_ujs
//= require i18n
//= require i18n/translations

function reloadStylesheets() {
    var queryString = '?reload=' + new Date().getTime();
    $('link[rel="stylesheet"]').each(function () {
        this.href = this.href.replace(/\?.*|$/, queryString);
    });
}

var isCtrl = false;
var isShift = false;

$(document).ready(function() {
    
    // action on key up
    $(document).keyup(function(e) {
        if(e.which == 17) {
            isCtrl = false;
        }
        if(e.which == 16) {
            isShift = false;
        }
    });
    // action on key down
    $(document).keydown(function(e) {
       
        if(e.which == 17) {
            isCtrl = true; 
        }
        if(e.which == 16) {
            isShift = true; 
        }
        if(e.which == 82 && isCtrl) { 
          
           reloadStylesheets();
        } 
    });
     
});