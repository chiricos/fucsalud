<?php

namespace Drupal\online_shop_fucs\Services;

use PHPMailer\PHPMailer\PHPMailer;

class EmailUtils
{

  private $otherRecipients = FALSE;
	private $donation = FALSE;
  private $books = '';
  private $items;
  private $dataPayment;

  public function __construct()
  {

  }

  public function setItems($items)
  {
    $this->items = $items;
  }

  public function setDataPayment($data_payment)
  {
    $this->dataPayment = $data_payment;
  }

  public function getRecipients() {
    if ($this->donation) {
      return [
        "sembrandofuturo@fucsalud.edu.co",
        "coordinacionweb@fucsalud.edu.co",
        "activos.fijos@fucsalud.edu.co",
      ];
    } else {
      return [
        "tiendavirtual@fucsalud.edu.co",
        "caacelas@fucsalud.edu.co",
        "coordinacionweb@fucsalud.edu.co",
        "activos.fijos@fucsalud.edu.co",
      ];
    }
  }

  public function validParams($items, $data_payment) {
    $this->setItems($items);
    $this->setDataPayment($data_payment);
    foreach ($items as $item) {
      $this->books .= $item->nombre . "<br>";
      $referencia = isset($item->referencia) ? $item->referencia : '';
      if ($this->books == 'Cena de donación - Sembrando futuro') {
        $this->otherRecipients = true;
      }
      if ($referencia == "Donaciones-P-social") {
        $this->donation = TRUE;
      }
    }
  }

  public function validStatus()
  {
    return strtolower($this->dataPayment['getTransactionInformationResult']['TranState']) == "ok" ? TRUE : FALSE;
  }

  public function getDataClient()
  {
    $data = "Nombre: " . $this->dataPayment['getTransactionInformationResult']['ReferenceArray'][3] . "<br>";
    $data .= "Tipo de documento y número: CC: " . $this->dataPayment['getTransactionInformationResult']['ReferenceArray'][0] . "<br>";
    $data .= "Dirección: " . $this->dataPayment['getTransactionInformationResult']['ReferenceArray'][4] . "<br>";
    $data .= "Número de contacto: " . $this->dataPayment['getTransactionInformationResult']['ReferenceArray'][5] . "<br>";
    $data .= "Correo electronico: " . $this->dataPayment['getTransactionInformationResult']['ReferenceArray'][6] . "<br>";
    $data .= "Ciudad: " . $this->items[0]->ciudad . "<br>";
    return $data;
  }

  public function sendRecipientEmail()
  {
    $client_data = $this->getDataClient();
    $body = $this->generateBody($client_data);
    $headers = $this->generateHeader();
    return $this->sendEmail($body, $headers);
  }

  public function generateBody($client_data) {

    $body = "Contenido de la compra<br>";
    $body .= $this->books . "<br>";
    $body .= "Valor transacción: " . $this->dataPayment['getTransactionInformationResult']['TransValue'] . "<br>Datos<br>";
    $body .= $client_data;
    $body .= "<p>Datos de envio: " . $this->items[0]->observaciones;
    return $body;

  }

  public function generateHeader() {
    if ($this->otherRecipients) {
      $headers = "MIME-Version: 1.0\r\n";
      $headers .= 'From: "Marcela Muñoz FUCS" coordinacionweb@fucsalud.edu.co' . "\r\n";
      $headers .= "Content-type: text/html; charset=iso-8859-1\r\n";
    } else {
      $headers = 'Marcela Muñoz FUCS" coordinacionweb@fucsalud.edu.co - ' . $this->dataPayment['getTransactionInformationResult']['ReferenceArray'][3];
    }
    return $headers;
  }

  public function sendEmail($body, $headers) {
    $the_subject = "Nueva transacción tienda virtual FUCS";
    $from_name = utf8_decode($headers );
    try {
      foreach ($this->getRecipients() as $userEmail) {
        $address_to = $userEmail;
        $phpmailer = new PHPMailer();
        $phpmailer->Username = "fucsalud.edu.co@gmail.com";
        $phpmailer->Password = "vhxtrgojpvwziuys";
        $phpmailer->SMTPSecure = 'ssl';
        $phpmailer->Host = "smtp.gmail.com";
        $phpmailer->Port = 465;
        $phpmailer->IsSMTP();
        $phpmailer->SMTPAuth = true;
        $phpmailer->setFrom($phpmailer->Username, $from_name);
        $phpmailer->AddAddress($address_to);
        $phpmailer->Subject = utf8_decode($the_subject);
        $phpmailer->Body = utf8_decode($body);
        $phpmailer->IsHTML(true);
        $phpmailer->Send();
      }
      return TRUE;
    } catch (\Exception $e) {
      return FALSE;
    }
  }

}
