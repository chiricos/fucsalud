<?php

namespace Drupal\fucs_form\Form;

use Drupal\Core\Form\FormStateInterface;
use Drupal\Core\Form\ConfigFormBase;

/**
 * Provides a client data form for the block instance device register form.
 *
 * @internal
 */
class FucsExportForm extends ConfigFormBase {

  /**
   * getSettings
   *
   * @return void
   */
  protected function getEditableConfigNames() {
    return [
      'fucs.form.export',
    ];
  }

  /**
   * {@inheritdoc}
   */
  public function getFormId() {
    return 'fucs_export_form';
  }

  /**
   * {@inheritdoc}
   */
  public function buildForm(array $form, FormStateInterface $form_state) {

    $form['configurations'] = [
      '#type' => 'details',
      '#title' => $this->t('Exportar'),
      '#open' => TRUE,
    ];

    $form['configurations']['document'] = [
      '#type' => 'textfield',
      '#title' => $this->t('Número de documento'),
    ];

    $form['configurations']['email'] = [
      '#type' => 'textfield',
      '#title' => $this->t('Correo eléctronico'),
    ];

    $form['configurations']['course'] = [
      '#type' => 'textfield',
      '#required' => TRUE,
      '#title' => $this->t('Curso'),
    ];

    $form['configurations']['uuid'] = [
      '#type' => 'textfield',
      '#title' => $this->t('Identificador unico del formulario'),
    ];

    $form['configurations']['startDate'] = [
      '#type' => 'datetime',
      '#title' => $this->t('Desde'),
    ];

    $form['configurations']['endDate'] = [
      '#type' => 'datetime',
      '#title' => $this->t('Hasta'),
    ];

    $form['submit'] = [
      '#type' => 'submit',
      '#value' => 'Exportar',
    ];

    return $form;

  }

  /**
   * {@inheritdoc}
   */
  public function submitForm(array &$form, FormStateInterface $form_state) {
    $info = [
      'document' => ($form_state->getValue('document') != NULL) ? $form_state->getValue('document') : '',
      'email' => ($form_state->getValue('email') != NULL) ? $form_state->getValue('email') : '',
      'course' => ($form_state->getValue('course') != NULL) ? $form_state->getValue('course') : '',
      'uuid' => ($form_state->getValue('uuid') != NULL) ? $form_state->getValue('uuid') : '',
      'startDate' => ($form_state->getValue('startDate') != NULL) ? $form_state->getValue('startDate')->format('d-m-Y H:i:s') : '',
      'endDate' => ($form_state->getValue('endDate') != NULL) ? $form_state->getValue('endDate')->format('d-m-Y H:i:s') : '',
    ];
    $filename = "form_" . date('Ymd') . ".txt";

    header("Content-Disposition: attachment; filename=\"$filename\"");
    header("Content-Type: application/vnd.ms-excel");

    $flag = FALSE;
    foreach ($this->getData($info) as $row) {
      if (!$flag) {
        echo implode("\t", array_keys($row)) . "\r\n";
        $flag = TRUE;
      }
      //array_walk($row, 'cleanData');
      echo implode("\t", array_values($row)) . "\r\n";
    }
    exit;
  }

