<?php

use App\Models\Produit;
use App\Models\Souscription;
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('produit_souscription', function (Blueprint $table) {
            $table->id();
            $table->foreignIdFor(Souscription::class)->constrained()
                ->onDelete('cascade');
            $table->foreignIdFor(Produit::class)->constrained()->onDelete('cascade');
            $table->unsignedInteger('quantite');
            $table->unsignedInteger('prix_unitaire')->comment('Prix unitaire au moment de la souscription en centimes');
            $table->unsignedInteger('sous_total')->comment('Quantité × Prix unitaire en centimes');
            $table->timestamps();

            // Contrainte d'unicité pour éviter les doublons
            $table->unique(['souscription_id', 'produit_id']);

            // Index pour les requêtes fréquentes
            $table->index('souscription_id');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('produit_souscription');
    }
};
