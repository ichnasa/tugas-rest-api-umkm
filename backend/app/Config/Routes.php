<?php

use CodeIgniter\Router\RouteCollection;

/** @var RouteCollection $routes */
$routes->get('/', 'Home::index');

// REST API UMKM
$routes->group('api', ['namespace' => 'App\Controllers\Api', 'filter' => 'cors'], static function (RouteCollection $routes) {
    $routes->resource('umkm', ['controller' => 'UmkmController', 'except' => ['new', 'edit']]);
    // Preflight CORS (dipakai Flutter Web)
    $routes->options('umkm', static function () {});
    $routes->options('umkm/(:any)', static function () {});
});
