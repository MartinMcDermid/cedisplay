$(document).ready(
         function() {
          setInterval(function() {
            $('.interviews-partial').load('/index/interviews_partial');
        }, 20000);
    });
