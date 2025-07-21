<?php

namespace Database\Seeders;

use Faker\Factory as Faker;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class ClientSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $faker = Faker::create('fr_FR');
        for ($i = 0; $i < 20; $i++) {
            DB::table('clients')->insert([
                'nom'                     => $faker->lastName,
                'prenoms'                   => $faker->firstName,
                'adresse'                    => $faker->address,
                'email'                     => $faker->companyEmail,
                'telephone'                => $faker->e164PhoneNumber,
            ]);
        }
    }
}
