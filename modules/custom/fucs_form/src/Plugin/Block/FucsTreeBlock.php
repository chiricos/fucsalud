<?php

namespace Drupal\fucs_form\Plugin\Block;

use Drupal\node\Entity\Node;
use Drupal\Core\Block\BlockBase;
use Drupal\Core\Form\FormStateInterface;
use Drupal\file\Entity\File;

/**
 * Provides a 'FucsTreeBlock' block.
 *
 * @Block(
 *  id = "fucs_tree_block",
 *  admin_label = @Translation("Módulo del árbol"),
 *  group = "fucs_tree"
 * )
 */
class FucsTreeBlock extends BlockBase {

  /**
   * {@inheritdoc}
   */
  public function defaultConfiguration() {
    return [
      'config' => isset($this->configuration['config']) ? $this->configuration['config'] : [],
    ];
  }

  /**
   * {@inheritdoc}
   */
  public function blockForm($form, FormStateInterface $form_state) {
    $form['#tree'] = TRUE;

    $form['config'] = [
      '#type' => 'details',
      '#title' => $this->t('Configuraciones'),
      '#open' => TRUE,
    ];

    $form['config']['width'] = [
      '#type' => 'number',
      '#title' => $this->t('Ancho de la imagen'),
      '#default_value' => isset($this->configuration['config']['width']) ? $this->configuration['config']['width'] : 800,
    ];

    $form['config']['y'] = [
      '#type' => 'number',
      '#title' => $this->t('Mover a lo alto'),
      '#default_value' => isset($this->configuration['config']['y']) ? $this->configuration['config']['y'] : -386,
    ];

    $form['config']['x'] = [
      '#type' => 'number',
      '#title' => $this->t('Mover a lo ancho'),
      '#default_value' => isset($this->configuration['config']['x']) ? $this->configuration['config']['x'] : 0,
    ];

    return $form;
  }

  /**
   * {@inheritdoc}
   */
  public function blockSubmit($form, FormStateInterface $form_state) {
    $this->configuration['config'] = $form_state->getValue('config');
  }

  /**
   * {@inheritdoc}
   */
  public function build() {
    $terms = $this->getTerms();
    $trees = $this->getTree($terms);

    $build = [
      '#theme' => 'fucs_tree',
      '#trees' => $trees,
      '#config' => $this->configuration["config"],
      '#attached' => [
        'library' => [
          'fucs_form/fucs-form',
        ],
      ],
    ];

    $build['#cache']['max-age'] = 0;
    return $build;
  }

  /**
   * getTerms
   */
  public function getTerms() {
    $terms = [];
    $termCateries = \Drupal::entityTypeManager()->getStorage('taxonomy_term')->loadTree('arbol_ano');
    foreach ($termCateries as $index => $termCatery) {
      $terms[$termCatery->tid] = isset($termCatery->name) ? $termCatery->name : '';
    }
    return $terms;
  }

  /**
   * getContent
   */
  public function getTree($terms) {
    $nids = \Drupal::entityQuery('node')
                      ->accessCheck(TRUE)
                      ->condition('type', 'arbol')
                      ->execute();
    $nodes = Node::loadMultiple($nids);
    $tree = [];
    foreach ($terms as $term) {
      $tree[$term] = [];
    }
    foreach ($nodes as $node) {
      $termLocal = \Drupal::entityTypeManager()->getStorage('taxonomy_term')->load($node->field_term_tree->getValue()[0]['target_id']);
      $tree[$termLocal->get('name')->getValue()[0]['value']]['months'][] = [
        'title' => $node->getTitle(),
        'name' => $node->field_tree_name->getValue() != NULL ? $node->field_tree_name->getValue()[0]['value'] : t('Descripción del archivo'),
        'file' => \Drupal::service('file_url_generator')->generateAbsoluteString($node->field_file_tree->entity->getFileUri()),
        'month' => $node->field_tree_month->getValue()[0]['value'],
      ];
    }
    return $tree;
  }

}
