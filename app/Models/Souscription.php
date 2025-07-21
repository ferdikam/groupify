<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Support\Facades\DB;

class Souscription extends Model
{
    /** @use HasFactory<\Database\Factories\SouscriptionFactory> */
    use HasFactory;

    protected $casts = [
        'date_souscription' => 'date',
        'montant_total' => 'integer',
        'montant_paye' => 'integer',
    ];

    /**
     * Relation avec le client
     */
    public function client(): BelongsTo
    {
        return $this->belongsTo(Client::class);
    }

    /**
     * Relation avec le groupage
     */
    public function groupage(): BelongsTo
    {
        return $this->belongsTo(Groupage::class);
    }

    /**
     * Relation avec les produits via la table pivot
     */
    public function produits(): BelongsToMany
    {
        return $this->belongsToMany(Produit::class, 'produit_souscription', 'souscription_id', 'produit_id')
            ->withPivot(['quantite', 'prix_unitaire', 'sous_total', 'produit_id', 'souscription_id'])
            ->withTimestamps();
    }

    public function souscriptionProduits(): HasMany
    {
        return $this->hasMany(SouscriptionProduit::class);
    }

    /**
     * Relation avec les paiements
     */
    public function paiements(): HasMany
    {
        return $this->hasMany(Paiement::class);
    }

    /**
     * Calculer le montant restant à payer
     */
    public function getMontantRestantAttribute(): int
    {
        return $this->montant_total - $this->montant_paye;
    }

    /**
     * Vérifier si la souscription est entièrement payée
     */
    public function getEstPayeeAttribute(): bool
    {
        return $this->montant_paye >= $this->montant_total;
    }

    /**
     * Calculer le pourcentage de paiement
     */
    public function getPourcentagePaiementAttribute(): float
    {
        if ($this->montant_total == 0) {
            return 0;
        }
        return ($this->montant_paye / $this->montant_total) * 100;
    }

    /**
     * Générer un numéro de souscription unique
     */
    public static function genererNumeroSouscription(): string
    {
        do {
            $numero = 'SOUS-' . date('Y') . '-' . str_pad(mt_rand(1, 99999), 5, '0', STR_PAD_LEFT);
        } while (self::where('numero_souscription', $numero)->exists());

        return $numero;
    }

    /**
     * Mettre à jour le montant total basé sur les produits
     */
    public function calculerMontantTotal(): void
    {
        $total = $this->produits->sum('pivot.sous_total');
        $this->update(['montant_total' => $total]);
    }

    /**
     * Mettre à jour le montant payé basé sur les paiements confirmés
     */
    public function calculerMontantPaye(): void
    {
        $montantPaye = $this->paiements()
            ->where('statut', 'confirme')
            ->sum('montant');

        $this->update(['montant_paye' => $montantPaye]);
    }

    protected static function boot()
    {
        parent::boot();

        static::saved(function ($souscription) {
            // Recalculer le montant total après sauvegarde
            $total = $souscription->souscriptionProduits()->sum('sous_total');

            if ($total != $souscription->montant_total) {
                // Utiliser updateQuietly pour éviter une boucle infinie
                $souscription->updateQuietly(['montant_total' => $total]);
            }
        });

        /*static::saved(function ($souscription) {
            // Recalculer le montant total après sauvegarde
            $total = DB::table('produit_souscription')
                ->where('souscription_id', $souscription->id)
                ->sum('sous_total');

            if ($total != $souscription->montant_total) {
                $souscription->update(['montant_total' => $total]);
            }
        });*/
    }

}
