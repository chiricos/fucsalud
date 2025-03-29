<?php

namespace Drupal\fucs_form\Form;

use Drupal\Core\Form\FormBase;
use Drupal\Core\Form\FormStateInterface;
use Drupal\Core\Routing\TrustedRedirectResponse;

/**
 * Provides a client data form for the block instance device register form.
 *
 * @internal
 */
class FucsLoginForm extends FormBase {

  private $formConfig;

  public function __construct()
  {
    $config = \Drupal::config('fucs.form.settings');
    $this->formConfig = $config->get("configurations");
  }

  /**
   * {@inheritdoc}
   */
  public function getFormId() {
    return 'fucs_login_form';
  }

  /**
   * {@inheritdoc}
   */
  public function buildForm(array $form, FormStateInterface $form_state) {

    $form = [
      '#theme' => 'fucs_login_form_build',
      '#attached' => [
        'library' => [
          'fucs_form/fucs-form'
        ],
      ],
      '#cache' => ['max-age' => 0],
    ];

    $form['#prefix'] = '<div class="container mx-auto bg-white shadow-md rounded px-8 pt-6 pb-8 mb-4">';
    $form['#suffix'] = '</div>';

    if ($this->formConfig["login"]["name"]) {
      $form['name'] = [
        '#type' => 'textfield',
        '#title' => $this->t('Nombre completo'),
        '#required' => TRUE,
        '#attributes' => [
          'class' => [
            'shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline',
          ],
        ],
        '#placeholder' => $this->t('Ingrese su nombre'),
      ];
    }

    if ($this->formConfig["login"]["email"]) {
      $form['email'] = [
        '#type' => 'textfield',
        '#title' => $this->t('Correo electrónico'),
        '#required' => TRUE,
        '#attributes' => [
          'class' => [
            'shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline',
          ],
        ],
        '#placeholder' => $this->t('Ingrese su correo'),
      ];
    }

    $form['document'] = [
      '#type' => 'number',
      '#title' => $this->t('Número de documento'),
      '#required' => TRUE,
      '#attributes' => [
        'class' => [
          'shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline',
        ],
      ],
      '#placeholder' => $this->t('Ingrese su documento'),
    ];


    $form['action'] = [
      '#type' => 'container',
      '#attributes' => array(
        'class' => 'text-center',
      ),
    ];

    $form['action']['submit'] = [
      '#type' => 'submit',
      '#value' => $this->t('Enviar'),
      '#attributes' => [
        'class' => [
          'bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded focus:outline-none focus:shadow-outline align-baseline'
        ],
      ]
    ];
    return $form;

  }

  /**
   * {@inheritdoc}
   */
  public function submitForm(array &$form, FormStateInterface $form_state) {

    /*$connection = \Drupal::database();
    $connection->insert('fucs_form')->fields([
      'name' => $form_state->getValue('name'),
      'email' => $form_state->getValue('email'),
      'numero_documento' => $form_state->getValue('document'),
      ]
    )->execute();*/
    $url = $this->formConfig["urlForm"] . '?name=' . $form_state->getValue('name') . '&email=' . $form_state->getValue('email') . '&document=' . $form_state->getValue('document');
    $response =  new TrustedRedirectResponse($url);
    $response->setMaxAge(0);
    $form_state->setResponse($response);
  }

}
