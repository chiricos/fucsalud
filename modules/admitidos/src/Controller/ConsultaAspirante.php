<?php

namespace Drupal\admitidos\Controller;
use Drupal\Core\Controller\ControllerBase;
use Symfony\Component\HttpFoundation\Request;
use Drupal\Core\Access\AccessResult; 
use Drupal\Core\Form\FormInterface;

class ConsultaAspirante extends ControllerBase {
  /**
   * Display the markup.
   *
   * @return array
   */
  public function consulta(Request $request) {

    $form = \Drupal::formBuilder()->getForm('Drupal\admitidos\Form\ConsultaForm');
    
    return $form;
  }
}