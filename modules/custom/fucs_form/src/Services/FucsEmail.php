<?php

namespace Drupal\fucs_form\Services;

use PHPMailer\PHPMailer\PHPMailer;
use PHPMailer\PHPMailer\SMTP;
use PHPMailer\PHPMailer\Exception;

/**
 * Class FucsEmail.
 */
class FucsEmail {

  /**
   * Content Fields.
   *
   * @var mixed
   */
  private $configFucs;

  /**
   * Content Fields.
   *
   * @var mixed
   */
  private $phpMailer;

  /**
   * Content Fields.
   *
   * @var mixed
   */
  private $data;

  /**
   * {@inheritdoc}
   */
  public function __construct() {
    $this->configFucs = \Drupal::config('fucs.config');
  }

  /**
   * {@inheritdoc}
   */
  public function sendEmail($data) {
return ;
    $this->data = $data;
    $emails = isset($this->configFucs->get('contact')['emails']) ? $this->configFucs->get('contact')['emails'] : '';
    if (empty($emails)) {
      $emails = isset($data["email"]) && !empty($data["email"]) ? $data["email"] : '';
    }
    else {
      $emails = isset($data["email"]) && !empty($data["email"]) ? $emails . "," . $data["email"] : $emails;
    }

    $this->phpmailer = new PHPMailer();
    if (!empty($emails)) {
      $emails = explode(',', $emails);
      foreach ($emails as $email) {
        $this->phpmailer->Username = $this->configFucs->get('contact')['userEmail'];
        $this->phpmailer->Password = $this->configFucs->get('contact')['passwordEmail'];
        $this->phpmailer->SMTPSecure = $this->configFucs->get('contact')['smtpsecure'];
        $this->phpmailer->Host = $this->configFucs->get('contact')['host'];
        $this->phpmailer->Port = $this->configFucs->get('contact')['port'];
        $this->phpmailer->IsSMTP();
        $this->phpmailer->SMTPAuth = TRUE;
        $this->phpmailer->setFrom($email, $this->generateHeader());
        $this->phpmailer->AddAddress($email);
        $this->phpmailer->Subject = $this->configFucs->get('contact')['subject'];
        $this->phpmailer->Body = $this->generateBody();
        $this->phpmailer->IsHTML(TRUE);
        $this->phpmailer->Send();
      }
    }
  }

  /**
   * {@inheritdoc}
   */
  public function generateHeader() {
    return utf8_decode($this->configFucs->get('contact')['header'] . " | " . $this->data["document"]);
  }

  /**
   * {@inheritdoc}
   */
  public function generateBody() {
    $body = '';
    $url = \Drupal::request()->getHost() . $this->data["certificate"];
    $body .= $this->configFucs->get('contact')['body'];
    $body .= "<a href='{$url}'>Descargar</a>";
    return $body;
  }

}
