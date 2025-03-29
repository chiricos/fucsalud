<?php

namespace Drupal\fucs_form\Form;

use Drupal\Core\Form\ConfigFormBase;
use Drupal\Core\Form\FormStateInterface;

/**
 * Class FucsConfig.
 */
class FucsConfig extends ConfigFormBase {

  /**
   * {@inheritdoc}
   */
  protected function getEditableConfigNames() {
    return [
      'fucs.config',
    ];
  }

  /**
   * {@inheritdoc}
   */
  public function getFormId() {
    return 'fucs_config';
  }

  /**
   * {@inheritdoc}
   */
  public function buildForm(array $form, FormStateInterface $form_state) {
    $config = $this->config('fucs.config');

    $form['#tree'] = TRUE;

    $form['contact'] = [
      '#type' => 'details',
      '#title' => $this->t('Mensajes de contacto'),
      '#group' => 'bootstrap',
      '#open' => TRUE,
    ];
    $form['contact']['emails'] = [
      '#type' => 'textfield',
      '#title' => $this->t('Correo donde llegan los mensajes de contacto'),
      '#description' => $this->t("Si es mas de un correo separelos por una come (,)"),
      '#default_value' => isset($config->get('contact')['emails']) ? $config->get('contact')['emails'] : '',
    ];
    $form['contact']['userEmail'] = [
      '#type' => 'textfield',
      '#title' => $this->t('Usuario - Correo de configuración'),
      '#description' => $this->t("Donde van a salir los correos"),
      '#default_value' => isset($config->get('contact')['userEmail']) ? $config->get('contact')['userEmail'] : '',
    ];
    $form['contact']['passwordEmail'] = [
      '#type' => 'textfield',
      '#title' => $this->t('Password - Correo de configuración '),
      '#description' => $this->t("Donde van a salir los correos"),
      '#default_value' => isset($config->get('contact')['passwordEmail']) ? $config->get('contact')['passwordEmail'] : '',
    ];
    $form['contact']['subject'] = [
      '#type' => 'textfield',
      '#title' => $this->t('Asunto'),
      '#default_value' => isset($config->get('contact')['subject']) ? $config->get('contact')['subject'] : 'Certificado de inducción - Fucsalud',
    ];
    $form['contact']['header'] = [
      '#type' => 'textfield',
      '#title' => $this->t('Cabecera'),
      '#default_value' => isset($config->get('contact')['header']) ? $config->get('contact')['header'] : 'From: "Fucsalud inducción" info@fucsalud.edu.co',
    ];
    $form['contact']['smtpsecure'] = [
      '#type' => 'textfield',
      '#title' => $this->t('SMTP Secure'),
      '#default_value' => isset($config->get('contact')['smtpsecure']) ? $config->get('contact')['smtpsecure'] : 'ssl',
    ];
    $form['contact']['host'] = [
      '#type' => 'textfield',
      '#title' => $this->t('Host'),
      '#default_value' => isset($config->get('contact')['host']) ? $config->get('contact')['host'] : 'smtp.gmail.com',
    ];
    $form['contact']['port'] = [
      '#type' => 'textfield',
      '#title' => $this->t('Port'),
      '#default_value' => isset($config->get('contact')['port']) ? $config->get('contact')['port'] : 465,
    ];
    $form['contact']['body'] = [
      '#type' => 'textarea',
      '#title' => $this->t('Body'),
      '#default_value' => isset($config->get('contact')['body']) ? $config->get('contact')['body'] : '',
    ];

    return parent::buildForm($form, $form_state);
  }

  /**
   * {@inheritdoc}
   */
  public function submitForm(array &$form, FormStateInterface $form_state) {
    parent::submitForm($form, $form_state);
    $this->config('fucs.config')
      ->set('contact', $form_state->getValue('contact'))
      ->save();
  }

}
