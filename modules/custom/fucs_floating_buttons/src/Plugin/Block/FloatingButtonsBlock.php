<?php

namespace Drupal\fucs_floating_buttons\Plugin\Block;

use Drupal\Core\Block\BlockBase;
use Drupal\Core\Form\FormStateInterface;

/**
 * Bloque de botones flotantes con URLs configurables.
 *
 * @Block(
 *   id = "fucs_floating_buttons_block",
 *   admin_label = @Translation("Botones flotantes laterales"),
 *   category = @Translation("Fucsaluds"),
 * )
 */
class FloatingButtonsBlock extends BlockBase {

  /**
   * {@inheritdoc}
   */
  public function defaultConfiguration() {
    return [
      'configurations' => [
        'btn_inscripcion_url'    => '/aspirantes/admisiones',
        'btn_inscripcion_titulo' => 'Inscripción',
        'btn_inscripcion_activo' => TRUE,
        'btn_whatsapp_url'       => 'https://wa.me/573013367384',
        'btn_whatsapp_titulo'    => 'WhatsApp',
        'btn_whatsapp_activo'    => TRUE,
        'btn_soporte_url'        => '/pqrs',
        'btn_soporte_titulo'     => 'Soporte PQRS',
        'btn_soporte_activo'     => TRUE,
      ],
    ];
  }

  /**
   * {@inheritdoc}
   */
  public function blockForm($form, FormStateInterface $form_state) {
    $c = $this->configuration['configurations'];

    // ---- Botón 1: Inscripción ----------------------------------------
    $form['configurations']['btn_inscripcion'] = [
      '#type'        => 'details',
      '#title'       => $this->t('Botón 1 — Inscripción (azul)'),
      '#open'        => TRUE,
    ];
    $form['configurations']['btn_inscripcion']['btn_inscripcion_activo'] = [
      '#type'          => 'checkbox',
      '#title'         => $this->t('Mostrar botón'),
      '#default_value' => $c['btn_inscripcion_activo'] ?? TRUE,
    ];
    $form['configurations']['btn_inscripcion']['btn_inscripcion_titulo'] = [
      '#type'          => 'textfield',
      '#title'         => $this->t('Texto / tooltip'),
      '#default_value' => $c['btn_inscripcion_titulo'] ?? 'Inscripción',
      '#required'      => FALSE,
    ];
    $form['configurations']['btn_inscripcion']['btn_inscripcion_url'] = [
      '#type'          => 'textfield',
      '#title'         => $this->t('URL de destino'),
      '#default_value' => $c['btn_inscripcion_url'] ?? '/aspirantes/admisiones',
      '#required'      => FALSE,
    ];

    // ---- Botón 2: WhatsApp -------------------------------------------
    $form['configurations']['btn_whatsapp'] = [
      '#type'  => 'details',
      '#title' => $this->t('Botón 2 — WhatsApp (verde)'),
      '#open'  => TRUE,
    ];
    $form['configurations']['btn_whatsapp']['btn_whatsapp_activo'] = [
      '#type'          => 'checkbox',
      '#title'         => $this->t('Mostrar botón'),
      '#default_value' => $c['btn_whatsapp_activo'] ?? TRUE,
    ];
    $form['configurations']['btn_whatsapp']['btn_whatsapp_titulo'] = [
      '#type'          => 'textfield',
      '#title'         => $this->t('Texto / tooltip'),
      '#default_value' => $c['btn_whatsapp_titulo'] ?? 'WhatsApp',
    ];
    $form['configurations']['btn_whatsapp']['btn_whatsapp_url'] = [
      '#type'          => 'textfield',
      '#title'         => $this->t('URL de WhatsApp'),
      '#description'   => $this->t('Formato: https://wa.me/57XXXXXXXXXX'),
      '#default_value' => $c['btn_whatsapp_url'] ?? 'https://wa.me/573013367384',
    ];

    // ---- Botón 3: Soporte -------------------------------------------
    $form['configurations']['btn_soporte'] = [
      '#type'  => 'details',
      '#title' => $this->t('Botón 3 — Soporte / PQRS (verde oliva)'),
      '#open'  => TRUE,
    ];
    $form['configurations']['btn_soporte']['btn_soporte_activo'] = [
      '#type'          => 'checkbox',
      '#title'         => $this->t('Mostrar botón'),
      '#default_value' => $c['btn_soporte_activo'] ?? TRUE,
    ];
    $form['configurations']['btn_soporte']['btn_soporte_titulo'] = [
      '#type'          => 'textfield',
      '#title'         => $this->t('Texto / tooltip'),
      '#default_value' => $c['btn_soporte_titulo'] ?? 'Soporte PQRS',
    ];
    $form['configurations']['btn_soporte']['btn_soporte_url'] = [
      '#type'          => 'textfield',
      '#title'         => $this->t('URL de destino'),
      '#default_value' => $c['btn_soporte_url'] ?? '/pqrs',
    ];

    return $form;
  }

  /**
   * {@inheritdoc}
   */
  public function blockSubmit($form, FormStateInterface $form_state) {
    $values = $form_state->getValue('configurations');

    // Aplanar los subgrupos de #type details en un array plano.
    $this->configuration['configurations'] = [
      'btn_inscripcion_activo' => (bool) ($values['btn_inscripcion']['btn_inscripcion_activo'] ?? TRUE),
      'btn_inscripcion_titulo' => $values['btn_inscripcion']['btn_inscripcion_titulo'] ?? '',
      'btn_inscripcion_url'    => $values['btn_inscripcion']['btn_inscripcion_url'] ?? '',
      'btn_whatsapp_activo'    => (bool) ($values['btn_whatsapp']['btn_whatsapp_activo'] ?? TRUE),
      'btn_whatsapp_titulo'    => $values['btn_whatsapp']['btn_whatsapp_titulo'] ?? '',
      'btn_whatsapp_url'       => $values['btn_whatsapp']['btn_whatsapp_url'] ?? '',
      'btn_soporte_activo'     => (bool) ($values['btn_soporte']['btn_soporte_activo'] ?? TRUE),
      'btn_soporte_titulo'     => $values['btn_soporte']['btn_soporte_titulo'] ?? '',
      'btn_soporte_url'        => $values['btn_soporte']['btn_soporte_url'] ?? '',
    ];
  }

  /**
   * {@inheritdoc}
   */
  public function build() {
    $c = $this->configuration['configurations'];

    return [
      '#theme'  => 'fucs_floating_buttons',
      '#config' => $c,
      '#attached' => [
        'library' => ['fucs/floating-actions'],
      ],
      '#cache'  => ['max-age' => 0],
    ];
  }

}
