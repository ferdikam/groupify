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

    public function produits(): BelongsToMany
    {
        return $this->belongsToMany(Produit::class, 'groupage_produit')
            ->withPivot(['moq','prix_achat','prix_transport_fournisseur','fret','prix_livraison','prix_de_revient', 'prix_vente']);
    }

    /**
     * Relation avec les souscriptions
     */
    public function souscriptions(): HasMany
    {
        return $this->hasMany(Souscription::class);
    }

    /**
     * Relation avec les clients qui ont souscrit
     */
    public function clients()
    {
        return $this->belongsToMany(Client::class, 'souscriptions')
            ->withPivot(['numero_souscription', 'montant_total', 'montant_paye', 'statut', 'date_souscription'])
            ->withTimestamps();
    }

    /**
     * Calculer le montant total des souscriptions pour ce groupage
     */
    public function getMontantTotalSouscriptionsAttribute(): int
    {
        return $this->souscriptions()->sum('montant_total');
    }

    /**
     * Calculer le montant total payé pour ce groupage
     */
    public function getMontantTotalPayeAttribute(): int
    {
        return $this->souscriptions()->sum('montant_paye');
    }

    /**
     * Nombre de clients ayant souscrit
     */
    public function getNombreClientsAttribute(): int
    {
        return $this->souscriptions()->distinct('client_id')->count();
    }

}
