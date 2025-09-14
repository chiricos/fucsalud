<?php

namespace Drupal\fucs_studio_apartments\Services;

use Drupal\Core\Mail\MailManagerInterface;
use Drupal\Core\Language\LanguageInterface;
use Drupal\Core\Render\Markup;
use Drupal\Component\Utility\SafeMarkup;
use Symfony\Component\DependencyInjection\ContainerInterface;

class EmailService {

  public function __construct() {
  }

  public function sendEmail($params) {
    $mailManager = \Drupal::service('plugin.manager.mail');

    $to = 'coordinacionweb@fucsalud.edu.co,apartaestudiosfucs@fucsalud.edu.co';
    $subject = 'Reserva apartaestudio';
    $message = "";
    foreach ($params as $param) {
      $message = $message . "\n" . $param;
    }
    $body = $message;

    // Define los parámetros del correo.
    $module = 'fucs_studio_apartments';
    $key = 'notificacion';
    $params['message'] = $body;
    $params['subject'] = $to;
    $langcode = \Drupal::currentUser()->getPreferredLangcode();
    $send = TRUE;

    // Enviar el correo.
    $result = $mailManager->mail($module, $key, $to, $langcode, $params, NULL, $send);
  }

}