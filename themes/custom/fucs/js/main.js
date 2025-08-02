(function ($) {
	$(window).on('load', function () {

		$('#videoFondo').on('click', function () {
      if (this.paused) {
        this.play();
      } else {
        this.pause();
      }
    });
		$('.flexslider').flexslider({
			animation: "slide",
			controlNav: true/*,
			start: function (slider) {
							slider.pause();
			}*/
		});
		$('.testimonioslider').flexslider({
			animation: "slide",
			controlNav: true/*,
			start: function (slider) {
							slider.pause();
			}*/
		});
	});
	$(document).ready(function() {
		$(".retroceder").click(function(){
			window.history.back();
		});

		$('.volumen-articulo a').text('Ver más');
		$(".volumen-articulo a").click(function() {
			url = $(this).attr("href");
			window.open(url, '_blank');
			return false;
		});
		// $('.continuada-menu-contenido ul > li > a').prepend('<span></span>');
		$('.aspirante-sub-menu ul li').prepend('<span></span>');
		var pag = $(window);
		var j = 0;
		$('.inscribete').on('click', function() {
			if (j == 0) {
				$('.form-inscribirse').fadeIn();
				$('.search-block-form').fadeIn();
				$(this).fadeOut();
				j++;
			} else {
				$('.form-inscribirse').fadeOut();
				$('.search-block-form').fadeOut();
				$('.block-search').fadeOut();
				j = 0;
			}
		});
		$('.inscribete-mobil-top').on('click', function() {
			if (j == 0) {
				$('.form-inscribirse').fadeIn();
				j++;
			}
		});
		var ancho = $('body').width();
		$('.form-inscribirse .form-submit:last-child').on('click', function() {
			$('.form-inscribirse').hide();
			$('.search-block-form').hide();
			$('.block-search').hide();
			if (ancho > 980) {
				$('.inscribete').fadeIn();
			}
			j = 0;
		});
		$('.form-inscribirse span').on('click', function() {
			$('.form-inscribirse').hide();
			$('.search-block-form').fadeOut();
			$('.block-search').fadeOut();
			if (ancho > 980) {
				$('.inscribete').fadeIn();
			}
			j = 0;
		});
		var i = 0;
		$('.menu-mobil img').on('click', function() {
			if (i == 0) {
				$('.mobil-open').hide();
				$('.mobil-close').show();
				$('.menu-desplegable').show();
				i++;
			} else {
				$('.mobil-open').show();
				$('.mobil-close').hide();
				$('.menu-desplegable').hide();
				i = 0;
			}
		});
		$('.tabs a').on('click', function() {
			$('.tabs a').removeClass('active');
			$(this).addClass('active');
		})
		$('.menu-noticias').on('click', function() {
			$('.sub-seccion').hide();
			$('.sub-eventos').hide();
			$('.sub-noticias').show();
			$("#block-calendarioaspirantes").hide();
		});
		$('.menu-eventos').on('click', function() {
			$('.sub-seccion').hide();
			$('.sub-noticias').hide();
			$('.sub-eventos').show();
			$("#block-calendarioaspirantes").show();
		})
		$('.menu-encuestas').on('click', function() {
			$('.sub-seccion').hide();
			$('.sub-noticias').hide();
			$('.sub-encuestas').show();
			$("#block-calendarioaspirantes").hide();
		})
		$('.menu-videos').on('click', function() {
			$('.sub-seccion').hide();
			$('.sub-noticias').hide();
			$('.sub-videos').show();
			$("#block-calendarioaspirantes").hide();
		})
		$('.form-inscribirse #edit-name').attr("placeholder", "*Nombre:");
		$('.form-inscribirse .form-email').attr("placeholder", "*Email:");
		$('.form-inscribirse #edit-subject-0-value').attr("placeholder", "*Teléfono:");
		$('.form-inscribirse form textarea').attr("placeholder", "*Mensaje:");
		$('.form-inscribirse .form-submit:last-child').val("CANCELAR");
		$('.form-inscribirse .form-submit:first-child').val("ENVIAR");
		$('.gtranslate select').addClass('notranslate');
		$('.content-laboratorios').on('click', function() {
			var elem = $(this).index();
			$('.laboratorios-mapa img').hide();
			$('.laboratorios-mapa img').eq(elem).show();
		});
		var i = 0;
		var j = 0;
		var k = 0;
		$('.footer-menu .a-sedes').on('click', function() {
			$('.footer-menu a').removeClass('active');
			$(this).addClass('active');
			$('.sedes').show();
			$('.closeSedes').show();
			$('.auditorios').hide();
			$('.chat').addClass('chatLabo');
			$('footer').addClass('footerLabo');
			$('.footer-menu a').addClass('aLabo');
			$('.firts-footer').addClass('firts-footer-open');
		});

		$('.closeSedes').click(function(){
			$('.sedes').hide();
			$('.closeSedes').hide();
			$('.auditorios').hide();
			$('.chat').removeClass('chatLabo');
			$('footer').removeClass('footerLabo');
			$('.footer-menu a').removeClass('aLabo');
			$('.firts-footer').removeClass('firts-footer-open');
		});

		$('#inputButton').on('click', function() {
			if ($('#inputSearch').val() != "") {
				var url = "http://fucsalud.edu.co/search/node?keys=" + $('#inputSearch').val();
				$(location).attr('href', url);
			} else {
				$('#inputSearch').css({
					'border': '1px solid red'
				});
			}
		});
		$('#inputButton1').on('click', function() {
			if ($('#inputSearch1').val() != "") {
				var url = "http://fucsalud.edu.co/search/node?keys=" + $('#inputSearch1').val();
				$(location).attr('href', url);
			} else {
				$('#inputSearch1').css({
					'border': '1px solid red'
				});
			}
		});
		var cantVarios = $('.varios .drawde-five').length;
		if (cantVarios > 6) {
			$('.varios .drawde-five').hide();
			for (var m = 0; m < 6; m++) {
				$('.varios .drawde-five').eq(m).show();
			}
		}
		var contVarios = 0;
		var contUltimo = 5;
		var contVariosMobil = 0;
		cantVarios--;
		if (ancho > 980) {
			$('.varios-right').on('click', function() {
				if (4 > contVarios && cantVarios > contUltimo) {
					$('.varios .drawde-five').eq(contVarios).hide();
					contUltimo++;
					$('.varios .drawde-five').eq(contUltimo).show();
					contVarios++;
				}
			});
			$('.varios-left').on('click', function() {
				//console.log(contVarios + "," + contUltimo);
				if (contVarios > 0 && contUltimo > 0) {
					$('.varios .drawde-five').eq(contUltimo).hide();
					contVarios--;
					contUltimo--;
					$('.varios .drawde-five').eq(contVarios).show();
				}
			});
		} else {
			$('.varios .drawde-five').css({
				'width': '100%'
			});
			$('.varios .drawde-five').hide();
			$('.varios .drawde-five').eq(contVariosMobil).show();
			$('.varios-right').on('click', function() {
				contVariosMobil++;
				if (contVariosMobil < $('.varios .drawde-five').length) {
					$('.varios .drawde-five').hide();
					$('.varios .drawde-five').eq(contVariosMobil).show();
				} else {
					contVariosMobil = $('.varios .drawde-five').length - 1;
				}
			});
			$('.varios-left').on('click', function() {
				contVariosMobil--;
				if (contVariosMobil > 0) {
					$('.varios .drawde-five').hide();
					$('.varios .drawde-five').eq(contVariosMobil).show();
				} else {
					contVariosMobil = 0;
				}
			});
		}
		var aspirantes = 0;
		$('.menu-botton').on('click', function() {
			if (aspirantes == 0) {
				$('.all-sub-submenu').fadeIn();
				$('.menu-botton').removeClass('icon-down-dir');
				$('.menu-botton').addClass('icon-up-dir');
				aspirantes++;
			} else {
				$('.all-sub-submenu').fadeOut();
				$('.menu-botton').removeClass('icon-up-dir');
				$('.menu-botton').addClass('icon-down-dir');
				aspirantes = 0;
			}
		});
		$('.menu-item--expanded').addClass('icon-down-dir');
		var programas = 0;
		$('.submenu-botton').on('click', function() {
			if (programas == 0) {
				$('.ul-submenu-botton').fadeIn();
				$('.submenu-botton').removeClass('icon-down-dir');
				$('.submenu-botton').addClass('icon-up-dir');
				programas++;
			} else {
				$('.ul-submenu-botton').fadeOut();
				$('.submenu-botton').removeClass('icon-up-dir');
				$('.submenu-botton').addClass('icon-down-dir');
				programas = 0;
			}
		});
		var testimonio = 0;
		$('.testimonio-content').hide();
		$('.testimonio-content').eq(0).show();
		$('.testimonios .left').on('click', function() {
			testimonio--;
			if (testimonio < 0) {
				testimonio = 0;
			} else {
				$('.testimonio-content').hide();
				$('.testimonio-content').eq(testimonio).fadeIn();
			}
		});
		$('.testimonios .right').on('click', function() {
			testimonio++;
			if (testimonio >= $('.testimonio-content').length) {
				testimonio = $('.testimonio-content').length - 1;
			} else {
				$('.testimonio-content').hide();
				$('.testimonio-content').eq(testimonio).fadeIn();
			}
		});
		var patrocinadores = 2;
		$('.patrocinadores .left').on('click', function() {
			patrocinadores--;
			if (patrocinadores < 2) {
				patrocinadores = 2;
			} else {
				var patrocinadoresAux = patrocinadores - 3;
				$('.patrocinadores ul li').eq(patrocinadores + 1).hide();
				$('.patrocinadores ul li').eq(patrocinadoresAux + 1).css({
					'display': 'inline-block'
				});
			}
		});
		$('.patrocinadores .right').on('click', function() {
			patrocinadores++;
			if (patrocinadores >= $('.patrocinadores ul li').length) {
				patrocinadores = $('.patrocinadores ul li').length - 1;
			} else {
				$('.patrocinadores ul li').eq(patrocinadores - 3).hide();
				$('.patrocinadores ul li').eq(patrocinadores).css({
					'display': 'inline-block'
				});
			}
		});
		var galeria = 0;
		var galeriaSize = $('.galeria section img').length;
		$('.principal img').hide();
		$('.principal img').eq(0).show();
		$('.galeria .right').on('click', function() {
			if (galeria < galeriaSize - 1) {
				$('.galeria section img').eq(galeria).hide();
				galeria++;
			}
		});
		$('.galeria .left').on('click', function() {
			if (galeria > 0) {
				galeria--;
				$('.galeria section img').eq(galeria).show();
			}
		});
		$('.galeria section .view-content > div').on('click', function() {
			$('.principal img').hide();
			$('.principal img').eq($(this).index()).show();
		});
		var galeriah = 0;
		var galeriahSize = $('.historia-galeria section img').length;
		$('.principal-historia img').hide();
		$('.principal-historia img').eq(0).show();
		$('.historia-galeria .galeria-historia .right').click(function() {
			if (galeriah < galeriahSize - 1) {
				$('.galeria-historia section img').eq(galeriah).hide();
				galeriah++;
			}
		});
		$('.galeria-historia .left').on('click', function() {
			if (galeriah > 0) {
				galeriah--;
				$('.galeria-historia section img').eq(galeriah).show();
			}
		});
		$('.galeria-historia section .view-content > div').on('click', function() {
			$('.principal-historia img').hide();
			$('.principal-historia img').eq($(this).index()).show();
		});
		$('.curso-carrera-info .panel-group .panel-default .collapse').hide();
		$('.curso-carrera-info .panel-group .panel-default a').on('click', function() {
			$('.curso-carrera-info .panel-group .panel-default .collapse').hide();
			$('.curso-carrera-info .panel-group .panel-default .collapse').css({
				'display': 'none!important'
			});
			var acordionContenedor = $(this).parents('.curso-carrera-info .panel-group .panel-default');
			acordionContenedor.children('.collapse').show();
		});
		$('.acordion-info .panel-group .panel-default .collapse').hide();
		$('.acordion-info .panel-group .panel-default a').on('click', function() {
			$('.acordion-info .panel-group .panel-default .collapse').hide();
			$('.acordion-info .panel-group .panel-default .collapse').css({
				'display': 'none!important'
			});
			var acordionContenedor = $(this).parents('.acordion-info .panel-group .panel-default');
			acordionContenedor.children('.collapse').show();
		});
		$('.auditorio').change(function() {
			if ($(this).val() == 1) {
				$('.ver-calendario').removeClass('hidden');
				$('.ver-calendario').attr('href', 'http://www.google.com/calendar/embed?src=fucsalud.edu.co_4lc4n44cucvb7q75nurqp62fjs%40group.calendar.google.com&ctz=America/Bogota');
			}
			if ($(this).val() == 2) {
				$('.ver-calendario').removeClass('hidden');
				$('.ver-calendario').attr('href', 'http://www.google.com/calendar/embed?src=fucsalud.edu.co_s1js0i1lveb6a0tqmks03ivlak%40group.calendar.google.com&ctz=America/Bogota');
			}
			if ($(this).val() == 3) {
				$('.ver-calendario').removeClass('hidden');
				$('.ver-calendario').attr('href', 'http://www.google.com/calendar/embed?src=fucsalud.edu.co_l4ocobm9ohsbh7hoftfq2pdirc%40group.calendar.google.com&ctz=America/Bogota');
			}
			if ($(this).val() == 4) {
				$('.ver-calendario').removeClass('hidden');
				$('.ver-calendario').attr('href', 'http://www.google.com/calendar/embed?src=fucsalud.edu.co_rt4b2kkiulcdlcbdjf1nbcm16g%40group.calendar.google.com&ctz=America/Bogota');
			}
		});
		$('.contenedor-agenda ').click(function() {
			$('.pop-agenda').show(300);
		});
		$('.content-pop-agenda span').click(function() {
			$('.pop-agenda').hide(300);
		});

		var sizeFont = 0;

		$(".increase").click(function(){
			if (sizeFont <= 1) {
				var sizeFuenteActual = $('a').css('font-size');
				var sizeFuenteActualNum = parseFloat(sizeFuenteActual, 10);
				var sizeFuenteNuevo = sizeFuenteActualNum*1.2;
				$('a, p').css('font-size', sizeFuenteNuevo);
				//$('.estudiantes-sub-menu ul li a').css('font-size', '16px');
				sizeFont++;
				return false;
			}

		});

		// Disminuir Font Size
		$(".diminish").click(function(){
			if (sizeFont > -2) {
				var sizeFuenteActual = $('a, p, div, li').css('font-size');
				var sizeFuenteActualNum = parseFloat(sizeFuenteActual, 10);
				var sizeFuenteNuevo = sizeFuenteActualNum*0.8;
				$('a, p').css('font-size', sizeFuenteNuevo);
				sizeFont--;
				return false;
			}
		});
	});
	var inputs = "textarea[maxlength]";
	$(document).on('keyup', "[maxlength]", function(e) {
		var este = $(this),
			maxlength = este.attr('maxlength'),
			maxlengthint = parseInt(maxlength),
			textoActual = este.val(),
			currentCharacters = este.val().length;
		remainingCharacters = maxlengthint - currentCharacters, espan = este.prev('label').find('span');
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
			} else if (texto.length < maxlength) {
				este.removeClass().addClass("bordegris");
			}
		}
	});
	$(document).ready(function() {
		function CSVToArray(strData, strDelimiter) {
			strDelimiter = (strDelimiter || ",");
			var objPattern = new RegExp(("(\\" + strDelimiter + "|\\r?\\n|\\r|^)" + "(?:\"([^\"]*(?:\"\"[^\"]*)*)\"|" + "([^\"\\" + strDelimiter + "\\r\\n]*))"), "gi");
			var arrData = [
				[]
			];
			var arrMatches = null;
			while (arrMatches = objPattern.exec(strData)) {
				var strMatchedDelimiter = arrMatches[1];
				if (strMatchedDelimiter.length && strMatchedDelimiter !== strDelimiter) {
					arrData.push([]);
				}
				var strMatchedValue;
				if (arrMatches[2]) {
					strMatchedValue = arrMatches[2].replace(new RegExp("\"\"", "g"), "\"");
				} else {
					strMatchedValue = arrMatches[3];
				}
				arrData[arrData.length - 1].push(strMatchedValue);
			}
			return (arrData);
		}

		$("#edit-fucs-programa-interes-c option[value='remove']").remove();
		/*var dropdown = $('select#edit-fucs-programa-interes-c');*/
		$('select#fucs_programa_interes_c').empty();
		$('select#fucs_programa_interes_c').append(new Option("Programa interés", "value"));

		var csv_path = "/datos-programas/programas.csv";
		var renderCSVDropdown = function(csv) {
			var dropdown = $('select#fucs_programa_interes_c');
			for (var i = 0; i < csv.length; i++) {
				var record = csv[i];
				//console.log(record);
				var entry = $('<option>', {
					value: record[0].trim(),
					text: record[1]
				});
				dropdown.append(entry);
			}
		};


		$.get(csv_path, function(data) {
			var csv = CSVToArray(data, ";");
			renderCSVDropdown(csv);
		});

		var csv_path2 = "/datos-programas/continuada/programasContinuada.csv";
		var renderCSVDropdown2 = function(csv2) {
			var dropdown2 = $('select#fucs_programa_interes_cd');
			for (var i = 0; i < csv2.length; i++) {
				var record2 = csv2[i];
				var entry2 = $('<option>', {
					value: record2[0].trim(),
					text: record2[1],
					id: record2[2],
				});
				dropdown2.append(entry2);
			}
		};

		$.get(csv_path2, function(data) {
			var csv2 = CSVToArray(data, ";");
			renderCSVDropdown2(csv2);
		});

		if($('body').hasClass('path-frontpage'))
			document.getElementById("assigned_user_id").value="1";

		$("select[name=fucs_programa_interes_c]").change(function(){
			var indice = document.getElementById("fucs_programa_interes_c").selectedIndex;
			var idOption = document.getElementById("fucs_programa_interes_c").options[indice].id;
			document.getElementById("assigned_user_id").value=idOption;
		});
		$('#acti1').click(function() {
			$('.mzona1').show();
			$('.mzona2').hide();
			$('.mzona3').hide();
			$('.mzona4').hide();
			$('.mzona5').hide();
			$('.mzona6').hide();
			$('.mzona7').hide();
			$('.mzona8').hide();
			$('#mmark1').show('drop', {
				direction: 'up'
			}, 200);
			$('#mmark2').hide(200);
			$('#mmark3').hide(200);
			$('#mmark4').hide(200);
			$('#mmark5').hide(200);
			$('#mmark6').hide(200);
			$('#mmark7').hide(200);
			$('#mmark8').hide(200);
		});
		$('#acti2').click(function() {
			$('.mzona2').show();
			$('.mzona1').hide();
			$('.mzona3').hide();
			$('.mzona4').hide();
			$('.mzona5').hide();
			$('.mzona6').hide();
			$('.mzona7').hide();
			$('.mzona8').hide();
			$('#mmark2').show('drop', {
				direction: 'up'
			}, 200);
			$('#mmark1').hide(200);
			$('#mmark3').hide(200);
			$('#mmark4').hide(200);
			$('#mmark5').hide(200);
			$('#mmark6').hide(200);
			$('#mmark7').hide(200);
			$('#mmark8').hide(200);
		});
		$('#acti3').click(function() {
			$('.mzona3').show();
			$('.mzona2').hide();
			$('.mzona1').hide();
			$('.mzona4').hide();
			$('.mzona5').hide();
			$('.mzona6').hide();
			$('.mzona7').hide();
			$('.mzona8').hide();
			$('#mmark3').show('drop', {
				direction: 'up'
			}, 200);
			$('#mmark2').hide(200);
			$('#mmark1').hide(200);
			$('#mmark4').hide(200);
			$('#mmark5').hide(200);
			$('#mmark6').hide(200);
			$('#mmark7').hide(200);
			$('#mmark8').hide(200);
		});
		$('#acti4').click(function() {
			$('.mzona4').show();
			$('.mzona2').hide();
			$('.mzona3').hide();
			$('.mzona1').hide();
			$('.mzona5').hide();
			$('.mzona6').hide();
			$('.mzona7').hide();
			$('.mzona8').hide();
			$('#mmark4').show('drop', {
				direction: 'up'
			}, 200);
			$('#mmark2').hide(200);
			$('#mmark3').hide(200);
			$('#mmark1').hide(200);
			$('#mmark5').hide(200);
			$('#mmark6').hide(200);
			$('#mmark7').hide(200);
			$('#mmark8').hide(200);
		});
		$('#acti5').click(function() {
			$('.mzona5').show();
			$('.mzona2').hide();
			$('.mzona3').hide();
			$('.mzona1').hide();
			$('.mzona4').hide();
			$('.mzona6').hide();
			$('.mzona7').hide();
			$('.mzona8').hide();
			$('#mmark5').show('drop', {
				direction: 'up'
			}, 200);
			$('#mmark2').hide(200);
			$('#mmark3').hide(200);
			$('#mmark1').hide(200);
			$('#mmark4').hide(200);
			$('#mmark6').hide(200);
			$('#mmark7').hide(200);
			$('#mmark8').hide(200);
		});
		$('#acti6').click(function() {
			$('.mzona6').show();
			$('.mzona5').hide();
			$('.mzona2').hide();
			$('.mzona3').hide();
			$('.mzona1').hide();
			$('.mzona4').hide();
			$('.mzona7').hide();
			$('.mzona8').hide();
			$('#mmark6').show('drop', {
				direction: 'up'
			}, 200);
			$('#mmark5').hide(200);
			$('#mmark2').hide(200);
			$('#mmark3').hide(200);
			$('#mmark1').hide(200);
			$('#mmark4').hide(200);
			$('#mmark7').hide(200);
			$('#mmark8').hide(200);
		});
		$('#acti7').click(function() {
			$('.mzona7').show();
			$('.mzona5').hide();
			$('.mzona2').hide();
			$('.mzona3').hide();
			$('.mzona1').hide();
			$('.mzona4').hide();
			$('.mzona6').hide();
			$('.mzona8').hide();
			$('#mmark7').show('drop', {
				direction: 'up'
			}, 200);
			$('#mmark5').hide(200);
			$('#mmark2').hide(200);
			$('#mmark3').hide(200);
			$('#mmark1').hide(200);
			$('#mmark4').hide(200);
			$('#mmark6').hide(200);
			$('#mmark8').hide(200);
		});
		$('#acti8').click(function () {
			$('.mzona8').show();
			$('.mzona7').hide();
			$('.mzona5').hide();
			$('.mzona2').hide();
			$('.mzona3').hide();
			$('.mzona1').hide();
			$('.mzona4').hide();
			$('.mzona6').hide();
			$('#mmark8').show('drop', {
				direction: 'up'
			}, 200);
			$('#mmark5').hide(200);
			$('#mmark2').hide(200);
			$('#mmark3').hide(200);
			$('#mmark1').hide(200);
			$('#mmark4').hide(200);
			$('#mmark6').hide(200);
			$('#mmark7').hide(200);
		});

		/*$("#block-soy .menu-item--expanded .menu").hide();

		$('#block-soy ').click(function (){
			$("#block-soy .menu-item--expanded .menu").toggle();
		});*/
		$('.pre-home-close').click(function (){
			$(".pre-home").hide(300);
		});

		$('.biblioteca-reserva-form').click(function() {
			$('.form-modal').show();
		})
		$('.form-modal-close').click(function() {
			$('.form-modal').hide();
		})
		$(".webform-confirmation").parents('.form-modal').show();

		$('.close-pop-up').click(function() {
			$(".fucs-pop-up").hide();
		})
		$('.fucs-one-site .close-pop-up').click(function() {
			$(".fucs-one-site").hide();
		})
		$('.fucs-one-site-close').click(function() {
			$(".fucs-one-site").hide();
		})
	});

	$(document).on('ready', function() {
		function changeText() {
			var mes = $('.pager .pager__item--current').html();
			switch (mes) {
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
	$('#cancel_store_btn').click(function (e) {
		createCookie('usuario', "", -1);
	});

	$('.apartaestudio-reserva').click(function() {
		$('.acordion-lateral-iz .block-fucs-studio-apartments').show();
	});
	$(document).keydown(function(event) {
    if (event.key === "Escape" || event.keyCode === 27) {
			$('.acordion-lateral-iz .block-fucs-studio-apartments').hide();
    }	
	});
	$('.apartment-contact-form .close').click(function() {
		$('.acordion-lateral-iz .block-fucs-studio-apartments').hide();
	});
}(jQuery));
