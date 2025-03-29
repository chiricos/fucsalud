<?php

namespace Drupal\drupal_google_auth\Plugin\Block;

use Drupal\Core\Block\BlockBase;
use Drupal\Core\Form\FormStateInterface;

/**
 * Provides a 'GoogleAuthBlock' block.
 *
 * @Block(
 *  id = "google_auth_block",
 *  admin_label = @Translation("Google auth"),
 *  group = "drupal"
 * )
 */
class GoogleAuthBlock extends BlockBase {

  protected $configuration;

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

    
    return $form;
  }

  /**
   * {@inheritdoc}
   */
  public function blockSubmit($form, FormStateInterface $form_state) {

  }

  /**
   * {@inheritdoc}
   */
  public function build() {
    $build = [
      '#theme' => 'google_auth',
      '#config' => $this->configuration,
    ];

    $build['#cache']['max-age'] = 0;
    return $build;
  }

}