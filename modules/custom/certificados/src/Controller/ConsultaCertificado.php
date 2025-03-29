<?php

namespace Drupal\certificados\Controller;

use Drupal\Core\Controller\ControllerBase;
use Symfony\Component\HttpFoundation\Request;
use Drupal\Core\Access\AccessResult;
use Drupal\Core\Form\FormInterface;

class ConsultaCertificado extends ControllerBase {
  /**
   * Display the markup.
   *
   * @return array
   */
  public function consulta(Request $request) {

    $form = \Drupal::formBuilder()->getForm('Drupal\certificados\Form\ConsultaForm');

    return $form;
  }

  public function consulta_conferencista(Request $request) {

    $form = \Drupal::formBuilder()->getForm('Drupal\certificados\Form\ConsultaFormConferencista');

    return $form;
  }

  public function consulta_eventos_conferencista(Request $request) {

    $form = \Drupal::formBuilder()->getForm('Drupal\certificados\Form\ConsultaFormEventosConferencista');

    return $form;
  }

  public function consulta_jurado(Request $request) {

    $form = \Drupal::formBuilder()->getForm('Drupal\certificados\Form\ConsultaFormJurado');

    return $form;
  }

  public function consulta_ganador(Request $request) {

    $form = \Drupal::formBuilder()->getForm('Drupal\certificados\Form\ConsultaFormGanador');

    return $form;
  }

  public function consulta_trabajo(Request $request) {

    $form = \Drupal::formBuilder()->getForm('Drupal\certificados\Form\ConsultaFormTrabajo');

    return $form;
  }
}