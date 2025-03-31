<?php

namespace App\Http\Controllers\Groupage;

use App\Actions\CreateGroupageAction;
use App\Http\Controllers\Controller;
use App\Http\Requests\CreateGroupageRequest;
use Illuminate\Http\Request;

class StoreController extends Controller
{
    /**
     * Handle the incoming request.
     */
    public function __invoke(CreateGroupageRequest $request, CreateGroupageAction $createGroupageAction)
    {
        if (! $request->user()->isAdmin()) {
            abort(403);
        }

        $createGroupageAction($request->only([
            'nom',
            'description',
            'date_debut',
            'date_fin',
            'statut',
            'produit_id',
        ]));
    }
}
