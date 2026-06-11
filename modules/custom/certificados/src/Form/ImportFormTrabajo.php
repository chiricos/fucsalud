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
      if (!is_array($row) || empty(array_filter($row))) {
        continue;
      }

      $conteo++;
      $row = $utils->fix_row_utf8($row);
      $connection->insert('certificado_trabajo')
        ->fields([
          'Nombre_autores' => $row['nombre_autores'] ?? NULL,
          'Nombre_trabajo' => $row['nombre_trabajo'] ?? NULL,
          'Modalidad' => $row['modalidad'] ?? NULL,
          'Tipo' => $row['tipo'] ?? NULL,
          'Documento' => $row['documento'] ?? NULL,
          'Evento' => $row['evento'] ?? NULL,
          'Fecha' => $row['fecha'] ?? NULL,
          'codigo' => $row['codigo'] ?? NULL,
        ])->execute();
    }

    // Mensaje de que se importo el listado.
    $this->messenger()->addStatus(t('Se crearon @conteo registros de manera correcta. ', ['@conteo' => $conteo]));
  }

  /**
   *
   */
  public function readCSV($csvFile) {
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
        foreach ($line_of_text[$row] as $key) {
          $header[] = preg_replace('/^\xEF\xBB\xBF/', '', trim($key));
        }
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
  }

}
