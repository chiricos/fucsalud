<?php

namespace Drupal\fucs_payments\Form;

use Drupal\Core\Form\FormBase;
use Drupal\Core\Form\FormStateInterface;
use Drupal\Core\Routing\TrustedRedirectResponse;

/**
 * Provides a client data form for the block instance device register form.
 *
 * @internal
 */
class FucsPaymentsForm extends FormBase {

  public function __construct(){}

  /**
   * {@inheritdoc}
   */
  public function getFormId() {
    return 'fucs_payments_form';
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

    $form['configurations']['startDate'] = [
      '#type' => 'datetime',
      '#title' => $this->t('Desde'),
    ];

    $form['configurations']['endDate'] = [
      '#type' => 'datetime',
      '#title' => $this->t('Hasta'),
    ];

    $form['configurations']['submit'] = [
      '#type' => 'submit',
      '#value' => 'Exportar',
    ];

    $connection = \Drupal::database();
    $query = $connection
      ->select('carrito')
      ->fields('carrito', [
        'id',
        'nombre',
        'direccion',
        'numero',
        'correo',
        'referencia',
        'observaciones',
        'precio',
        'transactionId',
        'state',
        'ciudad',
        'fecha',
      ])
      ->condition('state', 'OK', '=')
      ->orderBy('id', 'DESC');
    $data = $query->execute();
    $results = $data->fetchAll(\PDO::FETCH_OBJ);
    $form['mytable'] = [
      '#type' => 'table',
      '#header' => [t('id'), t('Nombre'), t('Ciudad'), t('Dirección'), t('Número'), t('Correo'), t('Referencia'), t('Observaciones'), t('Valor'), t('Número de transacción'), t('Estado'), t('Fecha')],
      '#empty' => t('There are no items yet. '),
    ];
    foreach ($results as $id => $result) {

      $form['mytable'][$id]['id'] = array(
        '#plain_text' => $result->id,
      );
      $form['mytable'][$id]['nombre'] = array(
        '#plain_text' => $result->nombre,
      );
      $form['mytable'][$id]['ciudad'] = array(
        '#plain_text' => $result->ciudad,
      );
      $form['mytable'][$id]['direccion'] = array(
        '#plain_text' => $result->direccion,
      );
      $form['mytable'][$id]['numero'] = array(
        '#plain_text' => $result->numero,
      );
      $form['mytable'][$id]['correo'] = array(
        '#plain_text' => $result->correo,
      );
      $form['mytable'][$id]['referencia'] = array(
        '#plain_text' => $result->referencia,
      );
      $form['mytable'][$id]['observaciones'] = array(
        '#plain_text' => $result->observaciones,
      );
      $form['mytable'][$id]['precio'] = array(
        '#plain_text' => $result->precio,
      );
      $form['mytable'][$id]['transactionId'] = array(
        '#plain_text' => $result->transactionId,
      );
      $form['mytable'][$id]['state'] = array(
        '#plain_text' => $result->state,
      );
      $form['mytable'][$id]['fecha'] = array(
        '#plain_text' => $result->fecha,
      );
    }
    return $form;

  }

  /**
   * {@inheritdoc}
   */
  public function submitForm(array &$form, FormStateInterface $form_state) {
    $startDate = ($form_state->getValue('startDate') != NULL) ? $form_state->getValue('startDate')->format('d-m-Y H:i:s') : '';
    $endDate = ($form_state->getValue('endDate') != NULL) ? $form_state->getValue('endDate')->format('d-m-Y H:i:s') : '';
    $filename = "payments_" . date('Ymd') . ".xls";

    header("Content-Disposition: attachment; filename=\"$filename\"");
    header("Content-Type: application/vnd.ms-excel");

    $flag = FALSE;
    foreach ($this->getData($startDate, $endDate) as $row) {
      if (!$flag) {
        echo implode("\t", array_keys($row)) . "\r\n";
        $flag = TRUE;
      }
      array_walk($row, __NAMESPACE__ . '\cleanData');
      echo implode("\t", array_values($row)) . "\r\n";
    }
    exit;
  }

  /**
   * getData()
   *
   * @return array
   */
  public function getData($startDate, $endDate) {
    $connection = \Drupal::database();
    $query = $connection->select('carrito')
      ->fields('carrito', [
        'id',
        'nombre',
        'direccion',
        'ciudad',
        'numero',
        'correo',
        'referencia',
        'observaciones',
        'precio',
        'transactionId',
        'state',
        'fecha',
      ])
      ->condition('state', "OK", '=')
      ->orderBy('id', 'DESC');

    $data = $query->execute();
    $results = $data->fetchAll(\PDO::FETCH_OBJ);
    $data = $this->filterData($results, $startDate, $endDate);

    return $data;
  }

  /**
   * filer Data
   *
   * @param [type] $results
   * @return array
   */
  public function filterData($results, $startDate, $endDate) {
    $data = [];
    foreach ($results as $value) {
      if (!empty($startDate) && !empty($endDate)) {
        if (strtotime($startDate) < strtotime($value->fecha) && strtotime($endDate) > strtotime($value->fecha)) {
          $data[] = $this->builData($value);
        }
      }
      elseif (!empty($startDate)) {
        if (strtotime($startDate) < strtotime($value->fecha)) {
          $data[] = $this->builData($value);
        }
      }
      elseif (!empty($endDate)) {
        if (strtotime($endDate) > strtotime($value->fecha)) {
          $data[] = $this->builData($value);
        }
      }
      else {
        $data[] = $this->builData($value);
      }
    }
    return $data;
  }

  /**
   * build Data
   *
   * @param [type] $value
   * @return Array
   */
  public function builData($value) {
    return [
      'id' => $value->id,
      'nombre' => $value->nombre,
      'Direccion' => $value->direccion,
      'Ciudad' => $value->ciudad,
      'Numero' => $value->numero,
      'Correo' => $value->correo,
      'Referencia' => $value->referencia,
      'Observaciones' => $value->observaciones,
      'precio' => $value->precio,
      'Id de la transaccion' => $value->transactionId,
      'Estado' => $value->state,
      'Fecha' => $value->fecha,
    ];
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
