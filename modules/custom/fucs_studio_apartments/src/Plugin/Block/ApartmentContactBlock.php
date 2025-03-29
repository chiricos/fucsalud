<?php

namespace Drupal\fucs_studio_apartments\Plugin\Block;

use Drupal\Core\Block\BlockBase;
use Drupal\Core\Form\FormStateInterface;
use Drupal\file\Entity\File;

/**
 * Provides a 'FucsApartmentContactBlock' block.
 *
 * @Block(
 *  id = "fucs_apartment_contact_block",
 *  admin_label = @Translation("Formulario de contacto - apartaestudio"),
 *  group = "fucs_form"
 * )
 */
class ApartmentContactBlock extends BlockBase {

  protected $configuration;
 
  /**
   * {@inheritdoc}
   */
  public function defaultConfiguration() {
    return [
      'form' => isset($this->configuration['form']) ? $this->configuration['form'] : [],
    ];
  }

  /**
   * {@inheritdoc}
   */
  public function blockForm($form, FormStateInterface $form_state) {

   
    $form_state->setRebuild();
    return $form;
  }

  /**
   * {@inheritdoc}
   */
  public function blockSubmit($form, FormStateInterface $form_state) {
    $test = "edward";
  }

  /**
   * {@inheritdoc}
   */
  public function build() {
    $formBuilder = \Drupal::formBuilder();
    $form = $formBuilder->getForm('\Drupal\fucs_studio_apartments\Form\ApartmentContactForm');
    $build = [
      '#theme' => 'fucs_studio_apartments',
      '#form' => $form,
    ];

    $build['#cache']['max-age'] = 0;
    return $build;
  }

}
