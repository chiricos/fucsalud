<?php

namespace Drupal\online_shop_fucs\Form;

use Drupal\Core\Form\ConfigFormBase;
use Drupal\Core\Form\FormStateInterface;

/**
 * Crear configuración para ecollet.
 *
 * @internal
 */
class EcolletSettingsForm extends ConfigFormBase {

  /**
   * {@inheritdoc}
   */
  protected function getEditableConfigNames() {
    return ['online_shop_fucs.ecollet_settings'];
  }

  /**
   * {@inheritdoc}
   */
  public function getFormId() {
    return 'online_shop_fucs_ecollet_settings_form';
  }

  /**
   * {@inheritdoc}
   */
  public function buildForm(array $form, FormStateInterface $form_state) {
    $config = $this->config('online_shop_fucs.ecollet_settings');

    $form['#tree'] = TRUE;

    $form['ecollet'] = [
      '#type' => 'details',
      '#title' => $this->t('Configuración de Ecollet'),
      '#group' => 'bootstrap',
      '#open' => TRUE,
    ];

    $form['ecollet']['test'] = [
      '#type' => 'checkbox',
      '#title' => $this->t('Ecollet de prueba'),
      '#default_value' => $config->get('ecollet') ? $config->get('ecollet')['test'] : '',
    ];

    $form['ecollet']['code'] = [
      '#type' => 'number',
      '#title' => $this->t('Código de entidad'),
      '#default_value' => $config->get('ecollet') && isset($config->get('ecollet')['code']) ? $config->get('ecollet')['code'] : 10228,
      '#required' => TRUE,
    ];

    $form['ecollet']['apikey'] = [
      '#type' => 'textfield',
      '#title' => $this->t('Api Key'),
      '#default_value' => $config->get('ecollet') && isset($config->get('ecollet')['apikey']) ? $config->get('ecollet')['apikey'] : 'FU231fs4lnd',
      '#required' => TRUE,
    ];

    $form['ecollet']['url_test'] = [
      '#type' => 'textfield',
      '#title' => $this->t('Ecollet link de pruebas'),
      '#default_value' => $config->get('ecollet') && isset($config->get('ecollet')['url_test']) ? $config->get('ecollet')['url_test'] : 'https://test1.e-collect.com/app_express/api/',
    ];

    $form['ecollet']['url_prod'] = [
      '#type' => 'textfield',
      '#title' => $this->t('Ecollet link de productivo'),
      '#default_value' => $config->get('ecollet') && isset($config->get('ecollet')['url_prod']) ? $config->get('ecollet')['url_prod'] : '',
    ];

    return parent::buildForm($form, $form_state);
  }

  /**
   * {@inheritdoc}
   */
  public function submitForm(array &$form, FormStateInterface $form_state) {
    $this->config('online_shop_fucs.ecollet_settings')
      ->set('ecollet', $form_state->getValue('ecollet'))
      ->save();

    parent::submitForm($form, $form_state);
  }

}
