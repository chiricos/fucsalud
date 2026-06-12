<?php

namespace Drupal\certificados\Controller;

use Drupal\Core\Controller\ControllerBase;
use Dompdf\Dompdf;
use Dompdf\Options;
use Symfony\Component\HttpFoundation\Response;

class ResultadoCertificado extends ControllerBase {

	private $fontCache = [];

	private $imageCache = [];

	public function consulta_resultado($documento = null) {//certificados conferencista

		$connection = \Drupal::database();

		if ($documento <> null) {
			$query = $connection->query("SELECT Nombre, Tipo, Documento, Evento, Fecha, Id FROM {certificado_asistencia} cert WHERE Documento = '".$documento."'");
			$certificate = [];
			if ($query) {
				foreach ($query as $key => $data){

					$certificate[$key]['id'] = isset($data->Id) ? $data->Id : $data['Id'];
					$certificate[$key]['description'] = isset($data->Evento) ? $data->Evento: $data['Evento'];
					$certificate[$key]['url'] = '/resultado-consulta-certificado-pdf/' . $certificate[$key]['id'];
				}
				if (count($certificate) == 1) {
					$this->consulta_resultado_pdf($certificate[0]['id']);
				}
			}
		}
		return [
			'#theme' => 'conferencista',
			'#data' => $certificate,
			'#cache' => [
				'max-age' => 0,
			]
		];
	}

	public function consulta_resultado_pdf($id = null) {//certificados asistencia

		$connection = \Drupal::database();

		if ($id <> null) {
			$query = $connection->query("SELECT Nombre, Tipo, Documento, Evento, Fecha, codigo, Id FROM {certificado_asistencia} cert WHERE Id = '".$id."'");

			if ($query) {
				foreach ($query as $row) {
					$nombre = $row->Nombre;
					$tipo = $row->Tipo;
					$documento = $row->Documento;
					$evento = $row->Evento;
					$fecha = $row->Fecha;
					$id = $row->Id;
					$codigo = $row->codigo;

					$css = $this->getCssWithFonts('getCssStyle');
					$markupTemplate = '
											<body>
												<style>' . $css . '</style>
												<table style="table-layout: fixed; width: 1056px">
													<colgroup>
														<col style="width: 528px">
														<col style="width: 528px">
													</colgroup>
												  <tr>
												    <td colspan="4"><img src="IMAGE:logo.png"></td>
												  </tr>
												  <tr>
												    <td colspan="4"><h2 class="titulo">UNIVERSIDAD FUCS</h2></td>
												  </tr>
												  <tr>
												    <td colspan="4"><p class="certifica">Certifica que:</p></td>
												  </tr>
												  <tr>
												    <td colspan="4"><p class="nombre">'.$nombre.'</p></td>
												  </tr>
												  <tr>
												    <td colspan="4"><p class="documento">'.$tipo.' '.$documento.'</p></td>
												  </tr>
												  <tr>
														<td colspan="4"><p class="asistio">Asistió:</p></td>
												  </tr>
												  <tr>
												    <td colspan="4"><p class="evento">'.$evento.'</p></td>
												  </tr>
												  <tr>
												    <td colspan="4"><p class="fecha">Realizado en Bogotá, D.C., Colombia, '.$fecha.'</p></td>
												  </tr>
												  <tr>
												    <td colspan="4"><p class="constancia">En constancia firman:</p></td>
												  </tr>
												  <tr>
														<td></td>
												    <td><img src="IMAGE:firma1.png" class="imgFirma"></td>
												    <td><img src="IMAGE:firma2.png" class="imgFirma"></td>
												  </tr>
													<tr>
												    <td colspan="4"><p class="acuerdo"> AR' . $id . '-' . $codigo .'</p></td>
												  </tr>
												  <tr>
												  	<td colspan="4"><img src="IMAGE:franja.png" style="width: 100%"></td>
												  </tr>
												</table>
											</body>';
					$markup = $this->makeMarkupWithImages($markupTemplate);
					return $this->renderCertPdf($markup);
				}
			}

			else {
				$contenido = array();
				$contenido['linea1'] = array(
					'#markup' => '<strong> No hay resultados!!! </strong><br><br>',
				);
			}
		}

		else {
			$contenido = array();
			$contenido['linea1'] = array(
				'#markup' => '<strong> No hay resultados!!! </strong><br><br>',
			);
		}

		return $contenido;
	}

	public function consulta_resultado_conferencista($documento = null) {//certificados conferencista

		$connection = \Drupal::database();

		if ($documento <> null) {
			$query = $connection->query("SELECT Nombre, Tipo, Documento, Ponencia, Evento, Fecha, codigo, Id FROM {certificado_conferencista} cert WHERE Documento = '".$documento."'");
			$certificate = [];
			if ($query) {
				foreach ($query as $key => $data){

					$certificate[$key]['id'] = isset($data->Id) ? $data->Id : '';
					$certificate[$key]['description'] = isset($data->Evento) ? $data->Evento: '';
					$certificate[$key]['url'] = '/resultado-consulta-certificado-conferencista-pdf/' . $certificate[$key]['id'];
				}
				if (count($certificate) == 1) {
					$this->consulta_resultado_conferencista_pdf($certificate[0]['id']);
				}
			}
		}
		return [
			'#theme' => 'conferencista',
			'#data' => $certificate,
			'#cache' => [
				'max-age' => 0,
			]
		];
	}

	public function consulta_resultado_eventos_conferencista($documento = null) {//certificados conferencista

		$connection = \Drupal::database();

		if ($documento <> null) {
			$query = $connection->query("SELECT Nombre, Tipo, Documento, Ponencia, Evento, Fecha, codigo, Id FROM {certificado_eventos_conferencista} cert WHERE Documento = '".$documento."'");
			$certificate = [];
			if ($query) {
				foreach ($query as $key => $data){

					$certificate[$key]['id'] = isset($data->Id) ? $data->Id : '';
					$certificate[$key]['description'] = isset($data->Evento) ? $data->Evento: '';
					$certificate[$key]['url'] = '/resultado-consulta-certificado-eventos-conferencista-pdf/' . $certificate[$key]['id'];
				}
				if (count($certificate) == 1) {
					$this->consulta_resultado_eventos_conferencista_pdf($certificate[0]['id']);
				}
			}
		}
		return [
			'#theme' => 'conferencista',
			'#data' => $certificate,
			'#cache' => [
				'max-age' => 0,
			]
		];
	}

