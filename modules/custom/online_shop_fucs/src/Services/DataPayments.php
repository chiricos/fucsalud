<?php

namespace Drupal\online_shop_fucs\Services;

use nguyenanhung\MyNuSOAP\nusoap_client;

/**
 * {@inheritdoc}
 */
class DataPayments {

  /**
   * La conexción con la base de datos
   *
   * @var string
   */
  private $db;

  /**
   * La información del usuario
   *
   * @var string
   */
  private $user;

  /**
   * Llamando servicio rest de ecollet
   *
   * @var string
   */
  private $ecolletPayment;

  public function __construct() {
    $this->db = \Drupal::database();
    if (isset($_SESSION['usuario']) && $_SESSION['usuario'] != "") {
      $this->user = $_SESSION['usuario'];
    }
    else {
      $_SESSION['usuario'] = $this->createRandomVal();
      $this->user = $_SESSION['usuario'];
      setcookie("usuario", $this->user, time() + 3600);
    }
    $this->ecolletPayment = \Drupal::service('online_shop_fucs.ecollet_payment');
  }

  /**
   * {@inheritdoc}
   */
  public function getUser() {
    return $this->user;
  }

  /**
   * {@inheritdoc}
   */
  public function getItems($type = "") {
    try {
      $query = $this->db->select('carrito', 'u');
      $query->condition('u.usuario_sesion', $this->user, '=')
        ->fields('u', [
          'id', 'nombre', 'precio', 'direccion', 'numero', 'correo', 'referencia', 'observaciones', 'state', 'fecha', 'transactionId', 'ciudad'
          ]);
      if ($type == "") {
        $query->isNull('u.state')
          ->isNull('u.transactionId');
      }
      else {
        $query->isNull('u.state');
      }
      $items = $query->execute()->fetchAll();
    }
    catch (\Exception $e) {
      return FALSE;
    }
    return $items;
  }

  /**
   * {@inheritdoc}
   */
  public function saveItem($data) {

    try {
      $this->db->insert('carrito')
        ->fields([
          'id',
          'nombre',
          'referencia',
          'precio',
          'usuario_sesion'
        ])
        ->values($data)
        ->execute();
    }
    catch (\Exception $e) {
      return FALSE;
    }
    return TRUE;
  }

  /**
   * {@inheritdoc}
   */
  public function deleteItem($id) {
    try {
      $this->db->delete('carrito')
        ->condition('id', $id)
        ->condition('usuario_sesion', $this->user)
        ->execute();
    }
    catch (\Exception $e) {
      return FALSE;
    }
    return TRUE;
  }

  /**
   * {@inheritdoc}
   */
  public function getTotal($items) {
    $total = 0;
    foreach ($items as $item) {
      $price = ($item->precio > 0) ? $item->precio : substr($item->precio, 1);
      $total = $total + $price;
    }
    return $total;
  }

  /**
   * {@inheritdoc}
   */
  public function createRandomVal() {
    $arreglo = [
      "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z", "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9"
      ];
    $pass = '';
    $tmp = '';
    $num = 0;

    for ($i = 0; $i < 40; $i++) {
      $num  = rand() % 62;
      $tmp  = $arreglo[$num];
      $pass = $pass . $tmp;
    }

    return $pass;
  }

  /**
   * {@inheritdoc}
   */
  public function sendPayment($data) {
    $items = $this->getItems();
    if (count($items) > 0) {
      $type = $this->getType($items[0]);
      $data['reference'] = $items[0]->referencia;
      $total = (string) $this->getTotal($items);
      $data['compra'] = $this->getTitles($items);
      $params['request'] = $this->getData($type, $data, $total);
      $payment = $this->sendDataPayment($params);
      if ($payment["code"] == "SUCCESS") {
        $this->updateData($payment, $data);
      }
      else {
        return FALSE;
      }

      return $payment;
    }
    return FALSE;
  }

  /**
   * {@inheritdoc}
   */
  public function getTitles($items) {
    $title = "";
    foreach ($items as $key => $item) {
      if ($key == 0) {
        $title = $item->nombre;
      }
      else {
        $title .= " - " . $item->nombre;
      }
    }
    return $title;
  }

  /**
   * {@inheritdoc}
   */
  public function getType($item) {
    $type = '';
    if ($item->referencia == "Libros") {
      $type = '7001';
    }
    elseif (($item->referencia == "Donacion") || ($item->referencia == "Donaciones") || ($item->referencia == "Donación") || ($item->referencia == "Donaciones-P-social")) {
      $type = '7002';
    }
    else {
      $type = '5500';
    }
    return $type;
  }

  /**
   * {@inheritdoc}
   */
  public function getData($type, $data, $total) {
    $base_url = \Drupal::request()->getSchemeAndHttpHost() . \Drupal::request()->getBasePath();
    $params = [
      'EntityCode' => '10228',
      'SessionToken' => $this->ecolletPayment->getSessionToken(),
      'SrvCode' => $type,
      'TransValue' => $total,
      'TransVatValue' => '0',
      'SrvCurrency' => 'COP',
      'URLResponse' => '',
      'URLRedirect' => $base_url . '/compras/confirmacion',
      'Sign' => '',
      'SignFields' => '',
      'ReferenceArray' => $this->getReference($data),
      //'compra' => $data["compra"],
    ];

    return $params;
  }

  /**
   * {@inheritdoc}
   */
  public function getReference($data) {
    return [
      $data['document'],
      'Recibo_' . $this->user,
      'CC',
      $data['name'],
      $data['address'],
      $data['phone_number'],
      $data['email'],
      $data['reference'],
      $data["city"],
    ];
  }

