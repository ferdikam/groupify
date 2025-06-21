<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Paiement extends Model
{
    /** @use HasFactory<\Database\Factories\PaiementFactory> */
    use HasFactory;
    protected $casts = [
        'date_paiement' => 'datetime',
        'montant' => 'integer',
    ];

    /**
     * Relation avec la souscription
     */
    public function souscription(): BelongsTo
    {
        return $this->belongsTo(Souscription::class);
    }

    /**
     * Générer un numéro de paiement unique
     */
    public static function genererNumeroPaiement(): string
    {
        do {
            $numero = 'PAY-' . date('Y') . '-' . str_pad(mt_rand(1, 99999), 5, '0', STR_PAD_LEFT);
        } while (self::where('numero_paiement', $numero)->exists());

        return $numero;
    }

    /**
     * Confirmer le paiement et mettre à jour la souscription
     */
    public function confirmer(): void
    {
        $this->update(['statut' => 'confirme']);
        $this->souscription->calculerMontantPaye();

        // Mettre à jour le statut de la souscription si elle est entièrement payée
        if ($this->souscription->est_payee) {
            $this->souscription->update(['statut' => 'payee']);
        }
    }

    /**
     * Rejeter le paiement
     */
    public function rejeter(string $raison = null): void
    {
        $this->update([
            'statut' => 'rejete',
            'commentaire' => $raison
        ]);
    }

    /**
     * Rembourser le paiement
     */
    public function rembourser(string $raison = null): void
    {
        $this->update([
            'statut' => 'rembourse',
            'commentaire' => $raison
        ]);

        $this->souscription->calculerMontantPaye();
    }

    /**
     * Scope pour les paiements confirmés
     */
    public function scopeConfirmes($query)
    {
        return $query->where('statut', 'confirme');
    }

    /**
     * Scope pour les paiements en attente
     */
    public function scopeEnAttente($query)
    {
        return $query->where('statut', 'en_attente');
    }
}