	public function consulta_resultado_conferencista_pdf($id = null) {
		$connection = \Drupal::database();

		if ($id <> null) {
			$query = $connection->query("SELECT Nombre, Tipo, Documento, Ponencia, Evento, Fecha, codigo, Id FROM {certificado_conferencista} cert WHERE Id = '".$id."'");
			$certificate = [];
			if ($query) {
				foreach ($query as $row) {
				$nombre = isset($row->Nombre) ? $row->Nombre : $row['Nombre'];
				$tipo = isset($row->Tipo) ? $row->Tipo : $row['Tipo'];
				$documento = isset($row->Documento) ? $row->Documento: $row['Documento'];
				$ponencia = isset($row->Ponencia) ? $row->Ponencia : $row['Ponencia'];
				$evento = isset($row->Evento) ? $row->Evento : $row['Evento'];
				$fecha = isset($row->Fecha) ? $row->Fecha : $row['Fecha'];
				$id = isset($row->Id) ? $row->Id : $row['Id'];
				$codigo = isset($row->codigo) ? $row->codigo : $row['codigo'];
				$base_url = \Drupal::request()->getSchemeAndHttpHost();

				$css = $this->getCssWithFonts('getCssTrabajo');
				$markupTemplate = '
										<body>
										<style>' . $css .'</style>
											<table style="table-layout: fixed; width: 1056px">
												<colgroup>
													<col style="width: 528px">
													<col style="width: 528px">
												</colgroup>
											  <tr>
											    <td colspan="4"><img src="IMAGE:logo.png" class="imgLogo"></td>
											  </tr>
											  <tr>
											    <td colspan="4"><h2 class="titulo">UNIVERSIDAD FUCS</h2></td>
											  </tr>
											  <tr>
											    <td colspan="4"><p class="certifica">Certifica que:</p></td>
											  </tr>
											  <tr>
											    <td colspan="4"><p class="nombre">'.$nombre.'</p></td>
											  </tr>
											  <tr>
											    <td colspan="4"><p class="documento">'.$tipo.' '.$documento.'</p></td>
											  </tr>
											  <tr>
											    <td colspan="4"><p class="asistio">Participó como conferencista con la ponencia:</p></td>
											  </tr>
											  <tr>
											    <td colspan="4"><p class="ponencia">'.$ponencia.'</p></td>
											  </tr>
											  <tr>
											    <td colspan="4"><p class="evento">'.$evento.'</p></td>
											  </tr>
											  <tr>
											    <td colspan="4"><p class="fecha">Realizado en Bogotá, D.C., Colombia, '.$fecha.'</p></td>
											  </tr>
											  <tr>
											    <td colspan="4"><p class="constancia">En constancia firman:</p></td>
											  </tr>
											  <tr>
											  	<td></td>
											    <td><img src="IMAGE:firma1.png" class="imgFirma"></td>
											    <td><img src="IMAGE:firma2.png" class="imgFirma"></td>
											    <td></td>
											  </tr>
												<tr>
													<td colspan="4"><p class="acuerdo"> AR' . $id . '-' . $codigo .'</p></td>
												</tr>
											  <tr>
											  	<td colspan="4"><img src="IMAGE:franja.png" style="width: 100%"></td>
											  </tr>
											</table>
										</body>';

				$markup = $this->makeMarkupWithImages($markupTemplate);
				return $this->renderCertPdf($markup);
			}

			$contenido = array();
			$contenido['linea1'] = array(
					'#markup' => '<strong> No hay resultados!!! </strong><br><br>',
				);

			}

			else {
				$contenido = array();
				$contenido['linea1'] = array(
					'#markup' => '<strong> No hay resultados!!! </strong><br><br>',
				);
			}
		}

		else {
			$contenido = array();
			$contenido['linea1'] = array(
				'#markup' => '<strong> No hay resultados!!! </strong><br><br>',
			);
		}

		return $contenido;
	}

	public function consulta_resultado_eventos_conferencista_pdf($id = null) {
		$connection = \Drupal::database();
		$contenido = array();

		if (!($id <> null)) {
			$contenido['linea1'] = array(
				'#markup' => '<strong> No hay resultados!!! </strong><br><br>',
			);
			return $contenido;
		}

		$query = $connection->query("SELECT Nombre, Tipo, Documento, Ponencia, Evento, Fecha, codigo, Id FROM {certificado_eventos_conferencista} cert WHERE Id = '".$id."'");
		$certificate = [];
		if ($query) {
			foreach ($query as $row) {
				$nombre = isset($row->Nombre) ? $row->Nombre : '';
				$tipo = isset($row->Tipo) ? $row->Tipo : '';
				$documento = isset($row->Documento) ? $row->Documento : '';
				$ponencia = isset($row->Ponencia) && ($row->Ponencia != NULL) ? $row->Ponencia : '';
				$evento = isset($row->Evento) ? $row->Evento : '';
				$fecha = isset($row->Fecha) ? $row->Fecha : '';
				$id = isset($row->Id) ? $row->Id : $row['Id'];
				$codigo = isset($row->codigo) ? $row->codigo : $row['codigo'];

				$css = $this->getCssWithFonts('getCssTrabajo');
				$markupTemplate = '
										<body>
										<style>' . $css .'</style>
											<table style="table-layout: fixed; width: 1056px">
												<colgroup>
													<col style="width: 528px">
													<col style="width: 528px">
												</colgroup>
											  <tr>
											    <td colspan="4"><img src="IMAGE:logo.png" class="imgLogo"></td>
											  </tr>
											  <tr>
											    <td colspan="4"><h2 class="titulo">UNIVERSIDAD FUCS</h2></td>
											  </tr>
											  <tr>
											    <td colspan="4"><p class="certifica">Certifica que:</p></td>
											  </tr>
											  <tr>
											    <td colspan="4"><p class="nombre">'.$nombre.'</p></td>
											  </tr>
											  <tr>
											    <td colspan="4"><p class="documento">'.$tipo.' '.$documento.'</p></td>
											  </tr>
											  <tr>
											    <td colspan="4"><p class="asistio">Participó:</p></td>
											  </tr>
											  <tr>
											    <td colspan="4"><p class="ponencia">'.$ponencia.'</p></td>
											  </tr>
											  <tr>
											    <td colspan="4"><p class="evento">'.$evento.'</p></td>
											  </tr>
											  <tr>
											    <td colspan="4"><p class="fecha">Bogotá, D.C., Colombia, '.$fecha.'</p></td>
											  </tr>
												<tr>
													<td colspan="4"><p class="acuerdo"> ' . $id . '-' . $codigo .'</p></td>
												</tr>
											  <tr>
											    <td colspan="4"><p class="constancia">En constancia firman:</p></td>
											  </tr>
											  <tr>
											  	<td></td>
											    <td><img src="IMAGE:firma1.png" class="imgFirma"></td>
											    <td><img src="IMAGE:firma2.png" class="imgFirma"></td>
											    <td></td>
											  </tr>
												<tr>
													<td colspan="4"><p class="acuerdo"> AR' . $id . '-' . $codigo .'</p></td>
												</tr>
											  <tr>
											  	<td colspan="4"><img src="IMAGE:franja.png" style="width: 100%"></td>
											  </tr>
											</table>
										</body>';

				$markup = $this->makeMarkupWithImages($markupTemplate);
				$response = $this->renderCertPdf($markup);
				$response->headers->set('Content-Disposition', 'inline; filename="certificado.pdf"');
				return $response;
			}
		}

		$contenido['linea1'] = array(
			'#markup' => '<strong> No hay resultados!!! </strong><br><br>',
		);
		return $contenido;
	}

