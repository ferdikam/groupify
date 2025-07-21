<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Produit extends Model
{
    /** @use HasFactory<\Database\Factories\ProduitFactory> */
    use HasFactory;

    public function groupages(): BelongsToMany
    {
        return $this->belongsToMany(Groupage::class)
            ->withPivot(['moq', 'prix_achat', 'prix_transport_fournisseur', 'fret', 'prix_livraison', 'prix_de_revient', 'prix_vente'])
            ->withTimestamps();;
    }

    public function fournisseur(): BelongsTo
    {
        return $this->belongsTo(Fournisseur::class);
    }

    /**
     * Relation avec les souscriptions
     */
    public function souscriptions(): BelongsToMany
    {
        return $this->belongsToMany(Souscription::class, 'produit_souscription', 'produit_id', 'souscription_id')
            ->withPivot(['quantite', 'prix_unitaire', 'sous_total'])
            ->withTimestamps();
    }

    /**
     * Obtenir le prix de vente pour un groupage spécifique
     */
    public function getPrixVentePourGroupage(int $groupageId): int
    {
        $pivot = $this->groupages()->where('groupage_id', $groupageId)->first()?->pivot;
        return $pivot?->prix_vente ?? 0;
    }

    /**
     * Calculer la quantité totale souscrite pour ce produit
     */
    public function getQuantiteTotaleSouscriteAttribute(): int
    {
        return $this->souscriptions()->sum('souscription_produits.quantite');
    }
}
