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
class FucsPaymentsPendingForm extends FormBase {

  private $paymentService;

  public function __construct(){
    $this->paymentService = \Drupal::service('online_shop_fucs.data_payments');
  }

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

    $form['configurations']['updateSuccess'] = [
      '#type' => 'checkbox',
      '#title' => $this->t('Actualizar transacciones a OK'),
    ];

    $form['configurations']['submit'] = [
      '#type' => 'submit',
      '#value' => 'Actualizar transacciones',
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
        'fecha',
      ])
      ->condition('state', 'PENDING', '=')
      ->orderBy('id', 'DESC');
    $data = $query->execute();
    $results = $data->fetchAll(\PDO::FETCH_OBJ);
    $form['mytable'] = [
      '#type' => 'table',
      '#header' => [t('id'), t('Nombre'), t('Dirección'), t('Número'), t('Correo'), t('Referencia'), t('Observaciones'), t('Valor'), t('Número de transacción'), t('Estado'), t('Fecha')],
      '#empty' => t('There are no items yet. '),
    ];
    foreach ($results as $id => $result) {

      $form['mytable'][$id]['id'] = array(
        '#plain_text' => $result->id,
      );
      $form['mytable'][$id]['nombre'] = array(
        '#plain_text' => $result->nombre,
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
    $updateSuccess = $form_state->getValue('updateSuccess');
    if ($updateSuccess == 1) {
      $this->updateTransactionsSuccess();
    }
    else {
      $this->updateTransactions();
    }
  }

  /**
   * updateTransactions()
   *
   * @return array
   */
  public function updateTransactions() {
    $connection = \Drupal::database();
    $query = $connection->select('carrito')
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
        'fecha',
      ])
      ->condition('state', NULL, 'IS NULL')
      ->orderBy('id', 'DESC');

    $data = $query->execute();
    $results = $data->fetchAll(\PDO::FETCH_OBJ);
    ini_set('max_execution_time', 300);
    foreach ($results as $result) {
      $status = $this->paymentService->callbackDataPayment($result);
      if (!empty($status['getTransactionInformationResult']['ReturnCode']) && $status['getTransactionInformationResult']['ReturnCode'] == "SUCCESS") {
        $data_payment = [
          'id' => !empty($result->id) ? $result->id : '',
          'date' => !empty($status['getTransactionInformationResult']['BankProcessDate']) ? $status['getTransactionInformationResult']['BankProcessDate'] : '',
        ];
        $this->paymentService->updateDataPaymentPending($data_payment);
      }
    }

    return $data;
  }

    /**
   * updateTransactions()
   *
   * @return array
   */
  public function updateTransactionsSuccess() {
    $connection = \Drupal::database();
    $query = $connection->select('carrito')
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
        'fecha',
      ])
      ->condition('state', 'PENDING', '=')
      ->orderBy('id', 'DESC');

    $data = $query->execute();
    $results = $data->fetchAll(\PDO::FETCH_OBJ);
    foreach ($results as $result) {
      $this->paymentService->updateDataPaymentSuccess($result);
    }
  }

}
