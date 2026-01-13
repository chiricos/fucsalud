<?php

namespace Drupal\online_shop_fucs\Services;

use Drupal\Core\Http\ClientFactory;
use Symfony\Component\DependencyInjection\ContainerInterface;

/**
 * Consume los servicios rest de ecollet.
 */
class EcolletPayment {

  /**
   * La URL base utilizada para construir las solicitudes.
   *
   * @var string
   */
  protected $baseUrl = "https://test1.e-collect.com/app_express/api/";

  /**
   * El cliente HTTP Guzzle usado para realizar solicitudes.
   *
   * @var \GuzzleHttp\Client
   */
  protected $httpClient;

  /**
   * {@inheritdoc}
   */
  public function __construct(ClientFactory $client_factory) {
    $this->httpClient = $client_factory->fromOptions([
      'timeout' => 10,
    ]);
  }

  /**
   * {@inheritdoc}
   */
  public static function create(ContainerInterface $container) {
    return new static(
      $container->get('http_client_factory')
    );
  }

  /**
   * {@inheritdoc}
   */
  public function getSessionToken() {
    $response = $this->httpClient->post($this->baseUrl . 'getSessionToken', [
      'headers' => [
        'Content-Type' => 'application/json',
        'Accept' => 'application/json',
      ],
      'json' => [
        'EntityCode' => 10228,
        'Apikey' => 'FU231fs4lnd',
      ],
    ]);
    $data = json_decode($response->getBody()->getContents(), TRUE);
    if (is_array($data) && isset($data["SessionToken"])) {
      return $data["SessionToken"];
    }
    return "";
  }

  /**
   * {@inheritdoc}
   */
  public function sendPayment($data) {
    $response = $this->httpClient->post($this->baseUrl . 'createTransactionPayment', [
      'headers' => [
        'Content-Type' => 'application/json',
        'Accept' => 'application/json',
      ],
      'json' => $data['request'],
    ]);
    $data = json_decode($response->getBody()->getContents(), TRUE);
    if (is_array($data) && isset($data["ReturnCode"])) {
      if ($data["ReturnCode"] == "SUCCESS") {
        return [
          'code' => $data["ReturnCode"],
          'TicketId' => $data["TicketId"],
          'eCollectUrl' => $data["eCollectUrl"],
        ];
      }
      else {
        return [
          'code' => $data["ReturnCode"],
          'TicketId' => "",
          'eCollectUrl' => "",
        ];
      }
    }
    return "";
  }

  /**
   * {@inheritdoc}
   */
  public function getTransaction($data) {
    $response = $this->httpClient->post($this->baseUrl . 'getTransactionInformation', [
      'headers' => [
        'Content-Type' => 'application/json',
        'Accept' => 'application/json',
      ],
      'json' => [
        'EntityCode' => $data["request"]["EntityCode"],
        'SessionToken' => $this->getSessionToken(),
        'TicketId' => $data["request"]["TicketId"],
      ],
    ]);
    $data = json_decode($response->getBody()->getContents(), TRUE);
    if (is_array($data) && isset($data["ReturnCode"])) {
      if ($data["ReturnCode"] == "SUCCESS") {
        return $data;
      }
      else {
        return [
          'code' => $data["ReturnCode"],
          'TicketId' => "",
          'eCollectUrl' => "",
        ];
      }
    }
    return "";
  }
}
