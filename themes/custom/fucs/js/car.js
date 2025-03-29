(function ($) {
	$(window).on('load', function () {

		totalProducts();
		$('.tienda-catalogo-car').click(function(){
			var datos = $(this).find("p").text().split(',');
			var url = "/car?nombre="+datos[1]+"&precio="+datos[2]+"&articulo="+datos[3];
			var request = '';
			request = $.ajax({
				url: url,
				type: "get",
			});

			request.always(function (response, textStatus, jqXHR){
				totalProducts();
				$('.show-add-car').show();
				$('.show-add-car').delay(3000).hide(600);

			});

		});

		$('.comprarInterna').click(function(){
			var nombre = $(this).find(".field--name-field-titulo-publicaciones").text();
			var precio = $(this).find(".field--name-field-precio").text();
			var articulo = $(this).find(".field--name-field-referencia .field__item a").text();
			var url = "/car?nombre="+nombre+"&precio="+precio+"&articulo="+articulo;
			console.log("url: "+url);
			var response = '';
			request = $.ajax({
				url: url,
				type: "get",
			});

			request.done(function (response, textStatus, jqXHR){
				totalProducts();
				$('.show-add-car').show();
				$('.show-add-car').delay(3000).hide(600);

				// console.log("textStatus: "+response);
			});
		});
		$(".eliminarProducto").click(function(){
			var url = "/delete/item?id=" + $(this).attr('value');
			var response = "";
			var id = $(this).attr('value');
			request = $.ajax({
				url: url,
				type: "get",
			});
			$.ajax({
				url: url,
				type: "get",
				success: function(response) {
					window.location = "/compras/carrito";
				},
				error: function(error) {
					console.log("error: "+error);
				}
			});
		});

		$(".donation").click(function () {
			var amount = $("#amount").val();
			if (amount > 0) {
				var url = "/car?nombre=DONACIÓN DE $" + amount + "&precio=" + amount + "&articulo=Donaciones";
				var request = '';
				request = $.ajax({
					url: url,
					type: "get",
					success: function (response) {
						window.location = "/compras/carrito";
					},
					error: function (error) {
						console.log("error: " + error);
					}
				});
			}
			else {
				$(".alert").removeClass('hidden');
			}


		});
	});

	function totalProducts() {

		var datos = $(this).find("total-products").text().split(',');
		$.ajax({
			url: "/products", success: function (result) {
				if (typeof result.products != "undefined") {
					$('.total-products').text(result.products);
				}
			}
		});
	}

}(jQuery));


