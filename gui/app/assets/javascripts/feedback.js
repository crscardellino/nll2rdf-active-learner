$(window).load(function() {
  $.get("/listfeatures/" + iteration,
    {},
    function(data) {
      $("#queries").empty();
      $("#queries").append(data);
      $("#feature-feedback").removeClass("hidden");
      $(window).scrollTop(0);

      $('.query-features').each(function(){
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

        $.each($(".query-features"), function(index, value) {
          var id = $(value).attr("id");
          if($(value).val() !== null) {
            queries[id] = $(value).val();
          } else {
            queries[id] = [];
          }
        });

        console.log(JSON.stringify(queries));

        $.ajax({
          type: "POST",
          dataType: "json",
          contentType: "application/json",
          data: JSON.stringify(queries),
          url: "/feedback/" + iteration
        }).done(function(data) {
           window.location.href = "/retrain/" + iteration + "?feedbackSize=-1";
         }).fail(function(data) {
           alert(data.responseText);
           $("#retrain").button("reset");
         });
      });
    }
  );
});