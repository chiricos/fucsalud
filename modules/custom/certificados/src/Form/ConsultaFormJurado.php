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

class ConsultaFormJurado extends FormBase {
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
			'#markup' => '<h2>GENERACIÓN DE CERTIFICADO DIGITAL DE EVENTOS ACADÉMICOS.</h2>
										<br><p>Para generar su certificado por favor ingrese su número de identificación.<br>Si su certificado es de  presentaciones de trabajo (presentaciones orales o póster) o ganadores ingrese el número de identificación del ponente.<br>De clic en el botón "ENVIAR"</p>
										<p>Nota: por favor debe esperar unos segundos mientras se genera su certificado, no cierre la ventana hasta tener la vista previa en pantalla.</p>
										<p>Guarde su certificado en el computador antes de imprimir. Para realizar una nueva consulta con otro número de identificación, por favor cierre la ventana e ingrese nuevamente.</p>',
		);

		$form['certificados_jurado'] = array(
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
		$documento = $form_state->getValue('certificados_jurado');
		$connection = \Drupal::database();

		if ($documento <> null) {
			$query = $connection->query("SELECT Nombre, Tipo, Documento, Evento, Fecha, Id FROM {certificado_jurado} cert WHERE Documento = '".$documento."' order by Id desc limit 1");

			if ($query) {
				$row = $query->fetchAssoc();
				$nombre = $row['Nombre'];
				$tipo = $row['Tipo'];
				$documento = $row['Documento'];
				$evento = $row['Evento'];
				$fecha = ['Fecha'];
				$id = $row['Id'];

				global $base_url;

				if ($documento <> null) {
					$response = new RedirectResponse($base_url.'/resultado-consulta-certificado-jurado/'.$documento);
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