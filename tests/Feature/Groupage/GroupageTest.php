<?php

use App\Models\Produit;
use App\Models\User;

test('Un administrateur peut créer un groupage', function () {
    $admin = User::factory()->create(['role' => 'admin']);
    $produit = Produit::factory()->create();
    $this->actingAs($admin);

    $groupageData = [
        'nom' => 'Groupage Test',
        'description' => 'Description du groupage de test',
        'date_debut' => now()->format('Y-m-d H:i:s'),
        'date_fin' => now()->addDays(21)->format('Y-m-d H:i:s'),
        'statut' => 'actif',
        'produit_id' => $produit->id,
    ];

    $response = $this->post(route('groupages.store'), $groupageData);

    // $response->assertStatus(201);
    $this->assertDatabaseHas('groupages', [
        'nom' => 'Groupage Test',
        'produit_id' => $produit->id,
    ]);
});

test('un utilisateur standard ne peut pas créer un groupage', function () {
    // Arrange
    $user = User::factory()->create(['role' => 'souscripteur']);
    $produit = Produit::factory()->create();

    $groupageData = [
        'nom' => 'Groupage Test',
        'description' => 'Description du groupage de test',
        'date_debut' => now()->format('Y-m-d H:i:s'),
        'date_fin' => now()->addDays(21)->format('Y-m-d H:i:s'),
        'statut' => 'actif',
        'produit_id' => $produit->id,
    ];

    // Act
    $response = $this
        ->actingAs($user)
        ->post(route('groupages.store'), $groupageData);

    // Assert
    $response->assertStatus(403);
});
