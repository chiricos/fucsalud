<?php
// mi_modulo/src/Plugin/Block/InsertarGastoFormBlock.php
/**
 * @file
 * Contains \Drupal\mi_modulo\Plugin\Block\InsertarGastoFormBlock.
 */

namespace Drupal\mi_modulo\Plugin\Block;

use Drupal\Core\Block\BlockBase;
use Drupal;
/** *
 * Bloque que muestra un formulario para insertar gastos *
 * @Block(
 *   id = "insertar_gasto_form_block",
 *   admin_label = @Translation("formulario para insertar gastos")
 * )
 */
class InsertarGastoFormBlock extends BlockBase {
    /**
     * {@inheritdoc}
     */
    public function build() {

        $form = Drupal::formBuilder()->getForm('Drupal\mi_modulo\Form\InsertarGastoForm');
        //añadimos clases a la etiqueta form
        $form['#attributes']['class'][] = 'mi-clase';
        //accedemos a los inputs y modificamos lo que queramos.
        $form['cantidad']['#value'] = 23;
        return [
            '#theme'        => 'bloque_insertar_gasto',
            '#template'        => 'bloque-insertar-gasto',
            '#titulo'       => 'Mi titulo super guay',
            '#descripcion'  => 'Un descripción',
            '#formulario'   => $form,
            '#cache'        => ['max-age' => 0],
            '#markup' => $this->t("Hello, World!")
        ];
    }
}



