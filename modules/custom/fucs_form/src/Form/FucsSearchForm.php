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
class FucsSearchForm extends FormBase {

  public function __construct() {}

  /**
   * {@inheritdoc}
   */
  public function getFormId() {
    return 'fucs_search_form';
  }

  /**
   * {@inheritdoc}
   */
  public function buildForm(array $form, FormStateInterface $form_state) {


    $form['#theme'] = 'fucs_search_form_build';
    $form['#cache'] = ['max-age' => 0];

    $form['document'] = [
      '#type' => 'textfield',
      '#placeholder' => t('Escriba el número de documento'),
    ];


    $form['submit'] = [
      '#type' => 'submit',
      '#value' => $this->t('Enviar'),
      '#attributes' => [
        'class' => [
          'w-auto bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded focus:outline-none focus:shadow-outline align-baseline form-fucs-submit'
        ],
      ],
    ];
    return $form;

  }

  /**
   * {@inheritdoc}
   */
  public function submitForm(array &$form, FormStateInterface $form_state) {

    $document = $form_state->getValue('document');
    $connection = \Drupal::database();
    $query = $connection->select('fucs_form')
      ->fields('fucs_form', [
        'id',
        'name',
        'email',
        'document',
        'course',
        'number',
        'question',
        'type',
        'answer',
        'status',
        'min',
        'form',
        'form_id',
        'uuid',
        'min',
        'created',
      ]);
    if (!empty($document)) {
      $query->condition('fucs_form.document', $document, '=');
    }
    $query->orderBy('id', 'DESC');
    $data = $query->execute();
    $results = $data->fetchAll(\PDO::FETCH_OBJ);
    $data = [];
    foreach ($results as $value) {
      $response = new TrustedRedirectResponse('/fucs/formulario/resultado?formId=' . $value->form_id . '&uuid=' . $value->uuid);
      $form_state->setResponse($response);
      return;
    }
  }
}
