$(window).on('load', function () {
    $('.flexslider').flexslider({
        animation: "slide",
        controlNav: true
    });
    $('.testimonioslider').flexslider({
        animation: "slide",
        controlNav: true
    });
});


$(document).ready(function(){

 
    $('.volumen-articulo a').text('Ver más');
	$(".volumen-articulo a").click(function() {
	      url = $(this).attr("href");
	      window.open(url, '_blank');
	      return false;
	});

	$('.continuada-menu-contenido ul > li > a').prepend('<span></span>');
	$('.aspirante-sub-menu ul li').prepend('<span></span>');

	
    var pag = $( window );
    
    
    pag.scroll(function() {
        if($('.slider .flexslider').length > 0 ){
            var altoSlider = $('.slider .flexslider').height();
        }else{
            var altoSlider = 0;
        }
        if(pag.scrollTop() <= 20 ){
            $(".menu-second").show("fast");
            $(".inscribete h4").show("fast");
            $("header").removeClass('scroll-header');
            $(".slider").removeClass('scroll-slider');
            $(".logo").removeClass('scroll-logo');
            $(".menu ul li a").removeClass('scroll-menu');
            $(".social").removeClass('scroll-social');
            $(".social a").removeClass('scroll-social-a');
            $(".inscribete").removeClass('scroll-inscribete');
            $(".menu ul").removeClass('scroll-menu-primary');
            $('.form-inscribirse').removeClass('scroll-form-inscribete');
            $('.menu-top').removeClass('scroll-menu-top');
            $('.menu-first ul li').removeClass('scroll-menu-first');
            $('.menu-item--expanded').addClass('icon-down-dir');
        }else{
            $(".menu-second").hide("fast");
            $(".inscribete h4").hide("fast");
            $("header").addClass('scroll-header');
            $("header").addClass('animated');
            $(".slider").addClass('scroll-slider');
            $(".slider").addClass('animated');
            $(".logo").addClass('scroll-logo');
            $(".logo").addClass('animated');
            $(".menu ul li a").addClass('scroll-menu');
            $(".social").addClass('scroll-social');
            $(".social").addClass('animated');
            $(".social a").addClass('scroll-social-a');
            $(".social a").addClass('animated');
            $(".inscribete").addClass('scroll-inscribete');
            $(".inscribete").addClass('animated');
            $(".menu ul").addClass('scroll-menu-primary');
            $(".menu ul").addClass('animated');
            $('.form-inscribirse').addClass('scroll-form-inscribete');
            $('.menu-top').addClass('scroll-menu-top');
            $('.menu-first ul li').addClass('scroll-menu-first');
            $('.menu-item--expanded'). removeClass('icon-down-dir');
        }
        if(pag.scrollTop() > altoSlider && altoSlider > 100){
            $('.all-sub-menu').addClass('aspirante-menu-scroll');
        }else{
            $('.all-sub-menu').removeClass('aspirante-menu-scroll');
        }
    });

    ////TABLET


    //ABRIR MENU

    var j=0;
    $('.inscribete').on('click',function () {
        if(j == 0){
            $('.form-inscribirse').fadeIn();
            $('.search-block-form').fadeIn();
            $(this).fadeOut();
            j++;
        }else{
            $('.form-inscribirse').fadeOut();
            $('.search-block-form').fadeOut();
            $('.block-search').fadeOut();
            j=0;
        }
    });
    $('.inscribete-mobil-top').on('click',function () {
        if(j == 0) {
            $('.form-inscribirse').fadeIn();
            j++;
        }
    });
    var ancho = $('body').width();
    $('.form-inscribirse .form-submit:last-child').on('click',function () {
        $('.form-inscribirse').hide();
        $('.search-block-form').hide();
        $('.block-search').hide();
        if(ancho > 980){
            $('.inscribete').fadeIn();
        }
        j=0;
    });

    $('.form-inscribirse span').on('click',function () {
        $('.form-inscribirse').hide();
        $('.search-block-form').fadeOut();
        $('.block-search').fadeOut();
        if(ancho > 980){
            $('.inscribete').fadeIn();
        }
        j=0;
    });

    var i=0;
    $('.menu-mobil img').on('click',function () {
        if(i == 0){
            $('.mobil-open').hide();
            $('.mobil-close').show();
            $('.menu-desplegable').show();
            i++;
        }else{
            $('.mobil-open').show();
            $('.mobil-close').hide();
            $('.menu-desplegable').hide();
            i=0;
        }

    });


    //seccion de videos y encuestas

    $('.tabs a').on('click',function () {
        $('.tabs a').removeClass('active');
        $(this).addClass('active');
    })

    $('.menu-noticias').on('click',function () {
        $('.sub-seccion').hide();
        $('.sub-eventos').hide();
        $('.sub-noticias').show();
    });

    $('.menu-eventos').on('click',function () {
        $('.sub-seccion').hide();
        $('.sub-noticias').hide();
        $('.sub-eventos').show();
    })

    $('.menu-encuestas').on('click',function () {
        $('.sub-seccion').hide();
        $('.sub-noticias').hide();
        $('.sub-encuestas').show();
    })

    $('.menu-videos').on('click',function () {
        $('.sub-seccion').hide();
        $('.sub-noticias').hide();
        $('.sub-videos').show();
    })

    $('.form-inscribirse #edit-name').attr("placeholder", "*Nombre:");
    $('.form-inscribirse .form-email').attr("placeholder", "*Email:");
    $('.form-inscribirse #edit-subject-0-value').attr("placeholder", "*Teléfono:");
    $('.form-inscribirse form textarea').attr("placeholder", "*Mensaje:");
    $('.form-inscribirse .form-submit:last-child').val("CANCELAR");
    $('.form-inscribirse .form-submit:first-child').val("ENVIAR");
    $('.gtranslate select').addClass('notranslate');


    /*
    * LABORATORIOS
    * */

    $('.content-laboratorios').on('click',function () {
        var elem = $(this).index();
        $('.laboratorios-mapa img').hide();
        $('.laboratorios-mapa img').eq(elem).show();
    });

    var i=0;
    var j=0;
    var k=0;
    $('.footer-menu .a-sedes').on('click',function () {
        $('.footer-menu a').removeClass('active');
        $(this).addClass('active');
        var elem = $(this).index();
        switch (elem) {
            case 0:
                if(i == 0){
                    $('.laboratorios').hide();
                    $('.sedes').show();
                    $('.auditorios').hide();
                    $('.chat').addClass('chatLabo');
                    $('footer').addClass('footerLabo');
                    $('.footer-menu a').addClass('aLabo');
                    i++;
                    j=0;
                    k=0;
                }else{
                    $('.laboratorios').hide();
                    $('.sedes').hide();
                    $('.auditorios').hide();
                    $('.chat').removeClass('chatLabo');
                    $('footer').removeClass('footerLabo');
                    $('.footer-menu a').removeClass('aLabo');
                    $(this).removeClass('active');
                    i=0;
                    j=0;
                    k=0;
                }
                break;
            
        }

    });

    $('#inputButton').on('click',function () {
        if($('#inputSearch').val() != ""){
            var url= "http://fucsalud.edu.co/search/node?keys="+$('#inputSearch').val();
            $(location).attr('href',url);
        }else{
            $('#inputSearch').css({'border':'1px solid red'});
        }
    });

    $('#inputButton1').on('click',function () {
        if($('#inputSearch1').val() != ""){
            var url= "http://fucs.app/search/node?keys="+$('#inputSearch1').val();
            $(location).attr('href',url);
        }else{
            $('#inputSearch1').css({'border':'1px solid red'});
        }
    });

    var cantVarios = $('.varios .drawde-five').length;
    if(cantVarios > 5){
        $('.varios .drawde-five').hide();
        for (var m = 0; m <5; m++){
            $('.varios .drawde-five').eq(m).show();
        }
    }
    var contVarios = 0;
    var contUltimo = 4;
    var contVariosMobil = 0;
    cantVarios--;
    if(ancho > 980){
        $('.varios-right').on('click',function () {
            if(4 > contVarios && cantVarios > contUltimo){
                $('.varios .drawde-five').eq(contVarios).hide();
                contUltimo++;
                $('.varios .drawde-five').eq(contUltimo).show();
                contVarios++;
            }
        });
        $('.varios-left').on('click',function () {
            console.log(contVarios + "," + contUltimo);
            if(contVarios > 0 && contUltimo > 0){
                $('.varios .drawde-five').eq(contUltimo).hide();
                contVarios--;
                contUltimo--;
                $('.varios .drawde-five').eq(contVarios).show();

            }

        });
    }else{
        $('.varios .drawde-five').css({'width':'100%'});
        $('.varios .drawde-five').hide();
        $('.varios .drawde-five').eq(contVariosMobil).show();
        $('.varios-right').on('click',function () {
            contVariosMobil++;
            if(contVariosMobil < $('.varios .drawde-five').length) {
                $('.varios .drawde-five').hide();
                $('.varios .drawde-five').eq(contVariosMobil).show();
            }else{
                contVariosMobil = $('.varios .drawde-five').length - 1;
            }
        });
        $('.varios-left').on('click',function () {
            contVariosMobil--;
            if(contVariosMobil > 0) {
                $('.varios .drawde-five').hide();
                $('.varios .drawde-five').eq(contVariosMobil).show();
            }else{
                contVariosMobil = 0;
            }

        });
    }


    /*========================================
    SUB MENU ASPIRANTES
    ========================================*/

    var aspirantes=0;
    $('.menu-botton').on('click',function(){
        if(aspirantes == 0){
            $('.all-sub-submenu').fadeIn();
            $('.menu-botton').removeClass('icon-down-dir');
            $('.menu-botton').addClass('icon-up-dir');
            aspirantes++;
        }else{
            $('.all-sub-submenu').fadeOut();
            $('.menu-botton').removeClass('icon-up-dir');
            $('.menu-botton').addClass('icon-down-dir');
            aspirantes=0;
        }
        
    });

    $('.menu-item--expanded'). addClass('icon-down-dir');

    /*========================================
     SUB MENU ASPIRANTES
     ========================================*/

    var programas=0;
    $('.submenu-botton').on('click',function(){
        if(programas == 0){
            $('.ul-submenu-botton').fadeIn();
            $('.submenu-botton').removeClass('icon-down-dir');
            $('.submenu-botton').addClass('icon-up-dir');
            programas++;
        }else{
            $('.ul-submenu-botton').fadeOut();
            $('.submenu-botton').removeClass('icon-up-dir');
            $('.submenu-botton').addClass('icon-down-dir');
            programas=0;
        }

    });

    /**************************************************
    * TESTIMONIOS
    * ************************************************/

    var testimonio = 0;
    $('.testimonio-content').hide();
    $('.testimonio-content').eq(0).show();
    $('.testimonios .left').on('click',function () {
        testimonio--;
        if(testimonio < 0){
            testimonio=0;
        }else{
            $('.testimonio-content').hide();
            $('.testimonio-content').eq(testimonio).fadeIn();
        }
    });
    $('.testimonios .right').on('click',function () {
        testimonio++;
        if(testimonio >= $('.testimonio-content').length){
            testimonio = $('.testimonio-content').length - 1;
        }else{
            $('.testimonio-content').hide();
            $('.testimonio-content').eq(testimonio).fadeIn();
        }
    });

    /**************************************************
    * PATROCINADORES
    * ************************************************/

    var patrocinadores = 2;

    $('.patrocinadores .left').on('click',function () {
        patrocinadores--;
        if(patrocinadores < 2){
            patrocinadores=2;
        }else{
            var patrocinadoresAux = patrocinadores-3;
            $('.patrocinadores ul li').eq(patrocinadores + 1).hide();
            $('.patrocinadores ul li').eq(patrocinadoresAux + 1 ).css({'display':'inline-block'});
        }
    });
    $('.patrocinadores .right').on('click',function () {
        patrocinadores++;
        if(patrocinadores >= $('.patrocinadores ul li').length){
            patrocinadores = $('.patrocinadores ul li').length - 1;
        }else{
            $('.patrocinadores ul li').eq(patrocinadores-3).hide();
            $('.patrocinadores ul li').eq(patrocinadores).css({'display':'inline-block'});
        }
    });

    /**************************************************
     * GALERIA BIENESTAR
     * ************************************************/

    var galeria = 0;
    var galeriaSize = $('.galeria section img').length;
    $('.principal img').hide();
    $('.principal img').eq(0).show();
    $('.galeria .right').on('click',function () {

        if(galeria < galeriaSize -1){
            $('.galeria section img').eq(galeria).hide();
            galeria++;
        }
    });

    $('.galeria .left').on('click',function () {
        if(galeria > 0){
            galeria--;
            $('.galeria section img').eq(galeria).show();
        }
    });


    $('.galeria section .view-content > div').on('click',function () {
        $('.principal img').hide();
        $('.principal img').eq($(this).index()).show();
    });

    /**************************************************
     * GALERIA HISTORIA
     * ************************************************/

    var galeria = 0;
    var galeriaSize = $('.historia-galeria section img').length;


    $('.principal-historia img').hide();
    $('.principal-historia img').eq(0).show();
    $('.historia-galeria .galeria-historia .right').click(function () {
    	
        if(galeria < galeriaSize -1){
            $('.galeria-historia section img').eq(galeria).hide();
            galeria++;
        }
    });

    $('.galeria-historia .left').on('click',function () {
        if(galeria > 0){
            galeria--;
            $('.galeria-historia section img').eq(galeria).show();
        }
    });


    $('.galeria-historia section .view-content > div').on('click',function () {
        $('.principal-historia img').hide();
        $('.principal-historia img').eq($(this).index()).show();
    });

    $('.curso-carrera-info .panel-group .panel-default .collapse').hide();
   $('.curso-carrera-info .panel-group .panel-default a').on('click',function(){
   	    $('.curso-carrera-info .panel-group .panel-default .collapse').hide();
   	    $('.curso-carrera-info .panel-group .panel-default .collapse').css({'display':'none!important'});
        var acordionContenedor =$(this).parents('.curso-carrera-info .panel-group .panel-default');
        acordionContenedor.children('.collapse').show();
    });
    $('.acordion-info .panel-group .panel-default .collapse').hide();
    $('.acordion-info .panel-group .panel-default a').on('click',function(){
        $('.acordion-info .panel-group .panel-default .collapse').hide();
        $('.acordion-info .panel-group .panel-default .collapse').css({'display':'none!important'});
        var acordionContenedor =$(this).parents('.acordion-info .panel-group .panel-default');
        acordionContenedor.children('.collapse').show();
    });

    $('.auditorio').change(function(){
        if($(this).val() == 1){
            $('.ver-calendario').removeClass('hidden');
            $('.ver-calendario').attr('href','http://www.google.com/calendar/embed?src=fucsalud.edu.co_4lc4n44cucvb7q75nurqp62fjs%40group.calendar.google.com&ctz=America/Bogota');
        }
        if($(this).val() == 2){
            $('.ver-calendario').removeClass('hidden');
            $('.ver-calendario').attr('href','http://www.google.com/calendar/embed?src=fucsalud.edu.co_s1js0i1lveb6a0tqmks03ivlak%40group.calendar.google.com&ctz=America/Bogota');
        }
        if($(this).val() == 3){
            $('.ver-calendario').removeClass('hidden');
            $('.ver-calendario').attr('href','http://www.google.com/calendar/embed?src=fucsalud.edu.co_l4ocobm9ohsbh7hoftfq2pdirc%40group.calendar.google.com&ctz=America/Bogota');
        }
        if($(this).val() == 4){
            $('.ver-calendario').removeClass('hidden');
            $('.ver-calendario').attr('href','http://www.google.com/calendar/embed?src=fucsalud.edu.co_rt4b2kkiulcdlcbdjf1nbcm16g%40group.calendar.google.com&ctz=America/Bogota');
        }
        
    });

    $('.contenedor-agenda ').click(function(){
        $('.pop-agenda').show(300);
    });

    $('.content-pop-agenda span').click(function(){
        $('.pop-agenda').hide(300);
    });

   
});

