<?php

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
        Schema::create('paiements', function (Blueprint $table) {
            $table->id();
            $table->foreignIdFor(Souscription::class)->constrained()->onDelete('cascade');
            $table->string('numero_paiement')->unique();
            $table->unsignedInteger('montant')->comment('Montant du paiement en centimes');
            $table->enum('mode_paiement', ['especes', 'carte', 'virement', 'cheque', 'mobile_money']);
            $table->string('reference_paiement')->nullable()->comment('Référence bancaire ou autre');
            $table->enum('statut', ['en_attente', 'confirme', 'rejete', 'rembourse'])->default('en_attente');
            $table->date('date_paiement');
            $table->text('commentaire')->nullable();
            $table->timestamps();

            $table->index('souscription_id');
            $table->index('statut');
            $table->index('date_paiement');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('paiements');
    }
};
