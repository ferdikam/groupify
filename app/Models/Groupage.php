<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Groupage extends Model
{
    /** @use HasFactory<\Database\Factories\GroupageFactory> */
    use HasFactory;

    public function groupageProduits(): HasMany
    {
        return $this->hasMany(GroupageProduit::class);
    }

    /*public function produits(): BelongsToMany
    {
        return $this->belongsToMany(Produit::class, 'groupage_product')
            ->withPivot(['moq','prix_achat','prix_transport_fournisseur','fret','prix_livraison','prix_de_revient', 'prix_vente']);
    }*/

    public function souscriptions(): HasMany
    {
        return $this->hasMany(Souscription::class, 'groupe_id');
    }

}
