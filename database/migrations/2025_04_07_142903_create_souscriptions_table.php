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
            $table->unsignedBigInteger('montant_total')->nullable();
            $table->unsignedBigInteger('avance_payee')->nullable();
            $table->unsignedBigInteger('solde_restant')->nullable();
            $table->string('statut')->default('en_attente')->comment("['en_attente', 'paye_partiellement', 'paye_totalement', 'livre']");
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
