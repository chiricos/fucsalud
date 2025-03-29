<?php
// mi_modulo/src/Controller/MiModuloController.php
namespace Drupal\biblioteca_form\Controller;

use Drupal\Core\Controller\ControllerBase;
use Drupal;

class MiModuloController extends ControllerBase {
    public function insertarGasto() {
        echo "entro controlador";exit;
        $form = $this->formBuilder()->getForm('Drupal\biblioteca_form\Form\InsertarGastoForm');

        return [
            '#theme' => 'pagina_insertar_gasto',
            '#titulo' => $this->t('Mi formulario'),
            '#descripcion' => 'Insertar formulario',
            '#formulario' => $form
        ];
    }
}
?>