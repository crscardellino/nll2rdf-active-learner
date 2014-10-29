$(window).load(function() {
  $.get("/query/" + iteration,
    {},
    function(data) {
      $("#queries").empty();
      $("#queries").append(data);
      $("#query-features").removeClass("hidden");

      $(".query-classes option").mousedown(function(){
         var $self = $(this);

         if ($self.prop("selected"))
            $self.prop("selected", false);
         else
            $self.prop("selected", true);

         return false;
      });


      $("#annotate").click(function(event) {
        event.preventDefault();
        $("#annotate").button("loading");
        queries = {};

        $.each($(".query-classes"), function(index, value) {
          var id = $(value).attr("id");
          queries[id] = $(value).val();
        });

        $.post("/annotate/" + iteration,
          JSON.stringify(queries),
          function(data) {
            if(data == "OK") {
              alert("Todo bien!");
              $("#annotate").button("reset");
            }
          }
        );
      });
    }
  );
});