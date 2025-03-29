<?php

namespace Drupal\fucs_form\Plugin\Block;

use Drupal\Core\Block\BlockBase;
use Drupal\Core\Form\FormStateInterface;
use Drupal\file\Entity\File;

/**
 * Provides a 'FucsFormBlock' block.
 *
 * @Block(
 *  id = "fucs_form_block",
 *  admin_label = @Translation("Módulo de inducciones"),
 *  group = "fucs_form"
 * )
 */
class FucsFormBlock extends BlockBase {

  protected $configuration;
  protected $formBuilder;
  protected $name;
  protected $email;
  protected $document;
  protected $course;

  /**
   * {@inheritdoc}
   */
  public function defaultConfiguration() {
    return [
      'configurations' => isset($this->configuration['configurations']) ? $this->configuration['configurations'] : [],
    ];
  }

  /**
   * {@inheritdoc}
   */
  public function blockForm($form, FormStateInterface $form_state) {

    /*
     * Listado de preguntas añadidas dinamicamente.
     */

    $form = [
      '#prefix' => '<div id="container-fields-wrapper">',
      '#suffix' => '</div>',
    ];

    $form['#tree'] = TRUE;

    $form['configurations'] = [
      '#type' => 'details',
      '#title' => $this->t('Configuraciones'),
      '#open' => TRUE,
    ];

    $form['configurations']['showUuid']['#markup'] = isset($this->configuration['configurations']['uuid']) ? "uuid:" . $this->configuration['configurations']['uuid'] : '';

    $form['configurations']['uuid'] = [
      '#type' => 'hidden',
      '#default_value' => isset($this->configuration['configurations']['uuid']) ? $this->configuration['configurations']['uuid'] : md5(rand(1, 1000)),
    ];

    $form['configurations']['title'] = [
      '#type' => 'textfield',
      '#title' => $this->t('Título del formulario'),
      '#default_value' => isset($this->configuration['configurations']['title']) ? $this->configuration['configurations']['title'] : "",
    ];

    $form['configurations']['min'] = [
      '#type' => 'number',
      '#title' => $this->t('Porcentaje para pasar'),
      '#description' => $this->t('Ingrese solo la cantidad sin el %'),
      '#default_value' => isset($this->configuration['configurations']['min']) ? $this->configuration['configurations']['min'] : 50,
    ];

    $form['configurations']['timeout'] = [
      '#type' => 'number',
      '#title' => 'Tiempo del formulario en segundos',
      '#description' => 'Es el tiempo límite para hacer el formulario',
      '#default_value' => isset($this->configuration["configurations"]["timeout"]) ? $this->configuration["configurations"]["timeout"] : 0,
    ];

    $form['configurations']['attempts'] = [
      '#type' => 'number',
      '#title' => $this->t('Número de intentos'),
      '#description' => $this->t('Las veces que puede realizar el formulario'),
      '#default_value' => isset($this->configuration['configurations']['attempts']) ? $this->configuration['configurations']['attempts'] : 3,
    ];

    $form['configurations']['login'] = [
      '#type' => 'details',
      '#title' => $this->t('Datos de registro'),
      '#open' => FALSE,
      '#description' => $this->t('Campos que se van a pedir al usuario'),
    ];

    $form['configurations']['login']['name'] = [
      '#type' => 'checkbox',
      '#title' => $this->t('Nombre requerido'),
      '#default_value' => isset($this->configuration['configurations']['login']['name']) ? $this->configuration['configurations']['login']['name'] : TRUE,
    ];

    $form['configurations']['login']['email'] = [
      '#type' => 'checkbox',
      '#title' => $this->t('Correo requerido'),
      '#default_value' => isset($this->configuration['configurations']['login']['email']) ? $this->configuration['configurations']['login']['email'] : FALSE,
    ];

    $form['configurations']['login']['course'] = [
      '#type' => 'checkbox',
      '#title' => $this->t('Programa academico requerido'),
      '#default_value' => isset($this->configuration['configurations']['login']['course']) ? $this->configuration['configurations']['login']['course'] : FALSE,
    ];

    $form['configurations']['login']['courses'] = [
      '#type' => 'textarea',
      '#title' => $this->t('Programas academicos'),
      '#description' => $this->t('Separar por comas(,) el programa academico'),
      '#default_value' => isset($this->configuration['configurations']['login']['courses']) ? $this->configuration['configurations']['login']['courses'] : FALSE,
      '#states' => [
        'visible' => [
          ':input[name="settings[configurations][login][course]"]' => ['checked' => TRUE],
        ],
      ],
    ];

    $form['container_questions'] = [
      '#type' => 'details',
      '#title' => $this->t('Preguntas'),
      '#open' => TRUE,
    ];

    $form['container_questions']['questions'] = [
      '#type' => 'container',
    ];

    $num_questions = $form_state->get('num_questions');
    $remove = $form_state->get('remove');

    if (empty($num_questions) && !$remove) {
      if (isset($this->configuration['configurations']['questions'])) {
        $num_questions = !empty($this->configuration['configurations']['questions']) ? count($this->configuration['configurations']['questions']) : 1;
      }
      else {
        $num_questions = 1;
      }
      $form_state->set('num_questions', $num_questions);
    }

    for ($i = 0; $i < $num_questions; $i++) {

      $element = "question" . $i;

      $form['container_questions']['questions'][$element] = [
        '#type' => 'details',
        '#title' => $this->t('Pregunta @number', ['@number' => $i + 1]),
        '#open' => TRUE,
        '#description' => $this->t('Configuración de la pregunta @num', ['@num' => ($i + 1)]),
        '#prefix' => '<div id="inner-container-wrapper">',
        '#suffix' => '</div>',
      ];

      $form['container_questions']['questions'][$element]['question'] = [
        '#type' => 'textarea',
        '#title' => $this->t('Escriba la pregunta:'),
        '#default_value' => isset($this->configuration['configurations']['questions'][$element]['question']) ? $this->configuration['configurations']['questions'][$element]['question'] : '',
        '#weight' => '0',
      ];

      $form['container_questions']['questions'][$element]['answer'] = [
        '#type' => 'textfield',
        '#title' => $this->t('Respuesta'),
        '#default_value' => isset($this->configuration['configurations']['questions'][$element]['answer']) ? $this->configuration['configurations']['questions'][$element]['answer'] : '',
        '#weight' => '0',
      ];

      $form['container_questions']['questions'][$element]['type'] = [
        '#title' => $this->t('Tipo de pregunta'),
        '#type' => 'select',
        '#options' => [
          'multiple' => $this->t('Respuesta multiple'),
          'only' => $this->t('Respuesta unica'),
        ],
        '#default_value' => isset($this->configuration['configurations']['questions'][$element]['type']) ? $this->configuration['configurations']['questions'][$element]['type'] : "multiple",
        '#weight' => '0',
      ];

      $form['container_questions']['questions'][$element]['optionA'] = [
        '#type' => 'textfield',
        '#title' => $this->t('Opcion A'),
        '#default_value' => isset($this->configuration['configurations']['questions'][$element]['optionA']) ? $this->configuration['configurations']['questions'][$element]['optionA'] : '',
        '#weight' => '0',
        '#states' => [
          'visible' => [
            ':input[name="container_questions[questions][' . $element . '][type]"]' => ['value' => 'multiple'],
          ],
        ],
      ];

      $form['container_questions']['questions'][$element]['optionB'] = [
        '#type' => 'textfield',
        '#title' => $this->t('Opcion B'),
        '#default_value' => isset($this->configuration['configurations']['questions'][$element]['optionB']) ? $this->configuration['configurations']['questions'][$element]['optionB'] : '',
        '#weight' => '0',
        '#states' => [
          'visible' => [
            ':input[name="container_questions[questions][' . $element . '][type]"]' => ['value' => 'multiple'],
          ],
        ],
      ];

      $form['container_questions']['questions'][$element]['optionC'] = [
        '#type' => 'textfield',
        '#title' => $this->t('Opcion C'),
        '#default_value' => isset($this->configuration['configurations']['questions'][$element]['optionC']) ? $this->configuration['configurations']['questions'][$element]['optionC'] : '',
        '#weight' => '0',
        '#states' => [
          'visible' => [
            ':input[name="container_questions[questions][' . $element . '][type]"]' => ['value' => 'multiple'],
          ],
        ],
      ];

      $form['container_questions']['questions'][$element]['optionD'] = [
        '#type' => 'textfield',
        '#title' => $this->t('Opcion D'),
        '#default_value' => isset($this->configuration['configurations']['questions'][$element]['optionD']) ? $this->configuration['configurations']['questions'][$element]['optionD'] : '',
        '#weight' => '0',
        '#states' => [
          'visible' => [
            ':input[name="container_questions[questions][' . $element . '][type]"]' => ['value' => 'multiple'],
          ],
        ],
      ];
      $form['container_questions']['questions'][$element]['image'] = [
        '#type' => 'managed_file',
        '#title' => $this->t('Seleccione la Imagen'),
        '#upload_location' => "public://formulario-fucs",
        '#upload_validators' => [
          'file_validate_extensions' => ['png jpg svg gif ico jpeg'],
          '#multiple' => TRUE,
          '#required' => TRUE,
        ],
        '#attached' => [
          'library' => [],
        ],
      ];
      $form['container_questions']['questions'][$element]["imageQuestion"]['id'] = [
        '#type' => 'hidden',
        '#title' => $this->t('id de la imagen'),
        '#default_value' => isset($this->configuration['configurations']['questions'][$element]["imageQuestion"]['id']) ? $this->configuration['configurations']['questions'][$element]["imageQuestion"]['id'] : '',
        '#weight' => '0',
      ];
      $form['container_questions']['questions'][$element]["imageQuestion"]['name'] = [
        '#type' => 'hidden',
        '#title' => $this->t('Nombre de laimagen'),
        '#default_value' => isset($this->configuration['configurations']['questions'][$element]["imageQuestion"]['name']) ? $this->configuration['configurations']['questions'][$element]["imageQuestion"]['name'] : '',
        '#weight' => '0',
      ];
      $form['container_questions']['questions'][$element]["imageQuestion"]['uri'] = [
        '#type' => 'hidden',
        '#title' => $this->t('uri'),
        '#default_value' => isset($this->configuration['configurations']['questions'][$element]["imageQuestion"]['uri']) ? $this->configuration['configurations']['questions'][$element]["imageQuestion"]['uri'] : '',
        '#weight' => '0',
      ];
      $form['container_questions']['questions'][$element]["imageQuestion"]['urlTotal'] = [
        '#type' => 'hidden',
        '#title' => $this->t('url total'),
        '#default_value' => isset($this->configuration['configurations']['questions'][$element]["imageQuestion"]['urlTotal']) ? $this->configuration['configurations']['questions'][$element]["imageQuestion"]['urlTotal'] : '',
        '#weight' => '0',
      ];
      if (!empty($this->configuration['configurations']['questions'][$element]["imageQuestion"]['urlTotal'])) {
        $form['container_questions']['questions'][$element]['showImage'] = [
          '#type' => 'markup',
          '#prefix' => '<div id="box" class="image_class">',
          '#suffix' => '</div>',
          '#markup' => '<img src="' . $this->configuration['configurations']['questions'][$element]["imageQuestion"]['urlTotal'] . '" alt="' . $this->configuration['configurations']['questions'][$element]["imageQuestion"]['name'] . '" >',
        ];
      }
    }

    $form['container_questions']['add'] = [
      '#type' => 'submit',
      '#value' => $this->t('Agregar una pregunta'),
      '#submit' => [
        [$this, 'addContainerCallback'],
      ],
      '#ajax' => [
        'callback' => [$this, 'addFieldSubmit'],
        'wrapper' => 'container-fields-wrapper',
      ],
      '#attributes' => [
        'data-link-action' => ['agregar preguntas'],
      ],
    ];

    if ($num_questions > 0) {
      $form['container_questions']['remove'] = [
        '#type' => 'submit',
        '#value' => $this->t('Eliminar la ultima pregunta'),
        '#submit' => [
          [$this, 'removeContainerCallback'],
        ],
        '#ajax' => [
          'callback' => [$this, 'addFieldSubmit'],
          'wrapper' => 'container-fields-wrapper',
        ],
        '#attributes' => [
          'data-link-action' => ['Eliminar preguntas'],
        ],
      ];
    }

    $form['actions']['#type'] = 'actions';
    $form['save'] = [
      '#type' => 'submit',
      '#value' => $this->t('Guardar la configuración'),
    ];
    $form['save']['#attributes']['class'][] = 'button button--primary';
    $form_state->setRebuild();
    return $form;
  }

