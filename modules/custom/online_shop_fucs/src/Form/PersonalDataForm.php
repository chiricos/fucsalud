<?php

namespace Drupal\online_shop_fucs\Form;

use Drupal\Core\Form\FormBase;
use Drupal\Core\Form\FormStateInterface;
use Drupal\Core\Routing\TrustedRedirectResponse;

/**
 * Provides a client data form for the block instance device register form.
 *
 * @internal
 */
class PersonalDataForm extends FormBase
{

  private $dataPayments;
  private $user;

  public function __construct()
  {
    $this->dataPayments = \Drupal::service('online_shop_fucs.data_payments');
    $this->user = $this->dataPayments->getUser();
  }

  /**
   * {@inheritdoc}
   */
  public function getFormId()
  {
    return 'personal_data_form';
  }

  /**
   * {@inheritdoc}
   */
  public function buildForm(array $form, FormStateInterface $form_state)
  {

    $form['#theme'] = 'personal_data_form_build';
    $form['user'] = $this->user;

    $form['content'] = [
      '#prefix' => '<div class="row">',
      '#suffix' => '</div>',
    ];

    $form['content']['name'] = [
      '#type' => 'textfield',
      '#required' => TRUE,
      '#maxlength' => '20',
      '#placeholder' => 'Nombre y apellidos',
      '#prefix' => '<div class="col-md-6">',
      '#suffix' => '</div>',
    ];

    $form['content']['document'] = [
      '#type' => 'number',
      '#required' => TRUE,
      '#maxlength' => '12',
      '#placeholder' => 'Número de documento',
      '#prefix' => '<div class="col-md-6">',
      '#suffix' => '</div>',
    ];

    $form['content']['email'] = [
      '#type' => 'email',
      '#required' => TRUE,
      '#maxlength' => '60',
      '#placeholder' => 'Correo',
      '#prefix' => '<div class="col-md-6">',
      '#suffix' => '</div>',
    ];

    $form['content']['address'] = [
      '#type' => 'textfield',
      '#required' => TRUE,
      '#maxlength' => '40',
      '#placeholder' => 'Dirección',
      '#prefix' => '<div class="col-md-6">',
      '#suffix' => '</div>',
    ];

    $form['content']['phone_number'] = [
      '#type' => 'number',
      '#required' => TRUE,
      '#maxlength' => '11',
      '#placeholder' => 'Número de Teléfono fijo o Celular',
      '#prefix' => '<div class="col-md-6">',
      '#suffix' => '</div>',
    ];

    $form['content']['city'] = [
      '#type' => 'textfield',
      '#required' => TRUE,
      '#maxlength' => '20',
      '#placeholder' => 'Ciudad',
      '#prefix' => '<div class="col-md-6">',
      '#suffix' => '</div>',
    ];

    $form['content']['data'] = [
      '#type' => 'textarea',
      '#required' => TRUE,
      '#placeholder' => 'Descripción de la compra',
      '#prefix' => '<div class="col-md-12">',
      '#suffix' => '</div>',
    ];

    $form['agree'] = [
      '#type' => 'checkbox',
      '#required' => TRUE,
      '#suffix' => '<span>Acepto, consiento y autorizo que mis datos personales sean tratados por la FUCS conforme a lo previsto en la presente
					<a href="http://www.fucsalud.edu.co/PolItica-de-tratamiento-y-proteccion-de-datos-personales/formato-de-autorizacion-para-la-recoleccion-y-tratamiento-de-datos-personales-en-formularios-electronicos" target="_blank">autorización</a>
					y de acuerdo con su
					<a href="https://www.fucsalud.edu.co/PolItica-de-tratamiento-y-proteccion-de-datos-personales" target="_blank">Política de Tratamiento y protección de Datos Personales</a>
				</span>'
    ];


    $form['submit'] = [
      '#type' => 'submit',
      '#value' => $this->t('COMPRAR'),
      '#attributes' => array('class' => array('buy')),
    ];
    return $form;
  }

  /**
   * {@inheritdoc}
   */
  public function validateForm(array &$form, FormStateInterface $form_state)
  {

    if ($form_state->getValue('name') == NULL || $form_state->getValue('name') == "") {
      $form_state->setErrorByName('name', $this->t('El nombre es requerido.'));
    }
    if ($form_state->getValue('document') == NULL || $form_state->getValue('document') == "") {
      $form_state->setErrorByName('document', $this->t('El documento es requerido.'));
    }
    if (strlen($form_state->getValue('document')) > 11) {
      $form_state->setErrorByName('document', $this->t('El documentos esta muy largo.'));
    }
    if ($form_state->getValue('email') == NULL || $form_state->getValue('email') == "") {
      $form_state->setErrorByName('email', $this->t('El email es requerido.'));
    }
    else {
      if ($form_state->getValue('email') == !\Drupal::service('email.validator')->isValid($form_state->getValue('email'))) {
        $form_state->setErrorByName(
          'email',
          t('The email  %mail no es valido.', array('%mail' => $form_state->getValue('email')))
        );
      }
    }
    if ($form_state->getValue('address') == NULL || $form_state->getValue('address') == "") {
      $form_state->setErrorByName('address', $this->t('La dirección es requerido.'));
    }
    if ($form_state->getValue('phone_number') == NULL || $form_state->getValue('phone_number') == "") {
      $form_state->setErrorByName('phone_number', $this->t('El celular es requerido.'));
    }
    if (strlen($form_state->getValue('phone_number')) > 11) {
      $form_state->setErrorByName('phone_number', $this->t('El celular esta muy largo.'));
    }
    if ($form_state->getValue('city') == NULL || $form_state->getValue('city') == "") {
      $form_state->setErrorByName('city', $this->t('La ciudad es requerido.'));
    }
    if ($form_state->getValue('data') == NULL || $form_state->getValue('data') == "") {
      $form_state->setErrorByName('data', $this->t('La data es requerido.'));
    }
    if ($form_state->getValue('agree') == NULL || $form_state->getValue('agree') == 0) {
      $form_state->setErrorByName('agree', $this->t('Debes aceptar para seguir.'));
    }

  }

  /**
   * {@inheritdoc}
   */
  public function submitForm(array &$form, FormStateInterface $form_state)
  {
    $data = [
      'name' => \Drupal::request()->get('name'),
      'document' => \Drupal::request()->get('document'),
      'email' => \Drupal::request()->get('email'),
      'address' => \Drupal::request()->get('address'),
      'phone_number' => \Drupal::request()->get('phone_number'),
      'city' => \Drupal::request()->get('city'),
      'data' => \Drupal::request()->get('data')
    ];

    $payment = $this->dataPayments->sendPayment($data);
    if ($payment) {
      $response = new TrustedRedirectResponse($payment['createTransactionPaymentResult']['eCollectUrl']);
      $form_state->setResponse($response);
    }
    return $form_state;
  }

}
