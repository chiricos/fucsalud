<?php
namespace Drupal\biblioteca_form\Plugin\Block;
use Drupal\Core\Block\BlockBase;

class MiBloqueBlock extends BlockBase {

    /**
     * {@inheritdoc}
     */
    public function build() {
        return [
            '#type' => 'markup',
            '#markup' => 'mi bloque por fin!!!!!!!!drawde',
        ];
    }

}

/*
 * return array(
      '#type' => 'markup',
      '#markup' => $this->configuration['mi bloque por fin!!!!!!!!'],
    );
 */


/**
 * return array(
    '#title' => 'This is an awesome title',
    '#description' => 'Lorem ipsum dolar sum amet ..'
  );
 */
