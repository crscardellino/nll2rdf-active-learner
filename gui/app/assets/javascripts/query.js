$(window).load(function() {
  $.get("/query/" + iteration,
    {},
    function(data) {
      $("#queries").empty();
      $("#queries").append(data);
      $("#query-instances").removeClass("hidden");
      $(window).scrollTop(0);

      $('.query-classes').each(function(){
          var select = $(this), values = {};
          $('option',select).each(function(i, option){
              values[option.value] = option.selected;
          }).click(function(event){
              values[this.value] = !values[this.value];
              $('option',select).each(function(i, option){
                  option.selected = values[option.value];
              });
          });
      });

      $("#retrain").click(function(event) {
        event.preventDefault();
        $("#retrain").button("loading");
        queries = {};

        var error = false;

        $.each($(".query-classes"), function(index, value) {
          var id = $(value).attr("id");
          queries[id] = $(value).val();

          error = error || (queries[id] === null);
        });

        if(error) {
          alert("You have to select at least one class for each instance");
          $("#retrain").button("reset");
        } else {
          $.ajax({
            type: "POST",
            dataType: "json",
            contentType: "application/json",
            data: JSON.stringify(queries),
            url: "/annotate/" + iteration
          }).done(function(data) {
             window.location.href = "/retrain/" + iteration;
           }).fail(function(data) {
             alert(data.responseText);
             $("#retrain").button("reset");
           });
        }
      });

      $("#retrain-no-feedback").click(function(event) {
        event.preventDefault();
        $("#retrain-no-feedback").button("loading");
        queries = {};

        var error = false;

        $.each($(".query-classes"), function(index, value) {
          var id = $(value).attr("id");
          queries[id] = $(value).val();

          error = error || (queries[id] === null);
        });

        if(error) {
          alert("You have to select at least one class for each instance");
          $("#retrain-no-feedback").button("reset");
        } else {
          $.ajax({
            type: "POST",
            dataType: "json",
            contentType: "application/json",
            data: JSON.stringify(queries),
            url: "/annotate/" + iteration
          }).done(function(data) {
             window.location.href = "/nofeedretrain/" + iteration;
           }).fail(function(data) {
             alert(data.responseText);
             $("#retrain-no-feedback").button("reset");
           });
        }
      });

      $("#feedback").click(function(event) {
        event.preventDefault();
        $("#feedback").button("loading");
        queries = {};

        var error = false;

        $.each($(".query-classes"), function(index, value) {
          var id = $(value).attr("id");
          queries[id] = $(value).val();

          error = error || (queries[id] === null);
        });

        if(error) {
          alert("You have to select at least one class for each instance");
          $("#feedback").button("reset");
        } else {
          $.ajax({
            type: "POST",
            dataType: "json",
            contentType: "application/json",
            data: JSON.stringify(queries),
            url: "/annotate/" + iteration
          }).done(function(data) {
             window.location.href = "/features/" + iteration;
           }).fail(function(data) {
             alert(data.responseText);
             $("#retrain").button("reset");
           });
        }
      });
    }
  );
});