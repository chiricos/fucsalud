<?php

namespace Drupal\fucs_form\Form;

use Drupal\Core\Form\FormStateInterface;
use Drupal\Core\Form\ConfigFormBase;
use Drupal\file\Entity\File;

/**
 * Provides a client data form for the block instance device register form.
 *
 * @internal
 */
class FucsSettingsForm extends ConfigFormBase {

  protected $configuration;

  /**
   * getSettings
   *
   * @return void
   */
  protected function getEditableConfigNames() {
    return [
      'fucs.form.settings',
    ];
  }

  /**
   * {@inheritdoc}
   */
  public function getFormId() {
    return 'fucs_settings_form';
  }

  /**
   * {@inheritdoc}
   */
  public function buildForm(array $form, FormStateInterface $form_state) {

    $config = $this->config('fucs.form.settings');
    $this->configuration = $config->get('container');

    /*
     * Listado de preguntas añadidas dinamicamente.
     */

    $form = [
      '#prefix' => '<div id="container-fields-wrapper">',
      '#suffix' => '</div>',
    ];

    $form['#tree'] = TRUE;

    $form['container'] = [
      '#type' => 'details',
      '#title' => $this->t('Certificados'),
      '#open' => TRUE,
    ];

    $form['container']['certificates'] = [
      '#type' => 'container',
    ];

    $num_certificates = $form_state->get('num_certificates');
    $remove = $form_state->get('remove');

    if (empty($num_certificates) && !$remove) {
      if (isset($this->configuration['container']['certificates'])) {
        $num_certificates = !empty($this->configuration['container']['certificates']) ? count($this->configuration['container']['certificates']) : 1;
      }
      else {
        $num_certificates = 1;
      }
      $form_state->set('num_certificates', $num_certificates);
    }

    for ($i = 0; $i < $num_certificates; $i++) {

      $element = "certificate" . $i;

      $form['container']['certificates'][$element] = [
        '#type' => 'details',
        '#title' => $this->t('Certificado @number', ['@number' => $i + 1]),
        '#open' => TRUE,
        '#description' => $this->t('Configuración de la pregunta @num', ['@num' => ($i + 1)]),
        '#prefix' => '<div id="inner-container-wrapper">',
        '#suffix' => '</div>',
      ];

      $form['container']['certificates'][$element]['uuid'] = [
        '#type' => 'textfield',
        '#title' => $this->t('Uuid del bloque:'),
        '#default_value' => isset($this->configuration['container']['certificates'][$element]['uuid']) ? $this->configuration['container']['certificates'][$element]['uuid'] : '',
        '#weight' => '0',
      ];

      $form['container']['certificates'][$element]['heigh'] = [
        '#type' => 'number',
        '#title' => $this->t('Posición del texto'),
        '#default_value' => isset($this->configuration['container']['certificates'][$element]['heigh']) ? $this->configuration['container']['certificates'][$element]['heigh'] : 290,
        '#weight' => '0',
      ];

      $form['container']['certificates'][$element]['primary'] = [
        '#type' => 'textfield',
        '#title' => $this->t('Primer texto'),
        '#description' => $this->t('Coloque @name en el lugar que quiere que salga el nombre'),
        '#default_value' => isset($this->configuration['container']['certificates'][$element]['primary']) ? $this->configuration['container']['certificates'][$element]['primary'] : '',
        '#weight' => '0',
      ];

      $form['container']['certificates'][$element]['secundary'] = [
        '#type' => 'textfield',
        '#title' => $this->t('Segundo texto'),
        '#description' => $this->t('Coloque @document en el lugar que quiere que salga el documento de identidad'),
        '#default_value' => isset($this->configuration['container']['certificates'][$element]['secundary']) ? $this->configuration['container']['certificates'][$element]['secundary'] : '',
        '#weight' => '0',
      ];

      $form['container']['certificates'][$element]['tertiary'] = [
        '#type' => 'textfield',
        '#title' => $this->t('Tercer texto'),
        '#description' => $this->t('Coloque @percentage en el lugar que quiere que salga el porcentaje'),
        '#default_value' => isset($this->configuration['container']['certificates'][$element]['tertiary']) ? $this->configuration['container']['certificates'][$element]['tertiary'] : '',
        '#weight' => '0',
      ];

      $form['container']['certificates'][$element]['fourth'] = [
        '#type' => 'textfield',
        '#title' => $this->t('Cuarto texto'),
        '#description' => $this->t('Coloque @date en el lugar que quiere que salga la fecha'),
        '#default_value' => isset($this->configuration['container']['certificates'][$element]['fourth']) ? $this->configuration['container']['certificates'][$element]['fourth'] : '',
        '#weight' => '0',
      ];

      $form['container']['certificates'][$element]['image'] = [
        '#type' => 'managed_file',
        '#title' => $this->t('Seleccione la Imagen'),
        '#upload_location' => "public://certificados-fucs",
        '#upload_validators' => [
          'file_validate_extensions' => ['png jpg svg gif ico jpeg'],
          '#required' => TRUE,
        ],
        '#attached' => [
          'library' => [],
        ],
      ];
      $form['container']['certificates'][$element]["imageCertificate"]['id'] = [
        '#type' => 'hidden',
        '#title' => $this->t('id de la imagen'),
        '#default_value' => isset($this->configuration['container']['certificates'][$element]["imageCertificate"]['id']) ? $this->configuration['container']['certificates'][$element]["imageCertificate"]['id'] : '',
        '#weight' => '0',
      ];
      $form['container']['certificates'][$element]["imageCertificate"]['name'] = [
        '#type' => 'hidden',
        '#title' => $this->t('Nombre de laimagen'),
        '#default_value' => isset($this->configuration['container']['certificates'][$element]["imageCertificate"]['name']) ? $this->configuration['container']['certificates'][$element]["imageCertificate"]['name'] : '',
        '#weight' => '0',
      ];
      $form['container']['certificates'][$element]["imageQueimageCertificatestion"]['uri'] = [
        '#type' => 'hidden',
        '#title' => $this->t('uri'),
        '#default_value' => isset($this->configuration['container']['certificates'][$element]["imageCertificate"]['uri']) ? $this->configuration['container']['certificates'][$element]["imageCertificate"]['uri'] : '',
        '#weight' => '0',
      ];
      $form['container']['certificates'][$element]["imageCertificate"]['urlTotal'] = [
        '#type' => 'textfield',
        '#title' => $this->t('url total'),
        '#default_value' => isset($this->configuration['container']['certificates'][$element]["imageCertificate"]['urlTotal']) ? $this->configuration['container']['certificates'][$element]["imageCertificate"]['urlTotal'] : '',
        '#weight' => '0',
      ];
      if (!empty($this->configuration['container']['certificates'][$element]["imageCertificate"]['urlTotal'])) {
        $form['container']['certificates'][$element]['showImage'] = [
          '#type' => 'markup',
          '#prefix' => '<div id="box" class="image_class">',
          '#suffix' => '</div>',
          '#markup' => '<img src="' . $this->configuration['container']['certificates'][$element]["imageCertificate"]['urlTotal'] . '" alt="' . $this->configuration['container']['certificates'][$element]["imageCertificate"]['name'] . '" >',
        ];
      }
    }

    $form['container']['add'] = [
      '#type' => 'submit',
      '#value' => $this->t('Agregar un certificado'),
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

    if ($num_certificates > 0) {
      $form['container']['remove'] = [
        '#type' => 'submit',
        '#value' => $this->t('Eliminar el último certificado'),
        '#submit' => [
          [$this, 'removeContainerCallback'],
        ],
        '#ajax' => [
          'callback' => [$this, 'addFieldSubmit'],
          'wrapper' => 'container-fields-wrapper',
        ],
        '#attributes' => [
          'data-link-action' => ['Eliminar certificados'],
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
  public function submitForm(array &$form, FormStateInterface $form_state) {
    $this->configuration['container']['certificates'] = $form_state->getValue(['container', 'certificates']);

    foreach ($this->configuration['container']['certificates'] as $key => $certificates) {
      $fid = isset($certificates["image"][0]) ? $certificates["image"][0] : NULL;
      if ($fid) {
        $file = File::load($fid);
        $filename = $file->getFilename();
        $fileuri = $file->getFileUri();
        $realpath = substr($fileuri, 9);
        $file->setPermanent();
        $file->save();
        $imgUri = base_path() . "sites/default/files/" . $realpath;
        $this->configuration['container']['certificates'][$key]["imageCertificate"]['name'] = $filename;
        $this->configuration['container']['certificates'][$key]["imageCertificate"]['uri'] = $fileuri;
        $this->configuration['container']['certificates'][$key]["imageCertificate"]['id'] = $fid;
        $this->configuration['container']['certificates'][$key]["imageCertificate"]['urlTotal'] = $imgUri;
      }
    }
    $this->config('fucs.form.settings')
      ->set('container', $this->configuration)
      ->save();
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
    $max = $form_state->get('num_certificates') + 1;
    $form_state->set('num_certificates', $max);
    $form_state->setRebuild();
  }

  /**
   * {@inheritdoc}
   */
  public function removeContainerCallback(array &$form, FormStateInterface $form_state) {
    $num_fields = $form_state->get('num_certificates');
    if ($num_fields > 0) {
      $max = $num_fields - 1;
      $form_state->set('num_certificates', $max);
      if ($max == 0) {
        $form_state->set('remove', TRUE);
      }
    }
    $form_state->setRebuild();
  }

}
