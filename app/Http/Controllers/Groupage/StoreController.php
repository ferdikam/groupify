<?php

namespace App\Http\Controllers\Groupage;

use App\Http\Controllers\Controller;
use App\Models\Groupage;
use Illuminate\Http\Request;

class StoreController extends Controller
{
    /**
     * Handle the incoming request.
     */
    public function __invoke(Request $request)
    {
        if (! $request->user()->isAdmin()) {
            abort(403);
        }
        Groupage::create([
            'nom' => $request->input('nom'),
            'description' => $request->input('description'),
            'date_debut' => $request->input('date_debut'),
            'date_fin' => $request->input('date_fin'),
            'statut' => $request->input('statut'),
            'produit_id' => $request->input('produit_id'),
        ]);
    }
}
