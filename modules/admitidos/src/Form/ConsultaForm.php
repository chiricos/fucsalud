<?php
/**
 * @file
 * Contains \Drupal\admitidos\Form\ConsultaForm.
 */
namespace Drupal\admitidos\Form;
use Drupal\Core\Form\FormBase;
use Drupal\Core\Form\FormStateInterface;
use Drupal\node\Entity\Node;
use Drupal\file\Entity\File;
use Symfony\Component\HttpFoundation\RedirectResponse;

class ConsultaForm extends FormBase {
	/**
	 * {@inheritdoc}
	 */
	public function getFormId() {
		return 'consultas_form';
	}
	/**
	 * {@inheritdoc}
	 */
	public function buildForm(array $form, FormStateInterface $form_state) {
		$form['description'] = array(
			'#markup' => '<p>Consulte con su número de documento el resultado de su proceso de admisión.</p>',
		);

		$form['aspirante'] = array(
			'#type' => 'textfield',
			'#title' => $this
				->t('Documento'),
			'#size' => 60,
			'#maxlength' => 128,
			'#required' => TRUE,
			'#attributes' => array(
				'placeholder' => t('Documento'),
			),
		);

		$form['actions']['#type'] = 'actions';
		$form['actions']['submit'] = array(
			'#type' => 'submit',
			'#value' => $this->t('Enviar'),
			'#button_type' => 'primary',
		);


		$form['actions']['listado'] = array(
			'#type' => 'submit',
			'#value' => $this->t('Listado de admitidos'),
			'#submit' => array('admitidos_listado'),
			'#limit_validation_errors' => array(),
		);

		return $form;
	}

	/**
	 * {@inheritdoc}
	 */
	public function submitForm(array &$form, FormStateInterface $form_state) {
		$documento = $form_state->getValue('aspirante');
		$connection = \Drupal::database();

		if ($documento <> null) {
			$query = $connection->query("SELECT Estado, Carrera, Id FROM {aspirantes} asp WHERE Documento = '".$documento."' order by Id desc limit 1");

			if ($query) {
				$row = $query->fetchAssoc();
				$estado = $row['Estado'];
				$carrera = $row['Carrera'];
				$id = $row['Id'];

				global $base_url;

				if (($estado == "ADMITIDO") || ($estado == "NO ADMITIDO") || ($estado == "LISTA DE ESPERA")) {
					$response = new RedirectResponse($base_url.'/resultado-consulta/'.$documento);
					$response->send();
				}

				else {
					$this->messenger()->addError(t("No se encontraron datos con el numero de documento ".$documento));
				}
			}
		}

		else
		{
			$this->messenger()->addError(t("Debe ingresar número de documento"));
		}
	}
}