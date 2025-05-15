<?php

use App\Models\Groupage;
use App\Models\Produit;
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
        Schema::create('groupage_produit', function (Blueprint $table) {
            $table->id();
            $table->foreignIdFor(Groupage::class);
            $table->foreignIdFor(Produit::class);
            $table->unsignedInteger('moq')->default(0)->comment("Quantité d'achat");
            $table->unsignedInteger('prix_achat')->default(0);
            $table->unsignedInteger('prix_transport_fournisseur')->default(0);
            $table->unsignedInteger('fret')->default(0)->comment("Transport + Douane");
            $table->unsignedInteger('prix_livraison')->default(0);
            $table->unsignedInteger('prix_de_revient')->default(0);
            $table->unsignedInteger('prix_vente')->default(0);
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::create('groupage_produit', function (Blueprint $table) {
            $table->dropForeign('groupage_produit_groupage_id_foreign');
            $table->dropForeign('groupage_produit_produit_id_foreign');
            $table->dropColumn('moq');
            $table->dropColumn('prix_achat');
            $table->dropColumn('prix_transport_fournisseur');
            $table->dropColumn('fret');
            $table->dropColumn('prix_livraison');
            $table->dropColumn('prix_de_revient');
            $table->dropColumn('prix_vente');
        });
    }
};
