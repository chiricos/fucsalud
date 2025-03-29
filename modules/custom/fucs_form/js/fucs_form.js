(function($) {

  /**
   * CALCULA EL TIEMPO
   */

  var tiempo = {
    hora: 0,
    minuto: 0,
    segundo: 0
  };
  var limit = $('.timeout').val();

  tiempo_corriendo = setInterval(function(){
    // Segundos
    tiempo.segundo++;
    if (tiempo.segundo >= 60) {
        tiempo.segundo = 0;
        tiempo.minuto++;
    }

    // Minutos
    if (tiempo.minuto >= 60) {
        tiempo.minuto = 0;
        tiempo.hora++;
    }

    var totalSegundo = (tiempo.hora*3600) + (tiempo.minuto*60) + tiempo.segundo;

    if (totalSegundo >= limit) {
      window.location.replace("/fucs/formulario/limite-de-tiempo");
    }

    $(".fucs-hour").text(tiempo.hora < 10 ? '0' + tiempo.hora : tiempo.hora);
    $(".fucs-minute").text(tiempo.minuto < 10 ? '0' + tiempo.minuto : tiempo.minuto);
    $(".fucs-second").text(tiempo.segundo < 10 ? '0' + tiempo.segundo : tiempo.segundo);
  }, 1000);

  /**
   * Visualizador de preguntas
   */

  $('.form-fucs-submit').removeClass('button');

  var totalQuestions = $('.form-question').length;
  var selectQuestion = 0;

  $('.fucs-prev').hide();
  $('.fucs-next').hide();

  if (totalQuestions > 0) {
    showForm();
  }

  $('.fucs-next').click(function() {
    next();
  });

  $('.fucs-prev').click(function() {
    prev();
  });

  $('.form-fucs-submit').click(function() {
    $(this).hide();
  });

  function next() {
    if (totalQuestions > (selectQuestion + 1)) {
      selectQuestion++;
      showForm();
    }
  }

  function prev(){
    if (0 < selectQuestion) {
      selectQuestion--;
      showForm();
    }
  }

  function showForm() {

    $('.form-question').hide();
    $('.form-fucs-submit').hide();
    $('.question-selected').text("Pregunta " + (selectQuestion + 1) + " de " + totalQuestions);

    if (selectQuestion == 0) {
      $('.fucs-prev').hide();
    }
    else {
      $('.fucs-prev').show();
    }

    if (totalQuestions == (selectQuestion + 1)) {
      $('.fucs-next').hide();
      $('.form-fucs-submit').show();
    }
    else {
      $('.fucs-next').show();
    }

    $( ".form-question" ).each(function( index ) {
      if (index == selectQuestion) {
        $(this).show();
      }
      else{
        $(this).hide();
      }
    });

  }

  $('.tree').hide();
  $('.tree:first').show();
  $('.tree:nth-child(2)').show();


  $('.tree-year').click(function() {
    $('.tree').hide();
    $('.tree-year').removeClass('tree-year-selected');
    $('.tree-'+$(this).text()).show();
    $(this).addClass('tree-year-selected');
  });
  $('.tree-year:first').addClass('tree-year-selected');

})(jQuery);