var inputs = "textarea[maxlength]";
	$(document).on('keyup', "[maxlength]", function (e) {
		var este = $(this),
			maxlength = este.attr('maxlength'),
			maxlengthint = parseInt(maxlength),
			textoActual = este.val(),
			currentCharacters = este.val().length;
			remainingCharacters = maxlengthint - currentCharacters,
			espan = este.prev('label').find('span');			
			// Detectamos si es IE9 y si hemos llegado al final, convertir el -1 en 0 - bug ie9 porq. no coge directamente el atributo 'maxlength' de HTML5
			if (document.addEventListener && !window.requestAnimationFrame) {
				if (remainingCharacters <= -1) {
					remainingCharacters = 0;            
				}
			}
			espan.html(remainingCharacters);
			if (!!maxlength) {
				var texto = este.val();	
				if (texto.length >= maxlength) {
					este.removeClass().addClass("borderojo");
					este.val(text.substring(0, maxlength));
					e.preventDefault();
				}
				else if (texto.length < maxlength) {
					este.removeClass().addClass("bordegris");
				}	
			}	
		});

    // JavaScript Document
$(document).ready(function(){
      $('#acti1').click(function(){
            $('.mzona1').show();
            $('.mzona2').hide();
            $('.mzona3').hide();
            $('.mzona4').hide();
            $('.mzona5').hide();
            $('.mzona6').hide();
            
            $('#mmark1').show('drop', {direction:'up'},200);
            $('#mmark2').hide(200);
            $('#mmark3').hide(200);
            $('#mmark4').hide(200);
            $('#mmark5').hide(200);
        });
        $('#acti2').click(function(){
            $('.mzona2').show();
            $('.mzona1').hide();
            $('.mzona3').hide();
            $('.mzona4').hide();
            $('.mzona5').hide();
            $('.mzona6').hide();
            
            $('#mmark2').show('drop', {direction:'up'},200);
            $('#mmark1').hide(200);
            $('#mmark3').hide(200);
            $('#mmark4').hide(200);
            $('#mmark5').hide(200);
        });
        $('#acti3').click(function(){
            $('.mzona3').show();
            $('.mzona2').hide();
            $('.mzona1').hide();
            $('.mzona4').hide();
            $('.mzona5').hide();
            $('.mzona6').hide();
            
            $('#mmark3').show('drop', {direction:'up'},200);
            $('#mmark2').hide(200);
            $('#mmark1').hide(200);
            $('#mmark4').hide(200);
            $('#mmark5').hide(200);
        });
        $('#acti4').click(function(){
            $('.mzona4').show();
            $('.mzona2').hide();
            $('.mzona3').hide();
            $('.mzona1').hide();
            $('.mzona5').hide();
            $('.mzona6').hide();
            
            $('#mmark4').show('drop', {direction:'up'},200);
            $('#mmark2').hide(200);
            $('#mmark3').hide(200);
            $('#mmark1').hide(200);
            $('#mmark5').hide(200);
        });
        $('#acti5').click(function(){
            $('.mzona5').show();
            $('.mzona2').hide();
            $('.mzona3').hide();
            $('.mzona1').hide();
            $('.mzona4').hide();
            $('.mzona6').hide();
            
            $('#mmark5').show('drop', {direction:'up'},200);
            $('#mmark2').hide(200);
            $('#mmark3').hide(200);
            $('#mmark1').hide(200);
            $('#mmark4').hide(200);
        }); 
        $('#acti6').click(function(){
            $('.mzona6').show();
            $('.mzona5').hide();
            $('.mzona2').hide();
            $('.mzona3').hide();
            $('.mzona1').hide();
            $('.mzona4').hide();
            
            $('#mmark6').show('drop', {direction:'up'},200);
            $('#mmark5').hide(200);
            $('#mmark2').hide(200);
            $('#mmark3').hide(200);
            $('#mmark1').hide(200);
            $('#mmark4').hide(200);
        }); 
});