	public function consulta_resultado_jurado($documento = null) {//certificados conferencista

		$connection = \Drupal::database();

		if ($documento <> null) {
			$query = $connection->query("SELECT Nombre, Tipo, Documento, Evento, Fecha, codigo, Id FROM {certificado_jurado} cert WHERE Documento = '".$documento."'");
			$certificate = [];
			if ($query) {
				foreach ($query as $key => $data){

					$certificate[$key]['id'] = isset($data->Id) ? $data->Id : $data['Id'];
					$certificate[$key]['description'] = isset($data->Evento) ? $data->Evento : $data['Evento'];
					$certificate[$key]['url'] = '/resultado-consulta-certificado-jurado-pdf/' . $certificate[$key]['id'];
				}
				if (count($certificate) == 1) {
					$this->consulta_resultado_jurado_pdf($certificate[0]['id']);
				}
			}
		}
		return [
			'#theme' => 'conferencista',
			'#data' => $certificate,
			'#cache' => [
				'max-age' => 0,
			]
		];
	}

	public function consulta_resultado_jurado_pdf($id = null) {//certificados jurado

		$connection = \Drupal::database();

		if ($id <> null) {
			$query = $connection->query("SELECT Nombre, Tipo, Documento, Evento, Fecha, codigo, Id FROM {certificado_jurado} cert WHERE Id = '".$id."'");

			if ($query) {
				foreach ($query as $row) {
					$nombre = $row->Nombre;
					$tipo = $row->Tipo;
					$documento = $row->Documento;
					$evento = $row->Evento;
					$fecha = $row->Fecha;
					$id = $row->Id;
					$codigo = isset($row->codigo) ? $row->codigo : $row['codigo'];

					$css = $this->getCssWithFonts('getCssTrabajo');
					$markupTemplate = '
											<body>
											<style>' . $css .'</style>
												<table style="table-layout: fixed; width: 1056px">
													<colgroup>
														<col style="width: 528px">
														<col style="width: 528px">
													</colgroup>
												  <tr>
												    <td colspan="4"><img src="IMAGE:logo.png" class="imgLogo"></td>
												  </tr>
												  <tr>
												    <td colspan="4"><h2 class="titulo">UNIVERSIDAD FUCS</h2></td>
												  </tr>
												  <tr>
												    <td colspan="4"><p class="certifica">Certifica que:</p></td>
												  </tr>
												  <tr>
												    <td colspan="4"><p class="nombre">'.$nombre.'</p></td>
												  </tr>
												  <tr>
												    <td colspan="4"><p class="documento">'.$tipo.' '.$documento.'</p></td>
												  </tr>
												  <tr>
												    <td colspan="4"><p class="asistio">Participó como jurado</p></td>
												  </tr>
												  <tr>
												    <td colspan="4"><p class="evento">'.$evento.'</p></td>
												  </tr>
												  <tr>
												    <td colspan="4"><p class="fecha">Realizado en Bogotá, D.C., Colombia, '.$fecha.'</p></td>
												  </tr>
												  <tr>
												    <td colspan="4"><p class="constancia">En constancia firman:</p></td>
												  </tr>
												  <tr>
														<td></td>
												    <td><img src="IMAGE:firma1.png" class="imgFirma"></td>
												    <td><img src="IMAGE:firma2.png" class="imgFirma"></td>
														<td></td>
												  </tr>
													<tr>
												    <td colspan="4"><p class="acuerdo"> AR' . $id . '-' . $codigo .'</p></td>
												  </tr>
												  <tr>
												  	<td colspan="4"><img src="IMAGE:franja.png" style="width: 100%"></td>
												  </tr>
												</table>
											</body>';

					$markup = $this->makeMarkupWithImages($markupTemplate);
					return $this->renderCertPdf($markup);
				}
			}

			else {
				$contenido = array();
				$contenido['linea1'] = array(
					'#markup' => '<strong> No hay resultados!!! </strong><br><br>',
				);
			}
		}

		else {
			$contenido = array();
			$contenido['linea1'] = array(
				'#markup' => '<strong> No hay resultados!!! </strong><br><br>',
			);
		}

		return $contenido;
	}

	public function consulta_resultado_ganador($documento = null) {//certificados conferencista

		$connection = \Drupal::database();

		if ($documento <> null) {
			$query = $connection->query("SELECT Nombre_autores, Nombre_trabajo, Evento, Posicion, Modalidad, Tipo, Documento, Fecha, codigo, Id FROM {certificado_ganador} cert WHERE Documento = '".$documento."'");
			$certificate = [];
			if ($query) {
				foreach ($query as $key => $data){

					$certificate[$key]['id'] = isset($data->Id) ? $data->Id : $data['Id'];
					$certificate[$key]['description'] = isset($data->Evento) ? $data->Evento : $data['Evento'];
					$certificate[$key]['url'] = '/resultado-consulta-certificado-ganador-pdf/' . $certificate[$key]['id'];
				}
				if (count($certificate) == 1) {
					$this->consulta_resultado_ganador_pdf($certificate[0]['id']);
				}
			}
		}
		return [
			'#theme' => 'conferencista',
			'#data' => $certificate,
			'#cache' => [
				'max-age' => 0,
			]
		];
	}

