<?php

namespace Drupal\online_shop_fucs\Controller;
use Drupal\Core\Controller\ControllerBase;

class ComprasController {

	public function mostrarCompra() {
		session_start();
		$usuario = $_SESSION['usuario'];
		return array(
			'#title' => 'Carrito de compras',
			'markup' => $usuario
		);
	}

	public function car() {
		$test= "hola";
	}
}