$(document).on('ready',function(){
	   function changeText(){
        var mes = $('.pager .pager__item--current').html();

        switch(mes) {

            case "January 2016":
                $('.pager .pager__item--current').html('Enero 2016');
                break;
            case "February 2016":
                $('.pager .pager__item--current').html('Febrero 2016');
                break;
            case "March 2016":
                $('.pager .pager__item--current').html('Marzo 2016');
                break;
            case "April 2016":
                $('.pager .pager__item--current').html('Abril 2016');
                break;
            case "May 2016":
                $('.pager .pager__item--current').html('Mayo 2016');
                break;
            case "June 2016":
                $('.pager .pager__item--current').html('Junio 2016');
                break;
            case "July 2016":
                $('.pager .pager__item--current').html('Julio 2016');
                break;
            case "August 2016":
                $('.pager .pager__item--current').html('Agosto 2016');
                break;
            case "September 2016":
                $('.pager .pager__item--current').html('Septiembre 2016');
                break;
            case "October 2016":
                $('.pager .pager__item--current').html('Octubre 2016');
                break;
            case "November 2016":
                $('.pager .pager__item--current').html('Noviembre 2016');
                break;
            case "December 2016":
                $('.pager .pager__item--current').html('Diciembre 2016');
                break;
            case "January 2017":
                $('.pager .pager__item--current').html('Enero 2017');
                break;
            case "February 2017":
                $('.pager .pager__item--current').html('Febrero 2017');
                break;
            case "February 2017 ":
                $('.pager .pager__item--current').html('Febrero 2017');
                break;
            case "March 2017":
                $('.pager .pager__item--current').html('Marzo 2017');
                break;
            case "April 2017":
                $('.pager .pager__item--current').html('Abril 2017');
                break;
            case "May 2017":
                $('.pager .pager__item--current').html('Mayo 2017');
                break;
            case "June 2017":
                $('.pager .pager__item--current').html('Junio 2017');
                break;
            case "July 2017":
                $('.pager .pager__item--current').html('Julio 2017');
                break;
            case "August 2017":
                $('.pager .pager__item--current').html('Agosto 2017');
                break;
            case "September 2017":
                $('.pager .pager__item--current').html('Septiembre 2017');
                break;
            case "October 2017":
                $('.pager .pager__item--current').html('Octubre 2017');
                break;
            case "November 2017":
                $('.pager .pager__item--current').html('Noviembre 2017');
                break;
            case "December 2017":
                $('.pager .pager__item--current').html('Diciembre 2017');
                break;
            case "January 2018":
                $('.pager .pager__item--current').html('Enero 2018');
                break;
            case "February 2018":
                $('.pager .pager__item--current').html('Febrero 2018');
                break;
            case "March 2018":
                $('.pager .pager__item--current').html('Marzo 2018');
                break;
            case "April 2018":
                $('.pager .pager__item--current').html('Abril 2018');
                break;
            case "May 2018":
                $('.pager .pager__item--current').html('Mayo 2018');
                break;
            case "June 2018":
                $('.pager .pager__item--current').html('Junio 2018');
                break;
            case "July 2018":
                $('.pager .pager__item--current').html('Julio 2018');
                break;
            case "August 2018":
                $('.pager .pager__item--current').html('Agosto 2018');
                break;
            case "September 2018":
                $('.pager .pager__item--current').html('Septiembre 2018');
                break;
            case "October 2018":
                $('.pager .pager__item--current').html('Octubre 2018');
                break;
            case "November 2018":
                $('.pager .pager__item--current').html('Noviembre 2018');
                break;
            case "December 2018":
                $('.pager .pager__item--current').html('Diciembre 2018');
                break;

        }
    }

    setInterval(changeText, 1);

});