  /**
   * {@inheritdoc}
   */
  public function blockSubmit($form, FormStateInterface $form_state) {
    $this->configuration['configurations'] = $form_state->getValue('configurations');
    $this->configuration['configurations']['questions'] = $form_state->getValue(['container_questions', 'questions']);
    foreach ($this->configuration['configurations']['questions'] as $key => $questions) {
      $fid = isset($questions["image"][0]) ? $questions["image"][0] : NULL;
      if ($fid) {
        $file = File::load($fid);
        $filename = $file->getFilename();
        $fileuri = $file->getFileUri();
        $realpath = substr($fileuri, 9);
        $imgUri = base_path() . "sites/default/files/" . $realpath;
        $this->configuration['configurations']['questions'][$key]["imageQuestion"]['name'] = $filename;
        $this->configuration['configurations']['questions'][$key]["imageQuestion"]['uri'] = $fileuri;
        $this->configuration['configurations']['questions'][$key]["imageQuestion"]['id'] = $fid;
        $this->configuration['configurations']['questions'][$key]["imageQuestion"]['urlTotal'] = $imgUri;
      }
    }

  }

  /**
   * {@inheritdoc}
   */
  public function addFieldSubmit(array &$form, FormStateInterface $form_state) {
    return $form;
  }

  /**
   * {@inheritdoc}
   */
  public function addContainerCallback(array &$form, FormStateInterface $form_state) {
    $max = $form_state->get('num_questions') + 1;
    $form_state->set('num_questions', $max);
    $form_state->setRebuild();
  }