	public function consulta_resultado_ganador_pdf($id = null) {//certificados ganadores

		$connection = \Drupal::database();

		if ($id <> null) {
			$query = $connection->query("SELECT Nombre_autores, Nombre_trabajo, Evento, Posicion, Modalidad, Tipo, Documento, Fecha, codigo, Id FROM {certificado_ganador} cert WHERE Id = '".$id."'");

			if ($query) {
				foreach ($query as $row) {
					$nombre_autores = $row->Nombre_autores;
					$nombre_trabajo = $row->Nombre_trabajo;
					$evento = $row->Evento;
					$modalidad = $row->Modalidad;
					$posicion = $row->Posicion;
					$tipo = $row->Tipo;
					$documento = $row->Documento;
					$fecha = $row->Fecha;
					$id = $row->Id;
					$codigo = isset($row->codigo) ? $row->codigo : $row['codigo'];

					$css = $this->getCssWithFonts('getCssTrabajo') . $this->getCssWithFonts('getCssGanador');
					$markupTemplate = '
											<body>
											<style>' . $css .'</style>
											  <table style="table-layout: fixed; width: 1056px">
													<colgroup>
														<col style="width: 528px">
														<col style="width: 528px">
													</colgroup>
												  <tr>
												    <td colspan="4"><img src="IMAGE:logo.png" class="imgLogo"></td>
												  </tr>
												  <tr>
												    <td colspan="4"><h2 class="titulo">UNIVERSIDAD FUCS</h2></td>
												  </tr>
												  <tr>
												    <td colspan="4"><p class="certifica">Certifica que el trabajo titulado:</p></td>
												  </tr>
												  <tr>
												    <td colspan="4"><p class="nombre">'.$nombre_trabajo.'</p></td>
												  </tr>
												  <tr>
												    <td colspan="4"><p class="asistio">Realizado por los siguientes autores:</p></td>
												  </tr>
												  <tr>
												    <td colspan="4"><p class="autores">'.$nombre_autores.'</p></td>
												  </tr>
												  <tr>
												    <td colspan="4"><p class="posicion">Ocupó el: '.$posicion.'       en la modalidad: '.$modalidad.'</p></td>
												  </tr>
												  <tr>
												    <td colspan="4"><p class="evento">'.$evento.'</p></td>
												  </tr>
												  <tr>
												    <td colspan="4"><p class="fecha">Realizado en Bogotá, D.C., Colombia, '.$fecha.'</p></td>
												  </tr>
												  <tr>
												    <td colspan="4"><p class="constancia">En constancia firman:</p></td>
												  </tr>
												  <tr>
														<td></td>
												    <td><img src="IMAGE:firma1.png" class="imgFirma"></td>
												    <td><img src="IMAGE:firma2.png" class="imgFirma"></td>
														<td></td>
												  </tr>
													<tr>
												    <td colspan="4"><p class="acuerdo"> AR' . $id . '-' . $codigo .'</p></td>
												  </tr>
												  <tr>
												  	<td colspan="4"><img src="IMAGE:franja.png" style="width: 100%"></td>
												  </tr>
												</table>
											</body>';

					$markup = $this->makeMarkupWithImages($markupTemplate);
					return $this->renderCertPdf($markup);
				}
			}

			else {
				$contenido = array();
				$contenido['linea1'] = array(
					'#markup' => '<strong> No hay resultados!!! </strong><br><br>',
				);
			}
		}

		else {
			$contenido = array();
			$contenido['linea1'] = array(
				'#markup' => '<strong> No hay resultados!!! </strong><br><br>',
			);
		}

		return $contenido;
	}

	public function consulta_resultado_trabajo($documento = null) {//certificados conferencista

		$connection = \Drupal::database();

		if ($documento <> null) {
			$query = $connection->query("SELECT Nombre_autores, Nombre_trabajo, Evento, Modalidad, Tipo, Documento, Fecha, Id FROM {certificado_trabajo} cert WHERE Documento = '".$documento."'");
			$certificate = [];
			if ($query) {
				foreach ($query as $key => $data){

					$certificate[$key]['id'] = isset($data->Id) ? $data->Id : $data['Id'];
					$certificate[$key]['description'] = isset($data->Evento) ? $data->Evento : $data['Evento'];
					$certificate[$key]['url'] = '/resultado-consulta-certificado-trabajo-pdf/' . $certificate[$key]['id'];
				}
				if (count($certificate) == 1) {
					$this->consulta_resultado_trabajo_pdf($certificate[0]['id']);
				}
			}
		}
		return [
			'#theme' => 'conferencista',
			'#data' => $certificate,
			'#cache' => [
				'max-age' => 0,
			]
		];
	}

	public function consulta_resultado_trabajo_pdf($id = null) {//certificados trabajos

		$connection = \Drupal::database();

		if ($id <> null) {
			$query = $connection->query("SELECT Nombre_autores, Nombre_trabajo, Evento, Modalidad, Tipo, Documento, Fecha, codigo, Id FROM {certificado_trabajo} cert WHERE Id = '".$id."'");

			if ($query) {
				foreach ($query as $row) {
					$nombre_autores = $row->Nombre_autores;
					$nombre_trabajo = $row->Nombre_trabajo;
					$evento = $row->Evento;
					$modalidad = $row->Modalidad;
					$tipo = $row->Tipo;
					$documento = $row->Documento;
					$fecha = $row->Fecha;
					$id = $row->Id;
					$codigo = isset($row->codigo) ? $row->codigo : $row['codigo'];

					$css = $this->getCssWithFonts('getCssTrabajo');
					$markupTemplate = '
											<body>
												<style>' . $css .'</style>
												<table style="table-layout: fixed; width: 1056px">
													<colgroup>
														<col style="width: 528px">
														<col style="width: 528px">
													</colgroup>
												  <tr>
												    <td colspan="4"><img src="IMAGE:logo.png" class="imgLogo"></td>
												  </tr>
												  <tr>
												    <td colspan="4"><h2 class="titulo">UNIVERSIDAD FUCS</h2></td>
												  </tr>
												  <tr>
												    <td colspan="4"><p class="certifica">Certifica que el trabajo titulado:</p></td>
												  </tr>
												  <tr>
												    <td colspan="4"><p class="nombre">'.$nombre_trabajo.'</p></td>
												  </tr>
												  <tr>
												    <td colspan="4"><p class="asistio">Realizado por los siguientes autores:</p></td>
												  </tr>
												  <tr>
												    <td colspan="4"><p class="autores">'.$nombre_autores.'</p></td>
												  </tr>
												  <tr>
												    <td colspan="4"><p class="posicion">Fue presentado en la modalidad: '.$modalidad.'</p></td>
												  </tr>
												  <tr>
												    <td colspan="4"><p class="evento">'.$evento.'</p></td>
												  </tr>
												  <tr>
												    <td colspan="4"><p class="fecha">Realizado en Bogotá, D.C., Colombia, '.$fecha.'</p></td>
												  </tr>
												  <tr>
												    <td colspan="4"><p class="constancia">En constancia firman:</p></td>
												  </tr>
												  <tr>
														<td></td>
												    <td><img src="IMAGE:firma1.png" class="imgFirma"></td>
												    <td><img src="IMAGE:firma2.png" class="imgFirma"></td>
														<td></td>
												  </tr>
													<tr>
												    <td colspan="4"><p class="acuerdo"> AR' . $id . '-' . $codigo .'</p></td>
												  </tr>
												  <tr>
												  	<td colspan="4"><img src="IMAGE:franja.png" style="width: 100%"></td>
												  </tr>
												</table>
											</body>';
					$markup = $this->makeMarkupWithImages($markupTemplate);
					return $this->renderCertPdf($markup);
				}
			}

			else {
				$contenido = array();
				$contenido['linea1'] = array(
					'#markup' => '<strong> No hay resultados!!! </strong><br><br>',
				);
			}
		}

		else {
			$contenido = array();
			$contenido['linea1'] = array(
				'#markup' => '<strong> No hay resultados!!! </strong><br><br>',
			);
		}

		return $contenido;
	}

