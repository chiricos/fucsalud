<?php

namespace Drupal\certificados\Services;

/**
 * Class FucsEmail.
 */
class Utils {

  /**
   * {@inheritdoc}
   */
	function fix_row_utf8($row) {
    return $row;
    foreach ($row as $key => $value) {
      if (is_string($value)) {
        // Corrige ISO-8859-1 a UTF-8
        $row[$key] = \mb_convert_encoding($value, 'UTF-8', 'ISO-8859-1');

        // Si sigue mal, aplica utf8_encode
        if (\mb_detect_encoding($row[$key], 'UTF-8', true) === false) {
          $row[$key] = \utf8_encode($value);
        }
      }
    }
    return $row;
	}	
}
