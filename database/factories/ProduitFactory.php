<?php

namespace Database\Factories;

use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends \Illuminate\Database\Eloquent\Factories\Factory<\App\Models\Produit>
 */
class ProduitFactory extends Factory
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
            'prix_unitaire' => fake()->numberBetween(10000, 100000),
            'stock_disponible' => fake()->numberBetween(20, 50),
        ];
    }
}