	public function getNormalize() {
		return '
		html {
			line-height: 1.15; /* 1 */
			-webkit-text-size-adjust: 100%; /* 2 */
		}
		body {
			margin: 0;
		}
		main {
			display: block;
		}
		h1 {
			font-size: 2em;
			margin: 0.67em 0;
		}
		hr {
			box-sizing: content-box; /* 1 */
			height: 0; /* 1 */
			overflow: visible; /* 2 */
		}
		pre {
			font-family: monospace, monospace; /* 1 */
			font-size: 1em; /* 2 */
		}
		a {
			background-color: transparent;
		}
		abbr[title] {
			border-bottom: none; /* 1 */
			text-decoration: underline; /* 2 */
			text-decoration: underline dotted; /* 2 */
		}
		b,
		strong {
			font-weight: bolder;
		}
		code,
		kbd,
		samp {
			font-family: monospace, monospace; /* 1 */
			font-size: 1em; /* 2 */
		}
		small {
			font-size: 80%;
		}
		sub,
		sup {
			font-size: 75%;
			line-height: 0;
			position: relative;
			vertical-align: baseline;
		}
		
		sub {
			bottom: -0.25em;
		}
		
		sup {
			top: -0.5em;
		}
		
		img {
			border-style: none;
		}
		button,
		input,
		optgroup,
		select,
		textarea {
			font-family: inherit; 
			font-size: 100%;
			line-height: 1.15;
			margin: 0; 
		}
		button,
		input { /* 1 */
			overflow: visible;
		}
		button,
		select { /* 1 */
			text-transform: none;
		}
		button,
		[type="button"],
		[type="reset"],
		[type="submit"] {
			-webkit-appearance: button;
		}
		button::-moz-focus-inner,
		[type="button"]::-moz-focus-inner,
		[type="reset"]::-moz-focus-inner,
		[type="submit"]::-moz-focus-inner {
			border-style: none;
			padding: 0;
		}
		button:-moz-focusring,
		[type="button"]:-moz-focusring,
		[type="reset"]:-moz-focusring,
		[type="submit"]:-moz-focusring {
			outline: 1px dotted ButtonText;
		}
		fieldset {
			padding: 0.35em 0.75em 0.625em;
		}
		legend {
			box-sizing: border-box; /* 1 */
			color: inherit; /* 2 */
			display: table; /* 1 */
			max-width: 100%; /* 1 */
			padding: 0; /* 3 */
			white-space: normal; /* 1 */
		}
		progress {
			vertical-align: baseline;
		}
		textarea {
			overflow: auto;
		}
		[type="checkbox"],
		[type="radio"] {
			box-sizing: border-box; /* 1 */
			padding: 0; /* 2 */
		}
		[type="number"]::-webkit-inner-spin-button,
		[type="number"]::-webkit-outer-spin-button {
			height: auto;
		}
		[type="search"] {
			-webkit-appearance: textfield; /* 1 */
			outline-offset: -2px; /* 2 */
		}
		[type="search"]::-webkit-search-decoration {
			-webkit-appearance: none;
		}
		::-webkit-file-upload-button {
			-webkit-appearance: button; /* 1 */
			font: inherit; /* 2 */
		}
		details {
			display: block;
		}
		summary {
			display: list-item;
		}
		template {
			display: none;
		}
		[hidden] {
			display: none;
		}
		';
	}