  /**
   * getData()
   *
   * @return array
   */
  public function getData($info) {
    $connection = \Drupal::database();
    $query = $connection->select('fucs_form')
      ->fields('fucs_form', [
        'name',
        'email',
        'document',
        'course',
        'number',
        'question',
        'type',
        'answer',
        'status',
        'min',
        'form',
        'form_id',
        'uuid',
        'min',
        'created',
      ]);
    if (!empty($info['startDate']) && !empty($info['endDate'])) {
      $query->condition('fucs_form.created', strtotime($info['startDate']), '>');
      $query->condition('fucs_form.created', strtotime($info['endDate']), '<');
    }
    elseif (!empty($info['startDate'])) {
      $query->condition('fucs_form.created', strtotime($info['startDate']), '>');
    }
    elseif (!empty($info['endDate'])) {
      $query->condition('fucs_form.created', strtotime($info['endDate']), '<');
    }
    elseif (!empty($info['document'])) {
      $query->condition('fucs_form.document', $info['document'], '=');
    }
    elseif (!empty($info['email'])) {
      $query->condition('fucs_form.email', '%' . $info['email'] . '%', 'LIKE');
    }
    elseif (!empty($info['course'])) {
      $query->condition('fucs_form.course', '%' . $info['course'] . '%', 'LIKE');
    }
    elseif (!empty($info['uuid'])) {
      $query->condition('fucs_form.uuid', $info['uuid'], '=');
    }
    $query->orderBy('document', 'ASC');

    $data = $query->execute();
    $results = $data->fetchAll(\PDO::FETCH_OBJ);
    $data = [];
    $formatDate = \Drupal::service('date.formatter');
    $count = 0;
    foreach ($results as $value) {
      $equal = FALSE;
      if (count($data) > 0) {
        foreach ($data as &$item) {
          if (isset($item["Id del fomulario"]) && $value->form_id == $item["Id del fomulario"]) {
            $item["Respuestas buenas"] = ($value->status == "correcto") ? $item["Respuestas buenas"] + 1 : $item["Respuestas buenas"];
            $item['Respuestas malas'] = ($value->status != "correcto") ? $item['Respuestas malas'] + 1 : $item['Respuestas malas'];
            $equal = TRUE;
          }

        }
        if (!$equal) {
          if (!isset($data[$value->form_id][$value->document]['Respuestas buenas'])) {
            $data[$value->form_id][$value->document]['Respuestas buenas'] = 0;
          }
          if (!isset($data[$value->form_id][$value->document]['Respuestas malas'])) {
            $data[$value->form_id][$value->document]['Respuestas malas'] = 0;
          }
          $data[$value->form_id][$value->document]['Nombre'] = $value->name;
          $data[$value->form_id][$value->document]['Correo'] = $value->email;
          $data[$value->form_id][$value->document]['Numero de identidad'] = $value->document;
          $data[$value->form_id][$value->document]['Curso'] = $value->course;
          $data[$value->form_id][$value->document]['Minimo para pasar'] = $value->min . " %";
          $data[$value->form_id][$value->document]['Respuestas buenas'] = ($value->status == "correcto") ? $data[$value->form_id][$value->document]['Respuestas buenas'] + 1 : $data[$value->form_id][$value->document]['Respuestas buenas'];
          $data[$value->form_id][$value->document]['Respuestas malas'] = ($value->status != "correcto") ? $data[$value->form_id][$value->document]['Respuestas malas'] + 1 : $data[$value->form_id][$value->document]['Respuestas malas'];
          $data[$value->form_id][$value->document]['Porcentaje'] = ($data[$value->form_id][$value->document]['Respuestas buenas'] * 100) / ($data[$value->form_id][$value->document]['Respuestas buenas'] + $data[$value->form_id][$value->document]['Respuestas malas']) . " %";
          $data[$value->form_id][$value->document]['Estado'] = ($data[$value->form_id][$value->document]['Respuestas buenas'] * 100) / ($data[$value->form_id][$value->document]['Respuestas buenas'] + $data[$value->form_id][$value->document]['Respuestas malas']) >= $value->min ? t("Aprobado") : t("No aprobado");
          $data[$value->form_id][$value->document]['Id del bloque'] = $value->form;
          $data[$value->form_id][$value->document]['Fecha'] = $formatDate->format($value->created);
          $count++;
        }
      }
      elseif (!$equal) {
        if (!isset($data[$value->form_id][$value->document]['Respuestas buenas'])) {
          $data[$value->form_id][$value->document]['Respuestas buenas'] = 0;
        }
        if (!isset($data[$value->form_id][$value->document]['Respuestas malas'])) {
          $data[$value->form_id][$value->document]['Respuestas malas'] = 0;
        }
        $data[$value->form_id][$value->document]['Nombre'] = $value->name;
        $data[$value->form_id][$value->document]['Correo'] = $value->email;
        $data[$value->form_id][$value->document]['Numero de identidad'] = $value->document;
        $data[$value->form_id][$value->document]['Curso'] = $value->course;
        $data[$value->form_id][$value->document]['Minimo para pasar'] = $value->min . " %";
        $data[$value->form_id][$value->document]['Respuestas buenas'] = ($value->status == "correcto") ? $data[$value->form_id][$value->document]['Respuestas buenas'] + 1 : $data[$value->form_id][$value->document]['Respuestas buenas'];
        $data[$value->form_id][$value->document]['Respuestas malas'] = ($value->status != "correcto") ? $data[$value->form_id][$value->document]['Respuestas malas'] + 1 : $data[$value->form_id][$value->document]['Respuestas malas'];
        $data[$value->form_id][$value->document]['Porcentaje'] = ($data[$value->form_id][$value->document]['Respuestas buenas'] * 100) / ($data[$value->form_id][$value->document]['Respuestas buenas'] + $data[$value->form_id][$value->document]['Respuestas malas']) . " %";
        $data[$value->form_id][$value->document]['Estado'] = ($data[$value->form_id][$value->document]['Respuestas buenas'] * 100) / ($data[$value->form_id][$value->document]['Respuestas buenas'] + $data[$value->form_id][$value->document]['Respuestas malas']) >= $value->min ? t("Aprobado") : t("No aprobado");
        $data[$value->form_id][$value->document]['Id del bloque'] = isset($value->form) && $value->form != NULL ? $value->form : '';
        $data[$value->form_id][$value->document]['Fecha'] = $formatDate->format($value->created);
        $count++;
      }

    }
    return $this->processData($data);
  }

  public function processData($values) {
    $data = [];
    $count = 0;
    foreach ($values as $key => $value) {
      foreach ($value as $index => $item) {
        $data[$count] = $item;
        $count++;
      }
    }
    return $data;
  }

  /**
   * cleanData
   *
   * @param [type] $str
   * @return void
   */
  public function cleanData (&$str) {
    $str = preg_replace("/\t/", "\\t", $str);
    $str = preg_replace("/\r?\n/", "\\n", $str);
    if (strstr($str, '"')) $str = '"' . str_replace('"', '""', $str) . '"';
  }

}