  /**
   * {@inheritdoc}
   */
  public function removeContainerCallback(array &$form, FormStateInterface $form_state) {
    $num_fields = $form_state->get('num_questions');
    if ($num_fields > 0) {
      $max = $num_fields - 1;
      $form_state->set('num_questions', $max);
      if ($max == 0) {
        $form_state->set('remove', TRUE);
      }
    }
    $form_state->setRebuild();
  }

  /**
   * {@inheritdoc}
   */
  public function build() {
    $config["valid"] = $this->validData();
    $config["attempts"]["valid"] = $this->attempts();
    $config["attempts"]["number"] = $this->configuration["configurations"]["attempts"];
    $config['timeout'] = $this->configuration["configurations"]["timeout"];
    $config['time'] = $this->getTime($this->configuration["configurations"]["timeout"]);
    $config['formConfig'] = $this->configuration['configurations']['login'];
    $config["formConfig"]["courses"] = explode(',' ,$config["formConfig"]["courses"]);

    $formBuilder = \Drupal::formBuilder();
    $form = $formBuilder->getForm('\Drupal\fucs_form\Form\FucsForm', 'default', $this->configuration);

    $build = [
      '#theme' => 'fucs_form',
      '#form' => $form,
      '#config' => $config,
      '#attached' => [
        'library' => [
          'fucs_form/fucs-form',
        ],
      ],
    ];

    $build['#cache']['max-age'] = 0;
    return $build;
  }

