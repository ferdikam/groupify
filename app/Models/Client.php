<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Casts\Attribute;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Client extends Model
{
    /** @use HasFactory<\Database\Factories\ClientFactory> */
    use HasFactory;

    public function souscriptions(): HasMany
    {
        return $this->hasMany(Souscription::class);
    }

    /**
     * Obtenir les groupages auxquels le client a souscrit
     */
    public function groupages()
    {
        return $this->belongsToMany(Groupage::class, 'souscriptions')
            ->withPivot(['numero_souscription', 'montant_total', 'montant_paye', 'statut', 'date_souscription'])
            ->withTimestamps();
    }

    public function nomComplet(): Attribute
    {
        return Attribute::make(
            get: fn ($value) => ucfirst($this->nom) ." " .ucfirst($this->prenoms)
        );
    }
}
