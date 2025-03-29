<?php

namespace Drupal\fucs_studio_apartments\Form;

use Drupal\Core\Form\FormBase;
use Drupal\Core\Form\FormStateInterface;
use Drupal\Core\Routing\TrustedRedirectResponse;

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
    $fullname = \Drupal::request()->query->get('fullname');
    $email = \Drupal::request()->query->get('email');
    $phone = \Drupal::request()->query->get('phone');
    $type = \Drupal::request()->query->get('type');
    $accept = \Drupal::request()->query->get('accept');
    $current_url = \Drupal::request()->getUri();
    if (strpos($current_url, "/apartaestudios/") !== false) {
      $form['html_custom'] = [
        '#markup' => '<div class="close"><spam>X</spam></div>',
      ];
    }
    
    if (!empty($fullname) && !empty($email) && !empty($phone) && !empty($type) && !empty($accept)) {
      $emailService = \Drupal::service('fucs_studio_apartments.email');
      $params = [
        'fullname' => $fullname,
        'email' => $email,
        'phone' => $phone,
        'type' => $type,
      ];
      $emailService->sendEmail($params);
      $form['#prefix'] = '<div><div class="apartment-success">Su solicitud fue realizado con exito</div>';
      $form['#suffix'] = '</div>';
      $response = new TrustedRedirectResponse('/apartastudios');
      $form_state->setResponse($response);
    }

    $form['fullname'] = [
      '#type' => 'textfield',
      '#title' => $this->t('Nombre completo'),
      '#placeholder' => $this->t('Ingresa tu nombre'),
      '#default_value' => isset($this->configuration['form']['fullname']) ? $this->configuration['form']['fullname'] : "",
      '#required' => true,
    ];

    $form['email'] = [
      '#type' => 'email',
      '#title' => $this->t('Correo electrónico'),
      '#placeholder' => $this->t('Ingresa el mail'),
      '#default_value' => isset($this->configuration['form']['email']) ? $this->configuration['form']['email'] : "",
      '#required' => true,
    ];

    $form['phone'] = [
      '#type' => 'number',
      '#title' => $this->t('Teléfono'),
      '#placeholder' => $this->t('Ingresa un teléfono de contacto'),
      '#default_value' => isset($this->configuration['form']['phone']) ? $this->configuration['form']['phone'] : "",
      '#required' => true,
    ];

    $options = array(
      '' => t('Selecciona el tipo de aartamento de tu interes'),
      //'tipo1' => t('Apartamento tipo 1'),
      'tipo2' => t('Apartamento tipo 2'),
      'tipo3' => t('Apartamento tipo 3'),
    );

    $form['type'] = [
      '#type' => 'select',
      '#title' => $this->t('Tipo de apartamento'),
      '#options' => $options,
      '#placeholder' => $this->t('Selecciona el tipo de aartamento de tu interes'),
      '#default_value' => isset($this->configuration['form']['type']) ? $this->configuration['form']['type'] : "",
      '#required' => true,
    ];

    $form['accept'] = array(
      '#type' => 'checkbox',
      '#title' => t('Acepto, consiento y autorizo como titular de los datos personales recopilados en este formulario, sean tratados por la Fundación Universitaria de Ciencias de la Salud - FUCS, conforme a los previsto en la presente <a href="@acept" target="_blank">autorización (PDP04-05-09)</a>',['@acept' => '']),
      '#default_value' => 0,
      '#description' => t('.'),
      '#required' => true,
    );

    if (!empty($fullname) && !empty($email) && !empty($phone) && !empty($type) && !empty($accept)) {
      $form['back'] = [
        '#type' => 'markup',
        '#markup' => '<a href="/apartastudios" class="button">Volver</a>',
      ];
    } else {
      $form['save'] = [
        '#type' => 'submit',
        '#value' => $this->t('Enviar'),
      ];
    }

    return $form;

  }

  public function submitForm(array &$form, FormStateInterface $form_state) {
    $fullname = \Drupal::request()->get('fullname');
    $email = \Drupal::request()->get('email');
    $phone = \Drupal::request()->get('phone');
    $type = \Drupal::request()->get('type');
    $accept = \Drupal::request()->get('accept');
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
      $form['#prefix'] = '<div><div class="apartment-success">Su solicitud fue realizado con exito</div>';
      $form['#suffix'] = '</div>';
    }
   
  }

}
