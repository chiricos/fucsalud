<?php
/**
 * @file
 * Contains \Drupal\certificados\Form\ConsultaForm.
 */
namespace Drupal\certificados\Form;
use Drupal\Core\Form\FormBase;
use Drupal\Core\Form\FormStateInterface;
use Drupal\node\Entity\Node;
use Drupal\file\Entity\File;
use Symfony\Component\HttpFoundation\RedirectResponse;

class ConsultaFormEventosConferencista extends FormBase {
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
			'#markup' => '<h2>GENERACIÓN DE CERTIFICADO DIGITAL.</h2>
										<br><p>Para generar su certificado por favor ingrese su número de identificación y de clic en el botón "ENVIAR"</p>
										<p>Nota: por favor debe esperar unos segundos mientras se genera su certificado, no cierre la ventana hasta tener la vista previa en pantalla.</p>
										<p>Guarde su certificado en el computador antes de imprimir. Para realizar una nueva consulta con otro número de identificación, por favor cierre la ventana e ingrese nuevamente.</p>',
		);

		$form['certificados_eventos_conferencista'] = array(
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

		return $form;
	}

	/**
	 * {@inheritdoc}
	 */
	public function submitForm(array &$form, FormStateInterface $form_state) {

		$documento = $form_state->getValue('certificados_eventos_conferencista');
		$connection = \Drupal::database();

		if ($documento <> null) {
			$query = $connection->query("SELECT Nombre, Tipo, Documento, Ponencia, Evento, Fecha, Id FROM {certificado_eventos_conferencista} cert WHERE Documento = '".$documento."' order by Id desc limit 1");

			if ($query) {
				$row = $query->fetchAssoc();
				$nombre = $row['Nombre'];
				$tipo = $row['Tipo'];
				$documento = $row['Documento'];
				$ponencia = $row['Ponencia'];
				$evento = $row['Evento'];
				$fecha = ['Fecha'];
				$id = $row['Id'];

				global $base_url;

				if ($documento <> null) {
					$response = new RedirectResponse($base_url.'/resultado-consulta-certificado-eventos-conferencista/'.$documento);
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