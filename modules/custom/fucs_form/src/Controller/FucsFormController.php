<?php

namespace Drupal\fucs_form\Controller;

use Drupal\Core\Controller\ControllerBase;
use Drupal\Core\Access\AccessResult;
use Dompdf\Dompdf;
use Dompdf\Options;
use Symfony\Component\HttpFoundation\Response;

/**
 * Class PaymentController.
 *
 * @package Drupal\home\Controller
 */
class FucsFormController extends ControllerBase {

  /**
   * Content Fields.
   *
   * @var mixed
   */
  private $configurations;

  /**
   * {@inheritdoc}
   */
  public function __construct() {
    $this->configurations = \Drupal::config('fucs.form.settings')->getRawData();
  }

  /**
   * status of form
   *
   * @return array
   */
  public function status() {
    $formId = \Drupal::request()->get('formId');
    $uuid = \Drupal::request()->get('uuid');
    if (!empty($formId)) {
      $results = $this->getDataDatabase($formId, $uuid);
      $good = 0;
      $bad = 0;
      $document = '';
      $data = $this->getVariables($results);

      $response = [
        'name' => $data['name'],
        'email' => $data['email'],
        'document' => $data['document'],
        'good' => $data['good'],
        'bad' => $data['bad'],
        'message' => $data['message'],
        'status' => $data["status"],
        'certificate' => '/fucs/formulario/certificado?uuid=' . $uuid . '&formId=' . $formId,
      ];
      if ($data["status"]) {
        $this->sendEmail($response);
      }
      $build = [
        '#theme' => 'fucs_status',
        '#configurations' => $this->configurations,
        '#data' => $response,
        '#attached' => [
          'library' => [
            'fucs_form/fucs-form',
          ],
        ],
      ];
    }
    else {
      $build = [
        '#markup' => $this->t('No se encuentra ningún formulario'),
      ];
    }
    $build['#cache']['max-age'] = 0;
    return $build;
  }

  /**
   * get data of database
   *
   * @return array
   */
  public function getDataDatabase($formId, $uuid) {
    $connection = \Drupal::database();
    $query = $connection->select('fucs_form')
                ->fields('fucs_form', [
                  'name',
                  'email',
                  'document',
                  'status',
                  'min',
                  'created',
                ])
                ->condition('fucs_form.form_id', $formId, '=')
                ->condition('fucs_form.uuid', $uuid, '=');
    $data = $query->execute();
    return $data->fetchAll(\PDO::FETCH_OBJ);
  }

  /**
   * get variables
   *
   * @return array
   */
  public function getVariables($results) {
    $data = [];
    $data['good'] = 0;
    $data['bad'] = 0;
    $formatDate = \Drupal::service('date.formatter');
    $data['min'] = isset($results[0]->min) ? $results[0]->min : 0;
    foreach ($results as $result) {
      $data['name'] = isset($result->name) ? $result->name : '';
      $data['email'] = isset($result->email) ? $result->email : '';
      $data['document'] = isset($result->document) ? $result->document : '';
      $data['date'] = isset($result->created) ? $formatDate->format($result->created) : '';
      if ($result->status == "correcto") {
        $data['good']++;
      }
      else {
        $data['bad']++;
      }
    }
    $data['message'] = '';
    $this->configurations['repeat'] = FALSE;
    $this->configurations['repeatUrl'] = isset($_COOKIE['formUrl']) ? $_COOKIE['formUrl'] : '/';
    $data['percentage'] = ($data['good'] * 100) / ($data['good'] + $data['bad']);
    if (strlen($data['percentage']) > 5) {
      $data['percentage'] = number_format($data['percentage'], 2, '.', '');
    }
    if ($data['percentage'] >= $data['min']) {
      $data['message'] = $this->t("¡Excelente! @name ya puedes decir a todos #SoyFUCS. No olvides descargar el certificado y entregarlo en tu Facultad. También debe llegarte una copia a tu correo FUCS, revísalo.", ["@name" => $data['name']]);
      $data['status'] = TRUE;
    }
    else {
      $data['message'] = $this->t("¡Ups! @name Parece que te faltó repasar un poco más. Recuerda que tienes solo tres intentos, si ya los usaste todos, debes escribir un correo a: <a href='' target='_blank'>coordinacionweb@fucsalud.edu.co</a> quien te programará una nueva fecha de ingreso con un nuevo intento.", ["@name" => $data['name']]);
      $this->configurations['repeat'] = TRUE;
      $data['status'] = FALSE;
    }
    return $data;
  }