	public function getCssTrabajo() {
		return '
		@font-face {
			font-family: "coronet";
			src: url("'.DRUPAL_ROOT .'/modules/custom/certificados/css/fonts/Coronet.eot");
			src: url("'.DRUPAL_ROOT .'/modules/custom/certificados/css/fonts/Coronet.eot?#iefix") format("embedded-opentype"),
					url("'.DRUPAL_ROOT .'/modules/custom/certificados/css/fonts/Coronet.woff2") format("woff2"),
					url("'.DRUPAL_ROOT .'/modules/custom/certificados/css/fonts/Coronet.woff") format("woff"),
					url("'.DRUPAL_ROOT .'/modules/custom/certificados/css/fonts/Coronet.ttf") format("truetype"),
					url("'.DRUPAL_ROOT .'/modules/custom/certificados/css/fonts/Coronet.svg#Coronet") format("svg");
			font-weight: normal;
			font-style: normal;
		}
		@font-face {
			font-family: "erasDemi";
			src: url("'.DRUPAL_ROOT .'/modules/custom/certificados/css/fonts/ErasITC-Demi.eot");
			src: url("'.DRUPAL_ROOT .'/modules/custom/certificados/css/fonts/ErasITC-Demi.eot?#iefix") format("embedded-opentype"),
					url("'.DRUPAL_ROOT .'/modules/custom/certificados/css/fonts/ErasITC-Demi.woff2") format("woff2"),
					url("'.DRUPAL_ROOT .'/modules/custom/certificados/css/fonts/ErasITC-Demi.woff") format("woff"),
					url("'.DRUPAL_ROOT .'/modules/custom/certificados/css/fonts/ErasITC-Demi.ttf") format("truetype"),
					url("'.DRUPAL_ROOT .'/modules/custom/certificados/css/fonts/ErasITC-Demi.svg#ErasITC-Demi") format("svg");
			font-weight: normal;
			font-style: normal;
		}
		
		@font-face {
			font-family: "erasMedium";
			src: url("'.DRUPAL_ROOT .'/modules/custom/certificados/css/fonts/ErasITC-Medium.eot");
			src: url("'.DRUPAL_ROOT .'/modules/custom/certificados/css/fonts/ErasITC-Medium.eot?#iefix") format("embedded-opentype"),
					url("'.DRUPAL_ROOT .'/modules/custom/certificados/css/fonts/ErasITC-Medium.woff2") format("woff2"),
					url("'.DRUPAL_ROOT .'/modules/custom/certificados/css/fonts/ErasITC-Medium.woff") format("woff"),
					url("'.DRUPAL_ROOT .'/modules/custom/certificados/css/fonts/ErasITC-Medium.ttf") format("truetype"),
					url("'.DRUPAL_ROOT .'/modules/custom/certificados/css/fonts/ErasITC-Medium.svg#ErasITC-Medium") format("svg");
			font-weight: 500;
			font-style: normal;
		}
		
		@font-face {
			font-family: "erasBold";
			src: url("'.DRUPAL_ROOT .'/modules/custom/certificados/css/fonts/ErasITC-Bold.eot");
			src: url("'.DRUPAL_ROOT .'/modules/custom/certificados/css/fonts/ErasITC-Bold.eot?#iefix") format("embedded-opentype"),
					url("'.DRUPAL_ROOT .'/modules/custom/certificados/css/fonts/ErasITC-Bold.woff2") format("woff2"),
					url("'.DRUPAL_ROOT .'/modules/custom/certificados/css/fonts/ErasITC-Bold.woff") format("woff"),
					url("'.DRUPAL_ROOT .'/modules/custom/certificados/css/fonts/ErasITC-Bold.ttf") format("truetype"),
					url("'.DRUPAL_ROOT .'/modules/custom/certificados/css/fonts/ErasITC-Bold.svg#ErasITC-Bold") format("svg");
			font-weight: bold;
			font-style: normal;
		}
		
		html
		{
			border: none !important;
			margin: 0 !important;
			padding: 0 !important;
		}
		
		body
		{
			border: none !important;
			color: black;
			height: 100% !important;
			margin: 0 !important;
			overflow: hidden;
			padding: 0 !important;
			text-align: center;
			width: 100% !important;
		}
		
		table
		{
			border: none !important;
			margin: 0 !important;
			padding: 0 !important;
			text-align: center;
		}
		
		p
		{
			border: none !important;
			color: black;
			display: block;
			overflow: hidden;
			overflow-wrap: break-word !important;
			padding: 0;
			position: relative;
			text-align: center;
		}
		
		td
		{
			overflow-wrap: break-word !important;
		}
		
		td p, td h2, td img
		{
			margin: 0 !important;
			padding: 0 !important;
		}
		
		img
		{
			display: block;
		}
		
		.respuestaCertificado
		{
			height: 100%;
			width: 100%
		}
		
		td img.imgLogo
		{
			padding: 10px 0 0 !important;
		}
		
		.titulo
		{
			color: #001160;
			font: normal 28px "erasDemi";
			padding: 0 0 10px;
			text-align: center;
			text-transform: uppercase;
		}
		
		.certifica
		{
			font: normal 15px "erasDemi";
			padding: 0 0 10px !important;
		}
		
		.nombre
		{
			font: 500 17px "erasMedium";
			padding: 0 0 10px !important;
			vertical-align: middle !important;
		}
		
		.asistio
		{
			font: 500 15px "erasMedium";
			padding: 0 0 30px;
		}
		
		.autores
		{
			background: url('.DRUPAL_ROOT .'/modules/custom/certificados/css/images/fondoNombre.png) no-repeat center;
			background-size: cover;
			font: normal 25px "coronet";
			line-height: 30px !important;
			padding: 0 0 20px !important;
			text-transform: capitalize;
			vertical-align: middle !important;
		}
		
		.posicion, .evento
		{
			font: normal 16px "erasDemi";
			padding: 0 0 10px !important;
		}
		
		.fecha
		{
			font: 500 16px "erasMedium";
			padding: 0 0 10px !important;
		}
		
		.constancia
		{
			font: normal 16px "erasDemi";
			padding: 0 0 10px;
		}
		
		.acuerdo {
			font: 500 12px "erasMedium";
		}
		';
	}

	public function getCssGanador() {
		return '
			@font-face {
				font-family: "coronet";
				src: url("'.DRUPAL_ROOT .'/modules/custom/certificados/css/fonts/Coronet.eot");
				src: url("'.DRUPAL_ROOT .'/modules/custom/certificados/css/fonts/Coronet.eot?#iefix") format("embedded-opentype"),
						url("'.DRUPAL_ROOT .'/modules/custom/certificados/css/fonts/Coronet.woff2") format("woff2"),
						url("'.DRUPAL_ROOT .'/modules/custom/certificados/css/fonts/Coronet.woff") format("woff"),
						url("'.DRUPAL_ROOT .'/modules/custom/certificados/css/fonts/Coronet.ttf") format("truetype"),
						url("'.DRUPAL_ROOT .'/modules/custom/certificados/css/fonts/Coronet.svg#Coronet") format("svg");
				font-weight: normal;
				font-style: normal;
			}
			@font-face {
				font-family: "erasDemi";
				src: url("'.DRUPAL_ROOT .'/modules/custom/certificados/css/fonts/ErasITC-Demi.eot");
				src: url("'.DRUPAL_ROOT .'/modules/custom/certificados/css/fonts/ErasITC-Demi.eot?#iefix") format("embedded-opentype"),
						url("'.DRUPAL_ROOT .'/modules/custom/certificados/css/fonts/ErasITC-Demi.woff2") format("woff2"),
						url("'.DRUPAL_ROOT .'/modules/custom/certificados/css/fonts/ErasITC-Demi.woff") format("woff"),
						url("'.DRUPAL_ROOT .'/modules/custom/certificados/css/fonts/ErasITC-Demi.ttf") format("truetype"),
						url("'.DRUPAL_ROOT .'/modules/custom/certificados/css/fonts/ErasITC-Demi.svg#ErasITC-Demi") format("svg");
				font-weight: normal;
				font-style: normal;
			}
			
			@font-face {
				font-family: "erasMedium";
				src: url("'.DRUPAL_ROOT .'/modules/custom/certificados/css/fonts/ErasITC-Medium.eot");
				src: url("'.DRUPAL_ROOT .'/modules/custom/certificados/css/fonts/ErasITC-Medium.eot?#iefix") format("embedded-opentype"),
						url("'.DRUPAL_ROOT .'/modules/custom/certificados/css/fonts/ErasITC-Medium.woff2") format("woff2"),
						url("'.DRUPAL_ROOT .'/modules/custom/certificados/css/fonts/ErasITC-Medium.woff") format("woff"),
						url("'.DRUPAL_ROOT .'/modules/custom/certificados/css/fonts/ErasITC-Medium.ttf") format("truetype"),
						url("'.DRUPAL_ROOT .'/modules/custom/certificados/css/fonts/ErasITC-Medium.svg#ErasITC-Medium") format("svg");
				font-weight: 500;
				font-style: normal;
			}
			
			@font-face {
				font-family: "erasBold";
				src: url("'.DRUPAL_ROOT .'/modules/custom/certificados/css/fonts/ErasITC-Bold.eot");
				src: url("'.DRUPAL_ROOT .'/modules/custom/certificados/css/fonts/ErasITC-Bold.eot?#iefix") format("embedded-opentype"),
						url("'.DRUPAL_ROOT .'/modules/custom/certificados/css/fonts/ErasITC-Bold.woff2") format("woff2"),
						url("'.DRUPAL_ROOT .'/modules/custom/certificados/css/fonts/ErasITC-Bold.woff") format("woff"),
						url("'.DRUPAL_ROOT .'/modules/custom/certificados/css/fonts/ErasITC-Bold.ttf") format("truetype"),
						url("'.DRUPAL_ROOT .'/modules/custom/certificados/css/fonts/ErasITC-Bold.svg#ErasITC-Bold") format("svg");
				font-weight: bold;
				font-style: normal;
			}
			
			html
			{
				border: none !important;
				margin: 0 !important;
				padding: 0 !important;
			}
			
			body
			{
				border: none !important;
				color: black;
				height: 100% !important;
				margin: 0 !important;
				overflow: hidden;
				padding: 0 !important;
				text-align: center;
				width: 100% !important;
			}
			
			table
			{
				border: none !important;
				margin: 0 !important;
				padding: 0 !important;
				text-align: center;
			}
			
			p
			{
				border: none !important;
				color: black;
				display: block;
				overflow: hidden;
				overflow-wrap: break-word !important;
				padding: 0;
				position: relative;
				text-align: center;
			}
			
			td
			{
				overflow-wrap: break-word !important;
			}
			
			td p, td h2, td img
			{
				margin: 0 !important;
				padding: 0 !important;
			}
			
			img
			{
				display: block;
			}
			
			.respuestaCertificado
			{
				height: 100%;
				width: 100%
			}
			
			td img.imgLogo
			{
				padding: 10px 0 0 !important;
			}
			
			.titulo
			{
				color: #001160;
				font: normal 28px "erasDemi";
				padding: 0 0 00px;
				text-align: center;
				text-transform: uppercase;
			}
			
			.certifica
			{
				font: normal 17px "erasDemi";
				padding: 0 0 10px !important;
			}
			
			.nombre
			{
				font: 500 17px "erasMedium";
				padding: 0 0 10px !important;
			}
			
			.asistio
			{
				font: 500 17px "erasMedium";
				padding: 0 0 10px;
			}
			
			.autores
			{
				background: url('.DRUPAL_ROOT .'/modules/custom/certificados/css/images/fondoNombre.png) no-repeat center;
				background-size: cover;
				font: normal 25px "coronet";
				line-height: 25px !important;
				padding: 0 0 20px !important;
				text-transform: capitalize;
				vertical-align: middle !important;
			}
			
			.posicion, .evento
			{
				font: normal 19px "erasDemi";
				padding: 0 0 10px !important;
			}
			
			.fecha
			{
				font: 500 18px "erasMedium";
				padding: 0 0 10px !important;
			}
			
			.constancia
			{
				font: normal 18px "erasDemi";
				padding: 0 0 30px;
			}
			
			.acuerdo {
				font: 500 12px "erasMedium";
			}
		';
	}

