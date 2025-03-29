<?php

namespace Drupal\certificados\Controller;

use Drupal\Core\Controller\ControllerBase;
use Symfony\Component\HttpFoundation\Request;
use Drupal\Core\Access\AccessResult;
use Drupal\Core\Form\FormInterface;

class ImportPage extends ControllerBase {
  /**
   * Display the markup.
   *
   * @return array
   */
  public function content(Request $request) {

    $form = \Drupal::formBuilder()->getForm('Drupal\certificados\Form\ImportForm');

    return $form;
  }

  public function content_conferencista(Request $request) {

    $form = \Drupal::formBuilder()->getForm('Drupal\certificados\Form\ImportFormConferencista');

    return $form;
  }

  public function content_eventos_conferencista(Request $request) {

    $form = \Drupal::formBuilder()->getForm('Drupal\certificados\Form\ImportFormEventosConferencista');

    return $form;
  }

  public function content_jurado(Request $request) {

    $form = \Drupal::formBuilder()->getForm('Drupal\certificados\Form\ImportFormJurado');

    return $form;
  }

  public function content_ganador(Request $request) {

    $form = \Drupal::formBuilder()->getForm('Drupal\certificados\Form\ImportFormGanador');

    return $form;
  }

  public function content_trabajo(Request $request) {

    $form = \Drupal::formBuilder()->getForm('Drupal\certificados\Form\ImportFormTrabajo');

    return $form;
  }
}