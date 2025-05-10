<?php

namespace App\Http\Controllers\Groupage;

use App\Actions\CreateGroupageAction;
use App\Http\Controllers\Controller;
use App\Http\Requests\CreateGroupageRequest;
use App\Models\Groupage;
use App\Models\Produit;

class GroupagesController extends Controller
{
    public function index()
    {
        if (! request()->user()->isAdmin()) {
            abort(403);
        }

        $groupages = Groupage::query()
            ->with('produit')
            ->latest()
            ->get();

        return view('groupage.index', [
            'groupages' => $groupages,

        ]);
    }

    public function create()
    {
        $produits = Produit::query()
            ->latest('nom')
            ->get();

        return view('groupage.create', [
            'produits' => $produits,
        ]);
    }

    public function store(CreateGroupageRequest $request, CreateGroupageAction $createGroupageAction)
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

        return redirect()->route('groupage.index');
    }

    public function show(Groupage $groupage)
    {
        $groupage->load('');

        return view('groupage.show', [
            'groupage' => $groupage,
        ]);
    }
}