  /**
   * {@inheritdoc}
   */
  public function sendDataPayment($data) {
    $result = $this->ecolletPayment->sendPayment($data);
    return $result;
  }

  /**
   * {@inheritdoc}
   */
  public function updateData($info_payment, $data) {
    try {
      $this->db->update('carrito')
        ->fields([
          'transactionId' => $info_payment["TicketId"],
          'observaciones' => $info_payment["eCollectUrl"],
          'direccion' => $data['address'],
          'numero' => $data['document'],
          'correo' => $data['email'],
          'ciudad' => $data['city'],
        ])
        ->condition('usuario_sesion', $this->user, '=')
        ->isNull('transactionId')
        ->execute();
      return TRUE;
    }
    catch (\Exception $e) {
      return FALSE;
    }

  }

  /**
   * {@inheritdoc}
   */
  public function updateStatus() {
    $items = $this->getItemsWithStatus();
    if (count($items) == 0) {
      $items = $this->getItems("confirm");
      if (count($items) > 0) {
        foreach ($items as $item) {
          $data_payment = $this->callbackDataPayment($item);
        }
        if (is_array($data_payment) && isset($data_payment["TranState"]) && $data_payment["TranState"] == "CREATED") {
          return FALSE;
        }
        $this->updateDataPayment($data_payment);
        return $this->sendEmails($items, $data_payment);
      }
      else {
        return FALSE;
      }
    }
    return FALSE;
  }

  /**
   * {@inheritdoc}
   */
  public function getItemsWithStatus($status = '', $operator = '=') {
    try {
      $query = $this->db->select('carrito', 'u');
      $query->condition('u.usuario_sesion', $this->user, '=');
      $query->isNotNull('u.state');
      $query->condition('u.state', $status, $operator);
      $query->fields('u', ['id', 'nombre', 'precio', 'direccion', 'numero', 'correo', 'referencia', 'observaciones', 'state', 'fecha', 'transactionId', 'ciudad']);
      $items = $query->execute()->fetchAll();
    }
    catch (\Exception $e) {
      return FALSE;
    }
    return $items;
  }

  /**
   * {@inheritdoc}
   */
  public function newClient() {
    $wsdl = "https://www.e-collect.com/p_express/webservice/eCollectWebservicesv2.asmx?wsdl";
    return new nusoap_client($wsdl, 'wsdl');
  }

  /**
   * {@inheritdoc}
   */
  public function callbackDataPayment($item) {
    $params['request'] = [
      'EntityCode' => '10228',
      'TicketId' => $item->transactionId
    ];
    return $this->ecolletPayment->getTransaction($params);
  }

  /**
   * {@inheritdoc}
   */
  public function updateDataPayment($data_payment) {
    try {
      $this->db->update('carrito')
        ->fields([
          'state' => $data_payment["TranState"],
          'fecha' => date('Y-m-d H:i:s'),
        ])
        ->condition('usuario_sesion', $this->user, '=')
        ->condition('transactionId', $data_payment["TicketId"], '=')
        ->execute();
      return TRUE;
    }
    catch (\Exception $e) {
      return FALSE;
    }
  }

  /**
   * {@inheritdoc}
   */
  public function updateDataPaymentPending($data_payment) {
    try {
      $this->db->update('carrito')
        ->fields([
          'state' => 'PENDING',
          'fecha' => $data_payment['date'],
        ])
        ->condition('id', $data_payment['id'], '=')
        ->execute();
      return TRUE;
    }
    catch (\Exception $e) {
      return FALSE;
    }
  }

  /**
   * {@inheritdoc}
   */
  public function updateDataPaymentSuccess($data_payment) {
    try {
      $this->db->update('carrito')
        ->fields([
          'state' => 'OK',
        ])
        ->condition('id', $data_payment->id, '=')
        ->execute();
      return TRUE;
    }
    catch (\Exception $e) {
      return FALSE;
    }
  }

  /**
   * {@inheritdoc}
   */
  public function sendEmails($items, $data_payment) {
    $email_utils = \Drupal::service('online_shop_fucs.email_utils');
    $email_utils->validParams($items, $data_payment);
    if ($email_utils->validStatus()) {
      $email_utils->sendRecipientEmail();
    }
    return [
      'data_payment' => $this->formatDataPayment($data_payment),
      'items' => $items,
      'status' => strtolower($data_payment["TranState"]),
      'status_name' => $this->validGetStatusPayment($data_payment),
    ];
  }

  /**
   * {@inheritdoc}
   */
  public function validGetStatusPayment($data_payment) {
    if (strtolower($data_payment["TranState"]) == "failed") {
      return "FALLIDA";

    }
    if (strtolower($data_payment["TranState"]) == "pending") {
      return "PENDIENTE";
    }
    if (strtolower($data_payment["TranState"]) == "not_authorized") {
      return "NO AUTORIZADA";
    }
    return "APROBADO";

  }

  /**
   * {@inheritdoc}
   */
  public function formatDataPayment($data_payment) {
    return [
      'ticket_id' => $data_payment["TicketId"],
      'trazability_code' => $data_payment["PaymentsArray"][0]["FICode"],
      'trans_value' => $data_payment["TransValue"],
      'bank_process_date' => $data_payment["PaymentsArray"][0]["BankProcessDate"],
      'bank_name' => $data_payment["PaymentsArray"][0]["FIName"],
      'original' => $data_payment,
    ];
  }

}
