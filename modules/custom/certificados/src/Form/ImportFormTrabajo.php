<?php

namespace Drupal\certificados\Form;

use Drupal\Core\Form\FormBase;
use Drupal\Core\Form\FormStateInterface;
use Drupal\file\Entity\File;
use Drupal\certificados\Services\Utils;

/**
 *
 */
class ImportFormTrabajo extends FormBase {

  /**
   * {@inheritdoc}
   */
  public function getFormId() {
    return 'certificados_form_trabajo';
  }

  /**
   * {@inheritdoc}
   */
  public function buildForm(array $form, FormStateInterface $form_state) {

    // Crea encabezado del formulario.
    $form['description'] = [
      '#markup' => '<p>Use este campo para importar su archivo formato CSV</p>',
    ];

    // Crea el campo para subir el archivo CSV.
    $form['import_csv'] = [
      '#type' => 'managed_file',
      '#title' => t('Subir archivo aqui'),
      '#upload_location' => 'public://',
      '#default_value' => '',
      "#upload_validators"  => ["file_validate_extensions" => ["csv"]],
      '#states' => [
        'visible' => [
          ':input[name="File_type"]' => ['value' => t('Seleccione el archivo')],
        ],
      ],
    ];

    // Crea el boton para enviar el archivo CSV.
    $form['actions']['#type'] = 'actions';
    $form['actions']['submit'] = [
      '#type' => 'submit',
      '#value' => $this->t('Subir CSV'),
      '#button_type' => 'primary',
    ];

    return $form;
  }

  /**
   * {@inheritdoc}
   */
  public function submitForm(array &$form, FormStateInterface $form_state) {

    $csv_file = $form_state->getValue('import_csv');
    $file = File::load($csv_file[0]);
    $file->setPermanent();
    $file->save();
    $data = $this->readCSV($file->getFileUri());
    $connection = \Drupal::database();
    $conteo = 0;
		$utils = new Utils();

    foreach ($data as $row) {
      $conteo++;
			$row = $utils->fix_row_utf8($row);
      $result = $connection->insert('certificado_trabajo')
        ->fields([
          'Nombre_autores' => $row['nombre_autores'],
          'Nombre_trabajo' => $row['nombre_trabajo'],
          'Modalidad' => $row['modalidad'],
          'Tipo' => $row['tipo'],
          'Documento' => $row['documento'],
          'Evento' => $row['evento'],
          'Fecha' => $row['fecha'],
          'codigo' => $row['codigo'],
        ])->execute();
    }

    // Mensaje de que se importo el listado.
    $this->messenger()->addStatus(t('Se crearon @conteo registros de manera correcta. ', ['@conteo' => $conteo]));
  }

  /**
   *
   */
  public function readCSV($csvFile) {
    // Detecta en que momento se termina cada fila del archivo CSV.
    ini_set('auto_detect_line_endings', TRUE);

    // Variable que controla numero de filas.
    $row = 0;
    // Variable para identificar los encabezados de las filas.
    $header = NULL;
    // Array para ir guardado los datos del CSV.
    $datos = [];
    // Abre el archivo CSV.
    $file_handle = fopen($csvFile, 'r');

    // Ciclo para leer lineas por linea el CSV.
    while (!feof($file_handle)) {
      $line_of_text[] = fgetcsv($file_handle, 1024, ';');

      if (!$header) {
        // Guarda en la variable los encabezados de las filas del CSV.
        $header = $line_of_text[$row];
      }
      // Guarda los datos en un array con cadaencabezado correspondiente.
      else {
        $datos[] = array_combine($header, $line_of_text[$row]);
      }

      // Aumenta el contador de filas.
      $row++;
    }

    // Cierra el archivo CSV.
    fclose($file_handle);

    return $datos;

    // Cierra la lectura de fin de filas.
    ini_set('auto_detect_line_endings', FALSE);
  }

}
