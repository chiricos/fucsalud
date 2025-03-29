<?php

namespace Drupal\online_shop_fucs\Controller;

use Drupal\Core\Controller\ControllerBase;

class BaseController extends ControllerBase
{

    function createRandomVal()
    {
        $arreglo = array("a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z", "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9");
        $pass = '';
        $tmp = '';
        $num = 0;

        for ($i = 0; $i < 40; $i++) {
            $num  = rand() % 62;
            $tmp  = $arreglo[$num];
            $pass = $pass . $tmp;
        }

        return $pass;
    }

    function getItems($user)
    {

        try {
            $connection = \Drupal::database();
            $query = $connection->select('carrito', 'u');
            $query->condition('u.usuario_sesion', $user, '=')
                ->fields('u', ['id', 'nombre', 'precio']);
            $items = $query->execute()->fetchAll();
        } catch (\Exception $e) {
            return FALSE;
        }
        return $items;
    }

    function saveItem($data)
    {

        try {
            \Drupal::database()->insert('carrito')
                ->fields([
                    'id',
                    'nombre',
                    'referencia',
                    'precio',
                    'usuario_sesion'
                ])
                ->values($data)
                ->execute();
        } catch (\Exception $e) {
            return FALSE;
        }
        return TRUE;
    }


    function deleteItem($user, $id)
    {

        try {
            \Drupal::database()->delete('carrito')
                ->condition('id', $id)
                ->condition('usuario_sesion', $user)
                ->execute();
        } catch (\Exception $e) {
            return FALSE;
        }
        return TRUE;
    }

    public function getTotal($items)
    {
        $total = 0;
        foreach ($items as $item) {
            $price = ($item->precio > 0) ? $item->precio : substr($item->precio, 1);
            $total = $total + $price;
        }
        return $total;
    }
}