  public function getTime($value) {
    $horas = floor($value / 3600);
    $minutos = floor(($value - ($horas * 3600)) / 60);
    $segundos = $value - ($horas * 3600) - ($minutos * 60);

    $horas = (strlen($horas) == 1) ? '0' . $horas : $horas;
    $minutos = (strlen($minutos) == 1) ? '0' . $minutos : $minutos;
    $segundos = (strlen($segundos) == 1) ? '0' . $segundos : $segundos;
    return $horas . ':' . $minutos . ":" . $segundos;
  }

  private function validData() {
    $valid = TRUE;
    $this->name = \Drupal::request()->get('name');
    $this->email = \Drupal::request()->get('email');
    $this->document = \Drupal::request()->get('document');
    $this->course = \Drupal::request()->get('course');
    if ($this->configuration['configurations']['login']['name']) {
      $valid = (!empty($this->name)) ? $valid : FALSE;
    }
    if ($this->configuration['configurations']['login']['email']) {
      $valid = (!empty($this->email)) ? $valid : FALSE;
    }
    if ($this->configuration['configurations']['login']['course']) {
      $valid = (!empty($this->course)) ? $valid : FALSE;
    }
    $valid = (!empty($this->document)) ? $valid : FALSE;

    return $valid;
  }

  private function attempts() {
    if (!empty($this->document)) {
      $connection = \Drupal::database();
      $query = $connection->select('fucs_form')
        ->fields('fucs_form', [
          'name',
          'email',
          'document',
          'form_id',
        ])->condition('fucs_form.document', $this->document, '=')
        ->condition('fucs_form.uuid', $this->configuration["configurations"]["uuid"], '=')
        ->distinct('form_id');
      $data = $query->execute();
      $results = $data->fetchAll(\PDO::FETCH_OBJ);
      if (count($results) >= $this->configuration["configurations"]["attempts"]) {
        return TRUE;
      }
      return FALSE;
    }
    return FALSE;
  }

}
