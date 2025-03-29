<?php

namespace Drupal\drupal_google_auth\Form;

use Drupal\Core\Form\ConfigFormBase;
use Drupal\Core\Form\FormStateInterface;

/**
 * Class FucsConfig.
 */
class GoogleAuthForm extends ConfigFormBase {

  /**
   * {@inheritdoc}
   */
  protected function getEditableConfigNames() {
    return [
      'google_auth.config',
    ];
  }

  /**
   * {@inheritdoc}
   */
  public function getFormId() {
    return 'google_auth_config';
  }

  /**
   * {@inheritdoc}
   */
  public function buildForm(array $form, FormStateInterface $form_state) {
    $config = $this->config('google_auth.config');

    $form['#tree'] = TRUE;

    $form['google'] = [
      '#type' => 'details',
      '#title' => $this->t('Configuración de Google Auth'),
      '#group' => 'bootstrap',
      '#open' => TRUE,
    ];
    $form['google']['clientId'] = [
      '#type' => 'textfield',
      '#title' => $this->t('Client Id'),
      '#description' => $this->t("Client id de la consola de Google"),
      '#default_value' => isset($config->get('google')['clientId']) ? $config->get('google')['clientId'] : '',
    ];
    $form['google']['clientSecret'] = [
      '#type' => 'textfield',
      '#title' => $this->t('Client Secret'),
      '#description' => $this->t("Client Secret de la consola de Google"),
      '#default_value' => isset($config->get('google')['clientSecret']) ? $config->get('google')['clientSecret'] : '',
    ];
    $form['google']['roles'] = [
      '#type' => 'textfield',
      '#title' => $this->t('Roles permitidos'),
      '#description' => $this->t("separar por una coma (,) los roles permitidos"),
      '#default_value' => isset($config->get('google')['roles']) ? $config->get('google')['roles'] : '',
    ];
  
    return parent::buildForm($form, $form_state);
  }

  /**
   * {@inheritdoc}
   */
  public function submitForm(array &$form, FormStateInterface $form_state) {
    parent::submitForm($form, $form_state);
    $this->config('google_auth.config')
      ->set('google', $form_state->getValue('google'))
      ->save();
  }

}
