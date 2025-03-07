<?php

namespace Database\Factories;

use App\Models\Produit;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends \Illuminate\Database\Eloquent\Factories\Factory<\App\Models\Groupage>
 */
class GroupageFactory extends Factory
{
    /**
     * Define the model's default state.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'nom' => fake()->word(),
            'description' => fake()->paragraph(),
            'date_debut' => now()->format('Y-m-d H:i:s'),
            'date_fin' => now()->addDays(21)->format('Y-m-d H:i:s'),
            'statut' => 'actif',
            'produit_id' => Produit::factory()->create()->id,
        ];
    }
}
