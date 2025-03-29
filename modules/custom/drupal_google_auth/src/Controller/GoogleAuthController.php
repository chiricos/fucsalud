<?php

namespace Drupal\drupal_google_auth\Controller;

use Drupal\user\Entity\User;
use Drupal\Core\Controller\ControllerBase;
use Google\Client;
use Drupal\Core\Routing\TrustedRedirectResponse;
use Symfony\Component\HttpFoundation\RedirectResponse;

class GoogleAuthController extends ControllerBase{

	protected $client;
	protected $config;

	public function __construct() {
		$this->config = \Drupal::config('google_auth.config');
		$this->client = new Client();
		$this->client->setClientId($this->config->get('google')['clientId']);
		$this->client->setClientSecret($this->config->get('google')['clientSecret']);
		$this->client->setRedirectUri(\Drupal::request()->getSchemeAndHttpHost() . '/auth/google/callback');
		$this->client->addScope('email');
		$this->client->addScope('profile');
	}

	public function getAuth() {
		return new TrustedRedirectResponse($this->client->createAuthUrl());
	}

	public function callback() {
		$code = \Drupal::request()->get('code');
		$scope = \Drupal::request()->get('scope');
		$auth_user = \Drupal::request()->get('authuser');
		$login = 0;
		$name = "";

		try {
			$token = $this->client->fetchAccessTokenWithAuthCode($code);
			if(!isset($token['error'])) {
				$this->client->setAccessToken($token['access_token']);		
			
				$google_service = new \Google_Service_Oauth2($this->client);
			
			 
				$data = $google_service->userinfo->get();
	
				$user = \Drupal::entityTypeManager()
					->getStorage('user')
					->loadByProperties([
					'mail' => $data->email,
				]);
				$user = reset($user);
				if ($user) {
					$current_user = \Drupal::service('entity_type.manager')->getStorage('user')->load($user->id());
					$rids = $user->getRoles();
					$roles_allows = $this->config->get('google')['roles'];
					$roles_allow = explode(',', $roles_allows);
					$login = 1;
					$name = $data->name;
					$user = User::load($user->id());
					user_login_finalize($user);
					foreach ($rids as $role) {
						foreach ($roles_allow as $role_allow) {
							if ($role == $role_allow) {
								\Drupal::currentUser()
									->setAccount($user);
								if ($role == "colaboradores") {
									$response = new RedirectResponse(\Drupal::request()->getSchemeAndHttpHost() . "/colaboradores");
									$response->send();
									return $response;
								}
								$response = new RedirectResponse(\Drupal::request()->getSchemeAndHttpHost() . "/auth/google/login?name={$name}&login={$login}");
								$response->send();
								return $response;
							}
						}
						
					}
				}
				
				
			}
		} 
		catch(\Exception $e) {
			print_r($e->getMessage());exit;
		}
		$response = new RedirectResponse(\Drupal::request()->getSchemeAndHttpHost() . "/auth/google/login?name={$name}&login={$login}");
		$response->send();
		return $response;
	}

	public function login() {
		$name = \Drupal::request()->get('name');
		$login = \Drupal::request()->get('login');
		$build = [
      '#theme' => 'google_login',
      '#name' => $name,
			'#login' => $login,
    ];

    $build['#cache']['max-age'] = 0;
    return $build;
	}


}