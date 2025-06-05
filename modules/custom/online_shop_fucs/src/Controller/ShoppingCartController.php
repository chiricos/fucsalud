<?php

namespace Drupal\online_shop_fucs\Controller;
use Symfony\Component\HttpFoundation\JsonResponse;
class ShoppingCartController
{

    public $dataPayments;
    public $user;

    public function __construct()
    {
        $this->dataPayments = \Drupal::service('online_shop_fucs.data_payments');
        $this->user = $this->dataPayments->getUser();
    }

    public function addItems()
    {
        $name = \Drupal::request()->query->get('nombre');
        $price = \Drupal::request()->query->get('precio');
        $artic = \Drupal::request()->query->get('articulo');

        $data = [
            null,
            $name,
            $artic,
            $price,
            $this->user,
        ];
        if ($this->dataPayments->saveItem($data)) {
            $message = "Item agregado con exito";
        } else {
            $message = "Item no pudo ser agregado";
        }
        $build = [
            '#title' => $message,
            'markup' => '',
        ];
        $build['#cache']['max-age'] = 0;
        return $build;
    }

    public function deleteItems()
    {
        $id = \Drupal::request()->query->get('id');
        if ($this->dataPayments->deleteItem($id)) {
            $message = "Item eliminado con exito";
        } else {
            $message = "Item no pudo ser eliminado";
        }
        return array(
            '#type' => 'markup',
            '#markup' => $id,
            '#title' => $message,
            '#cache' => array(
                'max-age' => 0,
            ),
        );
    }

    public function showItems()
    {
        $items = $this->dataPayments->getItems();
        if (count($items) > 0) {
            $build = [
                '#theme' => 'online_shop_fucs_items',
                '#items' => $items,
                '#total' => $this->dataPayments->getTotal($items),
            ];
        } else {
            $build = [
                '#title' => t('Carrito vacio'),
                '#markup' => t('Carrito vacio'),
            ];
        }
        $build['#cache']['max-age'] = 0;
        return $build;
    }

    public function confirm() {

        $data = $this->dataPayments->updateStatus();
        if ($data) {
            $build = [
                '#theme' => 'online_shop_fucs_confirm',
                '#items' => $data['items'],
                '#data_payment' => $data['data_payment'],
                '#status' => $data['status'],
                '#status_name' => $data['status_name'],
                '#title' => t('Proceso ya realizado'),
                '#markup' => t('Proceso ya realizado'),
            ];
        }
        else {
            $build = [
                '#title' => t('Proceso ya realizado'),
                '#markup' => t('Proceso ya realizado'),
            ];
        }

        $build['#cache']['max-age'] = 0;
        return $build;
    }

    public function donation() {
        $build = [
            '#theme' => 'donation',
        ];
        $build['#cache']['max-age'] = 0;
        return $build;
    }

    public function products() {
        $items = $this->dataPayments->getItems();
        return new JsonResponse(['products' => count($items), 'method' => 'GET', 'status' => 200]);
    }
}
