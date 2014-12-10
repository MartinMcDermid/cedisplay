$(document).ready(
         function() {
          setInterval(function() {
            $('.status-partial').load('/index/status_partial');
        }, 3000);
    });
