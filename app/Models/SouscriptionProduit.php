<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\Pivot;

class SouscriptionProduit extends Pivot
{
    protected $table = 'produit_souscription';
    public $incrementing = true;

    public function souscription(): BelongsTo
    {
        return $this->belongsTo(Souscription::class);
    }

    public function produit(): BelongsTo
    {
        return $this->belongsTo(Produit::class);
    }

    // Calculer automatiquement le sous-total
    protected static function boot()
    {
        parent::boot();

        static::saving(function ($souscriptionProduit) {
            $souscriptionProduit->sous_total = $souscriptionProduit->quantite * $souscriptionProduit->prix_unitaire;
        });
    }
}
