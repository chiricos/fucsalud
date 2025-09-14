<?php

namespace Drupal\fucs_studio_apartments\Plugin\Block;

use Drupal\Core\Block\BlockBase;

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

  /**
   * {@inheritdoc}
   */
  public function build() {
    $formBuilder = \Drupal::formBuilder();
    $form = $formBuilder->getForm('\Drupal\fucs_studio_apartments\Form\ApartmentContactForm');
    $form['#cache'] = ['max-age' => 0];
    return $form;
  }

}