  /**
   * get timeout
   *
   * @return array
   */
  public function tiemout() {
    $build = [
      '#markup' => $this->t('Su tiempo se ha acabado si quiere volver a intentarlo ingrese a <a href="@urlForm">Examen</a>', ['@urlForm' => $_COOKIE['formUrl']]),
    ];
    return $build;
  }

  /**
   * get login
   *
   * @return array
   */
  public function login() {
    $build = [
      '#markup' => $this->t('Su tiempo se ha acabado si quiere volver a intentarlo ingrese a <a href="@urlForm">Examen</a>', ['@urlForm' => $_COOKIE['formUrl']]),
    ];
    return $build;
  }

  /**
   * get access
   *
   * @return void
   */
  public function access() {
    return AccessResult::allowed();
  }

  /**
   * Generate pdf
   *
   * @return void
   */
  public function genratePdf() {

    $data = $this->getData();
    $options = new Options();
    $options->set('isHtml5ParserEnabled', true);
    $options->set('isRemoteEnabled', true);
    $dompdf = new Dompdf($options);
    $dompdf->loadHtml($this->generateHtml($data));
    $dompdf->setPaper('letter', 'landscape');
    $dompdf->render();
    $dompdf->stream("certificado", array("Attachment" => 0));
    try {
      $response = new Response($dompdf->output());
      $response->headers->set('Content-Type', 'application/pdf');
      //$response->headers->set('Content-Disposition', 'attachment; filename="certificado.pdf"');
    } catch(\Exception $e) {
      \Drupal::logger('fucs_form')->error($e->getMessage());
      return [
        '#markup' => 'Ha ocurrido un error al generar el PDF. Revisa los registros del sistema.',
      ];
    }
    

    return $response;
  }

  /**
   * get data
   */
  public function getData() {

    $data = [];
    $uuid = \Drupal::request()->get('uuid');
    $formId = \Drupal::request()->get('formId');

    $results = $this->getDataDatabase($formId, $uuid);
    $user = $this->getVariables($results);

    $cerfificates = $this->configurations['container']['container']['certificates'];

    foreach ($cerfificates as $key => $certificate) {
      if ($certificate['uuid'] == $uuid) {
        $data = [
          'primary' => str_replace('@name', $user['name'], $certificate['primary']),
          'secundary' => str_replace('@document', $user['document'], $certificate['secundary']),
          'tertiary' => str_replace('@percentage', $user['percentage'] . '%', $certificate['tertiary']),
          'fourth' => str_replace('@date', $user['date'], $certificate['fourth']),
          'image' => isset($certificate['imageCertificate']['urlTotal']) ? $certificate['imageCertificate']['urlTotal'] : '',
          'heigh' => isset($certificate['heigh']) ? $certificate['heigh'] : '',
        ];
      }
    }

    return $data;
  }

  /**
   * html pdf
   *
   * @param [type] $name
   * @return String
   */
  public function generateHtml($data) {
    return '<html>
    <body >
      <h1> ' . $data['primary'] . '</h1>
      <h2> ' . $data['secundary'] . '</h2>
      <h2> ' . $data['tertiary'] . '</h2>
      <p> ' . $data['fourth'] . '</p>
    <body>
    <style>
      html {
        margin:0;
        padding:0;
      }
      body {
        background: url(' . DRUPAL_ROOT . $data['image'] . ') no-repeat center center fixed;
        margin:0;
        padding:0;
        background-size: cover;
      }
      h1 {
        padding-top: ' . $data['heigh'] . 'px;
        text-align: center;
        width: 100%;
        text-transform: capitalize;
        font: normal 45px "coronet";
      }
      h2 {
        font-style: italic;
        font-weight: 100;
        text-align: center;
        width: 100%;
      }
      p {
        font-style: italic;
        text-align: center;
        width: 100%;
      }
    </style>
    </html>';
  }

  /**
   * {@inheritdoc}
   */
  public function sendEmail($data) {
    $fucsEmail = \Drupal::service('fucs_form.email');
    $fucsEmail->sendEmail($data);
  }

}
