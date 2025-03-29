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
class FucsForm extends FormBase {

  private $formConfig;
  private $formQuestions;

  public function __construct(){}

  /**
   * {@inheritdoc}
   */
  public function getFormId() {
    return 'fucs_form';
  }

  /**
   * {@inheritdoc}
   */
  public function buildForm(array $form, FormStateInterface $form_state) {

    $configBlock = $form_state->getBuildInfo();
    $configBlock = isset($configBlock["args"][1]) ? $configBlock["args"][1] : [];
    $this->formConfig = $configBlock["configurations"];
    $this->formQuestions = $configBlock["configurations"]["questions"];

    $form['#theme'] = 'fucs_form_build';
    $form['#cache'] = ['max-age' => 0];

    $form['#prefix'] = '<div class=" mx-auto">';
    $form['#suffix'] = '</div>';

    foreach ($this->formQuestions as $key => $config) {

      $form[$key] = [
        '#type' => 'container',
        '#attributes' => [
          'class' => 'bg-white p-8 w-2/4 m-auto shadow-xl rounded mb-4 form-question form-question-question0 js-form-wrapper form-wrapper border-2 border-gray-100' . $key . '',
        ],
      ];
      if (!empty($config["imageQuestion"]["urlTotal"])) {
        $form[$key]['image'] = [
          '#type' => 'markup',
          '#prefix' => '<div id="box" class="w-full m-auto">',
          '#suffix' => '</div>',
          '#markup' => '<img src="' . $config["imageQuestion"]["urlTotal"] . '" alt="' . $config["imageQuestion"]["name"] . '" class="m-auto">',
        ];
      }
      if ($config["type"] == "only") {
        $form[$key][$key] = [
          '#type' => 'textfield',
          '#title' => $config["question"],
          '#attributes' => [
            'class' => [
              'shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline',
            ],
          ],
          '#placeholder' => 'Respuesta',
        ];
      }
      elseif ($config["type"] == "multiple") {
        $options = [];
        if (!empty($config["optionA"])) {
          $options[$config["optionA"]] = "A. " . $config["optionA"];
        }
        if (!empty($config["optionB"])) {
          $options[$config["optionB"]] = "B. " . $config["optionB"];
        }
        if (!empty($config["optionC"])) {
          $options[$config["optionC"]] = "C. " . $config["optionC"];
        }
        if (!empty($config["optionD"])) {
          $options[$config["optionD"]] = "D. " . $config["optionD"];
        }
        $form[$key][$key] = [
          '#type' => 'radios',
          '#title' => $config["question"],
          '#options' => $options,
          '#attributes' => [
            'class' => [
              'mr-2 leading-tight w-auto text-justify text-2xl font-black',
            ],
          ],
        ];
      }
    }

    $form['paginate'] = [
      '#type' => 'container',
      '#attributes' => [
        'class' => '',
      ],
    ];

    $form['paginate']['questionNumbers'] = [
      '#type' => 'markup',
      '#prefix' => '<div ',
      '#suffix' => '</div>',
      '#markup' => '<p class="question-selected text-lg text-gray-800">Pregunta 1 de </p>',
    ];

    $form['paginate']['backNetx'] = [
      '#type' => 'markup',
      '#prefix' => '<div class="inline-flex w-full text-center my-6">',
      '#suffix' => '</div>',
      '#markup' => '<div class="bg-gray-300 hover:bg-gray-400 text-gray-800 font-bold py-2 px-4 m-auto fucs-prev cursor-pointer">Anterior</div><div class="bg-gray-300 hover:bg-gray-400 text-gray-800 font-bold py-2 px-4 m-auto fucs-next cursor-pointer ">Siguiente</div>',
    ];

    $form['action'] = [
      '#type' => 'container',
      '#attributes' => [
        'class' => 'text-center my-6',
      ],
    ];

    $form['action']['submit'] = [
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
    if (!$this->attempts()) {
      $baseUrl = (isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] == 'on' ? 'https' : 'http' ) . '://' .  $_SERVER['HTTP_HOST'] . '/';
      $parameters = basename($_SERVER['REQUEST_URI']);
      setcookie('formUrl', $baseUrl . $parameters, time() + (86400 * 30), "/");

      $connection = \Drupal::database();

      $number = 1;
      $formId = isset($form["#build_id"]) ? $form["#build_id"] : rand(100, 10000000);
      foreach ($this->formQuestions as $index => $formConfig) {
        $connection->insert('fucs_form')->fields([
          'name' => \Drupal::request()->get('name') != NULL ? \Drupal::request()->get('name') : "",
          'email' => \Drupal::request()->get('email') != NULL ? \Drupal::request()->get('email') : "",
          'document' => \Drupal::request()->get('document') != NULL ? \Drupal::request()->get('document') : "",
          'course' => \Drupal::request()->get('course') != NULL ? \Drupal::request()->get('course') : "",
          'number' => "Pregunta " . $number,
          'form_id' => $formId,
          'question' => $formConfig["question"],
          'type' => $formConfig["type"],
          'form' => $this->formConfig["title"],
          'answer' => $form_state->getValue($index),
          'created' => \Drupal::time()->getRequestTime(),
          'status' => ($formConfig["answer"] == $form_state->getValue($index)) ? "correcto" : "incorrecto",
          'uuid' => $this->formConfig["uuid"],
          'min' => $this->formConfig["min"],
        ]
        )->execute();
        $number++;
      }
      $response = new TrustedRedirectResponse('/fucs/formulario/resultado?formId=' . $formId . '&uuid=' . $this->formConfig["uuid"]);
      $form_state->setResponse($response);
      return;
    }
    else {
      $response = new TrustedRedirectResponse('/fucs/formulario/resultado?formId=' . $formId . '&uuid=' . $this->formConfig["uuid"]);
      $form_state->setResponse($response);
    }

  }

  private function attempts() {
    $document = \Drupal::request()->get('document') != NULL ? \Drupal::request()->get('document') : "";
    if (!empty($document)) {
      $connection = \Drupal::database();
      $query = $connection->select('fucs_form')
        ->fields('fucs_form', [
          'name',
          'email',
          'document',
          'form_id',
        ])->condition('fucs_form.document', $document, '=')
        ->condition('fucs_form.uuid', $this->formConfig["uuid"], '=')
        ->distinct('form_id');
      $data = $query->execute();
      $results = $data->fetchAll(\PDO::FETCH_OBJ);
      if (count($results) >= $this->formConfig["attempts"]) {
        return TRUE;
      }
      return FALSE;
    }
    return FALSE;
  }

}
