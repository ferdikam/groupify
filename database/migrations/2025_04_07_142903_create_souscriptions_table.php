<?php

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
        Schema::create('souscriptions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->foreignId('groupage_id')->constrained()->onDelete('cascade');
            $table->integer('quantite');
            $table->decimal('montant_total', 10, 2);
            $table->decimal('avance_payee', 10, 2)->default(0);
            $table->decimal('solde_restant', 10, 2);
            $table->enum('statut', ['en_attente', 'paye_partiellement', 'paye_totalement', 'livre'])->default('en_attente');
            $table->dateTime('date_livraison_souhaitee')->nullable();
            $table->text('lieu_livraison')->nullable();
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('souscriptions');
    }
};
