<?php

namespace Drupal\online_shop_fucs\EventSubscriber;

use Symfony\Component\HttpFoundation\RedirectResponse;
use Symfony\Component\HttpKernel\KernelEvents;
use Symfony\Component\EventDispatcher\EventSubscriberInterface;
use Drupal\Core\Url;
use Symfony\Component\HttpKernel\Event\GetResponseEvent;
use Drupal\Core\Session\AccountProxyInterface;

class CustomRedirectSubscriber implements EventSubscriberInterface {

    protected $currentUser;

    public function __construct(AccountProxyInterface $current_user) {
      $this->currentUser = $current_user;
    }

    public static function getSubscribedEvents() {
        $events[KernelEvents::REQUEST][] = ['checkForRedirection'];
        return $events;
      }

    public function checkForRedirection(GetResponseEvent $event) {
        $request = $event->getRequest();
        $path = $request->getPathInfo();
        $route_name = $event->getRequest()->attributes->get('_route');

        if (\Drupal::currentUser()->isAnonymous() && 
            strpos($route_name, 'view.colaboradores.page_1') === 0) {
            $this->redirectLogin($event);
        }
        if (strpos($path, '/colaboradores') !== false || strpos($path, '/colaborador') !== false) {
            $allowed_roles = ['colaborador', 'colaboradores', 'administrator']; // Roles permitidos
            $user_roles = $this->currentUser->getRoles();

            if (empty(array_intersect($allowed_roles, $user_roles))) {
                $this->redirectLogin($event);
            }
        }
       

    }

    public function redirectLogin($event) {
        $url = Url::fromRoute('user.login');
        $response = new RedirectResponse($url->toString());
        $event->setResponse($response);
    }

}