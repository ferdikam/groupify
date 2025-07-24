<?php

use Illuminate\Contracts\Http\Kernel;
use Illuminate\Http\Request;

require_once dirname(__DIR__).'/vendor/autoload.php';

$app = require_once dirname(__DIR__).'/bootstrap/app.php';
$kernel = $app->make(Kernel::class);

// Worker mode pour FrankenPHP
for ($nbRequests = 0, $running = true; $running; ++$nbRequests) {
    $running = \frankenphp_handle_request(function () use ($kernel, $nbRequests): void {
        // Éviter les fuites mémoire en recréant certains objets
        if ($nbRequests > 0) {
            $kernel->terminate(request(), response());
        }

        $request = Request::capture();
        $response = $kernel->handle($request);
        $response->send();

        // Nettoyage périodique
        if ($nbRequests % 500 === 0) {
            gc_collect_cycles();
        }
    });
}
