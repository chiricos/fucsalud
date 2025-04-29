<?php
/**
 * @file
 * Contains \Drupal\admitidos\Form\ImportForm.
 */
namespace Drupal\admitidos\Form;

use Drupal\Core\Form\FormBase;
use Drupal\Core\Form\FormStateInterface;
use Drupal\node\Entity\Node;
use Drupal\file\Entity\File;

class ImportForm extends FormBase {
	/**
	 * {@inheritdoc}
	 */
	public function getFormId() {
		return 'admitidos_form';
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

		$connection->delete('aspirantes')->execute();

		//Variable para controlar número de registros creados
		$conteo = 0;
		
		//Ciclo para insertar en base de datos lo que venga en cada linea del archivi CSV
		foreach($data as $row) {
			$conteo++;
			$result = $connection->insert('aspirantes')
				->fields([
				'Carrera' => $row['carrera'],
				'Nombre' => $row['nombre'],
				'Documento' => $row['documento'],
				'Estado' => $row['estado']
			])->execute();
		}

		//Mensaje de que se importo el listado
		$this->messenger()->addStatus(t('Se crearon @conteo registros de manera correcta. ', array('@conteo' => $conteo)));
	}

	public function readCSV($csvFile){
		$row = 0;
		$header = null;
		$datos = [];

		// Leer y normalizar el contenido del archivo CSV
		$csv_content = file_get_contents($csvFile);
		$csv_content = str_replace(["\r\n", "\r"], "\n", $csv_content);

		// Crear un archivo temporal con el contenido normalizado
		$temp = tmpfile();
		fwrite($temp, $csv_content);
		rewind($temp);

		while (($line = fgetcsv($temp, 1024, ',')) !== false) {
				if (!$header) {
						$header = $line;
				} else {
						$datos[] = array_combine($header, $line);
				}
		}

		fclose($temp);

		return $datos;
	}
}