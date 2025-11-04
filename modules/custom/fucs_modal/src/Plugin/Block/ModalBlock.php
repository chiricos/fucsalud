<?php

namespace Drupal\fucs_modal\Plugin\Block;

use Drupal\Core\Block\BlockBase;
use Drupal\Core\Form\FormStateInterface;
use Drupal\file\Entity\File;

/**
 * Provides a 'Custom Block' Block.
 *
 * @Block(
 *   id = "fucs_modal_block",
 *   admin_label = @Translation("Modal fucs Block"),
 *   category = @Translation("Fucsaluds"),
 * )
 */
class ModalBlock extends BlockBase {

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

    $form['configurations']['title'] = [
      '#type' => 'textfield',
      '#title' => $this->t('Título'),
      '#default_value' => isset($this->configuration["configurations"]["title"]) ? $this->configuration["configurations"]["title"] : "",
    ];

    $form['configurations']['image'] = [
      '#type' => 'managed_file',
      '#title' => $this->t('Imagen'),
      '#upload_location' => 'public://imagenes/',
      '#default_value' => !empty($this->configuration['configurations']['image'])  ? [$this->configuration['configurations']['image']] : NULL,
      '#upload_validators' => [
        'file_validate_extensions' => ['png jpg jpeg'],
      ],
    ];  

    $form['configurations']['link'] = [
      '#type' => 'textfield',
      '#title' => $this->t('Link'),
      '#default_value' => isset($this->configuration["configurations"]["link"]) ? $this->configuration["configurations"]["link"] : "",
    ];

    return $form;
  }

  /**
   * {@inheritdoc}
   */
  public function blockSubmit($form, FormStateInterface $form_state) {
    $this->configuration['configurations'] = $form_state->getValue('configurations');
    $image_fids = $form_state->getValue('configurations')['image'];
    if (!empty($image_fids) && is_array($image_fids)) {
      $fid = reset($image_fids);
      if ($fid) {
        $file = File::load($fid);
        if ($file) {
          $file->setPermanent();
          $file->save();
          $this->configuration['configurations']['image'] = $fid;
        }
      }
    }
  }

  /**
   * {@inheritdoc}
   */
  public function build() {
    $body = isset($this->configuration["configurations"]["body"]["value"]) ? $this->configuration["configurations"]["body"]["value"] : "";
    $image = !empty($this->configuration["configurations"]["image"]) ? File::load($this->configuration["configurations"]["image"]) : '';
    $url = !empty($image) ? $image->getFileUri() : '';

    $config = [
      'days' => $this->configuration["configurations"]['days'],
    ];
    $modal = [
      'title' => $this->configuration["configurations"]["title"],
      'body' => $body,
      'image' => !empty($url) ? \Drupal::service('file_url_generator')->generateAbsoluteString($url) : '',
      'link' => $this->configuration["configurations"]["link"],
      'link_text' => $this->configuration["configurations"]["link_text"],
    ];

    $build = [
      '#theme' => 'modal_block',
      '#config' => $modal,
      '#attached' => [
        'drupalSettings' => [
          'config' => $config,
        ],
      ],
    ];

    $build['#cache']['max-age'] = 0;
    return $build;
  }
}