<?php
/**
 * @file
 * Contains \Drupal\certificados\Form\ImportForm.
 */
namespace Drupal\certificados\Form;

use Drupal\Core\Form\FormBase;
use Drupal\Core\Form\FormStateInterface;
use Drupal\node\Entity\Node;
use Drupal\file\Entity\File;
use Drupal\certificados\Services\Utils;

class ImportFormConferencista extends FormBase {
	/**
	 * {@inheritdoc}
	 */
	public function getFormId() {
		return 'certificados_form_conferencista';
	}
	/**
	 * {@inheritdoc}
	 */
	public function buildForm(array $form, FormStateInterface $form_state) {

		//Crea encabezado del formulario
		$form['description'] = array(
			'#markup' => '<p>Use este campo para importar su archivo formato CSV</p>',
		);

		//Crea el campo para subir el archivo CSV
		$form['import_csv'] = array(
			'#type' => 'managed_file',
			'#title' => t('Subir archivo aqui'),
			'#upload_location' => 'public://',
			'#default_value' => '',
			"#upload_validators"  => array("file_validate_extensions" => array("csv")),
			'#states' => array(
				'visible' => array(
					':input[name="File_type"]' => array('value' => t('Seleccione el archivo')),
				),
			),
		);

		//Crea el boton para enviar el archivo CSV
		$form['actions']['#type'] = 'actions';
		$form['actions']['submit'] = array(
			'#type' => 'submit',
			'#value' => $this->t('Subir CSV'),
			'#button_type' => 'primary',
		);

		return $form;
	}

	/**
	 * {@inheritdoc}
	 */
	public function submitForm(array &$form, FormStateInterface $form_state) {

		//Obtiene el valor que viene del campo para subir el archivo CSV
		$csv_file = $form_state->getValue('import_csv');

		//Lee el archivo y guarda en base de datos el nombre
		$file = File::load( $csv_file[0] );
		$file->setPermanent();
		$file->save();

		//Lee la ruta y nombre del archivo CSV
		$data = $this->readCSV($file->getFileUri());

		//Abre coneccion a base de datos
		$connection = \Drupal::database();

		//Variable para controlar número de registros creados
		$conteo = 0;
		$utils = new Utils();

		//Ciclo para insertar en base de datos lo que venga en cada linea del archivo CSV
		foreach($data as $row) {
			$row = $utils->fix_row_utf8($row);
			$conteo++;
			$result = $connection->insert('certificado_conferencista')
				->fields([
				'Facultad' => $row['facultad'],
				'Nombre' => $row['nombre'],
				'Tipo' => $row['tipo'],
				'Documento' => $row['documento'],
				'Ponencia' => $row['ponencia'],
				'Evento' => $row['evento'],
				'Fecha' => $row['fecha'],
				'codigo' => $row['codigo'],
			])->execute();
		}
		//Mensaje de que se importo el listado
		$this->messenger()->addStatus(t('Se crearon @conteo registros de manera correcta. ', array('@conteo' => $conteo)));
	}

	public function readCSV($csvFile){
		//Detecta en que momento se termina cada fila del archivo CSV
		ini_set('auto_detect_line_endings',TRUE);

		$row = 0;															//Variable que controla numero de filas
		$header = NULL;												//Variable para identificar los encabezados de las filas
		$datos = array();											//Array para ir guardado los datos del CSV
		$file_handle = fopen($csvFile, 'r');	//Abre el archivo CSV

		//Ciclo para leer lineas por linea el CSV
		while (!feof($file_handle) ) {
			$line_of_text[] = fgetcsv($file_handle, 1024, ';');

			if(!$header)
				$header = $line_of_text[$row]; //Guarda en la variable los encabezados de las filas del CSV
			else
				$datos[] = array_combine($header, $line_of_text[$row]); //Guarda los datos en un array con cadaencabezado correspondiente

			//Aumenta el contador de filas
			$row++;
		}

		//Cierra el archivo CSV
		fclose($file_handle);

		return $datos;

		//Cierra la lectura de fin de filas
		ini_set('auto_detect_line_endings',FALSE);
	}
}
