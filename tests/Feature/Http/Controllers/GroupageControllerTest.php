<?php

use App\Models\Groupage;
use App\Models\Produit;
use App\Models\User;

uses(\Illuminate\Foundation\Testing\RefreshDatabase::class);

test('Un administrateur peut créer un groupage', function () {
    $produit = Produit::factory()->create();
    loginAdmin();
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

test('les administrateurs peuvent voir la liste des groupages', function () {
    // Arrange
    $admin = User::factory()->create(['role' => 'admin']);

    // Créer des groupages avec différents statuts
    $groupage = Groupage::factory()->create();

    // Act
    $this->actingAs($admin);

    $response = $this
        ->get(route('groupages.index'));

    expect($response->status())->toBe(200);

    $response->assertSee($groupage->nom)
        ->assertSee($groupage->date_debut)
        ->assertSee($groupage->date_fin)
        ->assertSee($groupage->statut);
});

it('valide les champs obligatoires du formulaire de création de groupage', function () {
    // Arrange
    $admin = User::factory()->create(['role' => 'admin']);

    // Créer des groupages avec différents statuts
    $groupage = Groupage::factory()->create();

    $response = $this
        ->actingAs($admin)
        ->post(route('groupages.store'), []);

    $response->assertSessionHasErrors([
        'nom',
        'date_debut',
        'date_fin',
        'produit_id',
    ]);
});
