<?php

use App\Models\Client;
use App\Models\Groupage;
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
            $table->foreignIdFor(Client::class)->constrained()->onDelete('cascade');
            $table->foreignIdFor(Groupage::class)->constrained()->onDelete('cascade');
            $table->string('numero_souscription')->unique();
            $table->unsignedInteger('montant_total')->default(0)->comment('Montant total en centimes');
            $table->unsignedInteger('montant_paye')->default(0)->comment('Montant payé en centimes');
            $table->enum('statut', ['en_attente', 'confirmee', 'payee', 'annulee'])->default('en_attente');
            $table->date('date_souscription');
            $table->timestamps();

            $table->index(['client_id', 'groupage_id']);
            $table->index('statut');
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