	public function getCssStyle() {
		return '
			@font-face {
				font-family: "coronet";
				src: url("'.DRUPAL_ROOT .'/modules/custom/certificados/css/fonts/Coronet.eot");
				src: url("'.DRUPAL_ROOT .'/modules/custom/certificados/css/fonts/Coronet.eot?#iefix") format("embedded-opentype"),
						url("'.DRUPAL_ROOT .'/modules/custom/certificados/css/fonts/Coronet.woff2") format("woff2"),
						url("'.DRUPAL_ROOT .'/modules/custom/certificados/css/fonts/Coronet.woff") format("woff"),
						url("'.DRUPAL_ROOT .'/modules/custom/certificados/css/fonts/Coronet.ttf") format("truetype"),
						url("'.DRUPAL_ROOT .'/modules/custom/certificados/css/fonts/Coronet.svg#Coronet") format("svg");
				font-weight: normal;
				font-style: normal;
			}
			@font-face {
				font-family: "erasDemi";
				src: url("'.DRUPAL_ROOT .'/modules/custom/certificados/css/fonts/ErasITC-Demi.eot");
				src: url("'.DRUPAL_ROOT .'/modules/custom/certificados/css/fonts/ErasITC-Demi.eot?#iefix") format("embedded-opentype"),
						url("'.DRUPAL_ROOT .'/modules/custom/certificados/css/fonts/ErasITC-Demi.woff2") format("woff2"),
						url("'.DRUPAL_ROOT .'/modules/custom/certificados/css/fonts/ErasITC-Demi.woff") format("woff"),
						url("'.DRUPAL_ROOT .'/modules/custom/certificados/css/fonts/ErasITC-Demi.ttf") format("truetype"),
						url("'.DRUPAL_ROOT .'/modules/custom/certificados/css/fonts/ErasITC-Demi.svg#ErasITC-Demi") format("svg");
				font-weight: normal;
				font-style: normal;
			}
			
			@font-face {
				font-family: "erasMedium";
				src: url("'.DRUPAL_ROOT .'/modules/custom/certificados/css/fonts/ErasITC-Medium.eot");
				src: url("'.DRUPAL_ROOT .'/modules/custom/certificados/css/fonts/ErasITC-Medium.eot?#iefix") format("embedded-opentype"),
						url("'.DRUPAL_ROOT .'/modules/custom/certificados/css/fonts/ErasITC-Medium.woff2") format("woff2"),
						url("'.DRUPAL_ROOT .'/modules/custom/certificados/css/fonts/ErasITC-Medium.woff") format("woff"),
						url("'.DRUPAL_ROOT .'/modules/custom/certificados/css/fonts/ErasITC-Medium.ttf") format("truetype"),
						url("'.DRUPAL_ROOT .'/modules/custom/certificados/css/fonts/ErasITC-Medium.svg#ErasITC-Medium") format("svg");
				font-weight: 500;
				font-style: normal;
			}
			
			@font-face {
				font-family: "erasBold";
				src: url("'.DRUPAL_ROOT .'/modules/custom/certificados/css/fonts/ErasITC-Bold.eot");
				src: url("'.DRUPAL_ROOT .'/modules/custom/certificados/css/fonts/ErasITC-Bold.eot?#iefix") format("embedded-opentype"),
						url("'.DRUPAL_ROOT .'/modules/custom/certificados/css/fonts/ErasITC-Bold.woff2") format("woff2"),
						url("'.DRUPAL_ROOT .'/modules/custom/certificados/css/fonts/ErasITC-Bold.woff") format("woff"),
						url("'.DRUPAL_ROOT .'/modules/custom/certificados/css/fonts/ErasITC-Bold.ttf") format("truetype"),
						url("'.DRUPAL_ROOT .'/modules/custom/certificados/css/fonts/ErasITC-Bold.svg#ErasITC-Bold") format("svg");
				font-weight: bold;
				font-style: normal;
			}
			
			html
			{
				border: none !important;
				margin: 0 !important;
				padding: 0 !important;
			}
			
			body
			{
				border: none !important;
				color: black;
				height: 100% !important;
				margin: 0 !important;
				overflow: hidden;
				padding: 0 !important;
				text-align: center;
				width: 100% !important;
			}
			
			table
			{
				border: none !important;
				margin: 0 !important;
				padding: 0 !important;
				text-align: center;
			}
			
			p
			{
				border: none !important;
				color: black;
				display: block;
				overflow: hidden;
				padding: 0;
				position: relative;
				text-align: center;
			}
			
			td p, td h2, td img
			{
				margin: 0 !important;
				padding: 0 !important;
			}
			
			img
			{
				display: block;
			}
			
			.respuestaCertificado
			{
				height: 100%;
				width: 100%
			}
			
			td img.imgLogo
			{
				padding: 10px 0 0 !important;
			}
			
			.titulo
			{
				color: #001160;
				font: normal 28px "erasDemi";
				padding: 0 0 30px;
				text-align: center;
				text-transform: uppercase;
			}
			
			.certifica
			{
				font: normal 17px "erasDemi";
				padding: 0 0 30px;
			}
			
			.nombre
			{
				background: url('.DRUPAL_ROOT .'/modules/custom/certificados/css/images/fondoNombre.png) no-repeat center;
				background-size: cover;
				font: normal 30px "coronet";
				padding: 0 0 30px;
				text-transform: capitalize;
			}
			
			.documento
			{
				font: normal 24px "coronet";
				padding: 0 0 10px !important;
			}
			
			.asistio
			{
				font: 500 17px "erasMedium";
				padding: 0 0 10px;
			}
			
			.evento
			{
				font: normal 19px "erasDemi";
				padding: 0 0 30px;
			}
			
			.fecha
			{
				font: 500 18px "erasMedium";
				padding: 0 0 27px !important;
			}
			
			.acuerdo {
				font: 500 12px "erasMedium";
			}
			
			.constancia
			{
				font: normal 18px "erasDemi";
				padding: 0 0 10px;
			}
			
			.autores{
				font-size:10px
			}
		';
	}

