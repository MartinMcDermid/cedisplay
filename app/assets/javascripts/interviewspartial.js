$(document).ready(
         function() {
          setInterval(function() {
            $('.interviews-partial').load('/index/interviews_partial');
        }, 60000);
    });
