;(function ($, window, document, undefined) {
  'use strict';

  var settings = {
        callback: $.noop,
        init: false
      }, 

      methods = {
        init : function (options) {
          settings = $.extend({}, options, settings);

          return this.each(function () {
            if (!settings.init) methods.events();
          });
        },

        events : function () {
          $(document).on('click.fndtn', '.tabs a', function (e) {
            methods.set_tab($(this).parent('dd, li'), e);
          });
          
          settings.init = true;
        },

        set_tab : function ($tab, e) {
          var $activeTab = $tab.closest('dl, ul').find('.active'),
              target = $tab.children('a').attr("href"),
              hasHash = /^#/.test(target),
              $content = $(target + 'Tab');

          if (hasHash && $content.length > 0) {
            // Show tab content
            e.preventDefault();
            $content.closest('.tabs-content').children('li').removeClass('active').hide();
            $content.css('display', 'block').addClass('active');
          }

          // Make active tab
          $activeTab.removeClass('active');
          $tab.addClass('active');

          settings.callback();
        }
      }

  $.fn.foundationTabs = function (method) {
    if (methods[method]) {
      return methods[method].apply(this, Array.prototype.slice.call(arguments, 1));
    } else if (typeof method === 'object' || !method) {
      return methods.init.apply(this, arguments);
    } else {
      $.error('Method ' +  method + ' does not exist on jQuery.foundationTabs');
    }
  };
}(jQuery, this, this.document));

;(function ($, window, undefined){
  'use strict';

  $.fn.foundationAccordion = function (options) {

    // DRY up the logic used to determine if the event logic should execute.
    var hasHover = function(accordion) {
      return accordion.hasClass('hover') && !Modernizr.touch
    };

    $(document).on('mouseenter', '.accordion li', function () {

        var p = $(this).parent();

        if (hasHover(p)) {
          var flyout = $(this).children('.content').first();

          $('.content', p).not(flyout).hide().parent('li').removeClass('active');
          flyout.show(0, function () {
            flyout.parent('li').addClass('active');
          });
        }
      }
    );

    $(document).on('click.fndtn', '.accordion li .title', function () {
        var li = $(this).closest('li'),
            p = li.parent();
       
        if(!hasHover(p)) {
          var flyout = li.children('.content').first();

          if (li.hasClass('active')) {
            p.find('li').removeClass('active').end().find('.content').hide();
          } else {
            $('.content', p).not(flyout).hide().parent('li').removeClass('active');
            flyout.show(0, function () {
              flyout.parent('li').addClass('active');
            });
          }
        }
      }
     );

  };

})( jQuery, this );