	/**
	 * Helper to render PDF from markup.
	 */
	private function renderCertPdf($markup) {
		$options = new Options();
		$options->set('isRemoteEnabled', false);
		$dompdf = new Dompdf($options);
		$dompdf->loadHtml($markup);
		$dompdf->setPaper('letter', 'landscape');
		$dompdf->render();

		$pdfOutput = $dompdf->output();

		$response = new Response($pdfOutput);
		$response->headers->set('Content-Type', 'application/pdf');
		$response->headers->set('Content-Disposition', 'inline; filename="certificado.pdf"');

		return $response;
	}

	/**
	 * Helper to get CSS with embedded base64 fonts.
	 */
	private function getCssWithFonts($cssMethod) {
		$fonts = $this->getEmbeddedFonts();
		$rawCss = $this->$cssMethod();
		$root = \Drupal::root();
		$imageDir = $root . '/modules/custom/certificados/css/images/';

		$replacements = [];
		foreach ($fonts as $name => $fontData) {
			foreach ($fontData as $format => $dataUri) {
				$oldFont = 'url("' . $root . '/modules/custom/certificados/css/fonts/' . $name . '")';
				$replacements[$oldFont] = $dataUri;
				$oldFix = 'url("' . $root . '/modules/custom/certificados/css/fonts/' . $name . '?#iefix")';
				$replacements[$oldFix] = $dataUri;
			}
		}
		$fondoPath = $imageDir . 'fondoNombre.png';
		if (file_exists($fondoPath)) {
			$fondoB64 = 'data:' . mime_content_type($fondoPath) . ';base64,' . base64_encode(file_get_contents($fondoPath));
			$replacements['url(' . $imageDir . 'fondoNombre.png)'] = $fondoB64;
		}

		return str_replace(array_keys($replacements), array_values($replacements), $rawCss);
	}

	/**
	 * Load and cache all fonts as base64 data URIs.
	 */
	private function getEmbeddedFonts() {
		if (!empty($this->fontCache)) {
			return $this->fontCache;
		}

		$fontDir = \Drupal::root() . '/modules/custom/certificados/css/fonts/';
		$fonts = [
			'Coronet' => ['eot', 'woff2', 'woff', 'ttf', 'svg'],
			'ErasITC-Demi' => ['eot', 'woff2', 'woff', 'ttf', 'svg'],
			'ErasITC-Medium' => ['eot', 'woff2', 'woff', 'ttf', 'svg'],
			'ErasITC-Bold' => ['eot', 'woff2', 'woff', 'ttf', 'svg'],
		];

		foreach ($fonts as $name => $formats) {
			$this->fontCache[$name] = [];
			foreach ($formats as $fmt) {
				$file = $fontDir . $name . '.' . $fmt;
				if (file_exists($file)) {
					$contents = file_get_contents($file);
					if ($fmt === 'svg') {
						$mimeType = 'image/svg+xml';
					} elseif ($fmt === 'woff2') {
						$mimeType = 'font/woff2';
					} elseif ($fmt === 'woff') {
						$mimeType = 'font/woff';
					} elseif ($fmt === 'ttf') {
						$mimeType = 'font/ttf';
					} else {
						$mimeType = 'application/vnd.ms-fontobject';
					}
					$this->fontCache[$name][$fmt] = 'data:' . $mimeType . ';base64,' . base64_encode($contents);
				}
			}
		}

		return $this->fontCache;
	}

	/**
	 * Replace IMAGE: placeholders in markup with base64 data URIs.
	 */
	private function makeMarkupWithImages($markup) {
		$imageDir = \Drupal::root() . '/modules/custom/certificados/css/images/';
		$imageFiles = ['logo.png', 'firma1.png', 'firma2.png', 'franja.png'];
		$imageNames = ['logo', 'firma1', 'firma2', 'franja'];
		$keys = [];
		$values = [];
		foreach ($imageFiles as $i => $f) {
			$name = $imageNames[$i];
			$dataUri = $this->base64Image($imageDir . $f);
			$keys[] = '"IMAGE:' . $f . '"';
			$values[] = '"' . $dataUri . '"';
		}
		return str_replace($keys, $values, $markup);
	}

	/**
	 * Convert an image file to base64 data URI with caching.
	 */
	private function base64Image($filePath) {
		if (!file_exists($filePath)) {
			return '';
		}
		if (!isset($this->imageCache[$filePath])) {
			$contents = file_get_contents($filePath);
			$mimeType = mime_content_type($filePath);
			$this->imageCache[$filePath] = 'data:' . $mimeType . ';base64,' . base64_encode($contents);
		}
		return $this->imageCache[$filePath];
	}

}