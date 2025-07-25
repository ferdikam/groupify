<?php

namespace Database\Seeders;

use App\Models\User;
// use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        // User::factory(10)->create();

        User::factory()->create([
            'name' => 'John Doe',
            'email' => 'john@example.com',
            'role' => 'admin',
        ]);

        User::factory()->create([
            'name' => 'Jane Doe',
            'email' => 'jane@example.com',
        ]);

        /*$this->call([
            ClientSeeder::class,
        ]);*/
    }
}
