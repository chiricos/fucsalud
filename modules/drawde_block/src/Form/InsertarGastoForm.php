<?php
//mi_modulo/src/Form/InsertarGastoForm.php

namespace Drupal\mi_modulo\Form;

use Drupal\Core\Form\FormBase;
use Drupal\Core\Form\FormStateInterface;
use Drupal\Component\Utility\UrlHelper;

/**
* Desarrollo de un formulario en drupal 8
* @author Ignacio Farré
*/
class InsertarGastoForm extends FormBase {

    /**
    * {@inheritdoc}
    */
    public function getFormId() {
        return 'insertar_gasto_form';
    }

    /**
    * {@inheritdoc}
    */
    public function buildForm(array $form, FormStateInterface $form_state) {
        $form['nombre'] = [
            '#type'             => 'textfield',
            '#required'         => TRUE,
            '#placeholder'      => 'Nombre',
        ];
        $form['apellido'] = [
            '#type'             => 'textfield',
            '#required'         => TRUE,
            '#placeholder'      => 'Apellido',
        ];
        $form['fecha'] = [
            '#type'             => 'date',
            '#required'         => TRUE,
            '#placeholder'      => 'Fecha de nacimiento',
        ];
        $form['pais'] = [
            '#type'             => 'textfield',
            '#required'         => TRUE,
            '#placeholder'      => 'País',
        ];
        $form['ciudad'] = [
            '#type'             => 'textfield',
            '#required'         => TRUE,
            '#placeholder'      => 'Ciudad',
        ];
        $form['correo'] = [
            '#type'             => 'email',
            '#required'         => TRUE,
            '#placeholder'      => 'Correo electrónico',
        ];
        $form['politicas'] = [
            '#type'             => 'checkbox',
            '#required'         => TRUE,
            '#title'            => $this->t('Acepto las politicas de privacidad'),
        ];
        $form['submit'] = [
            '#type'  => 'submit',
        ];
        return $form;
    }

    /**
    * {@inheritdoc}
    */
    public function validateForm(array &$form, FormStateInterface $form_state) {

        /*if ($form_state->getValue('nombre') == "drawde" ) {
            $form_state->setErrorByName('nombre', $this->t('La cantidad tiene que ser mayor que 1'));
        }*/
    }

    /**
    * {@inheritdoc}
    */
    public function submitForm(array &$form, FormStateInterface $form_state) {
        // Display result.
        foreach ($form_state->getValues() as $key => $value) {
            $this->messenger()->addStatus($key . ': ' . $value);
        }
    }
}
?>