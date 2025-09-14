<?php

namespace Drupal\fucs_studio_apartments\Form;

use Drupal\Core\Form\FormBase;
use Drupal\Core\Form\FormStateInterface;

/**
 * Provides a client data form for the block instance device register form.
 *
 * @internal
 */
class ApartmentContactForm extends FormBase {

  /**
   * {@inheritdoc}
   */
  public function getFormId() {
    return 'apartment_contact_form';
  }

  /**
   * {@inheritdoc}
   */
  public function buildForm(array $form, FormStateInterface $form_state) {
   
    $form['#prefix'] = '<div id="apartment-contact-form-wrapper">';
    $form['#suffix'] = '</div>';
    $form['fullname'] = [
      '#type' => 'textfield',
      '#title' => $this->t('Nombre completo'),
      '#placeholder' => $this->t('Ingresa tu nombre'),
      '#required' => TRUE,
      '#attributes' => [
        'minlength' => 6,
        'maxlength' => 20,
      ],
    ];

    $form['email'] = [
      '#type' => 'email',
      '#title' => $this->t('Correo electrónico'),
      '#placeholder' => $this->t('Ingresa el mail'),
      '#required' => TRUE,
    ];

    $form['phone'] = [
      '#type' => 'number',
      '#title' => $this->t('Teléfono'),
      '#placeholder' => $this->t('Ingresa un teléfono de contacto'),
      '#required' => TRUE,
      '#attributes' => [
        'minlength' => 6,
        'maxlength' => 12,
      ],
    ];

    $options = [
      '' => t('Selecciona el tipo de aartamento de tu interes'),
      'tipo1' => t('Apartaestudio Privado'),
      'tipo2' => t('Habitación con baño privado'),
      'tipo3' => t('Habitación con baño compartido'),
      'tipo4' => t('Apartamento completo 3 habitaciones'),
    ];

    $form['type'] = [
      '#type' => 'select',
      '#title' => $this->t('Tipo de apartamento'),
      '#options' => $options,
      '#placeholder' => $this->t('Selecciona el tipo de aartamento de tu interes'),
      '#required' => TRUE,
    ];

    $form['accept'] = [
      '#type' => 'checkbox',
      '#title' => t('Acepto, consiento y autorizo como titular de los datos personales recopilados en este formulario, sean tratados por la Fundación Universitaria de Ciencias de la Salud - FUCS, conforme a los previsto en la presente <a href="@acept" target="_blank">autorización (PDP04-05-09)</a>',['@acept' => '']),
      '#default_value' => 0,
      '#description' => t('.'),
      '#required' => TRUE,
    ];

    $form['save'] = [
      '#type' => 'submit',
      '#value' => $this->t('Enviar'),
      '#ajax' => [
        'callback' => '::ajaxSubmitHandler',
        'wrapper' => 'apartment-contact-form-wrapper',
        'effect' => 'fade',
      ],
    ];

    return $form;

  }

  /**
   * AJAX callback para reconstruir el formulario.
   */
  public function ajaxSubmitHandler(array &$form, FormStateInterface $form_state) {
    return $form;
  }

  /**
   * {@inheritdoc}
   */
  public function validateForm(array &$form, FormStateInterface $form_state) {
    $phone = $form_state->getValue('phone');
    if (strlen($form_state->getValue('fullname')) < 6) {
      $form_state->setErrorByName('fullname', $this->t('El nombre debe tener mínimo 6 caracteres.'));
    }
    if (strlen($form_state->getValue('fullname')) > 20) {
      $form_state->setErrorByName('fullname', $this->t('El nombre debe tener máximo 20 caracteres.'));
    }
    if (!is_numeric($phone)) {
      $form_state->setErrorByName('phone', $this->t('El teléfono debe ser numérico.'));
    }
    $length = strlen($phone);
    if ($length < 6 || $length > 12) {
      $form_state->setErrorByName('phone', $this->t('El número debe estar entre 6 y 12 dígitos.'));
    }
    if (!\Drupal::service('email.validator')->isValid($form_state->getValue('email'))) {
      $form_state->setErrorByName('email', $this->t('Ingrese un correo válido.'));
    }
  }

  /**
   * {@inheritdoc}
   */
  public function submitForm(array &$form, FormStateInterface $form_state) {
    $fullname = $form_state->getValue('fullname');
    $email = $form_state->getValue('email');
    $phone = $form_state->getValue('phone');
    $typeIndex = $form_state->getValue('type');
    $type = $form['type']['#options'][$typeIndex];
    $accept = $form_state->getValue('accept');
    if (!empty($fullname) && !empty($email) && !empty($phone) && !empty($type) && !empty($accept)) {
      $emailService = \Drupal::service('fucs_studio_apartments.email');
      $params = [
        'fullname' => $fullname,
        'email' => $email,
        'phone' => $phone,
        'type' => $type,
        'apartament' => $_SERVER["HTTP_REFERER"]
      ];
      $emailService->sendEmail($params);
      \Drupal::messenger()->addMessage($this->t('Su solicitud fue realizada con éxito.'));
    }
  }

}
